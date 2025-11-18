extends Control

@onready var play_button: Button = $PVPButton

const LOBBY_NAME := "Feudalia_MainLobby"

func _ready():
	play_button.pressed.connect(_on_play_pressed)

	# Señales informativas
	GDSync.connected.connect(_on_connected)
	GDSync.connection_failed.connect(_on_connection_failed)
	GDSync.lobby_joined.connect(_on_lobby_joined)
	GDSync.lobby_join_failed.connect(_on_lobby_join_failed)
	GDSync.lobby_created.connect(_on_lobby_created)
	GDSync.lobby_creation_failed.connect(_on_lobby_creation_failed)

	# Arrancamos GD-Sync
	GDSync.start_multiplayer()


func _on_play_pressed():
	var username = "Jugador_" + str(randi() % 1000)
	print("PLAY pulsado. Intentando conectar...")

	# Esperar a que GD-Sync esté inicializado
	while not GDSync.has_method("lobby_join"):
		print("Esperando inicialización de GD-Sync...")
		await get_tree().create_timer(0.5).timeout

	# Esperar a tener ID válido
	while GDSync.get_client_id() <= 0:
		print("Esperando ID de cliente...")
		await get_tree().create_timer(0.2).timeout

	print("Conectado con ID:", GDSync.get_client_id())
	GDSync.player_set_username(username)
	print("Nombre asignado:", username)

	print("Intentando unirse al lobby:", LOBBY_NAME)
	GDSync.lobby_join(LOBBY_NAME, "")


func _on_connected():
	print("GD-Sync conectado desde MainMenu.")

func _on_connection_failed(err):
	push_error("Error de conexión GD-Sync: %s" % str(err))

func _on_lobby_join_failed(lobby_name: String, error: int):
	print("No se pudo unir al lobby, lo creamos:", lobby_name)
	GDSync.lobby_create(lobby_name, "", true, 2, {}) # máx 2 jugadores

func _on_lobby_created(lobby_name: String):
	print("Lobby creado:", lobby_name)
	GDSync.lobby_join(lobby_name, "")

func _on_lobby_creation_failed(lobby_name: String, error: int):
	push_error("Error creando lobby: %s" % str(error))

func _on_lobby_joined(lobby_name: String):
	print("Unido al lobby:", lobby_name)
	print("Esperando instrucciones del host o cambio de escena sincronizado...")
