extends CharacterBody2D
class_name Minero

signal mine_depleted(mine: Node)

# ============================================================
# 🔧 VARIABLES EXPORTADAS
# ============================================================
@export var speed: float = 100.0
@export var gather_rate: float = 1.0     # tiempo entre golpes
@export var gather_amount: int = 5       # Daño por golpe
@export var search_radius: float = 2000.0
@export var search_fuzziness: float = 50.0
@export var stop_distance: float = 32.0
@export var target_offset: Vector2 = Vector2(-46, -46)

# ============================================================
# ⚙️ ESTADOS Y NODOS
# ============================================================
enum State { IDLE, FINDING_MINE, MOVING_TO_MINE, GATHERING }

var current_state: State = State.IDLE
var target_mine: Node = null
var gather_timer: float = 0.0
var chop_count: int = 0
var chop_needed: int = 3
var search_cooldown: float = 0.3
var debug: bool = true

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var resource_manager: Node = get_node("/root/Main/ResourceManager")

# ============================================================
# 🔧 READY
# ============================================================
func _ready() -> void:
	randomize()
	current_state = State.IDLE
	set_process(true)
	set_physics_process(true)

	if is_instance_valid(nav_agent):
		nav_agent.avoidance_enabled = true
		nav_agent.velocity_computed.connect(_on_velocity_computed)

	if debug:
		print("[Minero] Creado. Estado IDLE")

# ============================================================
# ⛏️ Buscar mina más cercana disponible
# ============================================================
func _find_nearest_mine() -> void:
	var mines = get_tree().get_nodes_in_group("mina_oro") # Solo minas de oro
	var nearest_mine: Node = null
	var min_distance: float = INF

	for mine in mines:
		if not is_instance_valid(mine): continue
		if mine.is_depleted or mine.is_occupied: continue
		if not mine.has_method("gather_resource"): continue

		var dist = global_position.distance_to(mine.global_position)
		if dist < min_distance:
			min_distance = dist
			nearest_mine = mine

	if nearest_mine:
		target_mine = nearest_mine
		_start_navigation()
	else:
		if debug: print("[Minero] No hay minas libres")
		_change_state(State.IDLE)


# ============================================================
# 🚶 Navegación hacia la mina
# ============================================================
func _start_navigation() -> void:
	if not is_instance_valid(target_mine):
		_change_state(State.IDLE)
		return

	# Ocupar la mina
	if not target_mine.occupy(self):
		target_mine = null
		_change_state(State.IDLE)
		return

	if not target_mine.depleted.is_connected(_on_mine_depleted):
		target_mine.depleted.connect(_on_mine_depleted)

	nav_agent.target_position = target_mine.global_position
	_change_state(State.MOVING_TO_MINE)

# ============================================================
# ✔ Comprobar si está dentro del rango para minar
# ============================================================
func _is_target_in_gather_range() -> bool:
	if not is_instance_valid(target_mine):
		return false
	return global_position.distance_to(target_mine.global_position) <= stop_distance

# ============================================================
# ⏳ MOVIMIENTO + AVOIDANCE
# ============================================================
func _physics_process(delta: float) -> void:
	match current_state:
		State.MOVING_TO_MINE:
			if not is_instance_valid(target_mine):
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

			var next_point: Vector2 = nav_agent.get_next_path_position()
			var direction: Vector2 = global_position.direction_to(next_point)
			var desired_velocity: Vector2 = direction * speed

			_animate_movement(direction)
			nav_agent.set_velocity(desired_velocity)

		State.GATHERING:
			velocity = Vector2.ZERO
			move_and_slide()
			_gather(delta)

		_:
			velocity = Vector2.ZERO
			move_and_slide()

func _on_velocity_computed(v: Vector2) -> void:
	velocity = v
	move_and_slide()

# ============================================================
# ⚒️ Minería automática (3 golpes)
# ============================================================
func _gather(delta: float) -> void:
	if not is_instance_valid(target_mine):
		_on_mine_depleted()
		return

	if target_mine.is_depleted:
		_on_mine_depleted()
		return

	gather_timer += delta
	if gather_timer < gather_rate:
		return

	gather_timer = 0.0
	chop_count += 1

	if debug:
		print("[Minero] Golpe", chop_count, "de", chop_needed)

	# Aplicar daño
	target_mine.gather_resource(gather_amount)

	# Añadir recurso al Resource Manager
	if is_instance_valid(resource_manager):
		resource_manager.add_resource("gold", 1) # Añadimos oro, no piedra


	# Si completó los golpes
	if chop_count >= chop_needed:
		if is_instance_valid(target_mine):
			emit_signal("mine_depleted", target_mine)
			if target_mine.has_method("fell"):
				target_mine.fell()  # método equivalente a 'deplete' en MinaOroAnimado

# ============================================================
# 🔄 Cambiar estado y animaciones
# ============================================================
func _change_state(new_state: State) -> void:
	if current_state == new_state:
		return

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

func _animate_movement(direction: Vector2) -> void:
	if abs(direction.x) > 0.1:
		anim_sprite.flip_h = direction.x < 0

# ============================================================
# 🔍 AI búsqueda
# ============================================================
func _process(delta: float) -> void:
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
func _on_mine_depleted() -> void:
	if is_instance_valid(target_mine):
		if target_mine.depleted.is_connected(_on_mine_depleted):
			target_mine.depleted.disconnect(_on_mine_depleted)
		target_mine.release()
		target_mine = null

	_change_state(State.IDLE)
