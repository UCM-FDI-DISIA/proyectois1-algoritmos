extends Control

@onready var play_pvp_button: Button = $PVPButton
@onready var play_pve_button: Button = $PVEButton

const LOBBY_NAME := "Feudalia_MainLobby"
const PVP_TIMEOUT := 30.0

var game_mode := ""
var wait_timer: SceneTreeTimer
var players_in_lobby := 0


func _ready():
	# Botones
	play_pvp_button.pressed.connect(_on_pvp_pressed)
	play_pve_button.pressed.connect(_on_pve_pressed)

	# Señales de GD-Sync
	GDSync.connected.connect(_on_connected)
	GDSync.connection_failed.connect(_on_connection_failed)
	GDSync.lobby_joined.connect(_on_lobby_joined)
	GDSync.lobby_join_failed.connect(_on_lobby_join_failed)
	GDSync.lobby_created.connect(_on_lobby_created)
	GDSync.lobby_creation_failed.connect(_on_lobby_creation_failed)

	# Señales para detectar jugadores
	GDSync.client_joined.connect(_on_client_joined)
	GDSync.client_left.connect(_on_client_left)
	



# ============================================================
# PVE DIRECTO
# ============================================================

func _on_pve_pressed():
	MultiplayerManager.players = [1]
	MultiplayerManager.my_quadrant_id = 0
	MultiplayerManager.quadrants_by_client = {1: 0}

	GameState.game_mode = "PVE"
	print("🎮 Modo PVE seleccionado")

	# Configuración local del estado del jugador (limpiar tropas)
	GameState.troop_counts = {
		"Archer": GameState.get_troop_count("Archer"),
		"Lancer": GameState.get_troop_count("Lancer"),
		"Monk": GameState.get_troop_count("Monk"),
		"Warrior": GameState.get_troop_count("Warrior")
	}

	print("🌍 Cargando mapa principal en modo PVE...")
	get_tree().change_scene_to_file("res://src/main.tscn")



# ============================================================
# PVP MATCHMAKING
# ============================================================

func _on_pvp_pressed():
	game_mode = "PVP"

	var username = "Jugador_" + str(randi() % 1000)
	print("PVP → intentando conectar...")

	# Esperar inicialización
	await GDSync.connected

	# Esperar client ID
	while GDSync.get_client_id() <= 0:
		print("Esperando ID de cliente...")
		await get_tree().create_timer(0.2).timeout
	
	print("Conectado con ID: ", GDSync.get_client_id())
	GDSync.player_set_username(username)
	print("Nombre asignado: ", username)

	print("Intentando unirse al lobby: ", LOBBY_NAME)
	GDSync.lobby_join(LOBBY_NAME, "")



# ============================================================
# SEÑALES GD-SYNC
# ============================================================

func _on_connected():
	print("GD-Sync conectado desde MainMenu.")


func _on_connection_failed(err):
	push_error("Error de conexión GD-Sync: %s" % str(err))


func _on_lobby_creation_failed(lobby_name: String, error: int):
	push_error("Error creando lobby", lobby_name, ": %s" % str(error))

func _on_lobby_created(lobby_name: String):
	print("Lobby creado: ", lobby_name)
	GDSync.lobby_join(lobby_name, "")

func _on_lobby_join_failed(lobby_name: String, error: int):
	print("No se pudo unir al lobby, lo creamos:", lobby_name, ' ', error)
	GDSync.lobby_create(lobby_name, "", true, 2, {}) # máx 2 jugadores



# ============================================================
# LOBBY JOINED → iniciar espera del otro jugador
# ============================================================

func _on_lobby_joined(lobby_name: String):
	print("Unido al lobby:", lobby_name)

	# Tú mismo ya cuentas como 1 jugador
	players_in_lobby = 1

	print("Esperando segundo jugador durante %s segundos..." % PVP_TIMEOUT)

	wait_timer = get_tree().create_timer(PVP_TIMEOUT)
	await wait_timer.timeout

	# Si NO llegó nadie → PVE automático
	if players_in_lobby < 2:
		print("Timeout → entrando en PVE automático")
		# La inicialización del juego la llevo desde otro fichero.



# ============================================================
# DETECCIÓN DE JUGADORES
# ============================================================

func _on_client_joined(client_id: int):
	players_in_lobby += 1
	print("Jugador conectado:", client_id, " → total:", players_in_lobby)

	# Al entrar el segundo → iniciar PVP
	if game_mode == "PVP" and players_in_lobby >= 2:
		print("¡Segundo jugador encontrado! Iniciando PVP…")
		# La inicialización del main se lleva desde otro fichero.



func _on_client_left(client_id: int):
	players_in_lobby -= 1
	print("Jugador salió:", client_id, " → total:", players_in_lobby)


# ============================================================
# CAMBIO A LA ESCENA DEL JUEGO REAL
# ============================================================

func _load_main_game_scene():
	print("Cargando escena principal del juego...")

	# CAMBIA SOLO ESTA RUTA:
	get_tree().call_deferred("change_scene_to_file", "res://scenes/Game.tscn")
