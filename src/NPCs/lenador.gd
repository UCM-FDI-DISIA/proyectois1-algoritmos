extends CharacterBody2D
class_name Lenador

# ============================================================
# 🔧 VARIABLES EXPORTADAS
# ============================================================
@export var speed := 100.0
@export var gather_rate := 1.0 
@export var gather_amount := 5 
@export var search_radius := 2000.0
@export var search_fuzziness := 50.0
@export var target_offset := Vector2(0, -16) # evita que el agente choque con árbol

# ============================================================
# ⚙️ ESTADOS
# ============================================================
enum State {
	IDLE,
	FINDING_TREE,
	MOVING_TO_TREE,
	GATHERING
}

var current_state = State.IDLE
var target_tree = null
var is_ready = false
var debug := true

# ============================================================
# 🧩 NODOS
# ============================================================
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var resource_manager = get_node("/root/Main/ResourceManager")

# ============================================================
# ⏱ COOLDOWN DE BÚSQUEDA
# ============================================================
var search_cooldown := 0.5

# ============================================================
# 🔧 READY
# ============================================================
func _ready():
	randomize()
	
	if is_instance_valid(nav_agent):
		nav_agent.avoidance_enabled = true
		nav_agent.velocity_computed.connect(self._on_velocity_computed)

	current_state = State.IDLE
	is_ready = true
	set_process(true)
	set_physics_process(true)
	
	if debug:
		print("[Lenador] Creado. Estado: IDLE")
	z_as_relative = false
# ============================================================
# ⏳ PROCESS
# ============================================================
func _process(delta: float):
	if search_cooldown > 0:
		search_cooldown -= delta
		return

	match current_state:
		State.IDLE:
			_change_state(State.FINDING_TREE)
		State.FINDING_TREE:
			_find_nearest_tree()

	search_cooldown = 0.3
	z_index = int(global_position.y)
# ============================================================
# 🧱 PHYSICS PROCESS
# ============================================================
func _physics_process(delta: float):
	match current_state:
		State.MOVING_TO_TREE:
			if not is_instance_valid(nav_agent):
				_change_state(State.IDLE)
				return

			if nav_agent.is_navigation_finished():
				_change_state(State.GATHERING)
				velocity = Vector2.ZERO
				move_and_slide()
				return

			if not nav_agent.is_target_reachable():
				if debug:
					print("[Lenador] Árbol no reachable → IDLE")
				_on_tree_depleted()
				return

			var next_point = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_point)
			var velocity_to_point = direction * speed
			_animate_movement(direction)
			nav_agent.set_velocity(velocity_to_point)

		State.GATHERING:
			_gather(delta)

		_:
			velocity = Vector2.ZERO
			move_and_slide()

# ============================================================
# 🧭 BÚSQUEDA DE ÁRBOLES
# ============================================================
func _find_nearest_tree():
	var space_state = get_world_2d().direct_space_state
	var shape_query = PhysicsShapeQueryParameters2D.new()
	shape_query.transform = Transform2D(0, global_position)
	var circle = CircleShape2D.new()
	circle.radius = search_radius
	shape_query.shape = circle
	shape_query.collide_with_areas = true
	shape_query.collide_with_bodies = true

	var results = space_state.intersect_shape(shape_query)

	if debug:
		print("[Lenador] Detectados %d posibles objetos" % results.size())

	var nearest_tree = null
	var min_distance = INF

	for result in results:
		var node = result.collider
		if is_instance_valid(node) and node.is_in_group("arbol") and node.has_method("gather_resource"):
			if node.has_meta("is_dead") and node.get_meta("is_dead"):
				continue

			var actual_distance = global_position.distance_to(node.global_position)
			var varied_distance = actual_distance + randf_range(0.0, search_fuzziness)

			if varied_distance < min_distance:
				min_distance = varied_distance
				nearest_tree = node

	if nearest_tree:
		target_tree = nearest_tree
		var target_pos = target_tree.global_position + target_offset

		if not nav_agent.is_target_reachable():
			if debug:
				print("[Lenador] Árbol encontrado pero no reachable, ignorando")
			target_tree = null
			_change_state(State.IDLE)
			return

		if not target_tree.is_connected("depleted", _on_tree_depleted):
			target_tree.connect("depleted", _on_tree_depleted)

		_start_navigation()
	else:
		if debug:
			print("[Lenador] No se encontró árbol → IDLE")
		_change_state(State.IDLE)

# ============================================================
# 🚶 NAVEGACIÓN
# ============================================================
func _start_navigation():
	if is_instance_valid(target_tree) and is_instance_valid(nav_agent):
		nav_agent.set_target_position(target_tree.global_position + target_offset)
		_change_state(State.MOVING_TO_TREE)
	else:
		_change_state(State.IDLE)

func _on_velocity_computed(safe_velocity: Vector2):
	velocity = safe_velocity
	move_and_slide()

# ============================================================
# ⛏️ RECOLECCIÓN
# ============================================================
var gather_timer := 0.0

func _gather(delta: float):
	if not is_instance_valid(target_tree):
		_on_tree_depleted()
		return

	anim_sprite.play("Recolectar")
	gather_timer += delta

	if gather_timer >= gather_rate:
		gather_timer = 0.0
		var wood_gained = target_tree.gather_resource(gather_amount)
		if is_instance_valid(resource_manager):
			resource_manager.add_resource("wood", wood_gained)
		if debug:
			print("[Lenador] Recolectando %d de madera" % wood_gained)
		if wood_gained == 0:
			_on_tree_depleted()

# ============================================================
# 🌲 EVENTOS
# ============================================================
func _on_tree_depleted():
	if is_instance_valid(target_tree) and target_tree.is_connected("depleted", _on_tree_depleted):
		target_tree.disconnect("depleted", _on_tree_depleted)
	target_tree = null
	_change_state(State.IDLE)

# ============================================================
# 🎭 ESTADOS Y ANIMACIÓN
# ============================================================
func _change_state(new_state: State):
	if current_state == new_state:
		return

	if debug:
		print("[Lenador] Cambio de estado → %d" % new_state)

	current_state = new_state

	if not is_instance_valid(anim_sprite):
		return

	match new_state:
		State.IDLE:
			anim_sprite.play("Idle")
		State.FINDING_TREE:
			pass
		State.MOVING_TO_TREE:
			anim_sprite.play("Caminar")
		State.GATHERING:
			anim_sprite.play("Recolectar")

func _animate_movement(direction: Vector2):
	anim_sprite.play("Caminar")
	if abs(direction.x) > 0.1:
		anim_sprite.flip_h = direction.x < 0
