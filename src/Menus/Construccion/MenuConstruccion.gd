extends CanvasLayer

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================

@export var PREVIEW_ALPHA := 0.5
@export var PREVIEW_BLOCK_COLOR := Color(1, 0, 0, 0.4)
@export var PREVIEW_OK_COLOR := Color(1, 1, 1, 0.5)
@export var GRID_SIZE := 64

# =====================================================================
# 🧾 NODOS DE INTERFAZ
# =====================================================================
@onready var btn_menu: TextureButton = $ControlRaiz/BtnMenu
@onready var panel_barra: PanelContainer = $ControlRaiz/PanelBarra
@onready var hbox_botones: HBoxContainer = $ControlRaiz/PanelBarra/HBoxBotones
@onready var btn_casa: TextureButton = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasa
@onready var marcador_casa: Sprite2D = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasa/Marcador
@onready var btn_casa_canteros: TextureButton = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasaCanteros
@onready var marcador_canteros: Sprite2D = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasaCanteros/Marcador

# =====================================================================
# 🏗️ ESTADO DE CONSTRUCCIÓN
# =====================================================================
var en_construccion := false
var casa_preview: Node2D
var area_preview: Area2D
var puede_construir := true
var resource_manager: ResourceManager
var casa_seleccionada: String = "" # "casa_normal" o "casa_canteros"

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
	
	# Aseguramos que los botones son de tipo Toggle
	btn_casa.toggle_mode = true
	btn_casa_canteros.toggle_mode = true
	
	btn_casa.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_casa_canteros.mouse_filter = Control.MOUSE_FILTER_STOP
	marcador_casa.visible = false
	marcador_canteros.visible = false

	# Conectar handlers
	btn_menu.pressed.connect(_on_menu_pressed)
	btn_casa.pressed.connect(_on_casa_pressed)
	btn_casa_canteros.pressed.connect(_on_casa_canteros_pressed)

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

func _on_casa_pressed() -> void:
	if btn_casa.button_pressed:
		# Se ha pulsado Casa, desactivar Casa Canteros y comenzar preview
		btn_casa_canteros.button_pressed = false
		marcador_canteros.visible = false
		_iniciar_construccion("casa_normal")
	else:
		# Se ha deseleccionado Casa
		_cancelar_construccion()
	marcador_casa.visible = btn_casa.button_pressed

func _on_casa_canteros_pressed() -> void:
	if btn_casa_canteros.button_pressed:
		# Se ha pulsado Casa Canteros, desactivar Casa normal y comenzar preview
		btn_casa.button_pressed = false
		marcador_casa.visible = false
		_iniciar_construccion("casa_canteros")
	else:
		# Se ha deseleccionado Casa Canteros
		_cancelar_construccion()
	marcador_canteros.visible = btn_casa_canteros.button_pressed

# ---------------------------------------------------------------------
# MÉTODO CENTRALIZADO DE INICIO DE CONSTRUCCIÓN (Corregido)
# ---------------------------------------------------------------------
func _iniciar_construccion(tipo_casa: String) -> void:
	# Si ya estamos en construcción, cancelamos la anterior sin limpiar el estado del botón
	if en_construccion:
		_cancelar_construccion(false) 

	var scene_a_instanciar: PackedScene
	
	if tipo_casa == "casa_normal":
		scene_a_instanciar = resource_manager.casa_scene
	elif tipo_casa == "casa_canteros":
		scene_a_instanciar = resource_manager.casa_canteros_scene
	else:
		push_error("[BuildHUD] Tipo de casa desconocido: %s" % tipo_casa)
		return

	if scene_a_instanciar == null or resource_manager.contenedor_casas == null:
		push_error("[BuildHUD] Faltan asignaciones para %s en ResourceManager" % tipo_casa)
		return

	en_construccion = true
	casa_seleccionada = tipo_casa
	
	casa_preview = scene_a_instanciar.instantiate() as Node2D

	# 🔄 Configuración de Preview unificada y ROBUSTA
	if casa_preview:
		# Intenta establecer la propiedad 'es_preview' o 'is_preview' si existe.
		# Esto no usa has_property() para mayor compatibilidad, pero asume que la propiedad
		# existe si el script de CasaAnimada/CasaCanteros está adjunto.
		if casa_preview is CasaAnimada:
			var c := casa_preview as CasaAnimada
			c.es_preview = true # Asumimos que esta propiedad existe en CasaAnimada
		elif casa_preview.get_script() and casa_preview.get_script().has_property("is_preview"):
			casa_preview.set("is_preview", true) # Para CasaCanteros o genérico
		elif casa_preview.get_script() and casa_preview.get_script().has_property("es_preview"):
			casa_preview.set("es_preview", true)
		
		# Desactivar colisión principal y limpiar layers para que no bloquee otros objetos
		var sh := casa_preview.get_node_or_null("CollisionShape2D")
		if sh: sh.set_deferred("disabled", true) # Desactiva la colisión real de la casa

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
# Estos ya no necesitan cambiar 'puede_construir', ya que _process comprueba el tamaño del array.
# Los mantenemos por si el usuario tiene lógica adicional en ellos.
func _on_area_preview_body_entered(body: Node) -> void:
	pass # La lógica de bloqueo se hace en _process

