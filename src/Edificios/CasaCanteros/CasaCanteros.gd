extends Node2D
class_name CasaCanteros

# VARIABLES EDITABLES
@export var cantero_scene: PackedScene
@export var coste_piedra_cantero := 2
@export var coste_aldeano_cantero := 1
@export var max_canteros := 5
@export var canteros_iniciales := 1
# UI_OFFSET: Ahora representa la posición VERTICAL desde el centro (X=0)
@export var UI_OFFSET := Vector2(0, -292) 

@export var SPAWN_RADIUS := 400.0
@export var MIN_DISTANCE := 190.0
@export var COLLISION_CHECK_RADIUS := 10.0
@export_range(1, 15, 1) var MAX_SPAWN_ATTEMPTS := 10
@export var NPC_COLLISION_RADIUS := 12.0

# ESTADO
var canteros_actuales := 0
var jugador_dentro := false
var debug := true
var spawned_positions: Array[Vector2] = []
var initial_spawn_complete := false

# NODOS
@onready var boton_cantero := $UI/ComprarCantero
@onready var max_canteros_button: Button = $UI/MaxCanterosButton # NUEVO: Botón de mensaje
@onready var area_interaccion := $interaccion
@onready var resource_manager := get_node("/root/Main/ResourceManager")

# READY
func _ready() -> void:
	randomize()

	if resource_manager == null:
		push_error("[CasaCanteros] ResourceManager no encontrado.")
		return

	if cantero_scene == null:
		push_error("[CasaCanteros] No se asignó la escena del Cantero.")
	
	# Asegura que los recursos iniciales existen en el manager
	resource_manager.add_resource("stone", 0)
	resource_manager.add_resource("villager", 0)

	area_interaccion.body_entered.connect(_on_player_enter)
	area_interaccion.body_exited.connect(_on_player_exit)
	boton_cantero.pressed.connect(_on_comprar_cantero)
	
	# Conexiones para actualizar el estado y tooltip al pasar el ratón
	boton_cantero.mouse_entered.connect(_on_boton_mouse_entered)
	boton_cantero.mouse_exited.connect(_on_boton_mouse_exited)

	# Centrado y visibilidad inicial
	_reposition_ui()
	
	boton_cantero.z_index = 100
	boton_cantero.visible = false
	boton_cantero.tooltip_text = ""
	
	# Configuración del botón de mensaje de límite
	max_canteros_button.z_index = 100
	max_canteros_button.visible = false
	max_canteros_button.disabled = true
	max_canteros_button.text = "¡Máximo de canteros alcanzado: %d/%d!" % [max_canteros, max_canteros]
	
	# Corrección de Contraste: Forzar el color del texto a blanco
	max_canteros_button.add_theme_color_override("font_color", Color.WHITE)

	if debug:
		print("[CasaCanteros] Inicializado correctamente.")

# CÁLCULO DE POSICIONAMIENTO CENTRAL
func _reposition_ui():
	# Calculamos el centro horizontal (X) de la UI.
	var center_offset_x = 0
	
	# 1. Botón de compra (ComprarCantero)
	# Se centra restando la mitad de su tamaño al offset X deseado (0, en este caso)
	var final_pos_cantero = UI_OFFSET + Vector2(center_offset_x - boton_cantero.size.x / 2, 0)
	boton_cantero.position = final_pos_cantero
	
	# 2. Botón de mensaje (MaxCanterosButton)
	var final_pos_max = UI_OFFSET + Vector2(center_offset_x - max_canteros_button.size.x / 2, 0)
	max_canteros_button.position = final_pos_max

func spawn_initial_canteros_on_build() -> void:
	if initial_spawn_complete:
		return
	
	spawned_positions.clear()
	
	var aldeanos_actuales : int = resource_manager.get_resource("villager")
	var num_a_spawnear = canteros_iniciales
	
	var canteros_pagables = floor(float(aldeanos_actuales) / coste_aldeano_cantero)
	num_a_spawnear = min(num_a_spawnear, max_canteros, canteros_pagables)
	
	for i in range(num_a_spawnear):
		resource_manager.remove_resource("villager", coste_aldeano_cantero)
		_spawn_cantero()
		canteros_actuales += 1
		
	if debug:
		print("[CasaCanteros] Spawn inicial completado. Canteros totales: %d." % canteros_actuales)
		
	initial_spawn_complete = true

