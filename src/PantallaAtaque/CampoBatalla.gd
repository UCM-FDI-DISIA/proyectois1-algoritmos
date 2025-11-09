extends Node2D

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var spacing: float = 96.0
@export var troop_scale: Vector2 = Vector2(3.0, 3.0)
@export var smoke_scene: PackedScene
@export var main_scene_path: String = "res://src/UI/Main.tscn"
@export var tween_duration: float = 3.0

# =====================================================================
# 🧾 NODOS
# =====================================================================
@onready var tropas_node: Node2D = $Objetos/Tropas
@onready var game_state: Node   = get_node("/root/GameState")

# =====================================================================
# 📊 ESTADO
# =====================================================================
var tile_size: Vector2 = Vector2(64, 64)
var battlefield_tiles: Vector2 = Vector2(60, 30)

var player_troops: Array[Node2D] = []
var enemy_troops: Array[Node2D]  = []
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
	_spawn_player_troops()
	_spawn_enemy_troops()
	_start_battle_countdown()

# =====================================================================
# 🪖 SPAWN JUGADOR
# =====================================================================
func _spawn_player_troops() -> void:
	var troop_counts: Dictionary = game_state.get_all_troop_counts()
	var troop_scenes := {
		"Archer":  preload("res://src/NPCs/Archer.tscn"),
		"Lancer":  preload("res://src/NPCs/Lancer.tscn"),
		"Monk":    preload("res://src/NPCs/Monk.tscn"),
		"Warrior": preload("res://src/NPCs/Warrior.tscn")
	}

	var battlefield_size := battlefield_tiles * tile_size
	var num_rows := troop_counts.values().count(func(c): return c > 0)

	var total_height := num_rows * spacing + (num_rows - 1) * spacing
	var start_y := (battlefield_size.y - total_height) / 2.0

	var index := 0
	for troop_name in troop_counts.keys():
		var count: int = troop_counts[troop_name]
		if count <= 0 or not troop_scenes.has(troop_name): continue

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
# 🪖 SPAWN ENEMIGO
# =====================================================================
func _spawn_enemy_troops() -> void:
	var troop_scenes := {
		"Archer":  preload("res://src/NPCs/Archer.tscn"),
		"Lancer":  preload("res://src/NPCs/Lancer.tscn"),
		"Monk":    preload("res://src/NPCs/Monk.tscn"),
		"Warrior": preload("res://src/NPCs/Warrior.tscn")
	}

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var index := 0
	for troop_name in troop_scenes.keys():
		var scene: PackedScene = troop_scenes[troop_name]
		var count: int = rng.randi_range(2, 9)
		enemy_counts[troop_name] = count

		var row_y := _row_y_for_index(index)

		for i in range(count):
			var troop: Node2D = scene.instantiate()
			troop.scale = Vector2(-troop_scale.x, troop_scale.y)
			troop.position = Vector2(battlefield_tiles.x * tile_size.x - 100 - i * spacing, row_y)
			tropas_node.add_child(troop)
			enemy_troops.append(troop)

		index += 1
	print("🟥 Tropas enemigas centradas")

# =====================================================================
# ⏱️ CUENTA ATRÁS INICIAL
# =====================================================================
func _start_battle_countdown() -> void:
	print("⏱️ Cuenta atrás iniciada...")

	var canvas := CanvasLayer.new()
	add_child(canvas)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment   = VERTICAL_ALIGNMENT_TOP
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
	# Modular: comprobar si la batalla puede continuar
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
# ⚡ MODULAR: Comprobar tropas y declarar ganador automático
# =====================================================================
func _check_forced_battle_result() -> bool:
	# Devuelve true si la batalla debe continuar, false si hay ganador automático
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
	_show_result_ui(result_text)

# =====================================================================
# 🎞️ TWEEN INDIVIDUAL
# =====================================================================
func _tween_troop(troop: Node2D, target_x: float) -> void:
	var sprite := _find_sprite(troop)
	if sprite and sprite.sprite_frames.has_animation("Run"):
		sprite.animation = "Run"
		sprite.play()

	var tween := create_tween()
	tween.tween_property(troop, "position:x", target_x, tween_duration) \
		.set_trans(Tween.TRANS_LINEAR) \
		.set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		if sprite and sprite.sprite_frames.has_animation("Idle"):
			sprite.animation = "Idle"
			sprite.play()
		tweens_completed += 1
		if tweens_completed >= total_tweens:
			_trigger_central_explosion()
	)

# =====================================================================
# 🔍 HELPER: AnimatedSprite2D anidado
# =====================================================================
func _find_sprite(node: Node) -> AnimatedSprite2D:
	for child in node.get_children():
		if child is AnimatedSprite2D: return child
		var nested := _find_sprite(child)
		if nested: return nested
	return null

# =====================================================================
# 💥 ATAQUE CENTRAL + HUMO
# =====================================================================
func _trigger_central_explosion() -> void:
	print("💥 Tropas llegan al centro. Ejecutando ataque simultáneo antes del humo.")
	await _play_all_attack_animations()
	print("💨 Animaciones de ataque completadas. Creando humo.")

	var center := Vector2(battlefield_tiles.x * tile_size.x / 2.0,
						  battlefield_tiles.y * tile_size.y / 2.0)

	if smoke_scene:
		var smoke := smoke_scene.instantiate() as Node2D
		smoke.position = center
		smoke.scale    = Vector2(5, 5)
		tropas_node.add_child(smoke)

	# Ocultar tropas
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
			sprite.animation = "Attack"
			sprite.play()
		animations.append(get_tree().create_timer(anim_length).timeout)
	for s in animations:
		await s

# =====================================================================
# 📊 CÁLCULO DE RESULTADO
# =====================================================================
func _show_battle_result() -> void:
	print("📊 Calculando resultado...")

	var weights := {
		"Archer": 2,
		"Lancer": 3,
		"Monk":   4,
		"Warrior":1
	}

	var player_power := 0
	for troop_name in game_state.get_all_troop_counts().keys():
		if weights.has(troop_name):
			player_power += game_state.get_all_troop_counts()[troop_name] * weights[troop_name]

	var enemy_power := 0
	for troop_name in enemy_counts.keys():
		if weights.has(troop_name):
			enemy_power += enemy_counts[troop_name] * weights[troop_name]

	var result_text := ""
	if   player_power > enemy_power: result_text = "🏆 ¡Gana el Jugador!"
	elif player_power < enemy_power: result_text = "💀 ¡Gana el Enemigo!"
	else:                            result_text = "⚖️ ¡Empate!"

	print("📣 Resultado → %s" % result_text)
	_show_result_ui(result_text)

# =====================================================================
# 🖥️ MOSTRAR RESULTADO EN PANTALLA
# =====================================================================
func _show_result_ui(result_text: String) -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)

	var label := Label.new()
	label.text = result_text
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(20, 20)
	canvas.add_child(label)

	await get_tree().create_timer(2.0).timeout

	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.size  = get_viewport_rect().size
	fade.z_index = 100
	canvas.add_child(fade)

	var fade_tween := create_tween()
	fade_tween.tween_property(fade, "color:a", 1.0, 2.0)
	await fade_tween.finished

	print("📂 Cargando escena principal...")
	get_tree().change_scene_to_file(main_scene_path)

# =====================================================================
# 🔧 HELPER: calcular Y de cada fila
# =====================================================================
func _row_y_for_index(index: int) -> float:
	var total_height := (enemy_counts.size() - 1) * spacing * 2.0
	var start_y := (battlefield_tiles.y * tile_size.y - total_height) / 2.0
	return start_y + index * spacing * 2.0
