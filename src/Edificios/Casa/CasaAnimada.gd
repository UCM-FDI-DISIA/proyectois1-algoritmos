extends Node2D
class_name CasaAnimada

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var CRECIMIENTO_POR_CASA := 2

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var es_preview: bool = false

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	if es_preview:
		return

	var manager := get_node("/root/Main/ResourceManager") as ResourceManager
	if manager == null:
		push_error("[CasaAnimada] ResourceManager no encontrado")
		return

	manager.add_house()
	manager.actualizar_aldeanos(CRECIMIENTO_POR_CASA * manager.get_house_count())
	print("[Casa] Construida. Total casas: %d" % manager.get_house_count())

# =====================================================================
# 🧹 AL SALIR DEL ÁRBOL
# =====================================================================
func _exit_tree() -> void:
	if es_preview:
		return

	var manager := get_node("/root/Main/ResourceManager") as ResourceManager
	if manager == null:
		push_error("[CasaAnimada] ResourceManager no encontrado al destruir")
		return

	manager.remove_house()
	manager.actualizar_aldeanos(CRECIMIENTO_POR_CASA * manager.get_house_count())
	print("[Casa] Destruida. Total casas: %d" % manager.get_house_count())
