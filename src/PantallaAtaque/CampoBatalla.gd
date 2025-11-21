extends Node2D

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var spacing: float = 96.0
@export var troop_scale: Vector2 = Vector2(3.0, 3.0)
@export var smoke_scene: PackedScene
@export var main_scene_path: String = "res://src/UI/Main.tscn"
@export var tween_duration: float = 3.0
@onready var main_menu_button: TextureButton = $MainMenuButton

# =====================================================================
# 🧾 NODOS
# =====================================================================
@onready var tropas_node: Node2D = $Objetos/Tropas
@onready var game_state: Node = get_node("/root/GameState")

# =====================================================================
# 📊 ESTADO
# =====================================================================
var tile_size: Vector2 = Vector2(64, 64)
var battlefield_tiles: Vector2 = Vector2(60, 30)

var player_troops: Array[Node2D] = []
var enemy_troops: Array[Node2D] = []
var enemy_counts: Dictionary = {}

var tweens_completed := 0
var total_tweens := 0

# =====================================================================
# 🚀 INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	if game_state == null:
		push_error("❌ No se encontró GameState")
		return
	
	# --- Spawn jugador ---
	_spawn_player_troops()
	
	# --- Determinar enemigo (PVP o PVE) ---
	var my_id: int = GDSync.get_client_id()
	var enemy_troops_dict: Dictionary
	
	var mp := get_tree().get_multiplayer()
	var all_peers := [mp.get_unique_id()]
	all_peers.append_array(mp.get_peers())
	print("Todos los jugadores conectados:", all_peers)
	
	# Utilizo el array de players para que también cuente al host
	if MultiplayerManager.players.size() > 1:
		# PVP: hay otro jugador además de ti
		var enemy_id: int = MultiplayerManager.get_enemy_id(my_id)
		enemy_troops_dict = GDSync.player_get_data(enemy_id, "troops_by_client", {
			"Archer": 0,
			"Lancer": 0,
			"Monk": 0,
			"Warrior": 0
		})
		print("👥 Enemigo PVP:", enemy_troops_dict)
	else:
		# PVE: generar enemigo aleatorio
		enemy_troops_dict = _generate_ai_troops()
		print("🤖 Enemigo PVE:", enemy_troops_dict)
	
	# --- Spawn enemigo ---
	_spawn_enemy_troops(enemy_troops_dict)
	
	# --- Iniciar batalla ---
	_start_battle_countdown()
	
	# --- Botón menú principal ---
	main_menu_button.visible = false
	main_menu_button.pressed.connect(_on_MainMenuButton_pressed)


# =====================================================================
# 🪖 SPAWN JUGADOR
# =====================================================================
func _spawn_player_troops() -> void:
	var troop_counts: Dictionary = game_state.get_all_troop_counts()
	var troop_scenes := {
		"Archer": preload("res://src/NPCs/Archer.tscn"),
		"Lancer": preload("res://src/NPCs/Lancer.tscn"),
		"Monk": preload("res://src/NPCs/Monk.tscn"),
		"Warrior": preload("res://src/NPCs/Warrior.tscn")
	}
	
	print("Soy el jugador: ", GDSync.get_client_id(), " y voy a actualizar mis tropas.")
	
	var battlefield_size := battlefield_tiles * tile_size
	var num_rows := 0
	for c in troop_counts.values():
		if c > 0:
			num_rows += 1

	var total_height := num_rows * spacing + (num_rows - 1) * spacing
	var start_y := (battlefield_size.y - total_height) / 2.0

	var index := 0
	for troop_name in troop_counts.keys():
		var count: int = troop_counts[troop_name]
		if count <= 0 or not troop_scenes.has(troop_name):
			continue

		var scene: PackedScene = troop_scenes[troop_name]
		var row_y := start_y + index * (spacing * 2.0)

		for i in range(count):
			var troop: Node2D = scene.instantiate()
			troop.scale = troop_scale
			troop.position = Vector2(100 + i * spacing, row_y)
			tropas_node.add_child(troop)
			player_troops.append(troop)

		index += 1
	print("✅ Tropas del jugador centradas")


# =====================================================================
# 🪖 SPAWN ENEMIGO (PVP o PVE)
# =====================================================================
func _spawn_enemy_troops(enemy_data: Dictionary) -> void:
	var troop_scenes := {
		"Archer": preload("res://src/NPCs/Archer.tscn"),
		"Lancer": preload("res://src/NPCs/Lancer.tscn"),
		"Monk": preload("res://src/NPCs/Monk.tscn"),
		"Warrior": preload("res://src/NPCs/Warrior.tscn")
	}

	enemy_counts = enemy_data
	var index := 0
	for troop_name in troop_scenes.keys():
		var count: int = enemy_counts.get(troop_name, 0)
		if count <= 0 or not troop_scenes.has(troop_name):
			continue

		var scene: PackedScene = troop_scenes[troop_name]
		var row_y := _row_y_for_index(index)

		for i in range(count):
			var troop: Node2D = scene.instantiate()
			troop.scale = Vector2(-troop_scale.x, troop_scale.y) # mirar hacia jugador
			troop.position = Vector2(battlefield_tiles.x * tile_size.x - 100 - i * spacing, row_y)
			tropas_node.add_child(troop)
			enemy_troops.append(troop)

		index += 1
	print("🟥 Tropas enemigas centradas")


