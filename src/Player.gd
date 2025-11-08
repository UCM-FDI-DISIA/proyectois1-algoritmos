extends CharacterBody2D

# =====================
# VARIABLES EXPORTADAS Y PRIVADAS
# =====================
@export var speed: float = 300.0

var animated_sprite: AnimatedSprite2D
var attack_area: Area2D
var is_attacking := false
var last_direction := Vector2.RIGHT

# =====================
# MÉTODOS PRINCIPALES
# =====================
func _ready() -> void:
	add_to_group("jugador")

	animated_sprite = $Animacion

	attack_area = $AttackArea
	attack_area.monitoring = true

	# Posicionar jugador en el centro y ajustar ZIndex
	position = get_viewport().get_visible_rect().size / 2
	z_index = int(position.y)

func _physics_process(delta: float) -> void:
	# =====================
	# BLOQUEO DE MOVIMIENTO SI ATACANDO
	# =====================
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		z_index = int(position.y)
		return

	# =====================
	# ENTRADA DE MOVIMIENTO
	# =====================
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.y += 1
	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1

	input_dir = input_dir.normalized()
	velocity = input_dir * speed
	move_and_slide()

	if input_dir != Vector2.ZERO:
		last_direction = input_dir

	# =====================
	# ANIMACIONES DE MOVIMIENTO
	# =====================
	if input_dir != Vector2.ZERO:
		if not animated_sprite.is_playing() or animated_sprite.animation != "Andar":
			animated_sprite.play("Andar")
		animated_sprite.flip_h = input_dir.x < 0
	elif animated_sprite.animation != "Idle":
		animated_sprite.play("Idle")

	# =====================
	# ATAQUES
	# =====================
	if Input.is_action_just_pressed("ataque"):
		start_attack(1)
	if Input.is_action_just_pressed("ataque2"):
		start_attack(2)

	z_index = int(position.y)

# =====================
# ATAQUES
# =====================
func start_attack(attack_number: int) -> void:
	if is_attacking:
		return

	is_attacking = true
	var dir_suffix = get_direction_suffix(last_direction)
	animated_sprite.play("Ataque%d_%s" % [attack_number, dir_suffix])
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
		# Aquí se podrían agregar enemigos u otros objetos interactuables

# =====================
# MÉTODOS AUXILIARES
# =====================
func get_direction_suffix(dir: Vector2) -> String:
	if abs(dir.y) > abs(dir.x):
		return "W" if dir.y < 0 else "S"
	else:
		return "H"

func on_animation_finished() -> void:
	if animated_sprite.animation.begins_with("Ataque"):
		is_attacking = false
		animated_sprite.play("Idle")
		animated_sprite.animation_finished.disconnect(on_animation_finished)
