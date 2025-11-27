extends CharacterBody2D
class_name Player

@export var speed: float = 300.0

@onready var animated_sprite: AnimatedSprite2D = $Animacion
@onready var attack_area: Area2D = $AttackArea
@onready var ui: CanvasLayer = get_node("/root/Main/UI")
@onready var joystick_move: VirtualJoystick = get_node("/root/Main/UI/Virtual Joystick")
@onready var joystick_attack: VirtualJoystick = get_node("/root/Main/UI/Virtual Joystick2")

var is_attacking := false
var last_direction := Vector2.RIGHT
var is_mobile := false

func _ready() -> void:
	add_to_group("jugador")
	attack_area.monitoring = true
	animated_sprite.play("Idle")

	is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
	joystick_move.visible = is_mobile
	joystick_attack.visible = is_mobile

	position = get_viewport().get_visible_rect().size / 2
	z_index = int(position.y)

func _process(_delta):
	z_index = int(global_position.y)

func _physics_process(_delta: float) -> void:
	z_index = int(position.y)

	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_dir := Vector2.ZERO

	if is_mobile and joystick_move and joystick_move.is_pressed:
		input_dir = joystick_move.output
	else:
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	input_dir = input_dir.normalized()
	velocity = input_dir * speed
	move_and_slide()

	if input_dir != Vector2.ZERO:
		last_direction = input_dir

	if input_dir != Vector2.ZERO:
		if animated_sprite.animation != "Andar":
			animated_sprite.play("Andar")
		animated_sprite.flip_h = input_dir.x < 0
	elif animated_sprite.animation != "Idle":
		animated_sprite.play("Idle")

	if Input.is_action_just_pressed("ataque") or (is_mobile and joystick_attack and joystick_attack.is_pressed):
		start_attack(1)

func start_attack(attack_number: int) -> void:
	if is_attacking:
		return
	is_attacking = true
	var anim_name = "Ataque%d_%s" % [attack_number, get_direction_suffix(last_direction)]
	animated_sprite.play(anim_name)
	animated_sprite.animation_finished.connect(on_animation_finished)
	check_attack_hits()

func check_attack_hits() -> void:
	if attack_area == null:
		return
	for obj in attack_area.get_overlapping_bodies():
		if obj is ArbolAnimado:
			obj.hit()
		elif obj is MinaOroAnimado:
			obj.hit()
		elif obj is MinaPiedraAnimado:
			obj.hit()

func get_direction_suffix(dir: Vector2) -> String:
	return "W" if dir.y < 0 else "S" if dir.y > 0 else "H"

func on_animation_finished() -> void:
	if animated_sprite.animation.begins_with("Ataque"):
		is_attacking = false
		animated_sprite.play("Idle")
		animated_sprite.animation_finished.disconnect(on_animation_finished)
