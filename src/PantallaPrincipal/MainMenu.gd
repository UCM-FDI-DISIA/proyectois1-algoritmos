extends Control

@onready var play_pvp_button: Button = $PVPButton
@onready var play_pve_button: Button = $PVEButton

const LOBBY_NAME := "Feudalia_MainLobby"
var num_Lobby := 1
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


	# Solo el servidor inicia la lógica de “host”
	if multiplayer.is_server() && !GDSync.is_active():
		GDSync._manual_connect("137.184.191.148")
		# Workaround obtenido de: https://www.gd-sync.com/docs/general-information
		# GDSync.start_multiplayer() # Esto no funciona en web.


# ============================================================
# PVE DIRECTO
# ============================================================
func _on_pve_pressed() -> void:
	game_mode = "PVE"
	GameState.is_pve = true
	GameState.game_mode = "PVE"

	print("🎮 Modo PVE seleccionado → partida local.")
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
	GameState.is_pve = false
	GameState.game_mode = "PVP"

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
