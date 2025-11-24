extends CanvasLayer

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var HIDE_TIME := 20.0
@export var TOOLTIP_PADDING := 6

# =====================================================================
# 🧾 NODOS DE INTERFAZ
# =====================================================================
@onready var boton_s: TextureButton
@onready var warrior_button: TextureButton = $Soldados/Warrior/ButtonW/ButtonWarrior
@onready var archer_button: TextureButton = $Soldados/Archer/ButtonA/ButtonArcher
@onready var lancer_button: TextureButton = $Soldados/Lancer/ButtonL/ButtonLancer
@onready var monk_button: TextureButton = $Soldados/Monk/ButtonM/ButtonMonk

@onready var warrior_mas: Sprite2D = $Soldados/Warrior/ButtonW/Mas
@onready var archer_mas: Sprite2D = $Soldados/Archer/ButtonA/Mas
@onready var lancer_mas: Sprite2D = $Soldados/Lancer/ButtonL/Mas
@onready var monk_mas: Sprite2D = $Soldados/Monk/ButtonM/Mas

@onready var boton_s_mas: Sprite2D    
@onready var boton_s_menos: Sprite2D

@onready var tooltip_preview: Panel = Panel.new()
@onready var tooltip_label: Label = Label.new()

# =====================================================================
# 📊 ESTADO LOCAL
# =====================================================================
var labels: Dictionary = {
	"Warrior": null,
	"Archer": null,
	"Lancer": null,
	"Monk": null
}
var resource_manager: ResourceManager
var hide_timer: Timer

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	# --- Quadrant ---
	var quadrant: int = MultiplayerManager.get_my_quadrant()

	if GameState.is_pve:
		quadrant = 0
		print("Modo PVE detectado. Cuadrante forzado a 0 para UI.")
	else:
		print(GDSync.get_client_id(), " Cuadrante PVP: ", quadrant)
	
	# ------------------------------------------------------------------
	# --- Asignación del nodo de botón S según el cuadrante ---
	var boton_s_path = ""
	match quadrant:
		0: boton_s_path = "../ElementosPantalla/BotonS1"
		1: boton_s_path = "../ElementosPantalla/BotonS2"
		2: boton_s_path = "../ElementosPantalla/BotonS3"
		3: boton_s_path = "../ElementosPantalla/BotonS4"
		_:
			push_error("❌ Cuadrante inválido para asignar BotonS. Saliendo de _ready.")
			return

	boton_s = get_node_or_null(boton_s_path)
	
	if boton_s == null:
		push_error("❌ BotonS no encontrado en la ruta: " + boton_s_path + ". Verifica si el nodo existe en ElementosPantalla.")
		return # Detener ejecución si el nodo principal no se encuentra.

	# ⚠️ NECESARIO: Esperar un frame para asegurar que los hijos instanciados se carguen
	await get_tree().process_frame

	# Usamos los nombres 'Mas' y 'Menos' de tu versión anterior, y get_node_or_null()
	boton_s_mas = boton_s.get_node_or_null("Mas") # <--- AQUI ESTA LA CORRECCIÓN
	boton_s_menos = boton_s.get_node_or_null("Menos") 
	
	# Añadir una verificación de seguridad:
	if boton_s_mas == null or boton_s_menos == null:
		push_error("❌ Nodos 'Mas' o 'Menos' NO ENCONTRADOS dentro de " + boton_s.name + ". Revisa la jerarquía interna de BotonS1.")
		# NO usamos 'return' aquí para intentar conectar el botón principal (boton_s)

	# --- Labels ---
	labels["Warrior"] = $Soldados/Warrior/WarriorLabel
	labels["Archer"] = $Soldados/Archer/ArcherLabel
	labels["Lancer"] = $Soldados/Lancer/LancerLabel
	labels["Monk"] = $Soldados/Monk/MonkLabel

	# ------------------------------------------------------------------
	resource_manager = get_node_or_null("/root/Main/ResourceManager")
	
	if resource_manager:
		resource_manager.ResourceUpdated.connect(_on_resource_updated)
		resource_manager.SoldierUpdated.connect(_on_soldier_updated)
	else:
		push_error("❌ [MenuSoldados] ResourceManager no encontrado en /root/Main/ResourceManager. La compra de soldados fallará.")
	# ------------------------------------------------------------------
	
	# --- Tooltip (Resto de la inicialización) ---
	tooltip_preview.modulate = Color(1, 1, 1, 0.8)
	tooltip_preview.visible = false
	add_child(tooltip_preview)
	tooltip_label.add_theme_color_override("font_color", Color.WHITE)
	tooltip_preview.add_child(tooltip_label)

	# --- Timer ---
	hide_timer = Timer.new()
	hide_timer.wait_time = HIDE_TIME
	hide_timer.one_shot = true
	hide_timer.timeout.connect(_on_hide_timer_timeout)
	add_child(hide_timer)

	# --- Botón S ---
	boton_s.pressed.connect(_on_boton_s_pressed)
	# Solo intenta cambiar la visibilidad si el nodo existe
	if boton_s_menos:
		boton_s_menos.visible = false

	# --- Botones de reclutamiento ---
	_connect_button_events(warrior_button, "Warrior")
	_connect_button_events(archer_button, "Archer")
	_connect_button_events(lancer_button, "Lancer")
	_connect_button_events(monk_button, "Monk")

	# Estas llamadas fallarán si resource_manager es null (por eso la verificación es clave)
	if resource_manager:
		update_all_labels()
		_update_button_states()
		
	visible = false

