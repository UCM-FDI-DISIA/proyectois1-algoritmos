extends CharacterBody2D
class_name Lenador

# ============================================================
# 🔧 VARIABLES EXPORTADAS (SIN CAMBIOS)
# ============================================================
@export var speed := 100.0
@export var gather_rate := 1.0
@export var gather_amount := 5
@export var search_radius := 2000.0
@export var search_fuzziness := 50.0
@export var target_offset := Vector2(0, -16)
@export var spawn_attempts := 10
@export var spawn_radius := 500.0
@export var collision_margin := 0.8 # Margen para reducir la zona de colisión al validar spawn

# ============================================================
# ⚙️ ESTADOS Y NODOS (SIN CAMBIOS)
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
# 🔧 READY (SIN CAMBIOS)
# ============================================================
func _ready():
	randomize()

	# Validar posición inicial al spawnear
	if not _validar_posicion_spawn(global_position):
		if not _encontrar_posicion_valida_spawn():
			if debug:
				print("[Lenador] Posición inicial no válida y no se encontró alternativa. Destruyendo.")
			queue_free()
			return

	if is_instance_valid(nav_agent):
		nav_agent.avoidance_enabled = true
		nav_agent.velocity_computed.connect(_on_velocity_computed)

	current_state = State.IDLE
	is_ready = true
	set_process(true)
	set_physics_process(true)

	if debug:
		print("[Lenador] Creado. Estado: IDLE")
	z_as_relative = false

# ============================================================
# 🌍 VALIDACIÓN DE POSICIÓN DE SPAWN (CORREGIDA)
# ============================================================
func _validar_posicion_spawn(pos: Vector2) -> bool:
	
	# 1. Comprobación de colisiones con otros objetos (EDIFICIOS/PROPS)
	if not _esta_libre_de_colisiones(pos):
		return false
	
	# 2. Comprobación del terreno (AGUA/SUELO VÁLIDO)
	if not _esta_sobre_terreno_valido_tilemap(pos):
		return false

	# Si pasa ambas comprobaciones, la posición es válida.
	return true

# --- FUNCIÓN AUXILIAR 1: COMPROBACIÓN DE COLISIONES FÍSICAS (SIN CAMBIOS) ---
# Método síncrono usando PhysicsDirectSpaceState2D.
func _esta_libre_de_colisiones(pos: Vector2) -> bool:
	if not is_inside_tree():
		return false
		
	var space_state = get_world_2d().direct_space_state
	var shape_query = PhysicsShapeQueryParameters2D.new()

	# 1. Definir la Transformación (posición)
	shape_query.transform = Transform2D.IDENTITY.translated(pos)

	# 2. Definir la Forma de Colisión (con margen)
	var test_shape: Shape2D
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is RectangleShape2D:
			var rect = RectangleShape2D.new()
			rect.extents = collision_shape.shape.extents * collision_margin
			test_shape = rect
		# (Se pueden añadir otros tipos de forma aquí, como CircleShape2D)
		else:
			test_shape = collision_shape.shape.duplicate()
	else:
		push_error("[Lenador] No se encontró CollisionShape para validar spawn.")
		return false 

	shape_query.shape = test_shape
	shape_query.exclude = [self]
	
	# IMPORTANTE: Usamos la máscara de colisión del Lenador
	shape_query.collision_mask = collision_mask 

	var results = space_state.intersect_shape(shape_query)
	
	# Retorna TRUE si no hay colisiones (la lista de resultados está vacía)
	return results.is_empty()

