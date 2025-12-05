extends StaticBody2D
class_name MinaPiedraAnimado

signal depleted

# ============================================================
# 🔧 ESTADOS DE OCUPACIÓN
# ============================================================
var is_occupied: bool = false
var occupying_cantero: Node = null
var regeneration_timer: Timer

func occupy(worker):
	if is_occupied:
		return false
	is_occupied = true
	occupying_cantero = worker
	return true

func release():
	is_occupied = false
	occupying_cantero = null

# ============================================================
# 🧩 NODOS
# ============================================================
@onready var anim_explosion: AnimatedSprite2D = $AnimacionExplosion
@onready var rocas_grandes: Node2D = $BigRocksContainer
@onready var rocas_pequenas: Node2D = $SmallRocksContainer

@onready var collision_full: CollisionShape2D = $CollisionShape2D
@onready var collision_small: CollisionShape2D = $CollisionShapeSmall

# ============================================================
# 🔧 VARIABLES EDITABLES
# ============================================================
@export var ROCA_INICIAL: int = 10
@export var PIEDRA_POR_GOLPE: int = 3
@export var TIEMPO_REGENERACION: float = 30.0
@export var TIEMPO_AGOTARSE: float = 0.4

var is_depleted: bool = false
var roca_queda: int = ROCA_INICIAL

# ============================================================
# 🚀 READY
# ============================================================
func _ready() -> void:
	add_to_group("mina")

	# Inicializar temporizador de regeneración
	regeneration_timer = Timer.new()
	add_child(regeneration_timer)
	regeneration_timer.one_shot = true
	regeneration_timer.timeout.connect(_on_regen_timer_timeout)

	_set_collision_state(true)
	set_rocas_visibles(rocas_grandes, true)
	set_rocas_visibles(rocas_pequenas, false)
	anim_explosion.visible = false

	anim_explosion.animation_finished.connect(_on_explosion_finished)

# ============================================================
# ⚔️ GOLPE DEL JUGADOR
# ============================================================
func hit() -> void:
	if is_depleted:
		return

	roca_queda -= PIEDRA_POR_GOLPE
	shake_rocas()
	anim_explosion.visible = true
	anim_explosion.play("Collect")

	var manager := get_node("/root/Main/ResourceManager")
	if manager:
		manager.add_resource("stone", PIEDRA_POR_GOLPE)

	if roca_queda <= 0:
		is_depleted = true
		emit_signal("depleted")
		get_tree().create_timer(TIEMPO_AGOTARSE).timeout.connect(_on_depletion_delay_timeout)

# ============================================================
# ⚔️ RECOLECCIÓN NPC (Cantero)
# ============================================================
func gather_resource(amount: int) -> int:
	if is_depleted:
		return 0

	var gathered: int = min(amount, roca_queda)

	if gathered > 0:
		roca_queda -= gathered
		anim_explosion.visible = true
		anim_explosion.play("Collect")

	# NO se emite depleted ni se marca is_depleted aquí, el NPC completa sus golpes primero
	return gathered

# ============================================================
# 💀 MINA AGOTADA
# ============================================================
func _on_depletion_delay_timeout() -> void:
	print("Mina agotada.")
	set_rocas_visibles(rocas_grandes, false)
	set_rocas_visibles(rocas_pequenas, true)
	_set_collision_state(false)
	regeneration_timer.start(TIEMPO_REGENERACION)

# ============================================================
# 🌱 REGENERACIÓN
# ============================================================
func _on_regen_timer_timeout() -> void:
	print("Mina regenerada.")
	is_depleted = false
	roca_queda = ROCA_INICIAL
	set_rocas_visibles(rocas_pequenas, false)
	set_rocas_visibles(rocas_grandes, true)
	_set_collision_state(true)

# ============================================================
# 🧱 COLISIONES SEGURAS
# ============================================================
func _set_collision_state(alive: bool) -> void:
	if alive:
		if collision_full: collision_full.set_deferred("disabled", false)
		if collision_small: collision_small.set_deferred("disabled", true)
	else:
		if collision_full: collision_full.set_deferred("disabled", true)
		if collision_small: collision_small.set_deferred("disabled", false)

# ============================================================
# 🪨 UTILIDADES
# ============================================================
func shake_rocas() -> void:
	var tween := create_tween()
	for child in rocas_grandes.get_children():
		if child is Node2D:
			var original: Vector2 = child.position
			tween.tween_property(child, "position:x", original.x + randf() * 4.0 - 2.0, 0.05)
			tween.tween_property(child, "position:x", original.x, 0.05)

func set_rocas_visibles(grupo: Node2D, visible: bool) -> void:
	for child in grupo.get_children():
		if child is Sprite2D:
			child.visible = visible

func _on_explosion_finished() -> void:
	anim_explosion.visible = false
