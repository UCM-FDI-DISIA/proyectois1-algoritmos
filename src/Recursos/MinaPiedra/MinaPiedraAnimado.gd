extends StaticBody2D
class_name MinaPiedraAnimado

# =====================================================================
# 🧾 NODOS
# =====================================================================
@onready var anim_explosion: AnimatedSprite2D = $AnimacionExplosion
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var rocas_grandes: Node2D = $BigRocksContainer
@onready var rocas_pequenas: Node2D = $SmallRocksContainer

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var cell_size: Vector2 = Vector2(168, 58)
@export var ROCA_INICIAL: int = 3
@export var PIEDRA_POR_GOLPE: int = 3
@export var TIEMPO_REGENERACION: float = 30.0
@export var TIEMPO_AGOTARSE: float = 0.4

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var is_depleted: bool = false
var roca_queda: int = ROCA_INICIAL

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = cell_size

	collision_shape.set_deferred("disabled", false)
	z_index = int(position.y)

	set_rocas_visibles(rocas_grandes, true)
	set_rocas_visibles(rocas_pequenas, false)
	anim_explosion.visible = false

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

	# Conexión única de animación
	anim_explosion.animation_finished.connect(_on_explosion_finished)

# =====================================================================
# ⚔️ RECOLECCIÓN
# =====================================================================
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
	var manager := get_node("/root/Main/ResourceManager") as ResourceManager
	if manager:
		manager.add_resource("stone", PIEDRA_POR_GOLPE)
		print("Piedra añadida: +%d" % PIEDRA_POR_GOLPE)

	if roca_queda <= 0:
		is_depleted = true
		$Timer.new().create_timer(TIEMPO_AGOTARSE).timeout.connect(_on_depletion_delay_timeout)

func _on_explosion_finished() -> void:
	anim_explosion.visible = false

func _on_depletion_delay_timeout() -> void:
	print("Mina de roca agotada.")
	set_rocas_visibles(rocas_grandes, false)
	set_rocas_visibles(rocas_pequenas, true)
	collision_shape.set_deferred("disabled", true)
	print("Regenerando en %.1f seg..." % TIEMPO_REGENERACION)
	$Timer.new().create_timer(TIEMPO_REGENERACION).timeout.connect(_on_regen_timer_timeout)

func shake_rocas() -> void:
	var tween := create_tween()
	for child in rocas_grandes.get_children():
		if child is Node2D:
			var original := child.position
			tween.tween_property(child, "position:x", original.x + randf() * 4.0 - 2.0, 0.05)
			tween.tween_property(child, "position:x", original.x, 0.05)

func _on_regen_timer_timeout() -> void:
	print("Mina de roca regenerada.")
	is_depleted = false
	roca_queda = ROCA_INICIAL
	set_rocas_visibles(rocas_pequenas, false)
	set_rocas_visibles(rocas_grandes, true)
	collision_shape.set_deferred("disabled", false)

func set_rocas_visibles(grupo: Node2D, visible: bool) -> void:
	for child in grupo.get_children():
		if child is Sprite2D:
			child.visible = visible
