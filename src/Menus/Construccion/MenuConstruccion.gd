extends CanvasLayer

# =====================
# VARIABLES Y NODOS
# =====================
var btn_menu : TextureButton
var panel_barra : PanelContainer
var hbox_botones : HBoxContainer
var btn_casa : TextureButton
var marcador_casa : Sprite2D

var en_construccion := false
var casa_preview : Node2D

var area_preview : Area2D
var puede_construir := true

var resource_manager : ResourceManager

const GRID_SIZE := 64

# =====================
# INICIALIZACIÓN
# =====================
func _ready() -> void:
	resource_manager = get_tree().root.get_node("Main/ResourceManager")
	if resource_manager == null:
		push_error("ResourceManager no encontrado")
	else:
		print("ResourceManager encontrado")

	btn_menu = $ControlRaiz/BtnMenu
	panel_barra = $ControlRaiz/PanelBarra
	hbox_botones = $ControlRaiz/PanelBarra/HBoxBotones
	btn_casa = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasa
	marcador_casa = $ControlRaiz/PanelBarra/HBoxBotones/BtnCasa/Marcador

	panel_barra.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_casa.mouse_filter = Control.MOUSE_FILTER_STOP

	panel_barra.visible = false
	marcador_casa.visible = false

	if resource_manager != null:
		btn_casa.tooltip_text = "Costo: Madera %d | Piedra %d | Oro %d" % [
			resource_manager.get_casa_wood_cost(),
			resource_manager.get_casa_stone_cost(),
			resource_manager.get_casa_gold_cost()
		]

	btn_menu.pressed.connect(_on_menu_pressed)
	btn_casa.pressed.connect(_on_casa_pressed)

# =====================
# HANDLERS DE EVENTOS
# =====================
func _on_menu_pressed() -> void:
	panel_barra.visible = not panel_barra.visible

	if not panel_barra.visible:
		_cancelar_construccion()

	panel_barra.mouse_filter = Control.MOUSE_FILTER_STOP if panel_barra.visible else Control.MOUSE_FILTER_IGNORE
	print("Panel de construcción %s" % ("visible" if panel_barra.visible else "oculto"))

func _on_casa_pressed() -> void:
	marcador_casa.visible = not marcador_casa.visible

	if en_construccion:
		print("Ya estás en modo construcción")
		return

	if resource_manager == null or resource_manager.casa_scene == null or resource_manager.contenedor_casas == null:
		push_error("Faltan asignaciones en ResourceManager (casaScene o contenedorCasas)")
		return

	en_construccion = true
	casa_preview = resource_manager.casa_scene.instantiate() as Node2D

	if casa_preview is CasaAnimada:
		var casa_anim = casa_preview as CasaAnimada
		casa_anim.es_preview = true

		var collision_shape = casa_anim.get_node_or_null("CollisionShape2D")
		if collision_shape != null:
			collision_shape.disabled = true

		var collision_parent = casa_anim.get_node_or_null("CollisionObject2D")
		if collision_parent != null:
			collision_parent.collision_layer = 0
			collision_parent.collision_mask = 0

	_tint_preview(Color(1,1,1,0.5))
	resource_manager.contenedor_casas.add_child(casa_preview)
	print("Preview de casa instanciado y agregado al contenedor")

	_crear_area_preview()

func _on_area_preview_body_entered(body: Node) -> void:
	if body.is_in_group("objeto_bloqueante") or body.is_in_group("jugador"):
		puede_construir = false
		_tint_preview(Color(1,0,0,0.4))

func _on_area_preview_body_exited(body: Node) -> void:
	if body.is_in_group("objeto_bloqueante") or body.is_in_group("jugador"):
		puede_construir = true
		_tint_preview(Color(1,1,1,0.5))

# =====================
# BUCLE PRINCIPAL
# =====================
func _process(delta: float) -> void:
	if not en_construccion or casa_preview == null:
		return

	var camera = get_viewport().get_camera_2d()
	var mouse_pos = camera.get_global_mouse_position()

	var x = floor(mouse_pos.x / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2
	var y = floor(mouse_pos.y / GRID_SIZE) * GRID_SIZE + GRID_SIZE / 2
	casa_preview.position = Vector2(x, y)

	if Input.is_mouse_button_pressed(MouseButton.RIGHT) or Input.is_key_pressed(Key.ESCAPE):
		_cancelar_construccion()
		return

	if Input.is_mouse_button_pressed(MouseButton.LEFT):
		if not puede_construir:
			print("No puedes construir encima del personaje")
			return

		if resource_manager.puedo_comprar_casa():
			resource_manager.pagar_casa()

			var casa_real = resource_manager.casa_scene.instantiate() as CasaAnimada
			casa_real.es_preview = false
			casa_real.position = casa_preview.position
			resource_manager.contenedor_casas.add_child(casa_real)

			casa_preview.queue_free()
			casa_preview = null
			en_construccion = false
			marcador_casa.visible = false
			btn_casa.pressed = false

			print("Casa construida correctamente")
		else:
			print("No tienes materiales suficientes para construir")
			_cancelar_construccion()

# =====================
# MÉTODOS AUXILIARES
# =====================
func _crear_area_preview() -> void:
	if casa_preview == null:
		return

	area_preview = Area2D.new()
	casa_preview.add_child(area_preview)

	var shape_original = casa_preview.get_node_or_null("CollisionShape2D")
	if shape_original != null and shape_original.shape != null:
		var nueva_forma = shape_original.shape.duplicate() as Shape2D
		var shape_clone = CollisionShape2D.new()
		shape_clone.shape = nueva_forma
		area_preview.add_child(shape_clone)

	area_preview.monitoring = true
	area_preview.monitorable = true
	area_preview.collision_layer = 0
	area_preview.collision_mask = 1

	area_preview.body_entered.connect(_on_area_preview_body_entered)
	area_preview.body_exited.connect(_on_area_preview_body_exited)

func _tint_preview(color: Color) -> void:
	if casa_preview == null:
		return

	for child in casa_preview.get_children():
		if child is CanvasItem:
			(child as CanvasItem).modulate = color

func _cancelar_construccion() -> void:
	if casa_preview != null:
		casa_preview.queue_free()
		casa_preview = null

	area_preview = null
	en_construccion = false
	marcador_casa.visible = false
	btn_casa.pressed = false

	print("Construcción cancelada")
