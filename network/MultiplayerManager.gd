extends Node

signal estado_matchmaking(msg: String)
signal partida_lista

var players: Array[int] = []             # IDs conectados
var quadrants_by_client: Dictionary = {} # client_id -> cuadrante
var my_quadrant_id: int = -1
var game_started: bool = false

var pantalla_carga_ref = null
const LOBBY_NAME := "Feudalia_MainLobby"
var num_Lobby := 1
var players_in_lobby := 0
const PVP_TIMEOUT := 30.0
var wait_timer: SceneTreeTimer

func _ready():
	print("✅ MultiplayerManager iniciado.")

	# Reconectar siempre las señales
	GDSync.client_joined.connect(_on_client_joined)
	GDSync.client_left.connect(_on_client_left)
	GDSync.lobby_joined.connect(_on_lobby_joined)

	GDSync.lobby_join_failed.connect(_on_lobby_join_failed)
	GDSync.lobby_created.connect(_on_lobby_created)
	GDSync.lobby_creation_failed.connect(_on_lobby_creation_failed)

	GDSync.expose_func(_receive_quadrant_assignment)



# ------------------------------------------------
# 🔹 Llamado desde PantallaCarga
# ------------------------------------------------
func iniciar_busqueda_partida(pantalla_carga):
	pantalla_carga_ref = pantalla_carga
	connect("estado_matchmaking", Callable(pantalla_carga, "_on_estado_matchmaking"))

	emit_signal("estado_matchmaking", "Conectando...")

	await get_tree().create_timer(0.5).timeout

	# Paso 1: Intentar unirse
	var current_lobby = LOBBY_NAME + str(num_Lobby)
	emit_signal("estado_matchmaking", "Uniéndose al lobby " + current_lobby)
	print("Intentando unirse al lobby: ", current_lobby)
	GDSync.lobby_join(current_lobby, "")



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
	
	players_in_lobby = 1  # tú mismo
	print("Esperando segundo jugador durante %s segundos..." % PVP_TIMEOUT)

	wait_timer = get_tree().create_timer(PVP_TIMEOUT)
	await wait_timer.timeout

	# Si mientras tanto hemos cambiado de modo, no hacemos nada
	if GameState.game_mode == "PVP":
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
		
		print("⏳ Timeout sin segundo jugador → entrando en PVE automático")
		GameState.is_pve = true
		GameState.game_mode = "PVE"
		GDSync.lobby_leave() # Dejo vacío el lobby en el que estaba
		SceneManager.change_scene("res://src/main.tscn", {
			"pattern": "squares",
			"speed": 2.0,
			"wait_time": 0.3
		})
		get_tree().change_scene_to_file("res://src/main.tscn")

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

func _on_lobby_join_failed(lobby_name: String, error: int) -> void:
	print("[MM] Falló lobby_join:", lobby_name, " error:", error)
	emit_signal("estado_matchmaking", "Lobby no existe. Creándolo...")
	GDSync.lobby_create(lobby_name, "", true, 2)
	

func _on_lobby_created(lobby_name: String) -> void:
	print("[MM] Lobby creado:", lobby_name)
	emit_signal("estado_matchmaking", "Lobby creado. Entrando...")
	GDSync.lobby_join(lobby_name)

func _on_lobby_creation_failed(lobby_name: String, error: int) -> void:
	print("[MM] No se pudo crear el lobby:", lobby_name, " error: ", error)
	emit_signal("estado_matchmaking", "Error creando lobby (%s). Reintentando..." % error)
	num_Lobby += 1
	print("Intento unirme al lobby ", LOBBY_NAME + str(num_Lobby))
	GDSync.lobby_join(LOBBY_NAME + str(num_Lobby))
	
