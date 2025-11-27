extends CanvasLayer

@onready var joystick_move: VirtualJoystick = get_node("/root/Main/UI/Virtual Joystick1")
@onready var joystick_attack: VirtualJoystick = get_node("/root/Main/UI/Virtual Joystick2")

func _ready() -> void:
	var is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"

	if joystick_move:
		joystick_move.visible = is_mobile
	if joystick_attack:
		joystick_attack.visible = is_mobile
