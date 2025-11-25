extends Node

# Main.gd
@onready var casas_parent := $Casas
@onready var player: Node2D = $"Objetos/Player"

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
		# PVE: siempre cuadrante 0
		q = 0
	else:
		# PVP: usar el quadrant asignado por MultiplayerManager
		q = MultiplayerManager.get_my_quadrant()
		if q == -1:
			push_warning("Aún no tengo cuadrante, usando 0 por defecto.")
			q = 0

	if quadrant_spawn_positions.has(q):
		player.global_position = quadrant_spawn_positions[q]
		print("Jugador local en cuadrante", q, "posición", player.global_position)
	else:
		push_error("Cuadrante inválido: %s" % str(q))

func place_casa(casa_scene: PackedScene, position: Vector2):
	var casa_instance = casa_scene.instantiate()
	casa_instance.global_position = position
	casas_parent.add_child(casa_instance)
	
	# Ajustamos z_index del sprite base si la casa es grande
	if casa_instance.has_node("Base"):
		var base_sprite = casa_instance.get_node("Base")
		base_sprite.z_index = int(casa_instance.global_position.y)
	
	return casa_instance
