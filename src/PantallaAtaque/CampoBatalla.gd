extends Node2D

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var spacing: float = 96.0
@export var troop_scale: Vector2 = Vector2(3.0, 3.0)
@export var smoke_scene: PackedScene
@export var main_scene_path: String = "res://src/UI/main.tscn" # Ruta para volver al menú
@export var results_scene_path: String = "res://src/PantallaResultadosBatalla/PantallaResultados.tscn"
@export var tween_duration: float = 3.0

# =====================================================================
# 🧾 NODOS
# =====================================================================
@onready var tropas_node: Node2D = $Objetos/Tropas
@onready var game_state: Node = get_node("/root/GameState") # Acceso directo al Autoload

# =====================================================================
# 📊 ESTADO DE LA BATALLA
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
		push_error("❌ ERROR: El Autoload 'GameState' no se encontró. Revisa la configuración del proyecto.")
		return

	# 1. Spawn del jugador
	_spawn_player_troops()

	# 2. Determinar y Spawn del enemigo
	var enemy_troops_data: Dictionary = _get_enemy_troop_data()
	_spawn_enemy_troops(enemy_troops_data)

	# 3. La UI del resultado ya NO se configura aquí.

	# 4. Iniciar la batalla después del delay
	call_deferred("_start_battle_countdown")


# =====================================================================
# 👤 AUXILIAR: Obtener Datos del Enemigo (PVE/PVP)
# =====================================================================
func _get_enemy_troop_data() -> Dictionary:
	var default_troops := { "Archer": 0, "Lancer": 0, "Monk": 0, "Warrior": 0 }
	
	# Se asume que GameState, GDSync y MultiplayerManager existen como Autoloads.
	if GameState.is_pve:
		print("Modo PVE → generando tropas de IA local.")
		return _generate_ai_troops()
	else:
		print("Modo PVP → leyendo tropas del enemigo real.")
		var my_id: int = GDSync.get_client_id()
		var enemy_id: int = MultiplayerManager.get_enemy_id(my_id)
		
		var enemy_data = GDSync.player_get_data(enemy_id, "troops_by_client", default_troops)
		enemy_counts = enemy_data
		return enemy_data


# =====================================================================
# 🪖 SPAWN TROPAS JUGADOR
# =====================================================================
func _spawn_player_troops() -> void:
	var troop_counts: Dictionary = game_state.get_all_troop_counts()
	
	var is_red_color := MultiplayerManager.get_my_quadrant() == 1
	print("Mi cuadrante es ", MultiplayerManager.get_my_quadrant(), " - Color rojo: ", is_red_color)
	
	var troop_scenes: Dictionary = _load_troop_scenes(is_red_color)

	var battlefield_size := battlefield_tiles * tile_size
	var num_rows := 0
	for c in troop_counts.values():
		if c > 0:
			num_rows += 1

	var total_row_height := num_rows * spacing * 2.0
	var start_y := (battlefield_size.y - total_row_height) / 2.0

	var index := 0
	for troop_name in troop_counts.keys():
		var count: int = troop_counts.get(troop_name, 0)
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
	print("Tropas del jugador spawnadas y listas.")


# =====================================================================
# 🪖 SPAWN TROPAS ENEMIGO
# =====================================================================
func _spawn_enemy_troops(enemy_data: Dictionary) -> void:
	enemy_counts = enemy_data
	
	var is_red_color := MultiplayerManager.get_my_quadrant() != 1
	print("El enemigo tiene color rojo: ", is_red_color)
	
	var troop_scenes: Dictionary = _load_troop_scenes(is_red_color)

	var index := 0
	for troop_name in troop_scenes.keys():
		var count: int = enemy_counts.get(troop_name, 0)
		if count <= 0 or not troop_scenes.has(troop_name):
			continue

		var scene: PackedScene = troop_scenes[troop_name]
		var row_y := _row_y_for_index(index)

		for i in range(count):
			var troop: Node2D = scene.instantiate()
			troop.scale = Vector2(-troop_scale.x, troop_scale.y)
			troop.position = Vector2(battlefield_tiles.x * tile_size.x - 100 - i * spacing, row_y)
			tropas_node.add_child(troop)
			enemy_troops.append(troop)

		index += 1
	print("Tropas enemigas spawnadas y listas.")


