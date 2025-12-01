extends CanvasLayer

@onready var joystick_move : VirtualJoystick = get_node("VirtualJoystick1")
@onready var joystick_attack : VirtualJoystick = get_node("VirtualJoystick2")

var is_mobile := false

func _ready() -> void:
	# 1) Android / iOS seguros
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		is_mobile = true
		_show_sticks(true)
		return

	# 2) Web / escritorio → esperar a que toque
	_show_sticks(false)
	set_process_input(true)

func _input(event):
	if not is_mobile and event is InputEventScreenTouch and event.pressed:
		is_mobile = true
		_show_sticks(true)
		set_process_input(false)   # deja de escuchar una vez detectado

func _show_sticks(visible: bool):
	if joystick_move:
		joystick_move.visible = visible
	if joystick_attack:
		joystick_attack.visible = visible
