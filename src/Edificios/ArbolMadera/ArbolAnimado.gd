extends StaticBody2D
class_name ArbolAnimado

signal depleted

# ============================================================
# 🔧 Estados de ocupación (para evitar 2 leñadores en un árbol)
# ============================================================
var is_occupied: bool = false
var occupying_lenador: Node = null
var regeneration_timer: Timer # Nodo para el temporizador de 30s

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
@export var TIEMPO_REGENERACION: float = 30.0 # 30 segundos de espera
@export var TIEMPO_MORIR: float = 0.1

var is_dead: bool = false
var madera_queda: int = MADERA_INICIAL

# ============================================================
# 🚀 READY
# ============================================================
func _ready() -> void:
	add_to_group("arbol") 
	
	# Inicializar el temporizador de regeneración
	regeneration_timer = Timer.new()
	add_child(regeneration_timer)
	regeneration_timer.one_shot = true
	regeneration_timer.timeout.connect(_on_regen_timer_timeout)

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

	var gathered: int = min(amount, madera_queda) 

	if gathered > 0:
		madera_queda -= gathered
		anim.play("chop")
		anim.animation_finished.connect(_on_npc_chop_finished, CONNECT_ONE_SHOT)

	# **CORRECCIÓN CLAVE:** NO emitimos 'depleted' ni marcamos is_dead aquí 
	# para el NPC, porque queremos que termine los 3 golpes antes de morir.
	# La disminución de madera se registra, pero la muerte la decide fell().

	return gathered


func _on_npc_chop_finished():
	# Si la madera se agotó, la animación se quedará en el último golpe (chop)
	# hasta que 'fell' active la animación "Die".
	if not is_dead:
		anim.play("Idle")

# ============================================================
# 💀 Talado FINAL por el leñador
# ============================================================
func fell():
	if is_dead:
		return

	is_dead = true
	
	# 1. Señal para detener inmediatamente al leñador
	emit_signal("depleted") 

	# 2. Animación de muerte
	anim.play("Die")

	# 3. Colisiones de tocón
	collision_full.set_deferred("disabled", true)
	collision_stump.set_deferred("disabled", false)

	# 4. Liberar ocupación
	release()

	# 5. **CORRECCIÓN CLAVE:** Iniciar el temporizador de 30 segundos
	regeneration_timer.start(TIEMPO_REGENERACION)
	print("Árbol regenerándose. Tiempo: ", TIEMPO_REGENERACION, " segundos.")

# ============================================================
# 💀 Muerte + regeneración
# ============================================================
func _on_death_delay_timeout():
	# Lógica del jugador, que sigue usando el temporizador simple
	anim.play("Die")

	collision_full.set_deferred("disabled", true)
	collision_stump.set_deferred("disabled", false)

	get_tree().create_timer(TIEMPO_REGENERACION).timeout.connect(_on_regen_timer_timeout)

func _on_regen_timer_timeout():
	# 1. Regenerar el árbol
	is_dead = false
	madera_queda = MADERA_INICIAL

	# 2. Volver al estado Idle (esto es lo que el leñador busca al buscar un árbol no 'is_dead')
	anim.play("Idle")

	# 3. Restaurar colisiones
	collision_full.set_deferred("disabled", false)
	collision_stump.set_deferred("disabled", true)
	
	print("Árbol regenerado, listo para ser talado de nuevo.")