# =====================================================================
# 🎨 AUXILIAR: Carga de Escenas de Tropas por Color (Usando load)
# =====================================================================
func _load_troop_scenes(is_red: bool) -> Dictionary:
	var color_suffix := "_red" if is_red else ""
	return {
		"Archer": load("res://src/NPCs/TropasCampoBatalla/Archer" + color_suffix + ".tscn"),
		"Lancer": load("res://src/NPCs/TropasCampoBatalla/Lancer" + color_suffix + ".tscn"),
		"Monk": load("res://src/NPCs/TropasCampoBatalla/Monk" + color_suffix + ".tscn"),
		"Warrior": load("res://src/NPCs/TropasCampoBatalla/Warrior" + color_suffix + ".tscn")
	}


# =====================================================================
# 🤖 AUXILIAR: Generar tropas AI PVE
# =====================================================================
func _generate_ai_troops() -> Dictionary:
	var troops := {
		"Archer": randi_range(1, 5),
		"Lancer": randi_range(1, 5),
		"Monk": randi_range(1, 5),
		"Warrior": randi_range(1, 5)
	}
	return troops


# =====================================================================
# ⏱️ CUENTA ATRÁS (Visual)
# =====================================================================
func _start_battle_countdown() -> void:
	print("Cuenta atrás visual iniciada...")

	var canvas := CanvasLayer.new()
	add_child(canvas)

	var label := Label.new()
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(20, 20)
	canvas.add_child(label)

	for i in range(3, 0, -1):
		label.text = str(i)
		await get_tree().create_timer(1.0).timeout

	label.text = "¡BATALLA!"
	await get_tree().create_timer(1.0).timeout
	label.queue_free()
	canvas.queue_free()

	_start_battle()


# =====================================================================
# 🏃 MOVIMIENTO AL CENTRO
# =====================================================================
func _start_battle() -> void:
	if not _check_forced_battle_result():
		return

	var center_x := (battlefield_tiles.x * tile_size.x) / 2.0
	var attack_margin := 120.0

	total_tweens = player_troops.size() + enemy_troops.size()
	tweens_completed = 0

	for troop in player_troops:
		_tween_troop(troop, center_x - attack_margin)

	for troop in enemy_troops:
		_tween_troop(troop, center_x + attack_margin)


# =====================================================================
# ⚡ VERIFICACIÓN DE VICTORIA/DERROTA FORZADA
# =====================================================================
func _check_forced_battle_result() -> bool:
	if player_troops.is_empty() and enemy_troops.is_empty():
		_save_results_and_transition("¡Empate!")
		return false
	elif player_troops.is_empty():
		_save_results_and_transition("¡Gana el Enemigo!")
		return false
	elif enemy_troops.is_empty():
		_save_results_and_transition("¡Gana el Jugador!")
		return false
	
	return true


# =====================================================================
# 🎞️ TWEEN INDIVIDUAL (Movimiento)
# =====================================================================
func _tween_troop(troop: Node2D, target_x: float) -> void:
	var sprite := _find_sprite(troop)
	if sprite and sprite.sprite_frames.has_animation("Run"):
		sprite.play("Run")

	var tween := create_tween()
	tween.tween_property(troop, "position:x", target_x, tween_duration)

	tween.finished.connect(func():
		if sprite and sprite.sprite_frames.has_animation("Idle"):
			sprite.play("Idle")

		tweens_completed += 1
		if tweens_completed >= total_tweens:
			_trigger_central_explosion()
	)


