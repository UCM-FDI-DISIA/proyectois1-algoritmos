extends CanvasLayer

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================

@export var PREVIEW_ALPHA := 0.5
@export var PREVIEW_BLOCK_COLOR := Color(1, 0, 0, 0.4)
@export var PREVIEW_OK_COLOR := Color(1, 1, 1, 0.5)
@export var GRID_SIZE := 64

# =====================================================================
# 🧾 NODOS DE INTERFAZ (Añadida Casa Mineros)
# =====================================================================
@onready var btn_menu: TextureButton = $ControlRaiz/BtnMenu
@onready var panel_barra: PanelContainer = $ControlRaiz/PanelBarra
@onready var hbox_botones: HBoxContainer = $ControlRaiz/PanelBarra/HBoxBotones

@onready var btn_casa: TextureButton = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasa
@onready var marcador_casa: Sprite2D = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasa/Marcador

@onready var btn_casa_canteros: TextureButton = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasaCanteros
@onready var marcador_canteros: Sprite2D = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasaCanteros/Marcador

@onready var btn_casa_lenadores: TextureButton = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasaLenadores
@onready var marcador_lenadores: Sprite2D = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasaLenadores/Marcador

# 💡 NUEVOS NODOS: Casa Mineros
@onready var btn_casa_mineros: TextureButton = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasaMineros # Asegúrate de que existe este nodo en el árbol
@onready var marcador_mineros: Sprite2D = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasaMineros/Marcador # Asegúrate de que existe este nodo en el árbol

# =====================================================================
# 🏗️ ESTADO DE CONSTRUCCIÓN
# =====================================================================
var en_construccion := false
var casa_preview: Node2D
var area_preview: Area2D
var puede_construir := true
var resource_manager: ResourceManager
# Tipos de casa: "casa_normal", "casa_canteros", "casa_lenadores", "casa_mineros"
var casa_seleccionada: String = ""

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	resource_manager = get_tree().root.get_node("Main/ResourceManager")
	if resource_manager == null:
		push_error("[BuildHUD] ResourceManager no encontrado en /root/Main/ResourceManager")
		return

	panel_barra.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_barra.visible = false
	
	# Aseguramos que todos los botones son de tipo Toggle
	btn_casa.toggle_mode = true
	btn_casa_canteros.toggle_mode = true
	btn_casa_lenadores.toggle_mode = true
	btn_casa_mineros.toggle_mode = true # Añadido
	
	btn_casa.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_casa_canteros.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_casa_lenadores.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_casa_mineros.mouse_filter = Control.MOUSE_FILTER_STOP # Añadido
	
	marcador_casa.visible = false
	marcador_canteros.visible = false
	marcador_lenadores.visible = false
	marcador_mineros.visible = false # Añadido

	# Conectar handlers
	btn_menu.pressed.connect(_on_menu_pressed)
	btn_casa.pressed.connect(_on_casa_pressed)
	btn_casa_canteros.pressed.connect(_on_casa_canteros_pressed)
	btn_casa_lenadores.pressed.connect(_on_casa_lenadores_pressed)
	btn_casa_mineros.pressed.connect(_on_casa_mineros_pressed) # Añadido

	_actualizar_tooltip()

# =====================================================================
# 📡 HANDLERS DE EVENTOS DE BOTONES
# =====================================================================

func _on_menu_pressed() -> void:
	panel_barra.visible = !panel_barra.visible
	if not panel_barra.visible:
		_cancelar_construccion()
	panel_barra.mouse_filter = Control.MOUSE_FILTER_STOP if panel_barra.visible else Control.MOUSE_FILTER_IGNORE
	print("[BuildHUD] Panel %s" % ("visible" if panel_barra.visible else "oculto"))

func _desactivar_otros_botones() -> void:
	"""Función auxiliar para desactivar todos los botones de construcción y sus marcadores."""
	btn_casa.button_pressed = false
	marcador_casa.visible = false
	btn_casa_canteros.button_pressed = false
	marcador_canteros.visible = false
	btn_casa_lenadores.button_pressed = false
	marcador_lenadores.visible = false
	btn_casa_mineros.button_pressed = false # Añadido
	marcador_mineros.visible = false # Añadido

func _on_casa_pressed() -> void:
	if btn_casa.button_pressed:
		_desactivar_otros_botones()
		btn_casa.button_pressed = true # Reactivar el botón actual
		_iniciar_construccion("casa_normal")
	else:
		_cancelar_construccion()
	marcador_casa.visible = btn_casa.button_pressed

func _on_casa_canteros_pressed() -> void:
	if btn_casa_canteros.button_pressed:
		_desactivar_otros_botones()
		btn_casa_canteros.button_pressed = true
		_iniciar_construccion("casa_canteros")
	else:
		_cancelar_construccion()
	marcador_canteros.visible = btn_casa_canteros.button_pressed

