extends CanvasLayer

# ----------------------------
# LABELS DE RECURSOS
# ----------------------------
var wood_label : Label
var stone_label : Label
var gold_label : Label
var villager_label : Label

# ----------------------------
# REFERENCIA AL RESOURCE MANAGER
# ----------------------------
var manager : ResourceManager
const MAX_RESOURCE := 99

# ----------------------------
# INICIALIZACIÓN
# ----------------------------
func _ready() -> void:
	# Referencias a las etiquetas de interfaz
	wood_label = $HBoxContainer/WoodContainer/WoodLabel
	stone_label = $HBoxContainer/StoneContainer/StoneLabel
	gold_label = $HBoxContainer/GoldContainer/GoldLabel
	villager_label = $HBoxContainer/VillagerContainer/VillagerLabel

	# Obtener el ResourceManager
	manager = get_node("/root/Main/ResourceManager")

	# Conectar señales del ResourceManager a los métodos locales
	manager.connect("ResourceUpdated", Callable(self, "_on_resource_updated"))
	manager.connect("VillagerCapacityUpdated", Callable(self, "_on_villager_capacity_updated"))

	# Inicializar valores al cargar la escena
	update_all_labels()

# ----------------------------
# SEÑALES
# ----------------------------
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

# ----------------------------
# ACTUALIZAR LABELS INDIVIDUALES
# ----------------------------
func update_resource_label(label: Label, value: int) -> void:
	label.text = str(value)
	label.add_theme_color_override(
		"font_color",
		Color(1, 0, 0) if value >= MAX_RESOURCE else Color(1, 1, 1)
	)

func update_villager_label() -> void:
	var current_villagers = manager.get_resource("villager")
	var max_villagers = manager.get_villager_capacity()
	villager_label.text = str(current_villagers) + " / " + str(max_villagers)
	villager_label.add_theme_color_override(
		"font_color",
		Color(1, 0, 0) if current_villagers >= max_villagers else Color(1, 1, 1)
	)

# ----------------------------
# ACTUALIZAR TODOS LOS RECURSOS
# ----------------------------
func update_all_labels() -> void:
	update_resource_label(wood_label, manager.get_resource("wood"))
	update_resource_label(stone_label, manager.get_resource("stone"))
	update_resource_label(gold_label, manager.get_resource("gold"))
	update_villager_label()
