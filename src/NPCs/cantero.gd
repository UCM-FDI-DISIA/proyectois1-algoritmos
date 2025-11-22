extends CharacterBody2D
class_name Cantero

@export var speed := 100.0
#var target_resource := null
var current_state := "IDLE" # estados: "IDLE", "MOVING", "GATHERING"

func _ready():
	# registrarse en el Matchmaker
	#if is_instance_valid(Matchmaker):
	#	Matchmaker.register_collector(self)

func _process(_delta):
	match current_state:
		"IDLE":
			_find_resource()
		"MOVING":
			_move_to_resource(_delta)
		"GATHERING":
			_gather(_delta)
