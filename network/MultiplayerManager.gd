extends Node

var players: Array[int] = []            # IDs conectados
var quadrants_by_client: Dictionary = {} # client_id -> cuadrante
var my_quadrant_id: int = -1
var game_started: bool = false


func _ready() -> void:
	print("✅ MultiplayerManager iniciado.")

	GDSync.client_joined.connect(_on_client_joined)
	GDSync.client_left.connect(_on_client_left)
	GDSync.lobby_joined.connect(_on_lobby_joined)

	GDSync.expose_func(_receive_quadrant_assignment)


# ------------------------------------------------
# 🔹 Eventos de GD-Sync
# ------------------------------------------------
func _on_lobby_joined(lobby_name: String) -> void:
	print("MultiplayerManager: entré al lobby:", lobby_name)
	var my_id := GDSync.get_client_id()
	if my_id > 0 and my_id not in players:
		players.append(my_id)

	if GDSync.is_host():
		_check_start_condition()


func _on_client_joined(client_id: int) -> void:
	print("Cliente unido:", client_id)
	if client_id not in players:
		players.append(client_id)

	if GDSync.is_host():
		_check_start_condition()


func _on_client_left(client_id: int) -> void:
	print("Cliente salió:", client_id)
	players.erase(client_id)
	quadrants_by_client.erase(client_id)


# ------------------------------------------------
# 🔹 Inicio de partida (solo el host)
# ------------------------------------------------
func _check_start_condition() -> void:
	if not GDSync.is_host() or game_started:
		return

	print("Jugadores actuales en lobby:", players)

	if players.size() >= 2:
		print("✅ Dos jugadores detectados. Asignando cuadrantes y arrancando partida...")
		_assign_quadrants()
		game_started = true

		await get_tree().create_timer(1.0).timeout
		print("🌍 Ejecutando cambio de escena sincronizado...")
		GDSync.change_scene("res://src/main.tscn")  # ✅ ruta correcta
	else:
		print("Esperando más jugadores antes de iniciar...")


# ------------------------------------------------
# 🔹 Asignación de cuadrantes
# ------------------------------------------------
func _assign_quadrants() -> void:
	if not GDSync.is_host():
		return

	players.sort()
	var available_quadrants = [0, 1]

	for i in range(min(players.size(), available_quadrants.size())):
		var client_id: int = players[i]
		var q: int = available_quadrants[i]
		quadrants_by_client[client_id] = q
		print(" -> Jugador", client_id, "tiene cuadrante", q)
		GDSync.call_func_on(client_id, _receive_quadrant_assignment, [q])


# ------------------------------------------------
# 🔹 Recepción del cuadrante en cada cliente
# ------------------------------------------------
func _receive_quadrant_assignment(q_id: int) -> void:
	my_quadrant_id = q_id
	print("Me asignaron el cuadrante:", my_quadrant_id)
	GDSync.player_set_data("quadrant_id", q_id)


# ------------------------------------------------
# 🔹 Utilidades
# ------------------------------------------------
func get_my_quadrant() -> int:
	return my_quadrant_id

func get_player_quadrant(client_id: int) -> int:
	return quadrants_by_client.get(client_id, -1)