# =====================================================================
# 🤖 FUNCION AUXILIAR: Generar tropas AI PVE
# =====================================================================
func _generate_ai_troops() -> Dictionary:
	var troops := {
		"Archer": randi() % 5 + 1,   # mínimo 1
		"Lancer": randi() % 5 + 1,
		"Monk": randi() % 5 + 1,
		"Warrior": randi() % 5 + 1
	}
	return troops


# =====================================================================
# ⏱️ CUENTA ATRÁS INICIAL
# =====================================================================
func _start_battle_countdown() -> void:
	print("⏱️ Cuenta atrás iniciada...")

	var canvas := CanvasLayer.new()
	add_child(canvas)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(20, 20)
	canvas.add_child(label)

	for i in range(3, 0, -1):
		label.text = str(i)
		print("⏳ %d..." % i)
		await get_tree().create_timer(1.0).timeout

	label.text = "¡BATALLA!"
	print("🔥 Batalla comienza!")
	await get_tree().create_timer(1.0).timeout
	label.queue_free()

	_start_battle()


# =====================================================================
# 🏃 MOVIMIENTO AL CENTRO
# =====================================================================
func _start_battle() -> void:
	if not _check_forced_battle_result():
		return

	print("🏃 Tropas avanzando hacia el centro...")

	var center_x := (battlefield_tiles.x * tile_size.x) / 2.0
	var attack_margin := 120.0

	total_tweens = player_troops.size() + enemy_troops.size()
	tweens_completed = 0

	for troop in player_troops:
		_tween_troop(troop, center_x - attack_margin)

	for troop in enemy_troops:
		_tween_troop(troop, center_x + attack_margin)


# =====================================================================
# ⚡ COMPROBAR BATALLA FORZADA
# =====================================================================
func _check_forced_battle_result() -> bool:
	if player_troops.is_empty():
		print("⚠️ El jugador no tiene tropas. Gana el enemigo automáticamente.")
		_show_battle_result_forced("enemy")
		return false
	elif enemy_troops.is_empty():
		print("⚠️ El enemigo no tiene tropas. Gana el jugador automáticamente.")
		_show_battle_result_forced("player")
		return false
	return true


func _show_battle_result_forced(winner: String) -> void:
	var result_text := ""
	if winner == "player":
		result_text = "🏆 ¡Gana el Jugador!"
	elif winner == "enemy":
		result_text = "💀 ¡Gana el Enemigo!"
	else:
		result_text = "⚖️ ¡Empate!"
	print("📣 Resultado → %s" % result_text)
	_show_result_ui(result_text, enemy_counts)


# =====================================================================
# 🎞️ TWEEN INDIVIDUAL
# =====================================================================
func _tween_troop(troop: Node2D, target_x: float) -> void:
	var sprite := _find_sprite(troop)
	if sprite and sprite.sprite_frames.has_animation("Run"):
		sprite.play("Run")

	var tween := create_tween()
	tween.tween_property(troop, "position:x", target_x, tween_duration)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		if sprite and sprite.sprite_frames.has_animation("Idle"):
			sprite.play("Idle")
		tweens_completed += 1
		if tweens_completed >= total_tweens:
			_trigger_central_explosion()
	)


# =====================================================================
# 🔍 HELPER: AnimatedSprite2D anidado
# =====================================================================
func _find_sprite(node: Node) -> AnimatedSprite2D:
	for child in node.get_children():
		if child is AnimatedSprite2D:
			return child
		var nested := _find_sprite(child)
		if nested:
			return nested
	return null


# =====================================================================
# 💥 ATAQUE CENTRAL + HUMO
# =====================================================================
func _trigger_central_explosion() -> void:
	print("💥 Tropas llegan al centro. Ejecutando ataque simultáneo antes del humo.")
	await _play_all_attack_animations()
	print("💨 Animaciones de ataque completadas. Creando humo.")

	var center := Vector2(battlefield_tiles.x * tile_size.x / 2.0, battlefield_tiles.y * tile_size.y / 2.0)

	if smoke_scene:
		var smoke := smoke_scene.instantiate() as Node2D
		smoke.position = center
		smoke.scale = Vector2(5, 5)
		tropas_node.add_child(smoke)

	for t in player_troops + enemy_troops:
		t.visible = false

	await get_tree().create_timer(2.0).timeout
	_show_battle_result()


# =====================================================================
# 🎞️ ANIMAR TODAS LAS TROPAS
# =====================================================================
func _play_all_attack_animations() -> void:
	var anim_length := 1.1
	var animations: Array = []
	for troop in player_troops + enemy_troops:
		var sprite := _find_sprite(troop)
		if sprite and sprite.sprite_frames.has_animation("Attack"):
			sprite.play("Attack")
		animations.append(get_tree().create_timer(anim_length).timeout)
	
	for s in animations:
		await s


