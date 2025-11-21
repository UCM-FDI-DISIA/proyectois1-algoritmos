extends Node2D
class_name CasaCanteros

# ============================================================
# 🔧 VARIABLES EDITABLES
# ============================================================
@export var cantero_scene: PackedScene
@export var coste_piedra_cantero := 5 # Coste de PIEDRA por Cantero
@export var coste_aldeano_cantero := 1 # Coste de POBLACIÓN por Cantero
@export var max_canteros := 5
@export var canteros_iniciales := 2 # Canteros a crear al inicio
@export var UI_OFFSET := Vector2(-45, -292) # Posición del botón sobre la casa
@export var SPAWN_RADIUS := 100.0 # Radio máximo de aparición alrededor de la casa

# ============================================================
# 🎮 ESTADO
# ============================================================
var canteros_actuales := 0
var jugador_dentro := false
var debug := true
# Almacena las posiciones ocupadas para evitar superposiciones
var spawned_positions: Array[Vector2] = []

# ============================================================
# 🧩 NODOS
# ============================================================
@onready var boton_cantero := $UI/ComprarCantero
@onready var area_interaccion := $interaccion
@onready var resource_manager := get_node("/root/Main/ResourceManager")

# ============================================================
# ⚙️ READY
# ============================================================
func _ready() -> void:
	
	if resource_manager == null:
		push_error("[CasaCanteros] ERROR: ResourceManager no encontrado.")
		return
	if cantero_scene == null:
		push_error("[CasaCanteros] ERROR: La escena 'Cantero' no está asignada.")
	
	# Asegura que los recursos iniciales existen en el manager
	resource_manager.add_resource("stone", 0)
	resource_manager.add_resource("villager", 0)

	# Lógica para spawn inicial
	_spawn_initial_canteros() 

	# Conectar señales
	area_interaccion.body_entered.connect(_on_player_enter)
	area_interaccion.body_exited.connect(_on_player_exit)
	boton_cantero.pressed.connect(_on_comprar_cantero)

	# Posicionar botón sobre la casa
	boton_cantero.position = UI_OFFSET
	boton_cantero.z_index = 100
	boton_cantero.visible = false
	
	if debug:
		print("[CasaCanteros] Casa creada con %d canteros." % canteros_actuales)

# ----------------------------------------------------------------------
# Generación de canteros iniciales
# ----------------------------------------------------------------------
func _spawn_initial_canteros() -> void:
	var aldeanos_actuales : int = resource_manager.get_resource("villager")
	var num_a_spawnear = min(canteros_iniciales, max_canteros)
	
	# Chequea si hay población suficiente para los iniciales
	if aldeanos_actuales < num_a_spawnear:
			print("[CasaCanteros] Advertencia: Población (%d) insuficiente para spawnear %d canteros iniciales." % [aldeanos_actuales, canteros_iniciales])
	else:
		for _i in range(num_a_spawnear):
			# Restar la población por cada cantero creado
			resource_manager.remove_resource("villager", coste_aldeano_cantero)
		
			# Spawnear el NPC
			_spawn_cantero()
		
			# Actualizar el contador de la casa
			canteros_actuales += 1
	
	# Si no se pudo crear ninguno, el contador inicial se queda en 0
	if canteros_actuales == 0:
		canteros_actuales = 0

# ============================================================
# 🚪 DETECCIÓN DE JUGADOR
# ============================================================
func _on_player_enter(body):
	if body.is_in_group("jugador"):
		jugador_dentro = true
		_actualizar_boton()

func _on_player_exit(body):
	if body.is_in_group("jugador"):
		jugador_dentro = false
		boton_cantero.visible = false


# ============================================================
# 🛠️ ACTUALIZAR BOTÓN
# ============================================================
func _actualizar_boton():
	boton_cantero.visible = jugador_dentro and canteros_actuales < max_canteros


# ============================================================
# 💰 COMPRAR NUEVO CANTERO
# ============================================================
func _on_comprar_cantero():
	if canteros_actuales >= max_canteros:
		print("[CasaCanteros] Límite de canteros alcanzado.")
		return

	# 1. Chequear recursos
	var piedra_actual : int = resource_manager.get_resource("stone")
	var aldeanos_actuales : int = resource_manager.get_resource("villager")

	if piedra_actual < coste_piedra_cantero:
		print("[CasaCanteros] No hay piedra suficiente (%d/%d)." %
			[piedra_actual, coste_piedra_cantero])
		return
		
	if aldeanos_actuales < coste_aldeano_cantero:
		print("[CasaCanteros] No hay aldeanos (población) disponible (%d/%d)." %
			[aldeanos_actuales, coste_aldeano_cantero])
		return

	# 2. Restar recursos
	resource_manager.remove_resource("stone", coste_piedra_cantero)
	resource_manager.remove_resource("villager", coste_aldeano_cantero) # Resta 1 de población

	# 3. Instanciar y configurar el Cantero
	if cantero_scene != null:
		_spawn_cantero()

	# 4. Actualizar estado y UI
	canteros_actuales += 1
	print("[CasaCanteros] Nuevo cantero añadido. Total: %d" % canteros_actuales)
	_actualizar_boton()


# ============================================================
# 👶 LÓGICA DE SPAWN ALEATORIO RESTRINGIDO (INFERIOR)
# ============================================================

const MIN_DISTANCE := 30.0 

func _get_random_spawn_position() -> Vector2:
	var house_center = self.global_position
	var new_pos: Vector2
	var attempts = 0
	var max_attempts = 10 

	while attempts < max_attempts:
		
		# 💡 CAMBIO CLAVE: Restringir el ángulo a la mitad INFERIOR (delantera) del círculo.
		# Esto va de 0 a PI radianes (0° a 180°), asumiendo que el eje Y positivo es ABAJO.
		var final_angle = randf_range(0.0, PI) 
		
		# NOTA: Si la casa tiene una rotación diferente de 0, 
		# deberías añadir esa rotación (self.global_rotation) a final_angle.
		# Dejamos 0.0 a PI si la casa no está rotada.

		var distance = randf_range(MIN_DISTANCE, SPAWN_RADIUS) 
		
		var offset = Vector2(cos(final_angle), sin(final_angle)) * distance
		new_pos = house_center + offset
		
		var is_too_close = false
		for existing_pos in spawned_positions:
			if existing_pos.distance_to(new_pos) < MIN_DISTANCE:
				is_too_close = true
				break
		
		if not is_too_close:
			spawned_positions.append(new_pos)
			return new_pos

		attempts += 1
	
	# Fallback: una posición simple en la parte inferior (Y positivo)
	return house_center + SPAWN_RADIUS * Vector2(0, 1) 


func _spawn_cantero() -> void:
	var cantero_npc = cantero_scene.instantiate()
	
	cantero_npc.global_position = _get_random_spawn_position()
	
	# Añadir al árbol
	get_parent().add_child(cantero_npc)
	
	# Iniciar animación 'Idle'
	var anim_sprite: AnimatedSprite2D = cantero_npc.get_node_or_null("AnimatedSprite2D")
	if anim_sprite:
		anim_sprite.play("Idle")
		if debug:
			print("[CasaCanteros] Cantero instanciado en %s." % cantero_npc.global_position)
	else:
		push_error("[CasaCanteros] ERROR: No se encontró 'AnimatedSprite2D' en la escena del Cantero.")


# ============================================================
# 🧹 AL ELIMINAR CASA
# ============================================================
func _exit_tree() -> void:
	print("[CasaCanteros] Casa destruida. Se perdieron %d canteros." %
		canteros_actuales)
