extends StaticBody2D
class_name ArbolAnimado

signal depleted

# ============================================================
# 🔧 Estados de ocupación (para evitar 2 leñadores en un árbol)
# ============================================================
var is_occupied: bool = false
var occupying_lenador: Node = null

func occupy(worker):
	if is_occupied:
		return false
	is_occupied = true
	occupying_lenador = worker
	return true

func release():
	is_occupied = false
	occupying_lenador = null

# ============================================================
# 🧩 NODOS
# ============================================================
@onready var anim: AnimatedSprite2D = $AnimacionArbol
@onready var anim_tronco: AnimatedSprite2D = $AnimacionTronco

@onready var collision_full: CollisionShape2D = $CollisionShape2D
@onready var collision_stump: CollisionShape2D = $CollisionShapeChop

# ============================================================
# 🔧 VARIABLES EXPORTADAS
# ============================================================
@export var MADERA_INICIAL: int = 15
@export var MADERA_POR_GOLPE: int = 5
@export var TIEMPO_REGENERACION: float = 30.0
@export var TIEMPO_MORIR: float = 0.1

var is_dead: bool = false
var madera_queda: int = MADERA_INICIAL

# ============================================================
# 🚀 READY
# ============================================================
func _ready() -> void:
	add_to_group("arbol") 

	collision_full.disabled = false
	collision_stump.disabled = true

	anim.play("Idle")

# ============================================================
# ⚔️ Golpe de JUGADOR (clic con el ratón)
# ============================================================
func hit() -> void:
	if is_dead:
		return

	madera_queda -= 1
	anim.play("chop")
	anim_tronco.play("tronquito")
	anim.animation_finished.connect(_on_player_anim_finished, CONNECT_ONE_SHOT)

func _on_player_anim_finished():
	var manager := get_node("/root/Main/ResourceManager")
	if manager:
		manager.add_resource("wood", MADERA_POR_GOLPE)

	if madera_queda <= 0:
		is_dead = true
		emit_signal("depleted")
		get_tree().create_timer(TIEMPO_MORIR).timeout.connect(_on_death_delay_timeout)
	else:
		anim.play("Idle")

# ============================================================
# ⛏️ Golpe de NPC (Lenador)
# ============================================================
func gather_resource(amount: int) -> int:
	if is_dead:
		return 0

	var gathered: int = min(amount, madera_queda)   # ← CORREGIDO

	if gathered > 0:
		madera_queda -= gathered
		anim.play("chop")
		anim.animation_finished.connect(_on_npc_chop_finished, CONNECT_ONE_SHOT)

	return gathered


func _on_npc_chop_finished():
	if not is_dead:
		anim.play("Idle")

# ============================================================
# 💀 Talado FINAL por el leñador
# ============================================================
func fell():
	if is_dead:
		return

	is_dead = true
	emit_signal("depleted")

	anim.play("Die")

	collision_full.set_deferred("disabled", true)
	collision_stump.set_deferred("disabled", false)

	# Liberar ocupación al morir por si no lo hace el leñador aún
	release()

	get_tree().create_timer(TIEMPO_REGENERACION).timeout.connect(_on_regen_timer_timeout)

# ============================================================
# 💀 Muerte + regeneración
# ============================================================
func _on_death_delay_timeout():
	anim.play("Die")

	collision_full.set_deferred("disabled", true)
	collision_stump.set_deferred("disabled", false)

	get_tree().create_timer(TIEMPO_REGENERACION).timeout.connect(_on_regen_timer_timeout)

func _on_regen_timer_timeout():
	is_dead = false
	madera_queda = MADERA_INICIAL

	anim.play("Idle")

	collision_full.set_deferred("disabled", false)
	collision_stump.set_deferred("disabled", true)
