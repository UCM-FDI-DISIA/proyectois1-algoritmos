extends StaticBody2D
class_name ArbolAnimado

signal depleted

# ============================================================
# 🔧 Estados de ocupación
# ============================================================
var is_occupied: bool = false
var occupying_lenador: Node = null
var regeneration_timer: Timer 

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
@export var GOLPES_PARA_TALAR: int = 3 # NUEVA: Golpes necesarios del jugador
@export var TIEMPO_REGENERACION: float = 30.0 # 30 segundos de espera
@export var TIEMPO_MORIR: float = 0.1

var is_dead: bool = false
var madera_queda: int = MADERA_INICIAL
var player_hits_count: int = 0 # NUEVA: Contador de golpes del jugador

# ============================================================
# 🚀 READY
# ============================================================
func _ready() -> void:
	add_to_group("arbol") 
	
	# Inicializar el temporizador de regeneración para el NPC
	regeneration_timer = Timer.new()
	add_child(regeneration_timer)
	regeneration_timer.one_shot = true
	regeneration_timer.timeout.connect(_on_regen_timer_timeout)
	anim.animation_finished.connect(_on_npc_chop_finished)

	collision_full.disabled = false
	collision_stump.disabled = true

	anim.play("Idle")

# ============================================================
# ⚔️ Golpe de JUGADOR (clic con el ratón)
# ============================================================
func hit() -> void:
	if is_dead:
		return

	player_hits_count += 1
	anim.play("chop")
	anim_tronco.play("tronquito") 
	anim.animation_finished.connect(_on_player_anim_finished, CONNECT_ONE_SHOT)

func _on_player_anim_finished():
	var manager := get_node("/root/Main/ResourceManager")

	if player_hits_count >= GOLPES_PARA_TALAR:
		# Muerte del árbol causada por el jugador
		is_dead = true
		emit_signal("depleted") 
		
		# Añadir la madera total del árbol por el golpe final
		if manager:
			manager.add_resource("wood", MADERA_INICIAL) # Asume que el jugador obtiene toda la madera restante.
			
		get_tree().create_timer(TIEMPO_MORIR).timeout.connect(_on_death_delay_timeout)
	else:
		# Añadir la madera parcial por el golpe
		if manager:
			manager.add_resource("wood", MADERA_POR_GOLPE)

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
		
		anim_tronco.play("tronquito") 

		anim.play("chop")

	# El NPC no marca el árbol como muerto, solo lo agota gradualmente.
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
	
	# 1. Señal para detener inmediatamente al leñador
	emit_signal("depleted") 

	# 2. Animación de muerte
	anim.play("Die")

	# 3. Colisiones de tocón
	collision_full.set_deferred("disabled", true)
	collision_stump.set_deferred("disabled", false)

	# 4. Liberar ocupación
	release()

	# 5. Iniciar el temporizador de 30 segundos
	regeneration_timer.start(TIEMPO_REGENERACION)
	print("Árbol regenerándose. Tiempo: ", TIEMPO_REGENERACION, " segundos.")

# ============================================================
# 💀 Muerte + regeneración
# ============================================================
func _on_death_delay_timeout():
	# Lógica del jugador (usa un temporizador diferente al NPC)
	anim.play("Die")

	collision_full.set_deferred("disabled", true)
	collision_stump.set_deferred("disabled", false)

	# Usar el temporizador interno del nodo para no depender del get_tree()
	regeneration_timer.start(TIEMPO_REGENERACION)


func _on_regen_timer_timeout():
	# Esta función se llama tras los 30 segundos (TIEMPO_REGENERACION)
	
	# 1. Regenerar el árbol
	is_dead = false
	madera_queda = MADERA_INICIAL
	player_hits_count = 0 # Reiniciar el contador de golpes del jugador

	# 2. Volver al estado Idle
	anim.play("Idle")

	# 3. Restaurar colisiones
	collision_full.set_deferred("disabled", false)
	collision_stump.set_deferred("disabled", true)
	
	print("Árbol regenerado, listo para ser talado de nuevo.")
