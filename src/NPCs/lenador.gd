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
@export var target_offset := Vector2(0, -16)

# ============================================================
# ⚙️ ESTADOS Y NODOS
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

var search_cooldown := 0.5
var gather_timer := 0.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var resource_manager = get_node("/root/Main/ResourceManager")
@onready var mapa = get_node("/root/Main/Mapa")

# ============================================================
# 🔧 READY
# ============================================================
func _ready():
	randomize()
	current_state = State.IDLE
	is_ready = true
	set_process(true)
	set_physics_process(true)

	if is_instance_valid(nav_agent):
		nav_agent.avoidance_enabled = true
		# Conexión correcta del signal
		nav_agent.velocity_computed.connect(self._on_velocity_computed)

	if debug:
		print("[Lenador] Creado. Estado: IDLE")

# ============================================================
# 🌳 BÚSQUEDA DE ÁRBOLES
# ============================================================
func get_all_tree_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []

	for tree in get_tree().get_nodes_in_group("arbol"):
		if is_instance_valid(tree):
			positions.append(tree.global_position)

	return positions

func _find_nearest_tree():
	var trees = get_tree().get_nodes_in_group("arbol")
	var nearest_tree = null
	var min_distance = INF

	for tree in trees:
		if not is_instance_valid(tree):
			continue
		if tree.has_meta("is_dead") and tree.get_meta("is_dead"):
			continue
		if not tree.has_method("gather_resource"):
			continue

		var dist = global_position.distance_to(tree.global_position)
		var dist_var = dist + randf_range(0.0, search_fuzziness)
		if dist_var < min_distance:
			min_distance = dist_var
			nearest_tree = tree

	if nearest_tree:
		target_tree = nearest_tree
		if not target_tree.is_connected("depleted", _on_tree_depleted):
			target_tree.connect("depleted", _on_tree_depleted)
		_start_navigation()
	else:
		if debug:
			print("[Lenador] No se encontraron árboles en el mapa")
		_change_state(State.IDLE)

# ============================================================
# 🚶 NAVEGACIÓN MEJORADA
# ============================================================
func _start_navigation():
	if not is_instance_valid(target_tree) or not is_instance_valid(nav_agent):
		_change_state(State.IDLE)
		return

	var target_pos = target_tree.global_position + target_offset
	nav_agent.set_target_position(target_pos)
	nav_agent.target_desired_distance = 30.0  # ¡clave!
	
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is RectangleShape2D:
			nav_agent.radius = collision_shape.shape.extents.length() * 0.8
		elif collision_shape.shape is CircleShape2D:
			nav_agent.radius = collision_shape.shape.radius * 0.8

	nav_agent.avoidance_enabled = true
	_change_state(State.MOVING_TO_TREE)


# ============================================================
# ⏳ PHYSICS_PROCESS MEJORADO
# ============================================================
func _physics_process(delta: float):
	match current_state:
		State.MOVING_TO_TREE:
			if not is_instance_valid(nav_agent) or not is_instance_valid(target_tree):
				_change_state(State.IDLE)
				return

			# Si el NavigationAgent considera que llegó al objetivo
			if nav_agent.is_navigation_finished():
				_change_state(State.GATHERING)
				velocity = Vector2.ZERO
				return

			# Si el árbol no es reachable, lo ignoramos
			if not nav_agent.is_target_reachable():
				if debug:
					print("[Lenador] Árbol no reachable → IDLE")
				_on_tree_depleted()
				return

			# Movimiento hacia siguiente punto del path
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


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

# ============================================================
# ⛏️ RECOLECCIÓN DE RECURSOS
# ============================================================
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

func _on_tree_depleted():
	if is_instance_valid(target_tree) and target_tree.is_connected("depleted", _on_tree_depleted):
		target_tree.disconnect("depleted", _on_tree_depleted)
	target_tree = null
	_change_state(State.IDLE)

# ============================================================
# 🔄 ESTADOS Y ANIMACIONES
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
