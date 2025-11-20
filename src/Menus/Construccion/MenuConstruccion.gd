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

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	resource_manager = get_tree().root.get_node("Main/ResourceManager")
	if resource_manager == null:
		push_error("[BuildHUD] ResourceManager no encontrado en /root/Main/ResourceManager")
		return

	panel_barra.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_casa.mouse_filter = Control.MOUSE_FILTER_STOP
	panel_barra.visible = false
	marcador_casa.visible = false
	btn_casa_canteros.mouse_filter = Control.MOUSE_FILTER_STOP
	marcador_canteros.visible = false

	btn_casa_canteros.pressed.connect(_on_casa_canteros_pressed)

	_actualizar_tooltip()

	btn_menu.pressed.connect(_on_menu_pressed)
	btn_casa.pressed.connect(_on_casa_pressed)

# =====================================================================
# 📡 HANDLERS DE EVENTOS
# =====================================================================
func _on_menu_pressed() -> void:
	panel_barra.visible = !panel_barra.visible
	if not panel_barra.visible:
		_cancelar_construccion()
	panel_barra.mouse_filter = Control.MOUSE_FILTER_STOP if panel_barra.visible else Control.MOUSE_FILTER_IGNORE
	print("[BuildHUD] Panel %s" % ("visible" if panel_barra.visible else "oculto"))

func _on_casa_pressed() -> void:
	marcador_casa.visible = !marcador_casa.visible
	if en_construccion:
		print("[BuildHUD] Ya en modo construcción")
		return
	if resource_manager == null or resource_manager.casa_scene == null or resource_manager.contenedor_casas == null:
		push_error("[BuildHUD] Faltan asignaciones en ResourceManager")
		return

	en_construccion = true
	casa_preview = resource_manager.casa_scene.instantiate() as Node2D
	if casa_preview is CasaAnimada:
		var c := casa_preview as CasaAnimada
		c.es_preview = true
		var sh := c.get_node_or_null("CollisionShape2D")
		if sh: sh.set_deferred("disabled", true)
		var co := c.get_node_or_null("CollisionObject2D")
		if co:
			co.collision_layer = 0
			co.collision_mask  = 0

	_tint_preview(PREVIEW_OK_COLOR)
	resource_manager.contenedor_casas.add_child(casa_preview)
	_crear_area_preview()

func _on_area_preview_body_entered(body: Node) -> void:
	if body.is_in_group("objeto_bloqueante") or body.is_in_group("jugador"):
		puede_construir = false
		_tint_preview(PREVIEW_BLOCK_COLOR)

func _on_area_preview_body_exited(body: Node) -> void:
	if body.is_in_group("objeto_bloqueante") or body.is_in_group("jugador"):
		puede_construir = true
		_tint_preview(PREVIEW_OK_COLOR)

func _on_casa_canteros_pressed() -> void:
	marcador_canteros.visible = !marcador_canteros.visible

	if en_construccion:
		print("[BuildHUD] Ya en modo construcción (otra casa activa)")
		return

	if resource_manager == null or resource_manager.casa_canteros_scene == null or resource_manager.contenedor_casas == null:
		push_error("[BuildHUD] Faltan asignaciones para CasaCanteros en ResourceManager")
		return

	en_construccion = true
	casa_preview = resource_manager.casa_canteros_scene.instantiate() as Node2D

	if casa_preview is CasaCanteros:
		var c := casa_preview as CasaCanteros
		# Marcar como preview si quieres impedir su lógica
		c.set("is_preview", true)

		var sh := c.get_node_or_null("CollisionShape2D")
		if sh: sh.set_deferred("disabled", true)

		var co := c.get_node_or_null("CollisionObject2D")
		if co:
			co.collision_layer = 0
			co.collision_mask  = 0

	_tint_preview(PREVIEW_OK_COLOR)
	resource_manager.contenedor_casas.add_child(casa_preview)

	_crear_area_preview()

#=====================================================================
# 🔄 BUCLE PRINCIPAL REVISADO
# =====================================================================
func _process(_delta: float) -> void:
	if not en_construccion or casa_preview == null:
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
	var area_libre = area_preview != null and area_preview.get_overlapping_bodies().size() == 0

	puede_construir = sobre_terreno and area_libre

	# Cambiar color del preview según sea válido o no
	_tint_preview(PREVIEW_OK_COLOR if puede_construir else PREVIEW_BLOCK_COLOR)

	# 🖱️ Control de cancelación
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_key_pressed(KEY_ESCAPE):
		_cancelar_construccion()
		return

	# 🏗️ Construir
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not puede_construir:
			print("[BuildHUD] No se puede construir aquí (obstáculo o terreno inválido)")
			return
		if btn_casa.button_pressed:
			if resource_manager.puedo_comprar_casa():
				resource_manager.pagar_casa()
				var real := resource_manager.casa_scene.instantiate()
				real.global_position = casa_preview.global_position
				resource_manager.contenedor_casas.add_child(real)
				_cancelar_construccion()
				print("[BuildHUD] Construcción realizada")
			else:
				print("[BuildHUD] Materiales insuficientes para casa normal")
				_cancelar_construccion()
				return
		elif btn_casa_canteros.button_pressed:
			if resource_manager.puedo_comprar_casa_canteros():
				resource_manager.pagar_casa_canteros()
				var real := resource_manager.casa_canteros_scene.instantiate()
				real.global_position = casa_preview.global_position
				resource_manager.contenedor_casas.add_child(real)
				_cancelar_construccion()
				print("[BuildHUD] Construcción realizada")
			else:
				print("[BuildHUD] Materiales insuficientes para CasaCanteros")
				_cancelar_construccion()
				return
		else:
			print("[BuildHUD] Ningún tipo de casa seleccionado")
			_cancelar_construccion()
			return
	

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
		
		# Reducir colisión para dar margen (80% del tamaño original)
		if clon.shape is RectangleShape2D:
			clon.shape.extents *= 0.8
		elif clon.shape is CircleShape2D:
			clon.shape.radius *= 0.8
		
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
		if ch is CanvasItem: ch.modulate = c

func _cancelar_construccion() -> void:
	if casa_preview: casa_preview.queue_free()
	casa_preview = null
	area_preview = null
	en_construccion = false
	marcador_casa.visible = false
	marcador_canteros.visible = false
	btn_casa.button_pressed = false
	btn_casa_canteros.button_pressed = false

func _actualizar_tooltip() -> void:
	btn_casa.tooltip_text = "Coste: Madera %d | Piedra %d | Oro %d" % [
		resource_manager.get_casa_wood_cost(),
		resource_manager.get_casa_stone_cost(),
		resource_manager.get_casa_gold_cost() ]

# 

# =====================================================================
# 🛠️ VERIFICAR TERRENO VÁLIDO
# =====================================================================
func _es_sobre_terreno_valido(pos: Vector2) -> bool:
	var mapa = get_node("/root/Main/Mapa")
	if mapa == null:
		push_error("[BuildHUD] No se encontró /root/Main/Mapa")
		return false

	var margen = 8 # pixeles desde el borde para permitir un pequeño ajuste
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

	# Comprobar tilemaps válidos
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
