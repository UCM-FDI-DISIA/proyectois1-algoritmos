extends StaticBody2D
class_name ArbolAnimado

# =====================================================================
# 🧾 NODOS
# =====================================================================
@onready var anim: AnimatedSprite2D = $AnimacionArbol
@onready var anim_tronco: AnimatedSprite2D = $AnimacionTronco
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var cell_size: Vector2 = Vector2(64, 64)
@export var MADERA_INICIAL: int = 3
@export var MADERA_POR_GOLPE: int = 5
@export var TIEMPO_REGENERACION: float = 30.0
@export var TIEMPO_MORIR: float = 0.01

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var is_dead: bool = false
var madera_queda: int = MADERA_INICIAL

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = cell_size

	anim.play("Idle")

	# Timer regeneración
	var regen_timer := Timer.new()
	regen_timer.wait_time = TIEMPO_REGENERACION
	regen_timer.one_shot = true
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	add_child(regen_timer)

	# Timer retraso "Die"
	var death_delay_timer := Timer.new()
	death_delay_timer.wait_time = TIEMPO_MORIR
	death_delay_timer.one_shot = true
	death_delay_timer.timeout.connect(_on_death_delay_timeout)
	add_child(death_delay_timer)

# =====================================================================
# ⚔️ RECOLECCIÓN
# =====================================================================
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

	# Entregar madera
	var manager := get_node("/root/Main/ResourceManager") as ResourceManager
	if manager:
		manager.add_resource("wood", MADERA_POR_GOLPE)
		print("Madera añadida: +%d" % MADERA_POR_GOLPE)

	anim.animation_finished.disconnect(_on_anim_finished)

	if madera_queda <= 0:
		is_dead = true
		$Timer.new().create_timer(TIEMPO_MORIR).timeout.connect(_on_death_delay_timeout)
	else:
		anim.play("Idle")

func _on_death_delay_timeout() -> void:
	anim.play("Die")
	collision_shape.set_deferred("disabled", true)
	print("Árbol caído. Regenerando en %.1f seg..." % TIEMPO_REGENERACION)
	$Timer.new().create_timer(TIEMPO_REGENERACION).timeout.connect(_on_regen_timer_timeout)

func _on_regen_timer_timeout() -> void:
	print("Árbol regenerado.")
	is_dead = false
	madera_queda = MADERA_INICIAL
	anim.play("Idle")
	collision_shape.set_deferred("disabled", false)