func _on_casa_lenadores_pressed() -> void:
	if btn_casa_lenadores.button_pressed:
		_desactivar_otros_botones()
		btn_casa_lenadores.button_pressed = true
		_iniciar_construccion("casa_lenadores")
	else:
		_cancelar_construccion()
	marcador_lenadores.visible = btn_casa_lenadores.button_pressed

func _on_casa_mineros_pressed() -> void: # NUEVO HANDLER
	if btn_casa_mineros.button_pressed:
		_desactivar_otros_botones()
		btn_casa_mineros.button_pressed = true
		_iniciar_construccion("casa_mineros")
	else:
		_cancelar_construccion()
	marcador_mineros.visible = btn_casa_mineros.button_pressed

# ---------------------------------------------------------------------
# MÉTODO CENTRALIZADO DE INICIO DE CONSTRUCCIÓN
# ---------------------------------------------------------------------
func _iniciar_construccion(tipo_casa: String) -> void:
	if en_construccion:
		_cancelar_construccion(false)
	
	var scene_a_instanciar: PackedScene
	
	match tipo_casa:
		"casa_normal":
			scene_a_instanciar = resource_manager.casa_scene
		"casa_canteros":
			scene_a_instanciar = resource_manager.casa_canteros_scene
		"casa_lenadores":
			scene_a_instanciar = resource_manager.casa_lenadores_scene
		"casa_mineros": # Añadido
			scene_a_instanciar = resource_manager.casa_mineros_scene # ASUME que esta variable existe en ResourceManager
		_:
			push_error("[BuildHUD] Tipo de casa desconocido: %s" % tipo_casa)
			return

	if scene_a_instanciar == null or resource_manager.contenedor_casas == null:
		push_error("[BuildHUD] Faltan asignaciones para %s en ResourceManager" % tipo_casa)
		return

	en_construccion = true
	casa_seleccionada = tipo_casa
	
	casa_preview = scene_a_instanciar.instantiate() as Node2D

	# 🔄 Configuración de Preview
	if casa_preview:
		if casa_preview.has_method("set"):
			if casa_preview.has_method("set_es_preview"):
				casa_preview.call("set_es_preview", true)
			elif casa_preview.has_method("set_is_preview"):
				casa_preview.call("set_is_preview", true)
		
		# Desactivar colisión principal y limpiar layers
		var sh := casa_preview.get_node_or_null("CollisionShape2D")
		if sh: sh.set_deferred("disabled", true)

		var co := casa_preview.get_node_or_null("CollisionObject2D")
		if co:
			co.collision_layer = 0
			co.collision_mask = 0

	_tint_preview(PREVIEW_OK_COLOR)
	resource_manager.contenedor_casas.add_child(casa_preview)
	_crear_area_preview()

# =====================================================================
# 📡 HANDLERS DE COLISIÓN (Simplificados)
# =====================================================================

func _on_area_preview_body_entered(body: Node) -> void:
	pass

func _on_area_preview_body_exited(body: Node) -> void:
	pass