# =====================================================================
# 📊 CÁLCULO DE RESULTADO
# =====================================================================
func _show_battle_result() -> void:
	print("📊 Calculando resultado...")

	var player_power := _calculate_power(game_state.get_all_troop_counts())
	var enemy_power := _calculate_power(enemy_counts)

	var result_text := ""
	if player_power > enemy_power:
		result_text = "🏆 ¡Gana el Jugador!"
	elif player_power < enemy_power:
		result_text = "💀 ¡Gana el Enemigo!"
	else:
		result_text = "⚖️ ¡Empate!"

	print("📣 Resultado → %s" % result_text)
	_show_result_ui(result_text, enemy_counts)


# =====================================================================
# 🖥️ MOSTRAR PANTALLA DE RESULTADO
# =====================================================================
func _show_result_ui(result_text: String, _enemy_counts: Dictionary) -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var bg := ColorRect.new()
	bg.color = Color(0,0,0,0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center_container)

	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.scroll_active = false
	label.scroll_following = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.fit_content = true
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center_container.add_child(label)

	var player_info := _format_troop_info(game_state.get_all_troop_counts(), "Jugador").split("\n")
	var enemy_info := _format_troop_info(_enemy_counts, "Enemigo").split("\n")
	var player_power := _calculate_power(game_state.get_all_troop_counts())
	var enemy_power := _calculate_power(_enemy_counts)

	var color := "yellow"
	if result_text.find("Jugador") != -1 and result_text.find("Gana") != -1:
		color = "green"
	elif result_text.find("Enemigo") != -1 and result_text.find("Gana") != -1:
		color = "red"

	var col_width: int = 28
	var col_spacing: int = 10
	var max_lines: int = max(player_info.size(), enemy_info.size())
	var lines: Array = []
	for i in range(max_lines):
		var p := player_info[i] if i < player_info.size() else ""
		var e := enemy_info[i] if i < enemy_info.size() else ""
		lines.append("[center]%s%s%s[/center]" % [
			pad_right(p, col_width),
			" ".repeat(col_spacing),
			e
		])

	var text := "\n[center][color=%s][b]%s[/b][/color][/center]\n\n%s\n\n[center]⚔️ Poder Jugador: [b]%d[/b]   💀 Poder Enemigo: [b]%d[/b][/center]" % [
		color,
		result_text,
		"\n".join(lines),
		player_power,
		enemy_power
	]
	label.bbcode_text = text
	_update_label_font(label)

	# Posicionar botón menú
	var button_placement_container := CenterContainer.new()
	canvas.add_child(button_placement_container)
	button_placement_container.anchor_top = 0.70
	button_placement_container.anchor_bottom = 1.0
	button_placement_container.anchor_left = 0.0
	button_placement_container.anchor_right = 1.0

	main_menu_button.get_parent().remove_child(main_menu_button)
	button_placement_container.add_child(main_menu_button)
	main_menu_button.scale = Vector2(1.75, 1.75)
	main_menu_button.visible = true


# =====================================================================
# 🔙 VOLVER AL MENÚ
# =====================================================================
func _on_MainMenuButton_pressed() -> void:
	if main_scene_path != "":
		print("🔄 Volviendo al menú principal...")
		get_tree().change_scene_to_file(main_scene_path)
	else:
		push_error("❌ main_scene_path no está configurado")


# =====================================================================
# ✒️ ACTUALIZAR FUENTE (RichTextLabel)
# =====================================================================
func _update_label_font(label: RichTextLabel) -> void:
	var screen_size := get_viewport().get_visible_rect().size
	var font_size := int(screen_size.y * 0.06)
	label.add_theme_font_size_override("font_size", font_size)
	label.custom_minimum_size = screen_size * 0.9


# =====================================================================
# 🧾 FORMATEAR INFO DE TROPAS
# =====================================================================
func _format_troop_info(troop_dict: Dictionary, title: String) -> String:
	var lines := []
	lines.append("👑 %s:" % title)
	for troop_name in troop_dict.keys():
		lines.append("   • %s × %d" % [troop_name, troop_dict[troop_name]])
	return "\n".join(lines)


# =====================================================================
# 🧮 CALCULAR PODER TOTAL
# =====================================================================
func _calculate_power(troop_dict: Dictionary) -> int:
	var weights := {
		"Archer": 2,
		"Lancer": 3,
		"Monk": 4,
		"Warrior": 1
	}
	var total := 0
	for t in troop_dict.keys():
		if weights.has(t):
			total += troop_dict[t] * weights[t]
	return total


# =====================================================================
# 🔧 HELPER: calcular Y de cada fila
# =====================================================================
func _row_y_for_index(index: int) -> float:
	var total_height := (enemy_counts.size() - 1) * spacing * 2.0
	var start_y := (battlefield_tiles.y * tile_size.y - total_height) / 2.0
	return start_y + index * spacing * 2.0


# =====================================================================
# 🖇️ UTILIDADES
# =====================================================================
func pad_right(text: String, width: int) -> String:
	var n := width - text.length()
	if n > 0:
		text += " ".repeat(n)
	return text
