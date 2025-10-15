extends CanvasLayer

# Referencias a las Labels
@onready var wood_label = $HBoxContainer/WoodContainer/WoodLabel
@onready var stone_label = $HBoxContainer/StoneContainer/StoneLabel
@onready var gold_label = $HBoxContainer/GoldContainer/GoldLabel
@onready var villager_label = $HBoxContainer/VillagerContainer/VillagerLabel

func _ready():
	var manager = get_node("/root/Main/ResourceManager")
	manager.connect("resource_updated", Callable(self, "_on_resource_updated"))

func _on_resource_updated(resource_name: String, new_value: int) -> void:
	match resource_name:
		"wood":
			wood_label.text = str(new_value)
		"stone":
			stone_label.text = str(new_value)
		"gold":
			gold_label.text = str(new_value)
		"villager":
			villager_label.text = str(new_value)
