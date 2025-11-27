extends Node2D

@export var offset: Vector2 = Vector2.ZERO # Ajuste opcional de posición

# Devuelve todas las posiciones de árboles existentes en el mapa
func get_all_tree_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []

	for tree in get_tree().get_nodes_in_group("arbol"):
		if is_instance_valid(tree):
			positions.append(tree.global_position + offset)

	return positions
