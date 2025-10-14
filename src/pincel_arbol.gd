extends Node2D

@export var arbol_scene: PackedScene      # arrastra tu arbolAnimado.tscn
@export var capa_objetos_path: NodePath   # arrastra tu TileMapLayer Objetos

var capa_objetos: TileMapLayer

func _ready():
	if capa_objetos_path != null:
		capa_objetos = get_node(capa_objetos_path)

func _input(event):
	# Solo detectar clicks del mouse izquierdo
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		if capa_objetos == null:
			return

		# Convertir posición del click a celda
		var local_pos = capa_objetos.to_local(event.position)
		var cell = capa_objetos.local_to_map(local_pos)

		if arbol_scene == null:
			push_error("No se asignó la escena del árbol.")
			return

		# Instanciar el árbol
		var arbol = arbol_scene.instantiate()
		var tile_size = capa_objetos.tile_set.tile_size
		arbol.position = capa_objetos.map_to_local(cell) + tile_size / 2.0

		# Añadir como hijo de la capa Objetos
		capa_objetos.add_child(arbol)

		print("Árbol instanciado en celda ", cell)
