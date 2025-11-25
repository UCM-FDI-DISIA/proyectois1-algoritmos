extends Node2D  # Script de Boton_puente

# Apuntamos al TextureButton hijo
@onready var btn_puente: TextureButton = $Puente1

func _ready() -> void:
	# Asignamos el texto del tooltip
	btn_puente.tooltip_text = "Pulsa para construir el puente"
	
	# Asegurarnos que el botón reciba eventos de ratón
	btn_puente.mouse_filter = Control.MOUSE_FILTER_STOP
