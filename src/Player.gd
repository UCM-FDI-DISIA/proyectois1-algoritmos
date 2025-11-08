extends CharacterBody2D

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var speed: float = 300.0

# =====================================================================
# 🎬 NODOS
# =====================================================================
@onready var animated_sprite: AnimatedSprite2D = $Animacion
@onready var attack_area: Area2D = $AttackArea

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var is_attacking := false
var last_direction := Vector2.RIGHT

# =====================================================================
# 🚀 INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	add_to_group("jugador")
	attack_area.monitoring = true
	# Centro de la pantalla como punto de partida
	position = get_viewport().get_visible_rect().size / 2
	z_index = int(position.y)

# =====================================================================
# 🔁 FÍSICA Y ENTRADA
# =====================================================================
func _physics_process(delta: float) -> void:
	# Bloqueo mientras ataca
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		z_index = int(position.y)
		return

	# Lectura de entrada
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"): input_dir.x += 1
	if Input.is_action_pressed("ui_left"):  input_dir.x -= 1
	if Input.is_action_pressed("ui_down"):  input_dir.y += 1
	if Input.is_action_pressed("ui_up"):    input_dir.y -= 1
	input_dir = input_dir.normalized()

	# Movimiento
	velocity = input_dir * speed
	move_and_slide()
	if input_dir != Vector2.ZERO:
		last_direction = input_dir

	# Animaciones
	if input_dir != Vector2.ZERO:
		if not animated_sprite.is_playing() or animated_sprite.animation != "Andar":
			animated_sprite.play("Andar")
		animated_sprite.flip_h = input_dir.x < 0
	elif animated_sprite.animation != "Idle":
		animated_sprite.play("Idle")

	# Ataques
	if Input.is_action_just_pressed("ataque"):  start_attack(1)
	if Input.is_action_just_pressed("ataque2"): start_attack(2)

	z_index = int(position.y)

# =====================================================================
# ⚔️ ATAQUES
# =====================================================================
func start_attack(attack_number: int) -> void:
	if is_attacking: return
	is_attacking = true
	animated_sprite.play("Ataque%d_%s" % [attack_number, get_direction_suffix(last_direction)])
	animated_sprite.animation_finished.connect(on_animation_finished)
	check_attack_hits()

func check_attack_hits() -> void:
	if attack_area == null: return
	for obj in attack_area.get_overlapping_bodies():
		if obj is ArbolAnimado:        obj.hit()
		elif obj is MinaOroAnimado:    obj.hit()
		elif obj is MinaPiedraAnimado: obj.hit()
		# Añadir más objetos si se desea

# =====================================================================
# 🛠️ MÉTODOS AUXILIARES
# =====================================================================
func get_direction_suffix(dir: Vector2) -> String:
	return "W" if dir.y < 0 else "S" if dir.y > 0 else "H"

func on_animation_finished() -> void:
	if animated_sprite.animation.begins_with("Ataque"):
		is_attacking = false
		animated_sprite.play("Idle")
		animated_sprite.animation_finished.disconnect(on_animation_finished)
