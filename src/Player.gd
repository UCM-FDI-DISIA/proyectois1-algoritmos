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
	if (!GameState.is_pve and MultiplayerManager.get_my_quadrant() == 1):
		color = "R"
	attack_area.monitoring = true
	animated_sprite.play("Idle" + color)

	is_mobile = OS.get_name() in ["Android", "iOS"]
	if not is_mobile:
		set_process_input(true)

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
		foot_player.stop()
		return

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	input_dir = input_dir.normalized()

	velocity = input_dir * speed
	move_and_slide()

	if input_dir != Vector2.ZERO:
		last_direction = input_dir

	# =====================================================================
	# 🎬 ANIMACIONES
	# =====================================================================
	var current_anim := ""
	if input_dir != Vector2.ZERO:
		current_anim = "Andar" + color
		animated_sprite.flip_h = input_dir.x < 0
	elif not is_attacking:
		current_anim = "Idle" + color

	if current_anim != "" and animated_sprite.animation != current_anim:
		animated_sprite.play(current_anim)

	# =====================================================================
	# 🔊 SONIDO DE PASOS FIJO
	# =====================================================================
	if current_anim == "Andar" + color:
		if not foot_player.playing:
			foot_player.play()
	else:
		foot_player.stop()

	_last_anim = current_anim

	# =====================================================================
	# ⚔️ ATAQUE
	# =====================================================================
	if Input.is_action_just_pressed("ataque"):
		start_attack(1)

# =====================================================================
# ⚔️ SISTEMA DE ATAQUE
# =====================================================================
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
