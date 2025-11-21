extends CanvasLayer

# =====================
# 🔢 LÍMITES Y COLORES
# =====================
@export var MAX_RESOURCE := 99
@export var COLOR_MAX := Color(1, 0, 0)
@export var COLOR_NORMAL := Color(1, 1, 1)

# =====================================================================
# 🧾 NODOS DE INTERFAZ
# =====================================================================
@onready var wood_label: Label = $HBoxContainer/WoodContainer/WoodLabel
@onready var stone_label: Label = $HBoxContainer/StoneContainer/StoneLabel
@onready var gold_label: Label = $HBoxContainer/GoldContainer/GoldLabel
@onready var villager_label: Label = $HBoxContainer/VillagerContainer/VillagerLabel

# =====================================================================
# ⚙️ GESTIÓN DE RECURSOS (Variable de clase)
# =====================================================================
var manager: ResourceManager # Esta es la variable que queremos asignar

# =====================================================================
# 🚀 INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	# 🚨 CORRECCIÓN CLAVE: Eliminamos 'var'. Asignamos directamente a la variable de clase 'manager'.
	manager = get_node("/root/Main/ResourceManager")
	
	if manager == null:
		push_error("[ResourceHUD] ResourceManager no encontrado en /root/Main/ResourceManager")
		return

	# Conectamos las señales
	manager.ResourceUpdated.connect(_on_resource_updated)
	manager.VillagerCapacityUpdated.connect(_on_villager_capacity_updated)
	
	# Actualizamos todas las etiquetas inmediatamente
	update_all_labels()

# =====================================================================
# 📡 SEÑALES
# =====================================================================
func _on_resource_updated(resource_name: String, new_value: int) -> void:
	match resource_name:
		"wood":
			update_resource_label(wood_label, new_value)
		"stone":
			update_resource_label(stone_label, new_value)
		"gold":
			update_resource_label(gold_label, new_value)
		"villager":
			update_villager_label()

func _on_villager_capacity_updated() -> void:
	update_villager_label()

# =====================================================================
# 🛠️ MÉTODOS AUXILIARES
# =====================================================================
func update_resource_label(label: Label, value: int) -> void:
	label.text = str(value)
	# Usamos .get_resource("wood") en ResourceManager para obtener el valor
	# si es necesario verificar el máximo, o simplemente el 'value' que ya se pasó.
	label.add_theme_color_override("font_color", COLOR_MAX if value >= MAX_RESOURCE else COLOR_NORMAL)

func update_villager_label() -> void:
	# Aseguramos que manager no es null antes de llamar
	if manager == null: return 
	
	var current := manager.get_resource("villager")
	var max_cap := manager.get_villager_capacity()
	
	villager_label.text = "%d / %d" % [current, max_cap]
	villager_label.add_theme_color_override("font_color", COLOR_MAX if current >= max_cap else COLOR_NORMAL)

func update_all_labels() -> void:
	# Aseguramos que manager no es null antes de llamar
	if manager == null: return
	
	# Usamos las funciones del ResourceManager para obtener los valores iniciales
	update_resource_label(wood_label, manager.get_resource("wood"))
	update_resource_label(stone_label, manager.get_resource("stone"))
	update_resource_label(gold_label, manager.get_resource("gold"))
	
	# Actualiza la etiqueta de aldeanos
	update_villager_label()
