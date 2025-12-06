extends Node2D
class_name CasaMineros

# VARIABLES EDITABLES
@export var minero_scene: PackedScene
@export var coste_hierro_minero := 1
@export var coste_aldeano_minero := 1
@export var max_mineros := 5
@export var mineros_iniciales := 1
# UI_OFFSET: Ahora representa la posición VERTICAL desde el centro (X=0)
@export var UI_OFFSET := Vector2(0, -292) 

@export var SPAWN_RADIUS := 400.0
@export var MIN_DISTANCE := 190.0
@export var COLLISION_CHECK_RADIUS := 10.0
@export_range(1, 15, 1) var MAX_SPAWN_ATTEMPTS := 10
@export var NPC_COLLISION_RADIUS := 12.0

# ESTADO
var mineros_actuales := 0
var jugador_dentro := false
var debug := true
var spawned_positions: Array[Vector2] = []
var initial_spawn_complete := false

# NODOS
@onready var boton_minero := $UI/ComprarMinero
@onready var max_mineros_button: Button = $UI/MaxMinerosButton 
@onready var area_interaccion := $interaccion
@onready var resource_manager := get_node("/root/Main/ResourceManager")

# READY
func _ready() -> void:
	randomize()

	if resource_manager == null:
		push_error("[CasaMineros] ResourceManager no encontrado.")
		return

	if minero_scene == null:
		push_error("[CasaMineros] No se asignó la escena del Minero.")
	
	# Asegura que los recursos iniciales existen en el manager
	resource_manager.add_resource("iron", 0) 
	resource_manager.add_resource("villager", 0)

	area_interaccion.body_entered.connect(_on_player_enter)
	area_interaccion.body_exited.connect(_on_player_exit)
	boton_minero.pressed.connect(_on_comprar_minero)

	# Conexiones para actualizar el estado y tooltip al pasar el ratón
	boton_minero.mouse_entered.connect(_on_boton_mouse_entered)
	boton_minero.mouse_exited.connect(_on_boton_mouse_exited)

	# Centrado y visibilidad inicial
	_reposition_ui()
	
	boton_minero.z_index = 100
	boton_minero.visible = false
	boton_minero.tooltip_text = ""
	
	# Configuración del botón de mensaje de límite
	max_mineros_button.z_index = 100
	max_mineros_button.visible = false
	max_mineros_button.disabled = true
	max_mineros_button.text = "¡Máximo de mineros alcanzado: %d/%d!" % [max_mineros, max_mineros]
	
	# Corrección de Contraste: Forzar el color del texto a blanco
	max_mineros_button.add_theme_color_override("font_color", Color.WHITE)

	if debug:
		print("[CasaMineros] Inicializado correctamente.")

# CÁLCULO DE POSICIONAMIENTO CENTRAL
func _reposition_ui():
	# Calculamos el centro horizontal (X) de la UI.
	var center_offset_x = 0
	
	# 1. Botón de compra (ComprarMinero)
	# Se centra restando la mitad de su tamaño al offset X deseado (0, en este caso)
	var final_pos_minero = UI_OFFSET + Vector2(center_offset_x - boton_minero.size.x / 2, 0)
	boton_minero.position = final_pos_minero
	
	# 2. Botón de mensaje (MaxMinerosButton)
	var final_pos_max = UI_OFFSET + Vector2(center_offset_x - max_mineros_button.size.x / 2, 0)
	max_mineros_button.position = final_pos_max

func spawn_initial_mineros_on_build() -> void:
	if initial_spawn_complete:
		return
	
	spawned_positions.clear()
	
	var aldeanos_actuales : int = resource_manager.get_resource("villager")
	var num_a_spawnear = mineros_iniciales
	
	var mineros_pagables = floor(float(aldeanos_actuales) / coste_aldeano_minero)
	num_a_spawnear = min(num_a_spawnear, max_mineros, mineros_pagables)
	
	for i in range(num_a_spawnear):
		resource_manager.remove_resource("villager", coste_aldeano_minero)
		_spawn_minero()
		mineros_actuales += 1
		
	if debug:
		print("[CasaMineros] Spawn inicial completado. Mineros totales: %d." % mineros_actuales)
		
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
		push_warning("[CasaMineros] Advertencia: No se encontró posición válida tras %d intentos en %s. Usando fallback." % [MAX_SPAWN_ATTEMPTS, center])

	return center + Vector2(0, SPAWN_RADIUS)

