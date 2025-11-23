extends CharacterBody2D
class_name Cantero

@export var speed := 100.0

var current_state := "IDLE" # estados: "IDLE", "MOVING", "GATHERING"

func _ready():
	pass   # De momento no hace nada


func _process(_delta):
	match current_state:
		"IDLE":
			_find_resource()
		"MOVING":
			_move_to_resource(_delta)
		"GATHERING":
			_gather(_delta)


# =====================================================
# 🧠 LÓGICA DE IA — Placeholders
# =====================================================

func _find_resource() -> void:
	pass


func _move_to_resource(delta: float) -> void:
	pass


func _gather(delta: float) -> void:
	pass
