extends Node

signal estado_matchmaking(msg: String)
signal partida_lista

var players: Array[int] = []             # IDs conectados
var quadrants_by_client: Dictionary = {} # client_id -> cuadrante
var my_quadrant_id: int = -1
var game_started: bool = false

var pantalla_carga_ref = null


func _ready() -> void:
	print("✅ MultiplayerManager iniciado.")

	GDSync.client_joined.connect(_on_client_joined)
	GDSync.client_left.connect(_on_client_left)
	GDSync.lobby_joined.connect(_on_lobby_joined)

	GDSync.expose_func(_receive_quadrant_assignment)


# ------------------------------------------------
# 🔹 Llamado desde PantallaCarga
# ------------------------------------------------
func iniciar_busqueda_partida(pantalla_carga):
	pantalla_carga_ref = pantalla_carga
	connect("estado_matchmaking", Callable(pantalla_carga, "_on_estado_matchmaking"))

	emit_signal("estado_matchmaking", "Conectando con servidor...")

	await get_tree().create_timer(0.5).timeout
	GDSync.lobby_join("FeudaliaLobby") # Si ya lo haces en otro sitio, quítalo


# ------------------------------------------------
# 🔹 Eventos de GD-Sync
# ------------------------------------------------
func _on_lobby_joined(lobby_name: String) -> void:
	print("MultiplayerManager: entré al lobby:", lobby_name)
	emit_signal("estado_matchmaking", "Conectado. Esperando jugadores...")

	var my_id := GDSync.get_client_id()
	if my_id > 0 and my_id not in players:
		players.append(my_id)

	if GDSync.is_host():
		_check_start_condition()


func _on_client_joined(client_id: int) -> void:
	print("Cliente unido:", client_id)
	emit_signal("estado_matchmaking", "Jugador conectado: %s" % client_id)

	if client_id not in players:
		players.append(client_id)

	if GDSync.is_host():
		_check_start_condition()


func _on_client_left(client_id: int) -> void:
	print("Cliente salió:", client_id)
	emit_signal("estado_matchmaking", "Un jugador abandonó la sala. Volviendo a menú...")

	GameState.set_PVE()
	GDSync.lobby_leave()


# ------------------------------------------------
# 🔹 Inicio de partida (solo host)
# ------------------------------------------------
func _check_start_condition() -> void:
	if not GDSync.is_host() or game_started:
		return

	print("Jugadores actuales en lobby:", players)

	if players.size() >= 2:
		print("✅ Dos jugadores detectados. Asignando cuadrantes...")
		emit_signal("estado_matchmaking", "Dos jugadores detectados. Preparando partida...")

		_assign_quadrants()

		game_started = true

		await get_tree().create_timer(1.0).timeout
		print("🌍 Ejecutando cambio de escena sincronizado...")
		emit_signal("estado_matchmaking", "Cargando mapa...")

		GDSync.change_scene("res://src/main.tscn")

		emit_signal("partida_lista")
	else:
		emit_signal("estado_matchmaking", "Esperando jugador adicional...")


# ------------------------------------------------
# 🔹 Asignar cuadrantes
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

		GDSync.player_set_data("quadrants_by_client", quadrants_by_client)

		print(" -> Jugador ", client_id, " tiene cuadrante ", q)
		emit_signal("estado_matchmaking", "Jugador %s asignado a cuadrante %s" % [client_id, q])

		GDSync.call_func_on(client_id, _receive_quadrant_assignment, [q])


# ------------------------------------------------
# 🔹 Recepción del cuadrante
# ------------------------------------------------
func _receive_quadrant_assignment(q_id: int) -> void:
	my_quadrant_id = q_id
	print("Me asignaron el cuadrante:", my_quadrant_id)
	emit_signal("estado_matchmaking", "Te asignaron el cuadrante %s" % q_id)

	GDSync.player_set_data("quadrant_id", q_id)


# ------------------------------------------------
# 🔹 Utilidades
# ------------------------------------------------
func reset() -> void:
	players = []
	quadrants_by_client = {}
	my_quadrant_id = -1
	game_started = false

func get_my_quadrant() -> int:
	return my_quadrant_id

func get_player_quadrant(client_id: int) -> int:
	return quadrants_by_client.get(client_id, -1)

func get_enemy_id(client_id: int) -> int:
	var enemy_id : int = players[0]
	if enemy_id == client_id:
		enemy_id = players[1]
	print(players, " mi enemigo es ", enemy_id)
	return enemy_id
