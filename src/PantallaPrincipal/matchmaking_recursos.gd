extends Node2D
class_name Matchmaker

# Listas de nodos recolectores y recursos
var collectors := []
var resources := []

# Función para registrar nodos (lo llenaremos después)
func register_collector(collector_node: Node):
	if not collectors.has(collector_node):
		collectors.append(collector_node)

func register_resource(resource_node: Node):
	if not resources.has(resource_node):
		resources.append(resource_node)