# =====================================================================
# 💥 ATAQUE Y HUMO
# =====================================================================
func _trigger_central_explosion() -> void:
	# 1. Ejecutar animaciones de ataque
	await _play_all_attack_animations()

	# 2. Añadir efecto de humo/explosión
	var center := Vector2(
		battlefield_tiles.x * tile_size.x / 2.0,
		battlefield_tiles.y * tile_size.y / 2.0
	)

	if smoke_scene:
		var smoke := smoke_scene.instantiate()
		smoke.position = center
		smoke.scale = Vector2(5, 5)
		tropas_node.add_child(smoke)

	# 3. Ocultar tropas
	for t in player_troops + enemy_troops:
		t.visible = false

	# 4. Esperar y mostrar resultado
	await get_tree().create_timer(2.0).timeout
	_show_battle_result()


# =====================================================================
# 📊 RESULTADO FINAL (Basado en Poder)
# =====================================================================
func _show_battle_result() -> void:
	var p_power := _calculate_power(game_state.get_all_troop_counts())
	var e_power := _calculate_power(enemy_counts)

	var result_text := ""
	if p_power > e_power:
		result_text = "¡Gana el Jugador!" 
	elif p_power < e_power:
		result_text = "¡Gana el Enemigo!"
	else:
		result_text = "¡Empate!"

	_save_results_and_transition(result_text)


# =====================================================================
# ➡️ GUARDAR Y TRANSICIONAR A PANTALLA DE RESULTADOS
# =====================================================================
func _save_results_and_transition(result_text: String) -> void:
	if game_state == null:
		push_error("GameState not found.")
		return

	# 1. Obtener datos finales
	var player_troop_data = game_state.get_all_troop_counts()
	var enemy_troop_data = enemy_counts
	var p_power = _calculate_power(player_troop_data)
	var e_power = _calculate_power(enemy_troop_data)
	
	# 2. Guardar los resultados en GameState
	if not game_state.has_method("set_battle_results"):
		push_error("GameState debe tener un método 'set_battle_results'.")
		return
		
	game_state.set_battle_results({
		"result_text": result_text,
		"player_troops_data": player_troop_data,
		"enemy_troops_data": enemy_troop_data,
		"player_power": p_power,
		"enemy_power": e_power
	})

	# 3. Limpiar la escena actual (opcional)
	for t in player_troops + enemy_troops:
		if is_instance_valid(t):
			t.queue_free()

	# 4. Cambiar de escena de forma diferida (¡CORRECCIÓN CLAVE!)
	if results_scene_path != "":
		print("Batalla terminada. Cambiando a escena de resultados.")
		# El uso de call_deferred() asegura que el cambio de escena
		# se ejecute después de que se completen todas las operaciones
		# pendientes del frame actual, como la destrucción de nodos.
		get_tree().call_deferred("change_scene_to_file", results_scene_path)
	else:
		push_error("❌ results_scene_path no está configurado.")


# =====================================================================
# 🧮 AUXILIAR: Cálculo de Poder Total
# =====================================================================
func _calculate_power(troop_dict: Dictionary) -> int:
	var weights = { "Archer": 2, "Lancer": 3, "Monk": 4, "Warrior": 1 }
	var total := 0
	for t in troop_dict.keys():
		if weights.has(t):
			total += troop_dict.get(t, 0) * weights[t]
	return total


# =====================================================================
# 🔧 AUXILIARES RESTANTES
# =====================================================================
func _row_y_for_index(index: int) -> float:
	var num_enemy_types := enemy_counts.keys().size()
	if num_enemy_types == 0: return 0.0
	
	var total_height := (num_enemy_types - 1) * spacing * 2.0
	var battlefield_height := battlefield_tiles.y * tile_size.y
	
	var start_y := (battlefield_height - total_height) / 2.0
	
	return start_y + index * spacing * 2.0

func _find_sprite(node: Node) -> AnimatedSprite2D:
	for child in node.get_children():
		if child is AnimatedSprite2D:
			return child
		var nested := _find_sprite(child)
		if nested:
			return nested
	return null

func _play_all_attack_animations() -> void:
	var anim_length := 1.1
	var waits := []

	for troop in player_troops + enemy_troops:
		var sprite := _find_sprite(troop)
		if sprite and sprite.sprite_frames.has_animation("Attack"):
			sprite.play("Attack")

		waits.append(get_tree().create_timer(anim_length).timeout)

	for w in waits:
		await w
