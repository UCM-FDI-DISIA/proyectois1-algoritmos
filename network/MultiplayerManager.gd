extends Node

signal estado_matchmaking(msg: String)
signal lobby_unido(p: String, a: bool)
signal avisar_Player

var players: Array[int] = []             # IDs conectados
var quadrants_by_client: Dictionary = {} # client_id -> cuadrante
var my_quadrant_id: int = -1
var game_started: bool = false

var pantalla_carga_ref = null
const LOBBY_NAME := "Feudalia_MainLobby"
var num_Lobby := 1
var players_in_lobby := 0
const PVP_TIMEOUT := 30.0
var lobby_join_timeout_timer: Timer = Timer.new() # Para notificar si no recivo señal del servidor

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
	GDSync.expose_func(_on_partida_lista)
	
	# Para gestionar si no tienes conexión
	add_child(lobby_join_timeout_timer)
	lobby_join_timeout_timer.one_shot = true
	lobby_join_timeout_timer.timeout.connect(_on_lobby_join_timeout)



# ------------------------------------------------
# 🔹 Llamado desde PantallaCarga
# ------------------------------------------------
func iniciar_busqueda_partida(pantalla_carga):
	pantalla_carga_ref = pantalla_carga
	print(">>> Iniciando búsqueda de partida...")
	connect("estado_matchmaking", Callable(pantalla_carga, "_on_estado_matchmaking"))
	connect("lobby_unido", Callable(pantalla_carga, "_on_lobby_unido"))
	
	emit_signal("estado_matchmaking", "Conectando...")
	emit_signal("lobby_unido", "0", true)

	await get_tree().create_timer(0.5).timeout

	# Paso 1: Intentar unirse
	var current_lobby = LOBBY_NAME + str(num_Lobby)
	if !GDSync.is_active() :
		print(">>> GDSync no activo.")
		emit_signal("estado_matchmaking", "Oh oh... GDSync no se ha iniciado")
		emit_signal("lobby_unido", "Revisa tu conexión a internet", false)
	else :
		print("Intentando unirse al lobby: ", current_lobby)
		
		lobby_join_timeout_timer.start(3.0) 
		emit_signal("lobby_unido", str(num_Lobby), true)
		if !game_started : GDSync.lobby_join(current_lobby)



# ------------------------------------------------
# 🔹 Eventos de GD-Sync
# ------------------------------------------------
func _on_lobby_joined(lobby_name: String) -> void:
	lobby_join_timeout_timer.stop() 
	print("MultiplayerManager: entré al lobby: ", lobby_name)
	emit_signal("estado_matchmaking", "Conectado. Esperando jugadores...")
	emit_signal("lobby_unido", str(num_Lobby), true)
	
	var my_id
	if !GameState.is_pve :  my_id = GDSync.get_client_id()
	else : my_id = -1
	if my_id > 0 and my_id not in players:
		players.append(my_id)
	
	players_in_lobby = 1  # tú mismo
	print("Esperando segundo jugador durante %s segundos..." % PVP_TIMEOUT)
	
	await get_tree().create_timer(PVP_TIMEOUT).timeout
	
	if players_in_lobby < 2 && !game_started:
		print("⏳ Timeout sin segundo jugador → entrando en PVE automático")
		emit_signal("estado_matchmaking", "No se encontró otro jugador. Entrando en modo PVE")
		GameState.set_PVE()
		GDSync.lobby_leave() # Dejo vacío el lobby en el que estaba
		
		game_started = true
		SceneManager.change_scene("res://src/main.tscn", {
			"pattern": "squares",
			"speed": 2.0,
			"wait_time": 0.3
		})


func _on_client_joined(client_id: int) -> void:
	players_in_lobby += 1
	print("Cliente unido:", client_id)
	emit_signal("estado_matchmaking", "Jugador conectado: %s" % client_id)

	if client_id not in players:
		players.append(client_id)
	
	if GDSync.is_host():
		_check_start_condition()


func _on_client_left(client_id: int) -> void:
	players_in_lobby -= 1
	print("Cliente salió: ", client_id)
	
	# Gestión de caídas: si un jugador se cae, el otro sigue en PVE.
	GameState.set_PVE()
	GDSync.lobby_leave()
	
	emit_signal("avisar_Player")

func conectar_con_label_avisos(pantalla_main):
	connect("avisar_Player", Callable(pantalla_main, "_on_avisando_jugador"))

# ------------------------------------------------
# 🔹 Inicio de partida (solo host)
# ------------------------------------------------
func _check_start_condition() -> void:
	if not GDSync.is_host() or game_started:
		return

	print("Jugadores actuales en lobby: ", players)
	
	if players.size() >= 2:
		print("✅ Dos jugadores detectados. Asignando cuadrantes...")
		emit_signal("estado_matchmaking", "Dos jugadores detectados. Preparando partida...")

		_assign_quadrants()

		await get_tree().create_timer(1.0).timeout
		print("🌍 Ejecutando cambio de escena sincronizado...")
		emit_signal("estado_matchmaking", "Cargando mapa...")
		
		game_started = true
		
		SceneManager.change_scene("res://src/main.tscn", {
			"pattern": "squares",
			"speed": 2.0,
			"wait_time": 0.3
		})

		GDSync.call_func_on(players[1], _on_partida_lista, [])
	else:
		emit_signal("estado_matchmaking", "Esperando jugador adicional...")

