extends Node2D  # Script del Node2D que contiene el TextureButton

# Apuntamos al TextureButton hijo
@onready var btn_puente: TextureButton = $Puente3
@onready var resource_manager: ResourceManager = get_node("/root/Main/ResourceManager") as ResourceManager

func _ready() -> void:
	# Asignamos el texto del tooltip usando los costes del ResourceManager
	btn_puente.tooltip_text = "Coste: Madera %d | Oro %d" % [
		resource_manager.PUENTES_WOOD_COST,
		resource_manager.PUENTES_GOLD_COST
	]
	
	# Asegurarnos de que el botón reciba eventos de ratón
	btn_puente.mouse_filter = Control.MOUSE_FILTER_STOP
