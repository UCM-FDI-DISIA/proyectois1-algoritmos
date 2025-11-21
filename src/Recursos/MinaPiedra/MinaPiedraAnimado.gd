extends StaticBody2D
class_name MinaPiedraAnimado

# =====================================================================
# 🧾 NODOS
# =====================================================================
@onready var anim_explosion := $AnimacionExplosion
@onready var rocas_grandes := $BigRocksContainer
@onready var rocas_pequenas := $SmallRocksContainer

var collision_full: CollisionShape2D
var collision_small: CollisionShape2D

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var ROCA_INICIAL := 3
@export var PIEDRA_POR_GOLPE := 3
@export var TIEMPO_REGENERACION := 30.0
@export var TIEMPO_AGOTARSE := 0.4

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var is_depleted := false
var roca_queda := ROCA_INICIAL

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	# Cargar nodos de colisión de forma segura
	collision_full = get_node_or_null("CollisionShape2D")
	collision_small = get_node_or_null("CollisionShapeSmall")

	# Colisión inicial: grande ON, pequeña OFF
	_set_collision_state(true)

	set_rocas_visibles(rocas_grandes, true)
	set_rocas_visibles(rocas_pequenas, false)
	anim_explosion.visible = false

	anim_explosion.animation_finished.connect(_on_explosion_finished)


# =====================================================================
# ⚔️ RECOLECCIÓN
# =====================================================================
func hit() -> void:
	if is_depleted:
		return

	roca_queda -= 1
	shake_rocas()
	anim_explosion.visible = true
	anim_explosion.play("Collect")

	var manager := get_node("/root/Main/ResourceManager") as ResourceManager
	if manager:
		manager.add_resource("stone", PIEDRA_POR_GOLPE)

	if roca_queda <= 0:
		is_depleted = true
		get_tree().create_timer(TIEMPO_AGOTARSE).timeout.connect(_on_depletion_delay_timeout)


func _on_explosion_finished() -> void:
	anim_explosion.visible = false


# =====================================================================
# 💀 MINA AGOTADA
# =====================================================================
func _on_depletion_delay_timeout() -> void:
	print("Mina agotada.")

	set_rocas_visibles(rocas_grandes, false)
	set_rocas_visibles(rocas_pequenas, true)

	_set_collision_state(false)

	get_tree().create_timer(TIEMPO_REGENERACION).timeout.connect(_on_regen_timer_timeout)


# =====================================================================
# 🌱 REGENERACIÓN
# =====================================================================
func _on_regen_timer_timeout() -> void:
	print("Mina regenerada.")

	is_depleted = false
	roca_queda = ROCA_INICIAL

	set_rocas_visibles(rocas_pequenas, false)
	set_rocas_visibles(rocas_grandes, true)

	_set_collision_state(true)


# =====================================================================
# 🧱 COLISIONES SEGURAS
# =====================================================================
func _set_collision_state(alive: bool) -> void:
	if alive:
		if collision_full: collision_full.set_deferred("disabled", false)
		if collision_small: collision_small.set_deferred("disabled", true)
	else:
		if collision_full: collision_full.set_deferred("disabled", true)
		if collision_small: collision_small.set_deferred("disabled", false)


# =====================================================================
# 🔧 UTILS
# =====================================================================
func shake_rocas() -> void:
	var tween := create_tween()
	for child in rocas_grandes.get_children():
		if child is Node2D:
			var original : Vector2 = child.position
			tween.tween_property(child, "position:x", original.x + randf() * 4.0 - 2.0, 0.05)
			tween.tween_property(child, "position:x", original.x, 0.05)


func set_rocas_visibles(grupo: Node2D, visible: bool) -> void:
	for child in grupo.get_children():
		if child is Sprite2D:
			child.visible = visible