# ------------------------------------------------
# 🔹 Inicio de partida (solo no-host)
# ------------------------------------------------
func _set_players_for_no_host(getplayers: Array[int]) -> void:
	if not GDSync.is_host() : 
		players = getplayers
		players_in_lobby = 2

func _on_partida_lista() -> void:
	if !game_started :
		SceneManager.change_scene("res://src/main.tscn", {
			"pattern": "squares",
			"speed": 2.0,
			"wait_time": 0.3
		})
	game_started = true

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

		if !GameState.is_pve : GDSync.player_set_data("quadrants_by_client", quadrants_by_client)

		print(" -> Jugador ", client_id, " tiene cuadrante ", q)
		emit_signal("estado_matchmaking", "Jugador %s asignado a cuadrante %s" % [client_id, q])

		GDSync.call_func_on(client_id, _receive_quadrant_assignment, [q, players])


# ------------------------------------------------
# 🔹 Recepción del cuadrante
# ------------------------------------------------
func _receive_quadrant_assignment(q_id: int, p: Array[int]) -> void:
	# IMPORTANTE: Doy esta información también al no-host
	my_quadrant_id = q_id
	players = p 
	players_in_lobby = 2
	
	print("Me asignaron el cuadrante: ", my_quadrant_id)
	emit_signal("estado_matchmaking", "Te asignaron el cuadrante %s" % q_id)

	if !GameState.is_pve : GDSync.player_set_data("quadrant_id", q_id)


# ------------------------------------------------
# 🔹 Utilidades
# ------------------------------------------------
func reset() -> void:
	players = []
	quadrants_by_client = {}
	my_quadrant_id = -1
	game_started = false
	
	lobby_join_timeout_timer.stop()
	lobby_join_timeout_timer = Timer.new()
	add_child(lobby_join_timeout_timer)
	lobby_join_timeout_timer.one_shot = true
	lobby_join_timeout_timer.timeout.connect(_on_lobby_join_timeout)



func get_my_quadrant() -> int:
	if (GameState.is_pve) : return 0
	else : return my_quadrant_id

func get_player_quadrant(client_id: int) -> int:
	return quadrants_by_client.get(client_id, -1)

func get_enemy_id(client_id: int) -> int:
	var enemy_id : int = players[0]
	if enemy_id == client_id:
		enemy_id = players[1]
	print(players, " mi enemigo es ", enemy_id)
	return enemy_id

func _on_lobby_join_failed(lobby_name: String, error: int) -> void:
	lobby_join_timeout_timer.stop()
	print("[MM] Falló lobby_join: ", lobby_name, " error:", error)
	emit_signal("estado_matchmaking", "Lobby no existe. Creándolo...")
	GDSync.lobby_create(lobby_name, "", true, 2)
	

func _on_lobby_created(lobby_name: String) -> void:
	print("[MM] Lobby creado: ", lobby_name)
	emit_signal("estado_matchmaking", "Lobby creado. Entrando...")
	emit_signal("lobby_unido", str(num_Lobby), true)
	
	lobby_join_timeout_timer.start(2.0)
	if !game_started : GDSync.lobby_join(lobby_name)

func _on_lobby_creation_failed(lobby_name: String, error: int) -> void:
	print("[MM] No se pudo crear el lobby: ", lobby_name, " error: ", error)
	emit_signal("estado_matchmaking", "Error creando lobby (%s). Reintentando..." % num_Lobby)
	num_Lobby += 1
	print("Intento unirme al lobby ", LOBBY_NAME + str(num_Lobby))
	emit_signal("lobby_unido", str(num_Lobby), true)
	
	lobby_join_timeout_timer.start(2.0)
	if !game_started : GDSync.lobby_join(LOBBY_NAME + str(num_Lobby))


func _on_lobby_join_timeout():
	if !game_started :
		lobby_join_timeout_timer.stop()
		# Esta función se llama si pasan 5 segundos sin respuesta
		print("TIMEOUT: No se recibió respuesta del servidor sobre el lobby.")
		
		# Muestra un mensaje de error claro sobre el posible problema de red
		emit_signal("estado_matchmaking", "Oh oh... No puede funcionar el PVP")
		emit_signal("lobby_unido", "Revisa la configuración de tu conexión a internet", false)
		
		await get_tree().create_timer(5).timeout
		emit_signal("estado_matchmaking", "Iniciando PVE...")
		emit_signal("lobby_unido", "Revisa la configuración de tu conexión a internet", false)
		await get_tree().create_timer(4).timeout
		GameState.set_PVE()
		
		game_started = true
		
		SceneManager.change_scene("res://src/main.tscn", {
			"pattern": "squares",
			"speed": 2.0,
			"wait_time": 0.3
		})
