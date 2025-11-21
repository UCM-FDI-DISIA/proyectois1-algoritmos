extends StaticBody2D
class_name MinaOroAnimado

# =====================================================================
# 🧾 NODOS
# =====================================================================
@onready var anim: AnimatedSprite2D = $AnimacionMina
@onready var anim_oro: AnimatedSprite2D = $AnimacionOro
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var cell_size: Vector2 = Vector2(168, 58)
@export var ORO_INICIAL: int = 3
@export var ORO_POR_GOLPE: int = 3
@export var TIEMPO_REGENERACION: float = 30.0
@export var TIEMPO_AGOTARSE: float = 0.3

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var is_depleted: bool = false
var oro_queda: int = ORO_INICIAL

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = cell_size

	anim.play("Idle")
	z_index = int(position.y)

	# Timer regeneración
	var regen_timer := Timer.new()
	regen_timer.wait_time = TIEMPO_REGENERACION
	regen_timer.one_shot = true
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	add_child(regen_timer)

	# Timer retraso agotamiento
	var depletion_delay_timer := Timer.new()
	depletion_delay_timer.wait_time = TIEMPO_AGOTARSE
	depletion_delay_timer.one_shot = true
	depletion_delay_timer.timeout.connect(_on_depletion_delay_timeout)
	add_child(depletion_delay_timer)

# =====================================================================
# ⚔️ RECOLECCIÓN
# =====================================================================
func hit() -> void:
	if is_depleted:
		return

	oro_queda -= 1
	print("Mina golpeada. Oro restante: %d" % oro_queda)

	anim.play("Collect")
	anim_oro.play("bolsita")
	anim.animation_finished.connect(_on_anim_finished)

func _on_anim_finished() -> void:
	if anim.animation != "Collect":
		return

	var manager := get_node("/root/Main/ResourceManager") as ResourceManager
	if manager:
		manager.add_resource("gold", ORO_POR_GOLPE)
		print("Oro añadido: +%d" % ORO_POR_GOLPE)

	anim.animation_finished.disconnect(_on_anim_finished)

	if oro_queda <= 0:
		is_depleted = true
		get_tree().create_timer(TIEMPO_AGOTARSE).timeout.connect(_on_depletion_delay_timeout)
	else:
		anim.play("Idle")

func _on_depletion_delay_timeout() -> void:
	anim.play("Depleted")
	print("Mina agotada. Regenerando en %.1f seg..." % TIEMPO_REGENERACION)
	get_tree().create_timer(TIEMPO_REGENERACION).timeout.connect(_on_regen_timer_timeout)

func _on_regen_timer_timeout() -> void:
	print("Mina regenerada.")
	is_depleted = false
	oro_queda = ORO_INICIAL
	anim.play("Idle")