#=====================================================================
# 🔄 BUCLE PRINCIPAL
# =====================================================================
func _process(_delta: float) -> void:
	if not en_construccion or casa_preview == null or casa_seleccionada == "":
		return

	var camera := get_viewport().get_camera_2d()
	var mp := camera.get_global_mouse_position()
	# Ajustar posición al grid
	casa_preview.global_position = Vector2(
		snapped(mp.x, GRID_SIZE) + GRID_SIZE * 0.5,
		snapped(mp.y, GRID_SIZE) + GRID_SIZE * 0.5
	)

	# 🔍 Verificar si se puede construir
	var sobre_terreno = await _es_sobre_terreno_valido(casa_preview.global_position)
	
	# Verificamos si el área está libre de obstáculos/jugador
	var cuerpos_superpuestos = 0
	if area_preview != null:
		for body in area_preview.get_overlapping_bodies():
			if body.is_in_group("objeto_bloqueante") or body.is_in_group("jugador"):
				cuerpos_superpuestos += 1
	
	var area_libre = cuerpos_superpuestos == 0

	puede_construir = sobre_terreno and area_libre

	# Cambiar color del preview según sea válido o no
	_tint_preview(PREVIEW_OK_COLOR if puede_construir else PREVIEW_BLOCK_COLOR)

	# 🖱️ Control de cancelación
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_key_pressed(KEY_ESCAPE):
		_cancelar_construccion()
		return

	# 🏗️ Construir (Lógica de construcción)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not puede_construir:
			print("[BuildHUD] No se puede construir aquí (obstáculo o terreno inválido)")
			return
		
		var real: Node2D = null
		var construccion_exitosa: bool = false
		var pos: Vector2 = casa_preview.global_position

		match casa_seleccionada:
			"casa_normal":
				if resource_manager.puedo_comprar_casa():
					real = resource_manager.casa_scene.instantiate() as Node2D
					resource_manager.pagar_casa()
					construccion_exitosa = true
				else:
					print("[BuildHUD] Materiales insuficientes para casa normal")
			"casa_canteros":
				if resource_manager.puedo_comprar_casa_canteros():
					real = resource_manager.casa_canteros_scene.instantiate() as Node2D
					real.global_position = camera.get_global_mouse_position()
					get_tree().get_root().add_child(real)
					real.spawn_initial_canteros_on_build() 
					resource_manager.pagar_casa_canteros()
					construccion_exitosa = true
				else:
					print("[BuildHUD] Materiales insuficientes para CasaCanteros")
			"casa_lenadores":
				if resource_manager.puedo_comprar_casa_lenadores():
					real = resource_manager.casa_lenadores_scene.instantiate() as Node2D
					real.global_position = camera.get_global_mouse_position()
					get_tree().get_root().add_child(real)
					real.spawn_initial_lenadores_on_build() 
					resource_manager.pagar_casa_lenadores()
					construccion_exitosa = true
				else:
					print("[BuildHUD] Materiales insuficientes para CasaLeñadores")
			"casa_mineros":
				if resource_manager.puedo_comprar_casa_mineros(): 
					real = resource_manager.casa_mineros_scene.instantiate() as Node2D
					real.global_position = camera.get_global_mouse_position()
					get_tree().get_root().add_child(real)
					real.spawn_initial_mineros_on_build() 
					resource_manager.pagar_casa_mineros()
					construccion_exitosa = true
				else:
					print("[BuildHUD] Materiales insuficientes para CasaMineros")
		
		if construccion_exitosa and real != null:
			real.global_position = pos
			resource_manager.contenedor_casas.add_child(real)
			print("[BuildHUD] Construcción realizada: %s" % casa_seleccionada)
			_cancelar_construccion()
		elif not construccion_exitosa:
			_cancelar_construccion()
	

# =====================================================================
# 🛠️ MÉTODOS AUXILIARES
# =====================================================================
func _crear_area_preview() -> void:
	if casa_preview == null:
		return

	area_preview = Area2D.new()
	casa_preview.add_child(area_preview)

	var sh := casa_preview.get_node_or_null("CollisionShape2D")
	if sh and sh.shape:
		var clon := CollisionShape2D.new()
		clon.shape = sh.shape.duplicate()
		area_preview.add_child(clon)

	area_preview.monitoring = true
	area_preview.monitorable = true
	area_preview.collision_layer = 0
	area_preview.collision_mask = 1

	area_preview.body_entered.connect(_on_area_preview_body_entered)
	area_preview.body_exited.connect(_on_area_preview_body_exited)

func _tint_preview(c: Color) -> void:
	if casa_preview == null: return
	for ch in casa_preview.get_children():
		if ch is CanvasItem:
			var final_color = c
			final_color.a = PREVIEW_ALPHA
			ch.modulate = final_color

func _cancelar_construccion(reset_buttons: bool = true) -> void:
	if casa_preview: casa_preview.queue_free()
	casa_preview = null
	area_preview = null
	en_construccion = false
	casa_seleccionada = ""
	
	if reset_buttons:
		marcador_casa.visible = false
		marcador_canteros.visible = false
		marcador_lenadores.visible = false
		marcador_mineros.visible = false # Añadido
		btn_casa.button_pressed = false
		btn_casa_canteros.button_pressed = false
		btn_casa_lenadores.button_pressed = false
		btn_casa_mineros.button_pressed = false # Añadido

func _actualizar_tooltip() -> void:
	if resource_manager:
		btn_casa.tooltip_text = "Coste: Madera %d | Piedra %d | Oro %d" % [
			resource_manager.get_casa_wood_cost(),
			resource_manager.get_casa_stone_cost(),
			resource_manager.get_casa_gold_cost() ]
		
		btn_casa_canteros.tooltip_text = "Coste: Madera %d | Piedra %d | Oro %d | Aldeanos %d" % [
			resource_manager.get_canteros_wood_cost(),
			resource_manager.get_canteros_stone_cost(),
			resource_manager.get_canteros_gold_cost(),
			resource_manager.get_canteros_villager_cost() ]
		
		btn_casa_lenadores.tooltip_text = "Coste: Madera %d | Piedra %d | Oro %d | Aldeanos %d" % [
			resource_manager.get_lenadores_wood_cost(),
			resource_manager.get_lenadores_stone_cost(),
			resource_manager.get_lenadores_gold_cost(),
			resource_manager.get_lenadores_villager_cost() ]
		
		btn_casa_mineros.tooltip_text = "Coste: Madera %d | Piedra %d | Oro %d | Aldeanos %d" % [
			resource_manager.get_mineros_wood_cost(),
			resource_manager.get_mineros_stone_cost(),
			resource_manager.get_mineros_gold_cost(),
			resource_manager.get_mineros_villager_cost() ]


