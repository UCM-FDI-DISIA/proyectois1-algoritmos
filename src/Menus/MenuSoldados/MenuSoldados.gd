extends CanvasLayer

# =====================================================================
# VARIABLES Y NODOS
# =====================================================================

# =====================
# LABELS Y SOLDADOS
# =====================
var labels := {}
var soldier_counts := {
	"Warrior": 0,
	"Archer": 0,
	"Lancer": 0,
	"Monk": 0
}

# =====================
# BOTONES
# =====================
var boton_s : TextureButton
var warrior_button : TextureButton
var archer_button : TextureButton
var lancer_button : TextureButton
var monk_button : TextureButton

# Sprites "Mas" de cada tipo
var warrior_mas : Sprite2D
var archer_mas : Sprite2D
var lancer_mas : Sprite2D
var monk_mas : Sprite2D

# Sprites del botón S
var boton_s_mas : Sprite2D
var boton_s_menos : Sprite2D

# =====================
# TOOLTIP
# =====================
var tooltip_preview : Panel
var tooltip_label : Label
const TOOLTIP_PADDING := 6

# =====================
# RECURSOS Y COSTES
# =====================
var resource_manager : ResourceManager
var soldier_costs := {
	"Warrior": { "villager": 1, "gold": 1, "wood": 0, "stone": 0 },
	"Archer":  { "villager": 1, "gold": 2, "wood": 0, "stone": 0 },
	"Lancer":  { "villager": 1, "gold": 3, "wood": 0, "stone": 0 },
	"Monk":    { "villager": 1, "gold": 5, "wood": 0, "stone": 0 }
}

# =====================
# TEMPORIZADOR VISIBILIDAD
# =====================
var hide_timer : Timer
const HIDE_TIME := 20.0

# =====================================================================
# INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	call_deferred("initialize_menu")

func initialize_menu() -> void:
	# --- Labels ---
	labels["Warrior"] = $Soldados/Warrior/WarriorLabel
	labels["Archer"]  = $Soldados/Archer/ArcherLabel
	labels["Lancer"]  = $Soldados/Lancer/LancerLabel
	labels["Monk"]    = $Soldados/Monk/MonkLabel

	# --- ResourceManager ---
	resource_manager = get_node_or_null("../ResourceManager")
	if resource_manager == null:
		push_error("[MenuSoldados] ResourceManager no encontrado")
	else:
		resource_manager.connect("ResourceUpdated", Callable(self, "_on_resource_updated"))

	# --- Botón externo ---
	boton_s = get_node_or_null("../ElementosPantalla/BotonS")
	if boton_s != null:
		boton_s.pressed.connect(_on_boton_s_pressed)

	# Sprites del botón S
	boton_s_mas = boton_s.get_node_or_null("Mas") if boton_s != null else null
	boton_s_menos = boton_s.get_node_or_null("Menos") if boton_s != null else null
	if boton_s_menos != null:
		boton_s_menos.visible = false

	# --- Botones soldados ---
	warrior_button = $Soldados/Warrior/ButtonW/ButtonWarrior
	archer_button  = $Soldados/Archer/ButtonA/ButtonArcher
	lancer_button  = $Soldados/Lancer/ButtonL/ButtonLancer
	monk_button    = $Soldados/Monk/ButtonM/ButtonMonk

	# Sprites "Mas"
	warrior_mas = $Soldados/Warrior/ButtonW/Mas
	archer_mas  = $Soldados/Archer/ButtonA/Mas
	lancer_mas  = $Soldados/Lancer/ButtonL/Mas
	monk_mas    = $Soldados/Monk/ButtonM/Mas

	_connect_button_events(warrior_button, "Warrior")
	_connect_button_events(archer_button,  "Archer")
	_connect_button_events(lancer_button,  "Lancer")
	_connect_button_events(monk_button,    "Monk")

	# --- Tooltip ---
	tooltip_preview = Panel.new()
	tooltip_preview.modulate = Color(1,1,1,0.8)
	tooltip_preview.visible = false
	add_child(tooltip_preview)

	tooltip_label = Label.new()
	tooltip_label.add_theme_color_override("font_color", Color.WHITE)
	tooltip_preview.add_child(tooltip_label)

	# --- Timer ---
	hide_timer = Timer.new()
	hide_timer.wait_time = HIDE_TIME
	hide_timer.one_shot = true
	hide_timer.timeout.connect(_on_hide_timer_timeout)
	add_child(hide_timer)

	update_all_labels()
	visible = false
	_update_button_states()

