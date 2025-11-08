extends Control

# NO CAMBIAR

func _ready() -> void:
	var play_button := $PlayButton
	play_button.pressed.connect(_on_play_button_pressed)

func _on_play_button_pressed() -> void:
	# Cambia a la escena principal del juego
	# El main está en la carpeta src
	get_tree().change_scene_to_file("res://src/main.tscn")
