extends Control

@onready var menu_soldados: CanvasLayer = $MenuSoldados


func _ready() -> void:
	menu_soldados.visible = false  # Oculto inicialmente


func toggle_menu() -> void:
	menu_soldados.visible = not menu_soldados.visible
	print("MenuSoldados.Visible =", menu_soldados.visible)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Tecla M
		if event.keycode == KEY_M:
			toggle_menu()
