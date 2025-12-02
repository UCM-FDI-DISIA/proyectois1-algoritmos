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
		nav_agent.velocity_computed.connect(self._on_velocity_computed)

		# === Debug: mostrar todos los navmeshes del padre ===
		print("NavAgent map:", nav_agent.get_navigation_map())
		for child in get_parent().get_children():
			if child is NavigationRegion2D:
				print("NavRegion:", child, "RID:", child.get_navigation_map())
	debug_tree_accessibility()

	if debug:
		print("[Lenador] Creado. Estado: IDLE")

func debug_tree_accessibility():
	if not is_instance_valid(nav_agent):
		print("❌ No hay NavigationAgent2D válido")
		return

	var map_rid = nav_agent.get_navigation_map()
	if not map_rid.is_valid():
		print("❌ NavigationMap no válido")
		return


	var trees = get_tree().get_nodes_in_group("arbol")
	for tree in trees:
		if not is_instance_valid(tree):
			continue

		var tree_pos = tree.global_position
		var closest_point = NavigationServer2D.map_get_closest_point(map_rid, tree_pos)

		if closest_point == Vector2.ZERO:
			print("[ALERTA] Árbol en", tree_pos, "NO tiene punto de navegación cercano")
			continue

		# Intentamos generar ruta desde el Lenador hasta el árbol
		var path = NavigationServer2D.map_get_path(map_rid, global_position, closest_point, false)

		if path.size() == 0:
			print("[NO ALCANZABLE] Árbol en", tree_pos)
		else:
			print("[ALCANZABLE] Árbol en", tree_pos, "→ ruta con", path.size(), "puntos")

# ============================================================
# 🌲 Encontrar árbol más cercano
# ============================================================
func _find_nearest_tree():
	# Obtener todos los nodos en el grupo "arbol"
	var trees = get_tree().get_nodes_in_group("arbol")
	var nearest_tree = null
	var min_distance = INF
	var map_rid = nav_agent.get_navigation_map()

	for tree in trees:
		if not is_instance_valid(tree): 
			continue
		if tree.has_meta("is_dead") and tree.get_meta("is_dead"): 
			continue
		if not tree.has_method("gather_resource"): 
			continue

		# PUNTO SEGURO: cerca del árbol, pero fuera del obstacle
		var raw_target = tree.global_position
		var corrected_target = NavigationServer2D.map_get_closest_point(map_rid, raw_target)

		# Si está demasiado lejos del NavMesh, descartamos
		if corrected_target.distance_to(raw_target) > 8: # 8px margen
			continue

		# Offset para no chocar con el obstacle
		var direction = (corrected_target - global_position).normalized()
		var safe_target = corrected_target - direction * nav_agent.radius

		var dist_var = global_position.distance_to(safe_target) + randf_range(0.0, search_fuzziness)

		if dist_var < min_distance:
			min_distance = dist_var
			nearest_tree = tree

	if nearest_tree:
		target_tree = nearest_tree
		# Conectar señal solo si no estaba conectada
		var callback = Callable(self, "_on_tree_depleted")
		if not target_tree.is_connected("depleted", callback):
			target_tree.connect("depleted", callback)
		_start_navigation()
	else:
		if debug:
			print("[Lenador] No se encontraron árboles alcanzables")
		_change_state(State.IDLE)



# ============================================================
# 🚶 Navegación robusta y corregida
# ============================================================
func _start_navigation():
	if not is_instance_valid(target_tree) or not is_instance_valid(nav_agent):
		_change_state(State.IDLE)
		return

	var map_rid = nav_agent.get_navigation_map()
	var raw_target: Vector2 = target_tree.global_position

	# → Corregir target al punto más cercano dentro del navmesh
	var corrected_target = NavigationServer2D.map_get_closest_point(map_rid, raw_target)

	# → Aplicar pequeño offset para no quedar dentro del obstacle
	var direction_from_agent = (corrected_target - global_position).normalized()
	var safe_target = corrected_target - direction_from_agent * nav_agent.radius

	if debug:
		print("[Lenador] Raw target:%s → Corrected:%s → Safe target:%s" % [raw_target, corrected_target, safe_target])

	# Asignar target corregido y seguro al NavigationAgent
	nav_agent.set_target_position(safe_target)
	_change_state(State.MOVING_TO_TREE)

	# Asignar target corregido al NavigationAgent
	nav_agent.set_target_position(corrected_target)
	_change_state(State.MOVING_TO_TREE)

# ============================================================
# ⏳ Movimiento + avoidance
# ============================================================
func _physics_process(delta: float):
	match current_state:

		State.MOVING_TO_TREE:

			if not is_instance_valid(target_tree):
				_change_state(State.IDLE)
				return

			if nav_agent.is_navigation_finished():
				if debug: print(">>> Navigation finished")
				_change_state(State.GATHERING)
				velocity = Vector2.ZERO
				return

			if not nav_agent.is_target_reachable():
				if debug: print(">>> Target no reachable, buscando otro...")
				target_tree = null
				_change_state(State.IDLE)
				return

			var next_point = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_point)

			var desired_velocity = direction * speed
			desired_velocity = _avoid_dynamic_collisions(desired_velocity, delta)

			_animate_movement(direction)
			nav_agent.set_velocity(desired_velocity)

		State.GATHERING:
			_gather(delta)

		_:
			velocity = Vector2.ZERO
			move_and_slide()

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

# ============================================================
# ⛏️ Recolección
# ============================================================
func _gather(delta: float):
	if not is_instance_valid(target_tree):
		_on_tree_depleted()
		return

	gather_timer += delta
	if gather_timer >= gather_rate:
		gather_timer = 0.0
		var wood_gained = target_tree.gather_resource(gather_amount)

		if is_instance_valid(resource_manager):
			resource_manager.add_resource("wood", wood_gained)

		if debug:
			print("[Lenador] Recolectando:", wood_gained)

		if wood_gained == 0:
			_on_tree_depleted()

func _on_tree_depleted():
	if is_instance_valid(target_tree) and target_tree.is_connected("depleted", _on_tree_depleted):
		target_tree.disconnect("depleted", _on_tree_depleted)

	target_tree = null
	_change_state(State.IDLE)

# ============================================================
# 🔄 Estados y animaciones
# ============================================================
func _change_state(new_state: State):
	if current_state == new_state:
		return

	if debug:
		print("[Lenador] Cambio de estado →", new_state)

	current_state = new_state

	match new_state:
		State.IDLE:
			anim_sprite.play("Idle")
		State.MOVING_TO_TREE:
			anim_sprite.play("Caminar")
		State.GATHERING:
			anim_sprite.play("Recolectar")

func _animate_movement(direction: Vector2):
	if abs(direction.x) > 0.1:
		anim_sprite.flip_h = direction.x < 0

# ============================================================
# 🔍 AI básico de búsqueda
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
# 🛡️ Evitar colisiones dinámicas con raycast
# ============================================================
func _avoid_dynamic_collisions(desired_velocity: Vector2, delta: float) -> Vector2:
	var space_state = get_world_2d().direct_space_state
	var cast_from = global_position
	var cast_to = global_position + desired_velocity * delta

	var query = PhysicsRayQueryParameters2D.new()
	query.from = cast_from
	query.to = cast_to
	query.exclude = [self]

	var result = space_state.intersect_ray(query)
	if result:
		return desired_velocity.slide(result.normal)

	return desired_velocity
