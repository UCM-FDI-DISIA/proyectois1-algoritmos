extends CharacterBody2D
class_name Player

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var speed: float = 300.0


# =====================================================================
# 🎬 NODOS
# =====================================================================
@onready var animated_sprite: AnimatedSprite2D = $Animacion
@onready var attack_area: Area2D = $AttackArea
@onready var foot_player: AudioStreamPlayer = $FootstepsPlayer
@onready var atk_player: AudioStreamPlayer = $AttackPlayer
@onready var ui: CanvasLayer = get_node("/root/Main/UI")
@onready var joystick_move: VirtualJoystick = ui.get_node("VirtualJoystick1")
@onready var joystick_attack: VirtualJoystick = ui.get_node("VirtualJoystick2")

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var is_attacking := false
var last_direction := Vector2.RIGHT
var is_mobile := false
var _last_anim := ""
var color := "B"

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	add_to_group("jugador")
	if (!GameState.is_pve && MultiplayerManager.get_my_quadrant() == 1) :
		color = "R"
	attack_area.monitoring = true
	animated_sprite.play("Idle" + color)

	is_mobile = OS.get_name() in ["Android", "iOS"]
	if not is_mobile:
		set_process_input(true)
	else:
		_show_sticks(true)

	position = get_viewport().get_visible_rect().size / 2
	z_index = int(position.y)

# =====================================================================
# 🔄 CICLO PRINCIPAL (VISUAL)
# =====================================================================
func _process(_delta):
	z_index = int(global_position.y)

# =====================================================================
# 🏃 MOVIMIENTO Y FÍSICA
# =====================================================================
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

# =====================================================================
# 🎬 ANIMACIONES Y SONIDOS
# =====================================================================
	# Animaciones
	var current_anim := ""
	if input_dir != Vector2.ZERO:
		current_anim = "Andar" + color
		animated_sprite.flip_h = input_dir.x < 0
	elif not is_attacking:
		current_anim = "Idle" + color

	if current_anim != "" and animated_sprite.animation != current_anim:
		animated_sprite.play(current_anim)

	# Sonido PASOS (mientras la animación sea "Andar")
	if current_anim == "Andar" + color:
		if _last_anim != "Andar" + color:
			foot_player.play()
		if not foot_player.playing:
			foot_player.play()
	else:
		if _last_anim == "Andar" + color:
			foot_player.stop()

	_last_anim = current_anim

# =====================================================================
# ⚔️ ATAQUE
# =====================================================================
	if Input.is_action_just_pressed("ataque") or (is_mobile and joystick_attack and joystick_attack.is_pressed):
		start_attack(1)

func start_attack(attack_number: int) -> void:
	if is_attacking:
		return
	is_attacking = true
	var anim_name = "Ataque%d_%s%s" % [attack_number, get_direction_suffix(last_direction), color]
	animated_sprite.play(anim_name)
	animated_sprite.animation_finished.connect(on_animation_finished)
	atk_player.stop()
	atk_player.play()
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
		animated_sprite.play("Idle" + color)
		animated_sprite.animation_finished.disconnect(on_animation_finished)

# =====================================================================
# 📱 DETECCIÓN TÁCTIL (WEB)
# =====================================================================
func _input(event):
	if not is_mobile and (event is InputEventScreenTouch or event is InputEventScreenDrag):
		is_mobile = true
		_show_sticks(true)
		set_process_input(false)

func _show_sticks(visible: bool):
	if joystick_move:
		joystick_move.visible = visible
	if joystick_attack:
		joystick_attack.visible = visible
