extends StaticBody2D
class_name MinaOroAnimado

signal depleted

# =====================================================================
# 🧩 NODOS
# =====================================================================
@onready var anim: AnimatedSprite2D = $AnimacionMina
@onready var anim_oro: AnimatedSprite2D = $AnimacionOro
@onready var collision_full: CollisionShape2D = $CollisionShape2D

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var ORO_INICIAL: int = 3
@export var ORO_POR_GOLPE: int = 1
@export var TIEMPO_REGENERACION: float = 30.0
@export var TIEMPO_AGOTARSE: float = 0.3
@export var stop_distance: float = 32.0
@export var target_offset: Vector2 = Vector2(0, -32)

@export var capacity: int = 1
var resource_type: String = "gold"

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var is_depleted: bool = false
var oro_queda: int = ORO_INICIAL
var is_occupied: bool = false
var occupying_miner: Node = null
var regeneration_timer: Timer

# =====================================================================
# ⚙️ READY
# =====================================================================
func _ready() -> void:
	add_to_group("mina_oro")

	# Timer regeneración
	regeneration_timer = Timer.new()
	regeneration_timer.one_shot = true
	regeneration_timer.timeout.connect(_on_regen_timer_timeout)
	add_child(regeneration_timer)

	anim.play("Idle")
	z_index = int(global_position.y)

# =====================================================================
# ⚔️ RECOLECCIÓN JUGADOR
# =====================================================================
func hit() -> void:
	if is_depleted:
		return

	oro_queda -= ORO_POR_GOLPE
	anim.play("Collect")
	anim_oro.play("Collect") 

	var manager: ResourceManager = get_node("/root/Main/ResourceManager") as ResourceManager
	if manager != null:
		manager.add_resource(resource_type, ORO_POR_GOLPE)

	if oro_queda <= 0:
		# Mina agotada por jugador
		is_depleted = true
		emit_signal("depleted")
		_on_depletion_delay_timeout()
	else:
		anim.play("Idle")

# =====================================================================
# ⚔️ RECOLECCIÓN NPC
# =====================================================================
func gather_resource(amount: int) -> int:
	if is_depleted:
		return 0

	var gathered: int = min(amount, oro_queda)
	if gathered > 0:
		oro_queda -= gathered
		anim.play("Collect")
		anim_oro.play("Collect") 

	return gathered

func fell() -> void:
	if is_depleted:
		return

	is_depleted = true
	emit_signal("depleted")

	anim.play("Depleted")
	

	regeneration_timer.start(TIEMPO_REGENERACION)
	print("Mina de oro agotada, regenerando en %.1f seg..." % TIEMPO_REGENERACION)

# =====================================================================
# 🔄 REGENERACIÓN
# =====================================================================
func _on_depletion_delay_timeout() -> void:
	fell()  # reutilizamos el método para jugador/NPC

func _on_regen_timer_timeout() -> void:
	print("Mina de oro regenerada.")
	is_depleted = false
	oro_queda = ORO_INICIAL

	anim.play("Idle")


# =====================================================================
# 🧾 UTILIDADES
# =====================================================================
func occupy(worker: Node) -> bool:
	if is_occupied:
		return false
	is_occupied = true
	occupying_miner = worker
	return true

func release() -> void:
	is_occupied = false
	occupying_miner = null

func get_capacity() -> int:
	return capacity

func get_type() -> String:
	return resource_type