# --- FUNCIÓN AUXILIAR 2: COMPROBACIÓN DE TILEMAP (AGUA/SUELO) ---
func _esta_sobre_terreno_valido_tilemap(pos: Vector2) -> bool:
	
	if not is_instance_valid(mapa):
		push_error("No se encontró mapa para validar spawn.")
		return false

	# 1. Calcular puntos de chequeo basados en el CollisionShape
	var extents = Vector2.ZERO
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is RectangleShape2D:
			# Usamos la mitad de la dimensión del rectángulo
			extents = collision_shape.shape.extents 
		elif collision_shape.shape is CircleShape2D:
			# Usamos el radio para crear un cuadrado de chequeo
			extents = Vector2(collision_shape.shape.radius, collision_shape.shape.radius)
	
	# Si no se pudo obtener el tamaño, usamos un valor predeterminado seguro
	if extents == Vector2.ZERO:
		extents = Vector2(8, 8) 
	
	# Definimos los puntos de las esquinas del área de colisión del Lenador
	var puntos_de_chequeo = [
		pos + Vector2(extents.x, extents.y),    # Abajo Derecha
		pos + Vector2(-extents.x, extents.y),   # Abajo Izquierda
		pos + Vector2(extents.x, -extents.y),   # Arriba Derecha
		pos + Vector2(-extents.x, -extents.y),  # Arriba Izquierda
		pos # Centro
	]
	
	# 2. Definir Tilemaps
	var tm_subsuelo = mapa.get_node_or_null("Subsuelo") 
	var tilemaps_validos = [
		mapa.get_node_or_null("Suelo"),
		mapa.get_node_or_null("Nivel1"),
		mapa.get_node_or_null("Nivel2"),
		mapa.get_node_or_null("Nivel3"),
		mapa.get_node_or_null("Nivel4"),
	]
	
	# 3. Comprobar cada punto
	for punto in puntos_de_chequeo:
		
		# --- A. Verificar Terreno Inválido (Agua/Subsuelo) ---
		if tm_subsuelo:
			var celda_subsuelo = tm_subsuelo.local_to_map(tm_subsuelo.to_local(punto))
			# Si cualquier punto toca un tile en el Subsuelo, es inválido
			if tm_subsuelo.get_cell_source_id(celda_subsuelo) != -1:
				if debug: print("[Lenador] Spawn Fallido: Toca Subsuelo/Agua en: %s" % punto)
				return false 
			
		# --- B. Verificar Terreno Válido (Suelo Pisable) ---
		var esta_en_terreno_valido = false
		
		for tm_valido in tilemaps_validos:
			if tm_valido == null: continue
			var celda_valida = tm_valido.local_to_map(tm_valido.to_local(punto))
			# Si cualquier punto encuentra un tile en una capa válida, cuenta como válido
			if tm_valido.get_cell_source_id(celda_valida) != -1:
				esta_en_terreno_valido = true
				break 
				
		# Si tras revisar todos los tilemaps válidos, NO encontramos suelo en este punto, es inválido
		if not esta_en_terreno_valido:
			if debug: print("[Lenador] Spawn Fallido: No se encontró Suelo Válido en: %s" % punto)
			return false

	# Si todos los puntos pasan ambas pruebas (no agua y sí suelo), la posición es correcta
	return true

func _encontrar_posicion_valida_spawn() -> bool:
	var original_pos = global_position
	var attempts = 0

	while attempts < spawn_attempts:
		attempts += 1

		# Generar posición aleatoria en un radio alrededor del punto original
		var angle = randf_range(0, TAU)
		var distance = randf_range(0, spawn_radius)
		var new_pos = original_pos + Vector2(cos(angle), sin(angle)) * distance

		if _validar_posicion_spawn(new_pos):
			global_position = new_pos
			if debug:
				print("[Lenador] Posición válida encontrada en intento %d" % attempts)
			return true

	if debug:
		print("[Lenador] No se encontró posición válida después de %d intentos" % spawn_attempts)
	return false

# ============================================================
# ⏳ PROCESS Y PHYSICS PROCESS (SIN CAMBIOS)
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
# 🧭 BÚSQUEDA DE ÁRBOLES (SIN CAMBIOS)
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
# 🚶 NAVEGACIÓN, RECOLECCIÓN Y ESTADOS (SIN CAMBIOS)
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
