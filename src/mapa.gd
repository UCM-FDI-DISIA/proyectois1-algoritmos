extends Node2D

@export var obstacle_groups: Array[String] = [] # opcional: si vacío, toma todo
@export var obstacle_radius: float = 12.0      # fallback para objetos sin CollisionShape2D

func _ready():
	_add_obstacles_recursively(get_tree().get_root())


func _add_obstacles_recursively(node: Node) -> void:
	for child in node.get_children():
		if not is_instance_valid(child):
			continue

		# IGNORAR los NavigationObstacle2D
		if child is NavigationObstacle2D:
			continue

		# Filtrar por grupos si es necesario
		if obstacle_groups.size() > 0:
			var in_group = false
			for g in obstacle_groups:
				if child.is_in_group(g):
					in_group = true
					break
			if not in_group:
				_add_obstacles_recursively(child)
				continue

		# Si tiene CollisionShape2D → añadimos NavigationObstacle2D
		if child.has_node("CollisionShape2D"):
			_create_nav_obstacle(child.get_node("CollisionShape2D"), child)
		else:
			# Fallback circular
			var obstacle := NavigationObstacle2D.new()
			child.add_child(obstacle)
			var shape := CollisionShape2D.new()
			var circle := CircleShape2D.new()
			circle.radius = obstacle_radius
			shape.shape = circle
			obstacle.add_child(shape)

		# Recursividad en hijos
		_add_obstacles_recursively(child)



func _create_nav_obstacle(col: CollisionShape2D, parent_obj: Node2D) -> void:
	if parent_obj.has_node("NavigationObstacle2D"):
		return

	var obstacle := NavigationObstacle2D.new()
	parent_obj.add_child(obstacle)

	# Copiamos la CollisionShape exacta
	var shape_copy := CollisionShape2D.new()
	shape_copy.shape = col.shape.duplicate()
	shape_copy.position = col.position
	obstacle.add_child(shape_copy)