# =====================================================================
# 🛠️ VERIFICAR TERRENO VÁLIDO (Sin cambios)
# =====================================================================
func _es_sobre_terreno_valido(pos: Vector2) -> bool:
	# 1. Comprobación de colisiones con otros objetos (edificios, árboles, etc.)
	if not await _esta_libre_de_colisiones(pos):
		return false

	# 2. Comprobación del terreno (tilemaps)
	if not _esta_sobre_terreno_valido(pos):
		return false

	# Si pasa ambas comprobaciones, la posición es válida.
	return true


# --- FUNCIÓN AUXILIAR 1: COMPROBACIÓN DE COLISIONES ---
# Mueve el área de prueba y comprueba si solapa con algo.
func _esta_libre_de_colisiones(pos: Vector2) -> bool:
	if area_preview == null:
		push_error("Error: 'area_preview' no ha sido creado.")
		return false

	# Colocamos el preview en la posición a testear
	# Importante: usamos la posición global para asegurar que coincide con el mundo del juego.
	casa_preview.global_position = pos

	# Forzamos una actualización inmediata de la física para este área.
	# Esto es crucial para que get_overlapping_bodies() funcione en el mismo frame.
	area_preview.force_update_transform()
	await get_tree().physics_frame

	# Obtenemos la lista de cuerpos con los que colisiona.
	# Si la lista no está vacía, significa que hay un obstáculo.
	var cuerpos_solapados = area_preview.get_overlapping_bodies()
	
	# Devolvemos 'true' si no hay colisiones (la lista está vacía).
	return cuerpos_solapados.is_empty()


# --- FUNCIÓN AUXILIAR 2: COMPROBACIÓN DE TERRENO ---
# Verifica si la construcción se sitúa sobre un tilemap válido y no sobre uno inválido.
func _esta_sobre_terreno_valido(pos: Vector2) -> bool:
	var mapa = get_node_or_null("/root/Main/Mapa")
	if mapa == null:
		push_error("[BuildHUD] No se encontró /root/Main/Mapa")
		return false

	# Definimos los puntos de las esquinas del edificio para dar un margen.
	var margen = 8
	var puntos = [
		pos + Vector2(margen, margen),
		pos + Vector2(-margen, margen),
		pos + Vector2(margen, -margen),
		pos + Vector2(-margen, -margen)
	]

	# Lista de tilemaps que son terreno NO construible (ej. agua).
	var tilemaps_invalidos = [mapa.get_node_or_null("Subsuelo")]
	
	# Lista de tilemaps que SÍ son construibles.
	var tilemaps_validos = [
		mapa.get_node_or_null("Suelo"),
		mapa.get_node_or_null("Nivel1"),
		mapa.get_node_or_null("Nivel2"),
		mapa.get_node_or_null("Nivel3"),
		mapa.get_node_or_null("Nivel4"),
	]

	# Comprobamos cada esquina del edificio.
	for punto_esquina in puntos:
		var esta_en_terreno_valido = false

		# 1. Primero, descartamos que esté en un terreno inválido.
		for tm_invalido in tilemaps_invalidos:
			if tm_invalido == null: continue
			var celda = tm_invalido.local_to_map(tm_invalido.to_local(punto_esquina))
			# Si la celda no está vacía (-1), es un terreno inválido.
			if tm_invalido.get_cell_source_id(celda) != -1:
				return false # Terminamos aquí, no es válido.

		# 2. Luego, verificamos que esté en AL MENOS UN terreno válido.
		for tm_valido in tilemaps_validos:
			if tm_valido == null: continue
			var celda = tm_valido.local_to_map(tm_valido.to_local(punto_esquina))
			# Si la celda no está vacía (-1), hemos encontrado un terreno válido.
			if tm_valido.get_cell_source_id(celda) != -1:
				esta_en_terreno_valido = true
				break # No hace falta seguir buscando para esta esquina.
		
		# Si tras recorrer todos los terrenos válidos, no encontramos ninguno, la posición es inválida.
		if not esta_en_terreno_valido:
			return false

	# Si todas las esquinas pasaron las pruebas, el terreno es válido.
	return true
