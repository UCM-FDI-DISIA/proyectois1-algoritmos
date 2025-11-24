extends Control

@onready var play_pvp_button: Button = $PVPButton
@onready var play_pve_button: Button = $PVEButton

const LOBBY_NAME := "Feudalia_MainLobby"
const PVP_TIMEOUT := 30.0

var game_mode := ""
var wait_timer: SceneTreeTimer
var players_in_lobby := 0


func _ready() -> void:
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

	# Solo el servidor inicia la lógica de “host”
	if multiplayer.is_server():
		GDSync.start_multiplayer()


# ============================================================
# PVE DIRECTO
# ============================================================
func _on_pve_pressed() -> void:
	game_mode = "PVE"
	GameState.is_pve = true
	GameState.game_mode = "PVE"

	print("🎮 Modo PVE seleccionado → partida local.")
	print("🌍 Cargando mapa principal en modo PVE...")
	get_tree().change_scene_to_file("res://src/main.tscn")


# ============================================================
# PVP MATCHMAKING
# ============================================================
func _on_pvp_pressed() -> void:
	game_mode = "PVP"
	GameState.is_pve = false
	GameState.game_mode = "PVP"

	var username = "Jugador_" + str(randi() % 1000)
	print("PVP → intentando conectar...")

	# Esperar inicialización de GDSync
	while not GDSync.has_method("lobby_join"):
		await get_tree().create_timer(0.5).timeout

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
	push_error("Error creando lobby %s: %s" % [lobby_name, str(error)])


func _on_lobby_created(lobby_name: String):
	print("Lobby creado: ", lobby_name)
	GDSync.lobby_join(lobby_name, "")


func _on_lobby_join_failed(lobby_name: String, error: int):
	print("No se pudo unir al lobby, lo creamos:", lobby_name, " error:", error)
	GDSync.lobby_create(lobby_name, "", true, 2, {}) # máx 2 jugadores


# ============================================================
# LOBBY JOINED → esperar al segundo jugador o pasar a PVE
# ============================================================
func _on_lobby_joined(lobby_name: String):
	print("Unido al lobby:", lobby_name)

	players_in_lobby = 1  # tú mismo
	print("Esperando segundo jugador durante %s segundos..." % PVP_TIMEOUT)

	wait_timer = get_tree().create_timer(PVP_TIMEOUT)
	await wait_timer.timeout

	# Si mientras tanto hemos cambiado de modo, no hacemos nada
	if game_mode != "PVP":
		return

	# Si NO llegó nadie → PVE automático
	if players_in_lobby < 2:
		print("⏳ Timeout sin segundo jugador → entrando en PVE automático")
		GameState.is_pve = true
		GameState.game_mode = "PVE"
		get_tree().change_scene_to_file("res://src/main.tscn")
		# En caso contrario, el host ya habrá lanzado la partida desde MultiplayerManager


# ============================================================
# DETECCIÓN DE JUGADORES
# ============================================================
func _on_client_joined(client_id: int):
	players_in_lobby += 1
	print("Jugador conectado:", client_id, " → total:", players_in_lobby)
	# El host lanzará la partida cuando haya 2 desde MultiplayerManager._check_start_condition()


func _on_client_left(client_id: int):
	players_in_lobby -= 1
	print("Jugador salió:", client_id, " → total:", players_in_lobby)
