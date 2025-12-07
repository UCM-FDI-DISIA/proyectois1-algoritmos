extends TextureButton

@onready var Hijo = $RockBattleArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Hijo.button = 3 # Replace with function body.
	Hijo.wait_till_ready()
