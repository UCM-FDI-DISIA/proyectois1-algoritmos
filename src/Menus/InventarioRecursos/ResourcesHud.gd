extends CanvasLayer

# =====================
# 🔢 LÍMITES Y COLORES
# =====================
@export var MAX_RESOURCE := 99
@export var COLOR_MAX := Color(1, 0, 0)        # Rojo cuando se alcanza el máximo
@export var COLOR_NORMAL := Color(1, 1, 1)     # Blanco por defecto

# =====================================================================
# 🧾 NODOS DE INTERFAZ
# =====================================================================
@onready var wood_label: Label   = $HBoxContainer/WoodContainer/WoodLabel
@onready var stone_label: Label  = $HBoxContainer/StoneContainer/StoneLabel
@onready var gold_label: Label   = $HBoxContainer/GoldContainer/GoldLabel
@onready var villager_label: Label = $HBoxContainer/VillagerContainer/VillagerLabel

# =====================================================================
# ⚙️ GESTIÓN DE RECURSOS
# =====================================================================
var manager: ResourceManager

# =====================================================================
# 🚀 INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	manager = get_node("/root/Main/ResourceManager")
	if manager == null:
		push_error("[ResourceHUD] ResourceManager no encontrado en /root/Main/ResourceManager")
		return

	manager.ResourceUpdated.connect(_on_resource_updated)
	manager.VillagerCapacityUpdated.connect(_on_villager_capacity_updated)
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
	label.add_theme_color_override("font_color", COLOR_MAX if value >= MAX_RESOURCE else COLOR_NORMAL)

func update_villager_label() -> void:
	var current := manager.get_resource("villager")
	var max_cap := manager.get_villager_capacity()
	villager_label.text = "%d / %d" % [current, max_cap]
	villager_label.add_theme_color_override("font_color", COLOR_MAX if current >= max_cap else COLOR_NORMAL)

func update_all_labels() -> void:
	update_resource_label(wood_label, manager.get_resource("wood"))
	update_resource_label(stone_label, manager.get_resource("stone"))
	update_resource_label(gold_label, manager.get_resource("gold"))
	update_villager_label()
