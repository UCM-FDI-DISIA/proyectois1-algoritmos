extends StaticBody2D
class_name ArbolAnimado

# =====================
# NODOS
# =====================
var anim : AnimatedSprite2D
var anim_tronco : AnimatedSprite2D
var collision_shape : CollisionShape2D
var regen_timer : Timer
var death_delay_timer : Timer

# =====================
# ESTADO
# =====================
var is_dead := false
var madera_queda := 3
const MADERA := 5
const MADERA_INICIAL := 3
const TIEMPO_REGENERACION := 30.0
const TIEMPO_MORIR := 0.01

@export var cell_size := Vector2(64, 64)

func _ready() -> void:
	anim = $AnimacionArbol
	anim_tronco = $AnimacionTronco
	collision_shape = $CollisionShape2D

	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = cell_size

	anim.play("Idle")

	# Timer para regenerar
	regen_timer = Timer.new()
	regen_timer.wait_time = TIEMPO_REGENERACION
	regen_timer.one_shot = true
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	add_child(regen_timer)

	# Timer para retrasar la animación de "Die"
	death_delay_timer = Timer.new()
	death_delay_timer.wait_time = TIEMPO_MORIR
	death_delay_timer.one_shot = true
	death_delay_timer.timeout.connect(_on_death_delay_timeout)
	add_child(death_delay_timer)

# =====================
# RECOLECCIÓN DE RECURSOS
# =====================
func hit() -> void:
	if is_dead:
		return

	madera_queda -= 1
	print("Árbol golpeado. Madera restante: %d" % madera_queda)

	anim.play("chop")
	anim_tronco.play("tronquito")
	anim.animation_finished.connect(_on_anim_finished)

func _on_anim_finished() -> void:
	if anim.animation == "chop":
		# === SUMAR MADERA ANTES DE MORIR ===
		var manager = get_node("/root/Main/ResourceManager")
		manager.add_resource("wood", MADERA)
		print("Madera añadida: +5")

		anim.animation_finished.disconnect(_on_anim_finished)

		if madera_queda <= 0:
			is_dead = true
			death_delay_timer.start()  # Espera breve antes de "Die"
		else:
			anim.play("Idle")

func _on_death_delay_timeout() -> void:
	anim.play("Die")
	if collision_shape != null:
		collision_shape.disabled = true

	print("Árbol caído. Regenerando en 30 segundos...")
	regen_timer.start()

func _on_regen_timer_timeout() -> void:
	print("Árbol regenerado.")
	is_dead = false
	madera_queda = MADERA_INICIAL
	anim.play("Idle")
	if collision_shape != null:
		collision_shape.disabled = false
