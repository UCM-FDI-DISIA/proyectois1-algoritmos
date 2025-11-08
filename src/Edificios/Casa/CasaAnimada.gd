extends Node2D

const CRECIMIENTO_POR_CASA := 2
var es_preview: bool = false

func _ready() -> void:
	# Si es preview, no ejecutar lógica de crecimiento
	if es_preview:
		return

	var manager := get_node("/root/Main/ResourceManager") as ResourceManager
	manager.add_house() # ✅ Se suma una sola vez
	manager.actualizar_aldeanos(CRECIMIENTO_POR_CASA * manager.get_house_count())

	print("[Casa] Construida nueva casa. Total casas: %d" % manager.get_house_count())

func _exit_tree() -> void:
	if es_preview:
		return

	var manager := get_node("/root/Main/ResourceManager") as ResourceManager
	manager.remove_house()
	manager.actualizar_aldeanos(CRECIMIENTO_POR_CASA * manager.get_house_count())

	print("[Casa] Se ha destruido una casa. Total casas: %d" % manager.get_house_count())
