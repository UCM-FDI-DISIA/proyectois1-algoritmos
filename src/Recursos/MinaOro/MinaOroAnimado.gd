extends StaticBody2D
class_name MinaOroAnimado

signal depleted

# =====================================================================
# 🧾 NODOS
# =====================================================================
@onready var anim: AnimatedSprite2D = $AnimacionMina
@onready var anim_oro: AnimatedSprite2D = $AnimacionOro
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# ⬅️ CORRECCIÓN: Referencias seguras a los Timers creados en el editor
@onready var regen_timer: Timer = $regenTimer
@onready var depletion_delay_timer: Timer = $deathDelayTimer

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var cell_size: Vector2 = Vector2(168, 58)
@export var ORO_INICIAL: int = 3
@export var ORO_POR_GOLPE: int = 3
@export var TIEMPO_REGENERACION: float = 30.0
@export var TIEMPO_AGOTARSE: float = 0.3

@export var capacity := 1
var resource_type := "gold"

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var is_depleted: bool = false
var oro_queda: int = ORO_INICIAL

var is_occupied: bool = false
var occupying_miner: Node = null


# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	add_to_group("mina_oro") 

	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = cell_size

	anim.play("Idle")
	z_index = int(position.y)
	
	# 1. Timer Regeneración
	if is_instance_valid(regen_timer):
		regen_timer.wait_time = TIEMPO_REGENERACION
		regen_timer.one_shot = true
		regen_timer.timeout.connect(_on_regen_timer_finished)

	# 2. Timer Retraso Agotamiento
	if is_instance_valid(depletion_delay_timer):
		depletion_delay_timer.wait_time = TIEMPO_AGOTARSE
		depletion_delay_timer.one_shot = true
		depletion_delay_timer.timeout.connect(_on_depletion_delay_timeout)

# =====================================================================
# ⚔️ RECOLECCIÓN JUGADOR
# =====================================================================
func hit() -> void:
	if is_depleted:
		return

	oro_queda -= 1 
	print("Mina golpeada por jugador. Oro restante: %d" % oro_queda)

	anim.play("Collect")
	anim_oro.play("bolsita")
	
	anim.animation_finished.connect(_on_anim_finished, CONNECT_ONE_SHOT) 

func _on_anim_finished() -> void:
	if anim.animation != "Collect":
		return

	var manager := get_node("/root/Main/ResourceManager") as ResourceManager
	if manager:
		manager.add_resource("gold", ORO_POR_GOLPE)
		print("Oro añadido (Jugador): +%d" % ORO_POR_GOLPE)

	if oro_queda <= 0:
		is_depleted = true
		# ⬅️ CORRECCIÓN: Llamada segura al Timer de agotamiento
		if is_instance_valid(depletion_delay_timer):
			depletion_delay_timer.start() 
	else:
		anim.play("Idle")

# =====================================================================
# ⛏️ RECOLECCIÓN NPC (Minero)
# =====================================================================
func gather_resource(amount: int) -> int:
	if is_depleted:
		return 0

	var gathered: int = 1
	
	if oro_queda > 0:
		oro_queda -= 1
		
		anim.play("Collect")
		anim_oro.play("bolsita") 

		anim.animation_finished.connect(_on_npc_anim_finished, CONNECT_ONE_SHOT)
		
		print("Mina golpeada por NPC. Oro restante: %d" % oro_queda)
		
		if oro_queda <= 0:
			is_depleted = true
			emit_signal("depleted") 
			
			# ⬅️ CORRECCIÓN: Llamada segura al Timer de agotamiento
			if is_instance_valid(depletion_delay_timer):
				depletion_delay_timer.start() 
		
		return gathered
	else:
		is_depleted = true
		emit_signal("depleted")
		return 0

func _on_npc_anim_finished() -> void:
	if anim.animation != "Collect":
		return
	
	if not is_depleted:
		anim.play("Idle")


# =====================================================================
# 🔄 LÓGICA DE AGOTAMIENTO Y REGENERACIÓN
# =====================================================================
func _on_depletion_delay_timeout() -> void:
	
	is_depleted = true 
	
	anim.play("Depleted")
	print("Mina agotada. Regenerando en %.1f seg..." % TIEMPO_REGENERACION)
	
	# ⬅️ CORRECCIÓN: Llamada segura al Timer de regeneración
	if is_instance_valid(regen_timer):
		regen_timer.start() 

func _on_regen_timer_finished() -> void:
	print("Mina regenerada.")
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
