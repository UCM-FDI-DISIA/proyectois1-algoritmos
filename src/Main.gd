extends Node

@onready var player = $"Objetos/Player"

var quadrant_spawn_positions := {
	0: Vector2(350, 400),      # Jugador 0
	1: Vector2(7500, 400),     # Jugador 1
}

func _ready() -> void:
	await get_tree().process_frame
	_place_player_by_quadrant()




func _place_player_by_quadrant() -> void:
	var q: int

	if GameState.is_pve:
		# 🔹 Un solo jugador, siempre en el cuadrante 0
		q = 0
	else:
		# 🔹 Modo PVP: usar MultiplayerManager
		q = MultiplayerManager.get_my_quadrant()
		if q == -1:
			push_warning("Aún no tengo cuadrante, usando 0 por defecto.")
			q = 0

	if quadrant_spawn_positions.has(q):
		player.global_position = quadrant_spawn_positions[q]
		print("Jugador local en cuadrante", q, "posición", player.global_position)
	else:
		push_error("Cuadrante inválido: %s" % str(q))