func _on_area_preview_body_exited(body: Node) -> void:
	pass # La lógica de desbloqueo se hace en _process

#=====================================================================
# 🔄 BUCLE PRINCIPAL (Corregido y Unificado)
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
	var sobre_terreno = _es_sobre_terreno_valido(casa_preview.global_position)
	
	# 💡 CORRECCIÓN para el color rojo: verificamos si el área está libre.
	var cuerpos_superpuestos = 0
	if area_preview != null:
		# Sólo contamos los cuerpos que pertenecen a los grupos que bloquean
		for body in area_preview.get_overlapping_bodies():
			if body.is_in_group("objeto_bloqueante") or body.is_in_group("jugador"):
				cuerpos_superpuestos += 1
	
	var area_libre = cuerpos_superpuestos == 0

	# 'puede_construir' ahora depende de ambas condiciones
	puede_construir = sobre_terreno and area_libre

	# Cambiar color del preview según sea válido o no
	_tint_preview(PREVIEW_OK_COLOR if puede_construir else PREVIEW_BLOCK_COLOR)

	# 🖱️ Control de cancelación
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_key_pressed(KEY_ESCAPE):
		_cancelar_construccion()
		return

	# 🏗️ Construir (Lógica corregida para el error de tipado 'real')
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not puede_construir:
			print("[BuildHUD] No se puede construir aquí (obstáculo o terreno inválido)")
			return
		
		var real: Node2D = null # Declaración con tipo para evitar el error
		var construccion_exitosa: bool = false
		var pos: Vector2 = casa_preview.global_position

		if casa_seleccionada == "casa_normal":
			if resource_manager.puedo_comprar_casa():
				real = resource_manager.casa_scene.instantiate() as Node2D
				resource_manager.pagar_casa()
				construccion_exitosa = true
			else:
				print("[BuildHUD] Materiales insuficientes para casa normal")
		elif casa_seleccionada == "casa_canteros":
			if resource_manager.puedo_comprar_casa_canteros():
				real = resource_manager.casa_canteros_scene.instantiate() as Node2D
				resource_manager.pagar_casa_canteros()
				construccion_exitosa = true
			else:
				print("[BuildHUD] Materiales insuficientes para CasaCanteros")

		if construccion_exitosa and real != null:
			real.global_position = pos
			resource_manager.contenedor_casas.add_child(real)
			print("[BuildHUD] Construcción realizada: %s" % casa_seleccionada)
			_cancelar_construccion()
		elif not construccion_exitosa:
			# Si la construcción falló por materiales, cancelamos el preview
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
		# Usamos una copia del shape para el Area2D
		clon.shape = sh.shape.duplicate() 
		
		# NOTA: Se ha quitado la reducción de tamaño del 80% para asegurar que el preview
		# tiene el mismo comportamiento que la casa final.
		
		area_preview.add_child(clon)

	area_preview.monitoring = true
	area_preview.monitorable = true
	# Limpiamos las capas de colisión y solo usamos la máscara para DETECTAR obstáculos
	area_preview.collision_layer = 0 
	area_preview.collision_mask = 1 # Asume que objetos_bloqueantes están en el layer 1

	# Conexiones de señal
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
		btn_casa.button_pressed = false
		btn_casa_canteros.button_pressed = false

func _actualizar_tooltip() -> void:
	if resource_manager:
		btn_casa.tooltip_text = "Coste: Madera %d | Piedra %d | Oro %d" % [
			resource_manager.get_casa_wood_cost(),
			resource_manager.get_casa_stone_cost(),
			resource_manager.get_casa_gold_cost() ]

# =====================================================================
# 🛠️ VERIFICAR TERRENO VÁLIDO (Sin cambios)
# =====================================================================
func _es_sobre_terreno_valido(pos: Vector2) -> bool:
	var mapa = get_node("/root/Main/Mapa")
	if mapa == null:
		push_error("[BuildHUD] No se encontró /root/Main/Mapa")
		return false

	var margen = 8
	var puntos = [
		pos + Vector2(margen, margen),
		pos + Vector2(-margen, margen),
		pos + Vector2(margen, -margen),
		pos + Vector2(-margen, -margen)
	]

	# Primero bloquear agua/subsuelo
	var subsuelo = mapa.get_node_or_null("Subsuelo")
	if subsuelo:
		for p in puntos:
			var cell_subsuelo = subsuelo.local_to_map(subsuelo.to_local(p))
			if subsuelo.get_cell_source_id(cell_subsuelo) != -1:
				return false

	# Comprobar tilemaps válidos (Suelo/Niveles)
	var tilemaps_validos = [
		mapa.get_node_or_null("Suelo"),
		mapa.get_node_or_null("Nivel1"),
		mapa.get_node_or_null("Nivel2"),
		mapa.get_node_or_null("Nivel3"),
		mapa.get_node_or_null("Nivel4"),
	]

	for p in puntos:
		var valido = false
		for tm in tilemaps_validos:
			if tm == null:
				continue
			var cell = tm.local_to_map(tm.to_local(p))
			if tm.get_cell_source_id(cell) != -1:
				valido = true
				break
		if not valido:
			return false

	return true
