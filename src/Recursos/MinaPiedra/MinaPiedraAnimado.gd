extends StaticBody2D
class_name MinaPiedraAnimado

# =====================
# NODOS
# =====================
var anim_explosion : AnimatedSprite2D
var collision_shape : CollisionShape2D
var rocas_grandes : Node2D
var rocas_pequenas : Node2D
var regen_timer : Timer
var depletion_delay_timer : Timer

# =====================
# ESTADO
# =====================
var is_depleted := false
var roca_queda := 3
const ROCA := 3
const ROCA_INICIAL := 3
const TIEMPO_REGENERACION := 30.0
const TIEMPO_AGOTARSE := 0.4

@export var cell_size := Vector2(168, 58)

func _ready() -> void:
	rocas_grandes = $BigRocksContainer
	rocas_pequenas = $SmallRocksContainer
	anim_explosion = $AnimacionExplosion
	collision_shape = $CollisionShape2D

	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = cell_size

	collision_shape.disabled = false
	z_index = int(position.y)

	set_rocas_visibles(rocas_grandes, true)
	set_rocas_visibles(rocas_pequenas, false)
	anim_explosion.visible = false

	# Timer de regeneración
	regen_timer = Timer.new()
	regen_timer.wait_time = TIEMPO_REGENERACION
	regen_timer.one_shot = true
	regen_timer.timeout.connect(_on_regen_timer_timeout)
	add_child(regen_timer)

	# Timer de retraso tras agotarse
	depletion_delay_timer = Timer.new()
	depletion_delay_timer.wait_time = TIEMPO_AGOTARSE
	depletion_delay_timer.one_shot = true
	depletion_delay_timer.timeout.connect(_on_depletion_delay_timeout)
	add_child(depletion_delay_timer)

	# Conexión única de animación
	anim_explosion.animation_finished.connect(_on_explosion_finished)

# =====================
# RECOLECCIÓN DE PIEDRA
# =====================
func hit() -> void:
	if is_depleted:
		return

	roca_queda -= 1
	print("Roca golpeada. Rocas restantes: %d" % roca_queda)

	# Efectos visuales
	shake_rocas()
	anim_explosion.visible = true
	anim_explosion.play("Collect")

	# Añadir recurso
	var manager = get_node("/root/Main/ResourceManager")
	manager.add_resource("stone", ROCA)
	print("Piedra añadida: +3")

	# Si se agotó la roca
	if roca_queda <= 0:
		is_depleted = true
		depletion_delay_timer.start()

func _on_explosion_finished() -> void:
	anim_explosion.visible = false

func _on_depletion_delay_timeout() -> void:
	print("Mina de roca agotada.")
	set_rocas_visibles(rocas_grandes, false)
	set_rocas_visibles(rocas_pequenas, true)

	if collision_shape != null:
		collision_shape.disabled = true

	print("Regenerando en 30 segundos...")
	regen_timer.start()

func shake_rocas() -> void:
	var tween = create_tween()
	for child in rocas_grandes.get_children():
		if child is Node2D:
			var original = child.position
			tween.tween_property(child, "position:x", original.x + randf() * 4.0 - 2.0, 0.05)
			tween.tween_property(child, "position:x", original.x, 0.05)

func _on_regen_timer_timeout() -> void:
	print("Mina de roca regenerada.")
	is_depleted = false
	roca_queda = ROCA_INICIAL

	set_rocas_visibles(rocas_pequenas, false)
	set_rocas_visibles(rocas_grandes, true)

	if collision_shape != null:
		collision_shape.disabled = false

func set_rocas_visibles(grupo: Node2D, visible: bool) -> void:
	for child in grupo.get_children():
		if child is Sprite2D:
			child.visible = visible