# CHEQUEO DE COLISIONES
func _is_position_free(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state

	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	query.exclude = [area_interaccion.get_rid()]

	var result = space_state.intersect_point(query, 1)
	return result.is_empty()

# NUEVA POSICIÓN ALEATORIA VÁLIDA
func _get_random_spawn_position() -> Vector2:
	var center := global_position
	var attempts := 0

	while attempts < MAX_SPAWN_ATTEMPTS:

		var angle = randf_range(PI / 2.0, 3.0 * PI / 2.0)
		var distance = randf_range(MIN_DISTANCE, SPAWN_RADIUS) 
		
		var offset = Vector2(cos(angle), sin(angle)) * distance
		var pos = center + offset

		# 1. Distancia con NPCs previos
		var ok := true
		for prev in spawned_positions:
			if prev.distance_to(pos) < MIN_DISTANCE:
				ok = false
				break

		# 2. Chequeo de colisión del mundo
		if ok and _is_position_free(pos):
			spawned_positions.append(pos)
			return pos

		attempts += 1

	if debug:
		push_warning("[CasaCanteros] Advertencia: No se encontró posición válida tras %d intentos en %s. Usando fallback." % [MAX_SPAWN_ATTEMPTS, center])

	return center + Vector2(0, SPAWN_RADIUS)

# SPAWNEAR CANTERO
func _spawn_cantero() -> void:
	var npc = cantero_scene.instantiate()

	npc.global_position = _get_random_spawn_position()

	if get_parent() != null:
		get_parent().add_child(npc)
	else:
		push_error("[CasaCanteros] ERROR: No se pudo añadir el cantero al árbol.")
		npc.queue_free()
		return

	var anim := npc.get_node_or_null("AnimatedSprite2D")
	if anim:
		anim.play("Idle")

	if debug:
		print("[CasaCanteros] Nuevo cantero en %s" % npc.global_position)

# COMPRAR CANTERO
func _on_comprar_cantero():
	if canteros_actuales >= max_canteros:
		print("[CasaCanteros] Máximo alcanzado.")
		return

	var stone : int = resource_manager.get_resource("stone")
	var villagers :int = resource_manager.get_resource("villager")

	if stone < coste_piedra_cantero:
		print("[CasaCanteros] No hay piedra suficiente.")
		return
	if villagers < coste_aldeano_cantero:
		print("[CasaCanteros] No hay aldeanos disponibles.")
		return

	resource_manager.remove_resource("stone", coste_piedra_cantero)
	resource_manager.remove_resource("villager", coste_aldeano_cantero)

	_spawn_cantero()

	canteros_actuales += 1
	_actualizar_boton()

# DETECCIÓN DE JUGADOR
func _on_player_enter(body):
	if body.is_in_group("jugador"):
		jugador_dentro = true
		_actualizar_boton()

func _on_player_exit(body):
	if body.is_in_group("jugador"):
		jugador_dentro = false
		boton_cantero.visible = false
		max_canteros_button.visible = false # Oculta el botón de mensaje al salir

# ACTUALIZACIÓN POR MOUSE HOVER
func _on_boton_mouse_entered():
	_actualizar_estado_y_tooltip()

func _on_boton_mouse_exited():
	pass

# BOTÓN (Lógica de Visibilidad y Estado)
func _actualizar_estado_y_tooltip():
	var stone = resource_manager.get_resource("stone")
	var vil = resource_manager.get_resource("villager")
	
	var max_alcanzado = canteros_actuales >= max_canteros
	var recursos_suficientes = (stone >= coste_piedra_cantero) and (vil >= coste_aldeano_cantero)

	if not jugador_dentro or max_alcanzado:
		return
	
	boton_cantero.disabled = not recursos_suficientes
	
	var tooltip_msg = "Comprar Cantero:\n Piedra: %d (Tienes: %d)\n Aldeanos: %d (Tienes: %d)" % [
		coste_piedra_cantero, stone,
		coste_aldeano_cantero, vil
	]
	
	if not recursos_suficientes:
		tooltip_msg += "\n🛑¡Recursos insuficientes!"
		
	boton_cantero.tooltip_text = tooltip_msg
	
func _actualizar_boton():
	var max_alcanzado = canteros_actuales >= max_canteros
	
	# 1. VISIBILIDAD y LÍMITE:
	if max_alcanzado:
		# Oculta el botón de compra
		boton_cantero.visible = false
		# Muestra el botón de mensaje de límite
		max_canteros_button.visible = jugador_dentro
		return
	
	# Si no está al máximo:
	# Oculta el botón de mensaje de límite
	max_canteros_button.visible = false
	
	# La visibilidad del botón de compra depende solo de si el jugador está dentro
	boton_cantero.visible = jugador_dentro
	
	# Actualizamos el estado de los recursos (solo si el jugador está dentro)
	if jugador_dentro:
		_actualizar_estado_y_tooltip()