# =====================================================================
# 🔁 SEÑALES
# =====================================================================
func _on_resource_updated(_resource: String, _value: int) -> void:
	_update_button_states()

func _on_soldier_updated(type: String, _count: int) -> void:
	if labels.has(type):
		labels[type].text = str(resource_manager.get_soldier_count(type))

func _on_hide_timer_timeout() -> void:
	_hide_menu()

# =====================================================================
# 🎮 EVENTOS DE BOTONES
# =====================================================================
func _connect_button_events(button: TextureButton, type: String) -> void:
	if button == null: return
	button.pressed.connect(_on_recruit_pressed.bind(type))
	button.mouse_entered.connect(_show_tooltip.bind(type))
	button.mouse_exited.connect(_hide_tooltip)

func _on_boton_s_pressed() -> void:
	if visible:
		_hide_menu()
		hide_timer.stop()
		boton_s_mas.visible   = true
		boton_s_menos.visible = false
	else:
		visible = true
		hide_timer.start()
		boton_s_mas.visible   = false
		boton_s_menos.visible = true

func _on_recruit_pressed(type: String) -> void:
	if resource_manager == null: return
	hide_timer.start()

	resource_manager.reclutar_soldado(type)          # <-- nueva función

	var gs = get_node_or_null("/root/GameState")
	if gs != null:
		gs.add_troops(type, 1)

	_update_button_states()

# =====================================================================
# 🛠️ MÉTODOS AUXILIARES
# =====================================================================
func _update_button_states() -> void:
	for type in labels:
		var costs: Dictionary = resource_manager.get_soldier_costs(type)
		var can_afford := true
		for res in costs:
			if resource_manager.get_resource(res) < costs[res]:
				can_afford = false
				break

		var button: TextureButton
		var mas: Sprite2D
		match type:
			"Warrior": button = warrior_button;  mas = warrior_mas
			"Archer":  button = archer_button;   mas = archer_mas
			"Lancer":  button = lancer_button;   mas = lancer_mas
			"Monk":    button = monk_button;     mas = monk_mas
		if button: button.disabled = not can_afford
		if mas:    mas.visible      = can_afford

func _show_tooltip(type: String) -> void:
	var costs: Dictionary = resource_manager.get_soldier_costs(type)
	var txt: PackedStringArray = []
	for res in costs:
		if costs[res] > 0: txt.append("%s: %d" % [res.capitalize(), costs[res]])
	tooltip_label.text = "  ".join(txt)

	var mp := get_viewport().get_mouse_position()
	var ts := tooltip_label.get_minimum_size() + Vector2(TOOLTIP_PADDING*2, TOOLTIP_PADDING*2)
	tooltip_preview.size = ts
	var ss := get_viewport().get_visible_rect().size
	var tp := mp + Vector2(16, 16)
	if tp.x + ts.x > ss.x: tp.x = ss.x - ts.x - 8
	if tp.y + ts.y > ss.y: tp.y = ss.y - ts.y - 8
	tooltip_preview.position = tp
	tooltip_preview.visible = true

func _process(_delta: float) -> void:
	if tooltip_preview.visible:
		var mp := get_viewport().get_mouse_position()
		var ts := tooltip_label.get_minimum_size() + Vector2(TOOLTIP_PADDING*2, TOOLTIP_PADDING*2)
		tooltip_preview.size = ts
		tooltip_preview.position = mp + Vector2(8, 8)

func _hide_tooltip() -> void:
	tooltip_preview.visible = false

func update_all_labels() -> void:
	for t in labels:
		labels[t].text = str(resource_manager.get_soldier_count(t))

func _hide_menu() -> void:
	visible = false
	boton_s_mas.visible   = true
	boton_s_menos.visible = false
