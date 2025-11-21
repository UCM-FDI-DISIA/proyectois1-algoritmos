extends StaticBody2D
class_name ArbolAnimado

# ============================================================
# ⚙️ SEÑALES NUEVAS
# ============================================================
signal depleted

# ============================================================
# 🧩 NODOS (Sin cambios)
# ============================================================
@onready var anim: AnimatedSprite2D = $AnimacionArbol
@onready var anim_tronco: AnimatedSprite2D = $AnimacionTronco

@onready var collision_full: CollisionShape2D = $CollisionShape2D
@onready var collision_stump: CollisionShape2D = $CollisionShapeChop

# ============================================================
# 🔧 VARIABLES EXPORTADAS (Sin cambios)
# ============================================================
@export var cell_size: Vector2 = Vector2(64, 64)
@export var MADERA_INICIAL: int = 3
@export var MADERA_POR_GOLPE: int = 5
@export var TIEMPO_REGENERACION: float = 30.0
@export var TIEMPO_MORIR: float = 0.01

var is_dead: bool = false
var madera_queda: int = MADERA_INICIAL

# ============================================================
# 🚀 READY (Añadido: Grupo)
# ============================================================
func _ready() -> void:
	# 💡 NECESARIO PARA QUE EL LEÑADOR LO ENCUENTRE
	add_to_group("arbol") 
	
	# activar colisión completa, desactivar colisión del tronco
	collision_full.disabled = false
	collision_stump.disabled = true

	anim.play("Idle")


# ============================================================
# ⚔️ RECOLECCIÓN (Funciones originales para interacción con el jugador/mouse)
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
		# 💡 EMITIR SEÑAL DE AGOTAMIENTO AQUÍ PARA QUE EL JUGADOR SE DÉ CUENTA INMEDIATAMENTE
		emit_signal("depleted")
		get_tree().create_timer(TIEMPO_MORIR).timeout.connect(_on_death_delay_timeout)
	else:
		anim.play("Idle")


# ============================================================
# ⛏️ RECOLECCIÓN (Función para la lógica del NPC Lenador)
# ============================================================
# Función llamada por el Lenador para extraer recursos.
func gather_resource(amount: int) -> int:
	if is_dead:
		return 0

	# 1. Calcular la madera a recolectar realmente
	var actual_gathered = min(amount, madera_queda)
	
	if actual_gathered > 0:
		madera_queda -= actual_gathered
		print("Árbol siendo talado por NPC. Madera restante: %d" % madera_queda)
		
		# 2. Iniciar animación de "chop" (asumimos que la animación es corta o se cicla en el NPC)
		# Nota: Podrías querer una animación de 'chop' que no interrumpa al NPC o solo sea visual.
		anim.play("chop")
		anim.animation_finished.connect(_on_npc_chop_finished, CONNECT_ONE_SHOT)
		
		# 3. Verificar agotamiento
		if madera_queda <= 0:
			is_dead = true
			# 💡 CRÍTICO: Emitir señal de agotamiento para que el leñador busque otro árbol
			emit_signal("depleted") 
			get_tree().create_timer(TIEMPO_MORIR).timeout.connect(_on_death_delay_timeout)
			
		return actual_gathered
	
	return 0

# Se desconecta la animación del NPC después de cada golpe.
func _on_npc_chop_finished():
	if not is_dead:
		anim.play("Idle")


# ============================================================
# 💀 ÁRBOL TALADO (Sin cambios)
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
# 🌱 REGENERACIÓN (Sin cambios)
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
