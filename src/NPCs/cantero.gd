extends CharacterBody2D
class_name Cantero

signal mine_depleted(mine)

# ============================================================
# 🔧 VARIABLES EXPORTADAS
# ============================================================
@export var speed := 100.0
@export var gather_rate := 1.0       # tiempo entre golpes
@export var gather_amount := 3       # piedras por golpe
@export var search_radius := 2000.0
@export var stop_distance := 64.0    # distancia para empezar a picar (más grande que árbol)
@export var target_offset := Vector2(0, -32)  # Ajusta según la mina

# ============================================================
# ⚙️ ESTADOS Y NODOS
# ============================================================
enum State { IDLE, FINDING_MINE, MOVING_TO_MINE, GATHERING }

var current_state = State.IDLE
var target_mine = null
var is_ready = false
var debug := true

var search_cooldown := 0.5
var gather_timer := 0.0
var chop_count := 0
var chop_needed := 3   # golpes necesarios para completar la recolección

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
		print("[Cantero] Creado. Estado IDLE")

# ============================================================
# 🔍 Buscar la mina más cercana
# ============================================================
func _find_nearest_mine():
	var mines = get_tree().get_nodes_in_group("mina")
	var nearest_mine = null
	var min_distance = INF
	var map_rid = nav_agent.get_navigation_map()

	for mine in mines:
		if not is_instance_valid(mine): continue
		if mine.is_depleted or mine.is_occupied: continue
		if not mine.has_method("gather_resource"): continue

		var raw = mine.global_position
		var corrected = NavigationServer2D.map_get_closest_point(map_rid, raw)
		if corrected.distance_to(raw) > 16: continue

		var dist = global_position.distance_to(corrected)
		if dist < min_distance:
			min_distance = dist
			nearest_mine = mine

	if nearest_mine:
		target_mine = nearest_mine
		_start_navigation()
	else:
		if debug: print("[Cantero] No hay minas alcanzables")
		_change_state(State.IDLE)

# ============================================================
# 🚶 Navegación
# ============================================================
func _start_navigation():
	if !is_instance_valid(target_mine):
		_change_state(State.IDLE)
		return

	if not target_mine.occupy(self):
		target_mine = null
		_change_state(State.IDLE)
		return

	if not target_mine.depleted.is_connected(self._on_mine_depleted):
		target_mine.depleted.connect(self._on_mine_depleted)

	var raw = target_mine.global_position + target_offset
	var corrected = NavigationServer2D.map_get_closest_point(nav_agent.get_navigation_map(), raw)
	nav_agent.target_position = corrected
	_change_state(State.MOVING_TO_MINE)


# ============================================================
# ✔ Comprobar si llegó
# ============================================================
func _is_target_in_gather_range() -> bool:
	if !is_instance_valid(target_mine): return false
	var target_pos = target_mine.global_position + target_offset
	return global_position.distance_to(target_pos) <= stop_distance

# ============================================================
# ⏳ MOVIMIENTO + AVOIDANCE
# ============================================================
func _physics_process(delta: float):
	match current_state:
		State.MOVING_TO_MINE:
			if !is_instance_valid(target_mine):
				_on_mine_depleted()
				return

			if _is_target_in_gather_range():
				velocity = Vector2.ZERO
				nav_agent.set_velocity(Vector2.ZERO)
				nav_agent.target_position = global_position
				_change_state(State.GATHERING)
				return

			if nav_agent.is_navigation_finished():
				_on_mine_depleted()
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
# 🪨 Recolección (3 golpes)
# ============================================================
func _gather(delta: float):
	if !is_instance_valid(target_mine):
		_on_mine_depleted()
		return

	if target_mine.is_depleted:
		if debug: print("[Cantero] Mina agotada, deteniendo recolección.")
		_on_mine_depleted()
		return

	gather_timer += delta
	if gather_timer < gather_rate:
		return
	
	gather_timer = 0.0
	chop_count += 1

	if debug:
		print("[Cantero] Golpe", chop_count, "de", chop_needed)

	# Aplicar daño a la mina
	target_mine.gather_resource(gather_amount)

	# Sumar al ResourceManager
	if is_instance_valid(resource_manager):
		resource_manager.add_resource("stone", gather_amount)

	# Si se completan los golpes, marcar agotada y llamar fell()
	if chop_count >= chop_needed:
		if debug: print("[Cantero] Mina picada completamente.")

		if is_instance_valid(target_mine):
			emit_signal("mine_depleted", target_mine)
			if target_mine.has_method("fell"):
				target_mine.fell()

# ============================================================
# 🔄 Estados y animaciones
# ============================================================
func _change_state(new_state):
	if current_state == new_state: return
	current_state = new_state

	match new_state:
		State.IDLE:
			anim_sprite.play("Idle")

		State.MOVING_TO_MINE:
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
			if target_mine == null:
				_change_state(State.FINDING_MINE)

		State.FINDING_MINE:
			_find_nearest_mine()

	search_cooldown = 0.3

# ============================================================
# 🧹 Reset al acabar
# ============================================================
func _on_mine_depleted():
	if is_instance_valid(target_mine):
		if target_mine.depleted.is_connected(self._on_mine_depleted):
			target_mine.depleted.disconnect(self._on_mine_depleted)
		target_mine.release()
		target_mine = null
		
	_change_state(State.IDLE)
