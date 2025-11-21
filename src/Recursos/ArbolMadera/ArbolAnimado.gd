extends StaticBody2D
class_name ArbolAnimado

@onready var anim: AnimatedSprite2D = $AnimacionArbol
@onready var anim_tronco: AnimatedSprite2D = $AnimacionTronco

@onready var collision_full: CollisionShape2D = $CollisionShape2D
@onready var collision_stump: CollisionShape2D = $CollisionShapeChop

@export var cell_size: Vector2 = Vector2(64, 64)
@export var MADERA_INICIAL: int = 3
@export var MADERA_POR_GOLPE: int = 5
@export var TIEMPO_REGENERACION: float = 30.0
@export var TIEMPO_MORIR: float = 0.01

var is_dead: bool = false
var madera_queda: int = MADERA_INICIAL

func _ready() -> void:
	# activar colisión completa, desactivar colisión del tronco
	collision_full.disabled = false
	collision_stump.disabled = true

	anim.play("Idle")


# ============================================================
# ⚔️ RECOLECCIÓN
# ============================================================
func hit() -> void:
	if is_dead:
		return

	madera_queda -= 1
	print("Árbol golpeado. Madera restante: %d" % madera_queda)

	anim.play("chop")
	anim_tronco.play("tronquito")
	anim.animation_finished.connect(_on_anim_finished)


func _on_anim_finished() -> void:
	if anim.animation != "chop":
		return

	var manager := get_node("/root/Main/ResourceManager") as ResourceManager
	if manager:
		manager.add_resource("wood", MADERA_POR_GOLPE)

	anim.animation_finished.disconnect(_on_anim_finished)

	if madera_queda <= 0:
		is_dead = true
		get_tree().create_timer(TIEMPO_MORIR).timeout.connect(_on_death_delay_timeout)
	else:
		anim.play("Idle")


# ============================================================
# 💀 ÁRBOL TALADO
# ============================================================
func _on_death_delay_timeout() -> void:
	anim.play("Die")

	# desactivar colisión grande
	collision_full.set_deferred("disabled", true)
	# activar colisión pequeña del tronco
	collision_stump.set_deferred("disabled", false)

	print("Árbol caído. Regenerando en %.1f seg..." % TIEMPO_REGENERACION)

	get_tree().create_timer(TIEMPO_REGENERACION).timeout.connect(_on_regen_timer_timeout)


# ============================================================
# 🌱 REGENERACIÓN
# ============================================================
func _on_regen_timer_timeout() -> void:
	print("Árbol regenerado.")
	is_dead = false
	madera_queda = MADERA_INICIAL

	anim.play("Idle")

	# recuperar colisión completa
	collision_full.set_deferred("disabled", false)
	# desactivar colisión pequeña
	collision_stump.set_deferred("disabled", true)
