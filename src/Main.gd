extends Node

# =====================================================================
# 🧱 NODOS DE ESCENA
# =====================================================================
@onready var casas_parent := $"Objetos/Casas"
@onready var player: Node2D = $"Objetos/Player"

# =====================================================================
# 🎯 SPAWN DE JUGADOR
# =====================================================================
var quadrant_spawn_positions := {
	0: Vector2(350, 400),
	1: Vector2(7500, 400),
}

# =====================================================================
# 🎵 MÚSICA DE FONDO
# =====================================================================
@onready var music_tracks: Array[AudioStream] = [
	preload("res://sfx/background1.mp3"),
	preload("res://sfx/background2.mp3"),
	preload("res://sfx/background3.mp3"),
	preload("res://sfx/background4.mp3")
]

var music_player: AudioStreamPlayer
var last_track_index := -1

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	await get_tree().process_frame
	_place_player_by_quadrant()
	_setup_music()

# =====================================================================
# 🎯 COLOCAR JUGADOR SEGÚN CUADRANTE
# =====================================================================
func _place_player_by_quadrant() -> void:
	var q: int

	if GameState.is_pve:
		q = 0
	else:
		q = MultiplayerManager.get_my_quadrant()
		if q == -1:
			q = 0

	if quadrant_spawn_positions.has(q):
		player.global_position = quadrant_spawn_positions[q]
		print("Jugador local en cuadrante", q, "posición", player.global_position)
	else:
		push_error("Cuadrante inválido: %s" % str(q))

# =====================================================================
# 🎵 CONFIGURAR MÚSICA DE FONDO
# =====================================================================
func _setup_music() -> void:
	# Crear bus "Music" si no existe
	var music_bus_idx := AudioServer.get_bus_index("Music")
	if music_bus_idx == -1:
		AudioServer.add_bus(AudioServer.bus_count)
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Music")

	# Crear AudioStreamPlayer por código
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = -15.0
	add_child(music_player)

	# Conectar fin de pista para siguiente al azar
	music_player.finished.connect(_on_music_finished)

	# Reproducir primera pista
	_play_random_music()

# =====================================================================
# 🎵 REPRODUCIR PISTA AL AZAR (SIN REPETIR)
# =====================================================================
func _play_random_music() -> void:
	if music_tracks.is_empty():
		return

	var index := last_track_index
	while index == last_track_index:
		index = randi() % music_tracks.size()

	last_track_index = index
	music_player.stream = music_tracks[index]
	music_player.play()
	
func _on_music_finished() -> void:
	_play_random_music()

# =====================================================================
# 🏗️ COLOCAR CASA EN EL MAPA
# =====================================================================
func place_casa(casa_scene: PackedScene, position: Vector2):
	var casa_instance = casa_scene.instantiate()
	casa_instance.global_position = position
	casas_parent.add_child(casa_instance)

	# Ajustar z-index según posición Y
	if casa_instance.has_node("Base"):
		var base_sprite = casa_instance.get_node("Base")
		base_sprite.z_index = int(casa_instance.global_position.y)

	return casa_instance
