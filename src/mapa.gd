extends Node2D

@export var obstacle_groups: Array[String] = [] # opcional: si vacío, toma todo
@export var obstacle_radius: float = 12.0      # fallback para objetos sin CollisionShape2D

func _ready():
	# Esperamos un frame para evitar conflictos al construir la escena
	call_deferred("_scan_map")


func _scan_map():
	# 🔥 SOLO analizamos el nodo del mapa, NO el árbol entero
	var mapa := get_tree().get_root().get_node("Main/Mapa")
	if mapa == null:
		push_error("[Mapa.gd] ❌ No se encontró Main/Mapa")
		return

	_add_obstacles_recursively(mapa)



func _add_obstacles_recursively(node: Node) -> void:
	for child in node.get_children():
		if not is_instance_valid(child):
			continue

		# IGNORAR NavigationObstacle2D ya existentes
		if child is NavigationObstacle2D:
			continue

		# Filtrar por grupos (si obstacle_groups no está vacío)
		if obstacle_groups.size() > 0:
			var in_group := false
			for g in obstacle_groups:
				if child.is_in_group(g):
					in_group = true
					break
			if not in_group:
				_add_obstacles_recursively(child)
				continue

		# Si tiene CollisionShape2D → creamos NavigationObstacle2D idéntico
		if child.has_node("CollisionShape2D"):
			_create_nav_obstacle(child.get_node("CollisionShape2D"), child)
		else:
			# Fallback: círculo pequeño
			var obstacle := NavigationObstacle2D.new()
			child.call_deferred("add_child", obstacle)

			var shape := CollisionShape2D.new()
			var circle := CircleShape2D.new()
			circle.radius = obstacle_radius
			shape.shape = circle

			obstacle.call_deferred("add_child", shape)

		# Recursión en hijos
		_add_obstacles_recursively(child)


func _create_nav_obstacle(col: CollisionShape2D, parent_obj: Node2D) -> void:
	# Evitar crear duplicados
	if parent_obj.has_node("NavigationObstacle2D"):
		return

	var obstacle := NavigationObstacle2D.new()
	parent_obj.call_deferred("add_child", obstacle)

	var shape_copy := CollisionShape2D.new()
	shape_copy.shape = col.shape.duplicate()
	shape_copy.position = col.position

	obstacle.call_deferred("add_child", shape_copy)
