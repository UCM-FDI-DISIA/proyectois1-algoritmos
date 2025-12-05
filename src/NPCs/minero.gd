extends CharacterBody2D
class_name Minero

signal mine_depleted(mine)

# ============================================================
# 🔧 VARIABLES EXPORTADAS
# ============================================================
@export var speed := 100.0
@export var gather_rate := 1.0     # tiempo entre golpes
@export var gather_amount := 5    # Daño por golpe (igual que la madera)
@export var search_radius := 2000.0
@export var search_fuzziness := 50.0
@export var stop_distance := 32.0   # distancia real para minar
@export var target_offset := Vector2(-46, -46)

# ============================================================
# ⚙️ ESTADOS Y NODOS
# ============================================================
enum State { IDLE, FINDING_MINE, MOVING_TO_MINE, GATHERING }

var current_state = State.IDLE
var target_mine = null # Cambiado target_tree a target_mine
var is_ready = false
var debug := true

var search_cooldown := 0.5
var gather_timer := 0.0

# 🔨 Golpes necesarios para minar (igual que para talar)
var chop_count := 0
var chop_needed := 3

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
		print("[Minero] Creado. Estado IDLE")

# ============================================================
# ⛰️ Encontrar mina más cercana
# ============================================================
func _find_nearest_mine():
	# Buscar nodos en el grupo "mina"
	var mines = get_tree().get_nodes_in_group("mina")
	var nearest_mine = null
	var min_distance = INF
	var map_rid = nav_agent.get_navigation_map()

	for mine in mines:
		if not is_instance_valid(mine): continue
		# Solo busca minas no agotadas y no ocupadas
		if mine.is_dead or mine.is_occupied: continue
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
		if debug: print("[Minero] No hay minas alcanzables o libres")
		_change_state(State.IDLE)

# ============================================================
# 🚶 Navegación
# ============================================================
func _start_navigation():
	if !is_instance_valid(target_mine): 
		_change_state(State.IDLE)
		return

	# Ocupar y conectar señal
	if !target_mine.occupy(self):
		target_mine = null
		_change_state(State.IDLE)
		return
		
	if !target_mine.depleted.is_connected(self._on_mine_depleted):
		# Conectamos a _on_mine_depleted (función renombrada)
		target_mine.depleted.connect(self._on_mine_depleted)

	var raw = target_mine.global_position
	var corrected = NavigationServer2D.map_get_closest_point(nav_agent.get_navigation_map(), raw)
	nav_agent.target_position = corrected
	_change_state(State.MOVING_TO_MINE)

# ============================================================
# ✔ DISTANCIA REAL para empezar a minar
# ============================================================
func _is_target_in_gather_range() -> bool:
	if !is_instance_valid(target_mine): return false
	return global_position.distance_to(target_mine.global_position) <= stop_distance

# ============================================================
# ⏳ MOVIMIENTO + AVOIDANCE
# ============================================================
func _physics_process(delta: float):
	match current_state:

		State.MOVING_TO_MINE:
			if !is_instance_valid(target_mine):
				_on_mine_depleted() # Llama al reset si la mina desapareció
				return

			if _is_target_in_gather_range():
				if debug: print(">>> Mina alcanzada, comenzando minería")
				velocity = Vector2.ZERO
				nav_agent.set_velocity(Vector2.ZERO)
				nav_agent.target_position = global_position
				_change_state(State.GATHERING)
				return

			if nav_agent.is_navigation_finished():
				if debug: print(">>> La ruta terminó pero no alcanzó la mina")
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
# ⚒️ RECOLECCIÓN (3 GOLPES)
# ============================================================
func _gather(delta: float):
	if !is_instance_valid(target_mine):
		_on_mine_depleted()
		return

	# El minero se detiene si la mina está marcada como agotada (por la señal 'depleted')
	if target_mine.is_dead:
		if debug: print("[Minero] Mina inactiva/agotada, deteniendo minería.")
		_on_mine_depleted()
		return

	gather_timer += delta
	if gather_timer < gather_rate:
		return
	
	gather_timer = 0.0
	chop_count += 1

	if debug:
		print("[Minero] Golpe", chop_count, "de", chop_needed)

	# 1. Aplicar daño a la mina
	target_mine.gather_resource(gather_amount)

	# 2. Sumar 1 de piedra al Resource Manager por golpe
	if is_instance_valid(resource_manager):
		# Recurso cambiado a "stone"
		resource_manager.add_resource("stone", 1) 
		if debug:
			print("[Minero] Añadida 1 de piedra al Resource Manager por el golpe.")
	
	# 3. Si se completaron los golpes, agotar la mina
	if chop_count >= chop_needed:
		if debug: print("[Minero] Mina agotada completamente (3 golpes).")

		if is_instance_valid(target_mine):
			emit_signal("mine_depleted", target_mine) # Señal cambiada
			
			if target_mine.has_method("deplete"): # Función de agotamiento cambiada a 'deplete'
				target_mine.deplete() 
		
		# La mina emitirá 'depleted', lo que llama a _on_mine_depleted

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
# 🧹 RESET AL ACABAR
# ============================================================
func _on_mine_depleted():
	# Desconectar la señal y liberar ocupación
	if is_instance_valid(target_mine):
		if target_mine.depleted.is_connected(self._on_mine_depleted):
			target_mine.depleted.disconnect(self._on_mine_depleted)
		target_mine.release()
		target_mine = null
		
	_change_state(State.IDLE)
