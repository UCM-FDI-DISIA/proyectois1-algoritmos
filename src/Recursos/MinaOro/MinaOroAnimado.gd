extends StaticBody2D
class_name MinaOroAnimado

# =====================
# NODOS
# =====================
var anim : AnimatedSprite2D
var anim_oro : AnimatedSprite2D
var collision_shape : CollisionShape2D
var regen_timer : Timer
var depletion_delay_timer : Timer

# =====================
# ESTADO
# =====================
var is_depleted := false
var oro_queda := 3
const ORO := 3
const ORO_INICIAL := 3
const TIEMPO_REGENERACION := 30.0
const TIEMPO_AGOTARSE := 0.3

@export var cell_size := Vector2(168, 58)

func _ready() -> void:
	anim = $AnimacionMina
	anim_oro = $AnimacionOro
	collision_shape = $CollisionShape2D

	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = cell_size

	collision_shape.disabled = false
	anim.play("Idle")
	z_index = int(position.y)

	# Timer para regenerar
	regen_timer = Timer.new()
	regen_timer.wait_time = TIEMPO_REGENERACION
	regen_timer.one_shot = true
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	add_child(regen_timer)

	# Timer para retrasar la animación de agotamiento
	depletion_delay_timer = Timer.new()
	depletion_delay_timer.wait_time = TIEMPO_AGOTARSE
	depletion_delay_timer.one_shot = true
	depletion_delay_timer.timeout.connect(_on_depletion_delay_timeout)
	add_child(depletion_delay_timer)

# =====================
# RECOLECCIÓN DE ORO
# =====================
func hit() -> void:
	if is_depleted:
		return

	oro_queda -= 1
	print("Mina golpeada. Oro restante: %d" % oro_queda)

	anim.play("Collect")
	anim_oro.play("bolsita")
	anim.animation_finished.connect(_on_anim_finished)

func _on_anim_finished() -> void:
	if anim.animation == "Collect":
		var manager = get_node("/root/Main/ResourceManager")
		manager.add_resource("gold", ORO)
		print("Oro añadido: +3")

		anim.animation_finished.disconnect(_on_anim_finished)

		if oro_queda <= 0:
			is_depleted = true
			depletion_delay_timer.start()
		else:
			anim.play("Idle")

func _on_depletion_delay_timeout() -> void:
	anim.play("Depleted")
	print("Mina agotada. Regenerando en 30 segundos...")
	regen_timer.start()

func _on_regen_timer_timeout() -> void:
	print("Mina regenerada.")
	is_depleted = false
	oro_queda = ORO_INICIAL
	anim.play("Idle")
