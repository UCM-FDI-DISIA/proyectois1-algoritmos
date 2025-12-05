extends CharacterBody2D
class_name Lenador

signal tree_felled(tree)

# ============================================================
# 🔧 VARIABLES EXPORTADAS
# ============================================================
@export var speed := 100.0
@export var gather_rate := 1.0     # tiempo entre golpes
@export var gather_amount := 5
@export var search_radius := 2000.0
@export var search_fuzziness := 50.0
@export var stop_distance := 32.0   # distancia real para talar
@export var target_offset := Vector2(-46, -46)

# ============================================================
# ⚙️ ESTADOS Y NODOS
# ============================================================
enum State { IDLE, FINDING_TREE, MOVING_TO_TREE, GATHERING }

var current_state = State.IDLE
var target_tree = null
var is_ready = false
var debug := true

var search_cooldown := 0.5
var gather_timer := 0.0

# 🔨 Golpes necesarios para talar
var chop_count := 0
var chop_needed := 3 # Ya estaba en 3, perfecto para el requerimiento

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

	if debug:
		print("[Lenador] Creado. Estado IDLE")

# ============================================================
# 🌲 Encontrar árbol más cercano
# ============================================================
func _find_nearest_tree():
	var trees = get_tree().get_nodes_in_group("arbol")
	var nearest_tree = null
	var min_distance = INF
	var map_rid = nav_agent.get_navigation_map()

	for tree in trees:
		if not is_instance_valid(tree): continue
		# Solo busca árboles no muertos y no ocupados
		if tree.is_dead or tree.is_occupied: continue
		if not tree.has_method("gather_resource"): continue

		var raw = tree.global_position
		var corrected = NavigationServer2D.map_get_closest_point(map_rid, raw)
		if corrected.distance_to(raw) > 16: continue

		var dist = global_position.distance_to(corrected)
		if dist < min_distance:
			min_distance = dist
			nearest_tree = tree

	if nearest_tree:
		target_tree = nearest_tree
		_start_navigation()
	else:
		if debug: print("[Lenador] No hay árboles alcanzables")
		_change_state(State.IDLE)

# ============================================================
# 🚶 Navegación
# ============================================================
func _start_navigation():
	if !is_instance_valid(target_tree): 
		_change_state(State.IDLE)
		return

	# Ocupar y conectar señal
	if !target_tree.occupy(self):
		target_tree = null
		_change_state(State.IDLE)
		return
		
	if !target_tree.depleted.is_connected(self._on_tree_depleted):
		target_tree.depleted.connect(self._on_tree_depleted)

	var raw = target_tree.global_position
	var corrected = NavigationServer2D.map_get_closest_point(nav_agent.get_navigation_map(), raw)
	nav_agent.target_position = corrected
	_change_state(State.MOVING_TO_TREE)

# ============================================================
# ✔ DISTANCIA REAL para empezar a talar
# ============================================================
func _is_target_in_gather_range() -> bool:
	if !is_instance_valid(target_tree): return false
	return global_position.distance_to(target_tree.global_position) <= stop_distance

# ============================================================
# ⏳ MOVIMIENTO + AVOIDANCE
# ============================================================
func _physics_process(delta: float):
	match current_state:

		State.MOVING_TO_TREE:
			if !is_instance_valid(target_tree):
				_on_tree_depleted()
				return

			if _is_target_in_gather_range():
				velocity = Vector2.ZERO
				nav_agent.set_velocity(Vector2.ZERO)
				nav_agent.target_position = global_position
				_change_state(State.GATHERING)
				return

			if nav_agent.is_navigation_finished():
				_on_tree_depleted()
				return

			var next_point = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_point)
			var desired_velocity = direction * speed

			_animate_movement(direction)
			nav_agent.set_velocity(desired_velocity)

		State.GATHERING:
			velocity = Vector2.ZERO
			move_and_slide()
			_gather(delta)

		_:
			velocity = Vector2.ZERO
			move_and_slide()

func _on_velocity_computed(v):
	velocity = v
	move_and_slide()

# ============================================================
# 🪓 RECOLECCIÓN (3 GOLPES)
# ============================================================
func _gather(delta: float):
	if !is_instance_valid(target_tree):
		_on_tree_depleted()
		return

	# El leñador se detiene si el árbol está marcado como muerto (por la señal 'depleted')
	if target_tree.is_dead:
		if debug: print("[Lenador] Árbol inactivo/muerto, deteniendo tala.")
		_on_tree_depleted()
		return

	gather_timer += delta
	if gather_timer < gather_rate:
		return
	
	gather_timer = 0.0
	chop_count += 1

	if debug:
		print("[Lenador] Golpe", chop_count, "de", chop_needed)

	# 1. Aplicar daño al árbol
	target_tree.gather_resource(gather_amount)

	# 2. Sumar 1 de madera al Resource Manager por golpe
	if is_instance_valid(resource_manager):
		resource_manager.add_resource("wood", 1)
	
	# 3. Si se completaron los golpes, talar el árbol
	if chop_count >= chop_needed:
		if debug: print("[Lenador] Árbol talado completamente (3 golpes).")

		if is_instance_valid(target_tree):
			emit_signal("tree_felled", target_tree)
			
			# **CORRECCIÓN CLAVE:** El leñador llama a fell() para activar la muerte y el temporizador
			if target_tree.has_method("fell"):
				target_tree.fell()
		
		# El árbol emitirá 'depleted', lo que llama a _on_tree_depleted

# ============================================================
# 🔄 Estados y animaciones
# ============================================================
func _change_state(new_state):
	if current_state == new_state: return
	current_state = new_state

	match new_state:
		State.IDLE:
			anim_sprite.play("Idle")

		State.MOVING_TO_TREE:
			anim_sprite.play("Caminar")

		State.GATHERING:
			chop_count = 0
			gather_timer = 0
			anim_sprite.play("Recolectar")

func _animate_movement(direction: Vector2):
	if abs(direction.x) > 0.1:
		anim_sprite.flip_h = direction.x < 0

# ============================================================
# 🔍 AI básico de búsqueda
# ============================================================
func _process(delta: float):
	z_index = int(global_position.y)

	if search_cooldown > 0:
		search_cooldown -= delta
		return

	match current_state:
		State.IDLE:
			if target_tree == null:
				_change_state(State.FINDING_TREE)

		State.FINDING_TREE:
			_find_nearest_tree()

	search_cooldown = 0.3

# ============================================================
# 🧹 RESET AL ACABAR
# ============================================================
func _on_tree_depleted():
	# Desconectar la señal y liberar ocupación
	if is_instance_valid(target_tree):
		if target_tree.depleted.is_connected(self._on_tree_depleted):
			target_tree.depleted.disconnect(self._on_tree_depleted)
		target_tree.release()
		target_tree = null
		
	_change_state(State.IDLE)
