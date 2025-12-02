extends Control

@onready var play_pvp_button: Button = $PVPButton
@onready var play_pve_button: Button = $PVEButton

func _ready() -> void:
	# Botones
	play_pvp_button.pressed.connect(_on_pvp_pressed)
	play_pve_button.pressed.connect(_on_pve_pressed)

	# Señales de GD-Sync
	GDSync.connected.connect(_on_connected)
	GDSync.connection_failed.connect(_on_connection_failed)
	
	print (multiplayer.is_server())
	print("GDSync autoload: ", GDSync)
	print("Tiene método start_multiplayer?: ", GDSync.has_method("start_multiplayer"))
	print("Tiene método manual_connect?: ", GDSync.has_method("_manual_connect"))
	print("is_active(): ", GDSync.is_active())


# ============================================================
# PVE DIRECTO
# ============================================================
func _on_pve_pressed() -> void:
	GameState.is_pve = true
	GameState.game_mode = "PVE"

	print("🎮 Modo %s seleccionado → partida local." % GameState.game_mode)
	print("🌍 Cargando mapa principal en modo PVE...")
	
	SceneManager.change_scene("res://src/main.tscn", {
			"pattern": "squares",
			"speed": 2.0,
			"wait_time": 0.3
	})

	# ============================================================
# PVP MATCHMAKING
# ============================================================
func _on_pvp_pressed() -> void:
	# Solo el servidor inicia la lógica de “host”
	if multiplayer.is_server() && !GDSync.is_active():
		GDSync._manual_connect("64.225.79.138")
		# Workaround obtenido de: https://www.gd-sync.com/docs/general-information
		# GDSync.start_multiplayer() # Esto no funciona en web.
	
	GameState.is_pve = false
	GameState.game_mode = "PVP"
	
	var username = "Jugador_" + str(randi() % 1000)
	print("PVP → intentando conectar...")

	# Esperar inicialización de GDSync
	while not GDSync.has_method("lobby_join"):
		await get_tree().create_timer(0.5).timeout

	# Esperar client ID
	while GDSync.get_client_id() <= 0:
		print("Esperando ID de cliente... ", GDSync.get_client_id())
		await get_tree().create_timer(0.2).timeout

	print("Conectado con ID: ", GDSync.get_client_id())
	GDSync.player_set_username(username)
	print("Nombre asignado: ", username)
	
	print("PVP → cambiando a PantallaCarga...")

	# Solo cambiamos de escena; PantallaCarga se encargará del matchmaking
	var pantalla_carga_scene: PackedScene = load("res://src/PantallaCarga/PantallaCarga.tscn")
	SceneManager.change_scene(pantalla_carga_scene, {
		"pattern": "squares",
		"speed": 2.0,
		"wait_time": 0.3
	})


# ============================================================
# SEÑALES GD-SYNC
# ============================================================
func _on_connected():
	print("GD-Sync conectado desde MainMenu.")


func _on_connection_failed(err):
	push_error("Error de conexión GD-Sync: %s" % str(err))
