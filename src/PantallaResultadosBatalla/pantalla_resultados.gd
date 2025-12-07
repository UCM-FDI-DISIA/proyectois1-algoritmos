extends Control

# =====================================================================
# 🧾 NODOS
# =====================================================================
@onready var texto_resultados: RichTextLabel = $TextoResultados # Asume que es RichTextLabel
@onready var reset_button: TextureButton = $ResetButton
@onready var game_state: Node = get_node("/root/GameState") 
@export var main_scene_path: String = "res://src/PantallaPrincipal/main_menu.tscn"

# =====================================================================
# 🚀 INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	if game_state == null:
		push_error("❌ ERROR: El Autoload 'GameState' no se encontró.")
		return
		
	# Asumo que GameState tiene el método 'get_battle_results'
	if not game_state.has_method("get_battle_results"):
		push_error("GameState debe tener el método 'get_battle_results' para leer los datos.")
		return
	
	var results: Dictionary = game_state.get_battle_results()
	
	if results.is_empty():
		texto_resultados.bbcode_text = "[center][color=red][b]ERROR: No se encontraron resultados de batalla.[/b][/color][/center]"
		return
	
	texto_resultados.mouse_filter = Control.MOUSE_FILTER_IGNORE	
	_display_results(results)
	reset_button.pressed.connect(_on_ResetButton_pressed)

# =====================================================================
# 🖥️ MOSTRAR RESULTADOS
# =====================================================================
func _display_results(results: Dictionary) -> void:
	var result_text: String = results.get("result_text", "Resultado Desconocido")
	var p_troop_data: Dictionary = results.get("player_troops_data", {})
	var e_troop_data: Dictionary = results.get("enemy_troops_data", {})
	var p_power: int = results.get("player_power", 0)
	var e_power: int = results.get("enemy_power", 0)

	var p_info := _format_troop_info(p_troop_data, "Jugador").split("\n")
	var e_info := _format_troop_info(e_troop_data, "Enemigo").split("\n")

	var color := "yellow"
	if result_text.find("Jugador") != -1 and result_text.find("Gana") != -1:
		color = "green"
	elif result_text.find("Enemigo") != -1 and result_text.find("Gana") != -1:
		color = "red"

	var lines := []
	var max_lines: int = max(p_info.size(), e_info.size())

	# Formato de línea central para las tropas
	for i in range(max_lines):
		var p := p_info[i] if i < p_info.size() else ""
		var e := e_info[i] if i < e_info.size() else ""
		
		# CORRECCIÓN: Eliminamos la etiqueta [center] aquí
		lines.append("%s       %s" % [_pad_right(p, 25), e])

	# Montar el texto final
	# Aquí mantenemos el [center] porque solo aplica a esa línea específica.
	var final_text := "\n[center][color=%s][b]%s[/b][/color][/center]\n\n[center]%s[/center]\n\n" % [
		color, result_text, "\n".join(lines)
	]

	final_text += "[center] Poder Jugador: [b]%d[/b]    Poder Enemigo: [b]%d[/b][/center]" % [
		p_power, e_power
	]

	texto_resultados.bbcode_enabled = true
	texto_resultados.bbcode_text = final_text
	
	_update_label_style(texto_resultados)


# =====================================================================
# 🔙 VOLVER AL MENÚ
# =====================================================================
func _on_ResetButton_pressed() -> void:
	if main_scene_path != "":
		# Reseteo de Singletons
		if game_state: game_state.reset()
		if MultiplayerManager: MultiplayerManager.reset()
		if GDSync.is_active() && GameState.is_pve: GDSync.lobby_leave()
		
		# Cambio de escena
		get_tree().change_scene_to_file(main_scene_path)
	else:
		push_error("❌ main_scene_path no está configurado")


# =====================================================================
# 🧾 AUXILIAR: Formato y Utilidades
# =====================================================================

func _format_troop_info(troop_dict: Dictionary, title: String) -> String:
	var lines := ["%s:" % title]
	for _name in troop_dict.keys():
		lines.append("    • %s × %d" % [_name, troop_dict.get(_name, 0)])
	return "\n".join(lines)

func _pad_right(text: String, width: int) -> String:
	var n := width - text.length()
	if n > 0: text += " ".repeat(n)
	return text

func _update_label_style(label: RichTextLabel) -> void:
	var _size := int(get_viewport().get_visible_rect().size.y * 0.06)
	label.add_theme_font_size_override("font_size", _size)
	label.custom_minimum_size = get_viewport().get_visible_rect().size * 0.9