# SPAWNEAR MINERO
func _spawn_minero() -> void:
	var npc = minero_scene.instantiate()

	npc.global_position = _get_random_spawn_position()

	if get_parent() != null:
		get_parent().add_child(npc)
	else:
		push_error("[CasaMineros] ERROR: No se pudo añadir el minero al árbol.")
		npc.queue_free()
		return

	var anim := npc.get_node_or_null("AnimatedSprite2D")
	if anim:
		anim.play("Idle")

	if debug:
		print("[CasaMineros] Nuevo minero en %s" % npc.global_position)

# COMPRAR MINERO
func _on_comprar_minero():
	if mineros_actuales >= max_mineros:
		print("[CasaMineros] Máximo alcanzado.")
		return

	var gold : int = resource_manager.get_resource("gold")
	var villagers :int = resource_manager.get_resource("villager")

	if gold < coste_hierro_minero:
		print("[CasaMineros] No hay hierro suficiente.")
		return
	if villagers < coste_aldeano_minero:
		print("[CasaMineros] No hay aldeanos disponibles.")
		return

	resource_manager.remove_resource("gold", coste_hierro_minero)
	resource_manager.remove_resource("villager", coste_aldeano_minero)

	_spawn_minero()

	mineros_actuales += 1
	_actualizar_boton()

# DETECCIÓN DE JUGADOR
func _on_player_enter(body):
	if body.is_in_group("jugador"):
		jugador_dentro = true
		_actualizar_boton()

func _on_player_exit(body):
	if body.is_in_group("jugador"):
		jugador_dentro = false
		boton_minero.visible = false
		max_mineros_button.visible = false 

# ACTUALIZACIÓN POR MOUSE HOVER
func _on_boton_mouse_entered():
	_actualizar_estado_y_tooltip()

func _on_boton_mouse_exited():
	pass

# BOTÓN (Lógica de Visibilidad y Estado)
func _actualizar_estado_y_tooltip():
	var gold = resource_manager.get_resource("gold")
	var vil = resource_manager.get_resource("villager")
	
	var max_alcanzado = mineros_actuales >= max_mineros
	var recursos_suficientes = (gold >= coste_hierro_minero) and (vil >= coste_aldeano_minero)

	if not jugador_dentro or max_alcanzado:
		return
	
	boton_minero.disabled = not recursos_suficientes
	
	var tooltip_msg = "Comprar Minero:\nOro: %d (Tienes: %d)\nAldeanos: %d (Tienes: %d)" % [
		coste_hierro_minero, gold,
		coste_aldeano_minero, vil
	]
	
	if not recursos_suficientes:
		tooltip_msg += "\n🛑¡Recursos insuficientes!"
		
	boton_minero.tooltip_text = tooltip_msg
	
func _actualizar_boton():
	var max_alcanzado = mineros_actuales >= max_mineros
	
	# 1. VISIBILIDAD y LÍMITE:
	if max_alcanzado:
		# Oculta el botón de compra
		boton_minero.visible = false
		# Muestra el botón de mensaje de límite
		max_mineros_button.visible = jugador_dentro
		return
	
	# Si no está al máximo:
	# Oculta el botón de mensaje de límite
	max_mineros_button.visible = false
	
	# La visibilidad del botón de compra depende solo de si el jugador está dentro
	boton_minero.visible = jugador_dentro
	
	# Actualizamos el estado de los recursos (solo si el jugador está dentro)
	if jugador_dentro:
		_actualizar_estado_y_tooltip()