# =====================================================================
# EVENTOS DE BOTONES Y RECURSOS
# =====================================================================
func _connect_button_events(button: TextureButton, type: String) -> void:
	if button == null:
		return
	button.pressed.connect(Callable(self, "_on_recruit_pressed").bind(type))
	button.mouse_entered.connect(Callable(self, "_show_tooltip").bind(type))

	button.mouse_exited.connect(_hide_tooltip)

func _on_boton_s_pressed() -> void:
	if visible:
		_hide_menu()
		hide_timer.stop()
		if boton_s_mas != null:
			boton_s_mas.visible = true
		if boton_s_menos != null:
			boton_s_menos.visible = false
	else:
		visible = true
		hide_timer.start()
		print("MenuSoldados mostrado")
		if boton_s_mas != null:
			boton_s_mas.visible = false
		if boton_s_menos != null:
			boton_s_menos.visible = true

func _on_resource_updated(resource_name: String, new_value: int) -> void:
	_update_button_states()

func _on_recruit_pressed(type: String) -> void:
	if resource_manager == null or not soldier_counts.has(type):
		return

	hide_timer.start()
	var costs = soldier_costs[type]

	# Verificar recursos
	for res_key in costs.keys():
		if resource_manager.get_resource(res_key) < costs[res_key]:
			print("No hay recursos suficientes para reclutar %s" % type)
			return

	# Restar recursos
	for res_key in costs.keys():
		resource_manager.remove_resource(res_key, costs[res_key])

	soldier_counts[type] += 1
	if labels.has(type):
		labels[type].text = str(soldier_counts[type])

	print("Reclutado 1 %s. Total = %d" % [type, soldier_counts[type]])

	var gs = get_node_or_null("/root/GameState")
	if gs != null:
		gs.call("AddTroops", type, 1)

	_update_button_states()

# =====================================================================
# MÉTODOS AUXILIARES
# =====================================================================
func _update_button_states() -> void:
	for type in soldier_costs.keys():
		var can_afford := true
		for res_key in soldier_costs[type].keys():
			if resource_manager.get_resource(res_key) < soldier_costs[type][res_key]:
				can_afford = false
				break

		var button: TextureButton
		var mas: Sprite2D

		match type:
			"Warrior":
				button = warrior_button
				mas = warrior_mas
			"Archer":
				button = archer_button
				mas = archer_mas
			"Lancer":
				button = lancer_button
				mas = lancer_mas
			"Monk":
				button = monk_button
				mas = monk_mas

		if button != null:
			button.disabled = not can_afford
			if mas != null:
				mas.visible = can_afford

func _show_tooltip(type: String) -> void:
	if tooltip_preview == null or tooltip_label == null:
		return

	var cost = soldier_costs[type]
	var text_parts := []
	for r in ["wood", "stone", "gold", "villager"]:
		if cost.has(r) and cost[r] > 0:
			text_parts.append("%s: %d" % [r.capitalize(), cost[r]])

	tooltip_label.text = "  ".join(text_parts)

	var mouse_pos = get_viewport().get_mouse_position()
	var label_size = tooltip_label.get_minimum_size() + Vector2(TOOLTIP_PADDING*2, TOOLTIP_PADDING*2)
	tooltip_preview.size = label_size

	var screen_size = get_viewport().get_visible_rect().size
	var tooltip_pos = mouse_pos + Vector2(16,16)
	if tooltip_pos.x + label_size.x > screen_size.x:
		tooltip_pos.x = screen_size.x - label_size.x - 8
	if tooltip_pos.y + label_size.y > screen_size.y:
		tooltip_pos.y = screen_size.y - label_size.y - 8

	tooltip_preview.position = tooltip_pos
	tooltip_preview.visible = true

func _process(delta: float) -> void:
	if tooltip_preview != null and tooltip_preview.visible:
		var mouse_pos = get_viewport().get_mouse_position()
		var label_size = tooltip_label.get_minimum_size() + Vector2(TOOLTIP_PADDING*2, TOOLTIP_PADDING*2)
		tooltip_preview.size = label_size
		tooltip_preview.position = mouse_pos + Vector2(8,8)

func _hide_tooltip() -> void:
	if tooltip_preview != null:
		tooltip_preview.visible = false

func update_all_labels() -> void:
	for type in soldier_counts.keys():
		if labels.has(type):
			labels[type].text = str(soldier_counts[type])

func _hide_menu() -> void:
	visible = false
	print("MenuSoldados oculto")

func _on_hide_timer_timeout() -> void:
	_hide_menu()
	if boton_s_mas != null:
		boton_s_mas.visible = true
	if boton_s_menos != null:
		boton_s_menos.visible = false
