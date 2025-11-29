extends Control

signal tiempo_especifico_alcanzado

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var START_TIME := 120.0          # duración total (segundos)
@export var SIGNAL_AT   := 90.0          # segundo en el que se emite la señal
@export var FINAL_WARN  := 15.0          # últimos segundos con advertencia roja
@export var POST_DELAY  := 3.0           # segundos extra antes de cambiar de escena
@export var GRACE_PERIOD := 10.0         # Periodo de cortesía en segundos

# =====================================================================
# 🧾 NODOS PRINCIPALES DEL TIMER
# =====================================================================
@onready var timer_label: Label   = $TimerLabel
@onready var warning_label: Label = $WarningLabel
@onready var main_timer: Timer    = $CountdownTimer

# =====================================================================
# 🚨 NODOS COUNTDOWN Y GRACE PERIOD (RUTAS CORREGIDAS)
# =====================================================================
# El script está en TimerRoot. Las rutas deben ser relativas a él.

# Hijos directos de TimerRoot (o CanvasLayer hijo directo)
@onready var countdown_layer: CanvasLayer = $CuentaAtrasCanvasLayer
@onready var grace_timer: Timer = $GraceTimer

# Hijos de CuentaAtrasCanvasLayer
@onready var countdown_sprite: AnimatedSprite2D = $CuentaAtrasCanvasLayer/Countdown
@onready var ribbon_message: Sprite2D = $CuentaAtrasCanvasLayer/RibbonMessage 
@onready var grace_label: Label = $CuentaAtrasCanvasLayer/GraceLabel 

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var remaining_time: float
var post_timer: Timer
var signal_fired := false
var time_over    := false
var countdown_started := false
var battle_declared_to_me := false 


# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	# --- Inicialización y Ocultamiento de la UI de Aviso ---
	
	# 1. Countdown Sprite
	if is_instance_valid(countdown_sprite):
		countdown_sprite.play("Contador") 
		countdown_sprite.stop()
		countdown_sprite.set_frame(0)
		countdown_sprite.hide()
	
	# 2. Ribbon (Cinta)
	if is_instance_valid(ribbon_message):
		ribbon_message.hide() # Ocultar la cinta
	else:
		push_error("Error: Nodo RibbonMessage no encontrado. Revisar ruta en @onready.")
	
	# 3. Grace Label (Texto)
	if is_instance_valid(grace_label):
		grace_label.hide() # Ocultar el texto
	else:
		push_error("Error: Nodo GraceLabel no encontrado. Revisar ruta en @onready.")
	
	# --- Conexiones de Timers ---
	if is_instance_valid(grace_timer):
		grace_timer.timeout.connect(_on_grace_timer_timeout)
	else:
		push_error("Error: Nodo GraceTimer no encontrado.")
		# Se añade dinámicamente si no existe para asegurar la funcionalidad del timer
		grace_timer = Timer.new()
		grace_timer.one_shot = true
		grace_timer.timeout.connect(_on_grace_timer_timeout)
		add_child(grace_timer)

	# --- Conexión al GameState (el singleton) ---
	if Engine.has_singleton("GameState") and GameState.has_signal("battle_declared_against_player"):
		GameState.battle_declared_against_player.connect(_on_battle_declared_against_player)
	
	GDSync.player_data_changed.connect(_on_player_data_changed)
	remaining_time = START_TIME

	main_timer.timeout.connect(_on_timer_timeout)
	main_timer.start()
	_update_label()

	# Timer post-finalización
	post_timer = Timer.new()
	post_timer.one_shot = true
	post_timer.timeout.connect(_on_post_timer_timeout)
	add_child(post_timer)


# =====================================================================
# 🆕 FUNCIÓN DE RECEPCIÓN DE BATALLA (Punto de entrada)
# =====================================================================
func _on_battle_declared_against_player():
	if battle_declared_to_me: return 
	
	battle_declared_to_me = true
	main_timer.stop() 
	
	print("🚨 Batalla declarada: Iniciando periodo de cortesía de %d segundos." % GRACE_PERIOD)
	
	# 1. Mostrar mensaje de cortesía (Ribbon y Label)
	if is_instance_valid(ribbon_message):
		ribbon_message.show()
	
	if is_instance_valid(grace_label):
		grace_label.text = "¡BATALLA DECLARADA!\nTermina de construir tu ejercito."
		grace_label.show()
		
	# 2. Iniciar el timer de cortesía
	if is_instance_valid(grace_timer):
		grace_timer.start(GRACE_PERIOD)
	else:
		# En caso de que el timer falle, saltamos al countdown
		push_error("GraceTimer no es válido, saltando a countdown final.")
		_start_final_countdown()


# =====================================================================
# ⏰ FIN DEL PERIODO DE CORTESÍA (10s)
# =====================================================================
func _on_grace_timer_timeout():
	# 1. Ocultar la UI de cortesía
	if is_instance_valid(ribbon_message):
		ribbon_message.hide()
	if is_instance_valid(grace_label):
		grace_label.hide()
		
	print("⏳ Periodo de cortesía terminado. Iniciando countdown final...")
	
	# 2. Iniciar el Countdown de 3, 2, 1
	_start_final_countdown()


# =====================================================================
# 🔁 BUCLE PRINCIPAL (Solo para el contador principal)
# =====================================================================
func _on_timer_timeout() -> void:
	if time_over or battle_declared_to_me: return 

	remaining_time -= 1.0
	if remaining_time <= 0:
		remaining_time = 0
		main_timer.stop()
		time_over = true
		
		# Cuando el tiempo general termina (no por declaración), iniciamos el countdown
		_start_final_countdown()

	_update_label()

	# Señal configurable
	if not signal_fired and remaining_time <= SIGNAL_AT:
		print("TimerRoot: llegamos a %d s — emitiendo señal" % SIGNAL_AT)
		tiempo_especifico_alcanzado.emit()
		signal_fired = true

# =====================================================================
# ⚔️ COUNTDOWN Y SALTO DE ESCENA (UNIFICADO)
# =====================================================================
func _start_final_countdown():
	# 1. Iniciar el countdown animado (3, 2, 1)
	if POST_DELAY >= 3.0 and is_instance_valid(countdown_sprite): 
		_start_countdown_animation()
	
	# 2. Iniciar el timer que realmente espera los 3 segundos y cambia de escena
	post_timer.start(POST_DELAY)
	print("Esperando %d s antes de la batalla..." % POST_DELAY)


func _start_countdown_animation() -> void:
	if countdown_started: return 
	
	countdown_started = true
	
	# Asegurar posición central (fija en la pantalla)
	countdown_sprite.global_position = get_viewport().size / 2
	
	# Configurar y mostrar el sprite
	countdown_sprite.set_frame(0) 
	countdown_sprite.show()
	
	# Reproducir la animación (Asumimos que "Contador" es 1 FPS y no hace loop)
	countdown_sprite.play("Contador") 

# =====================================================================
# 🚪 CAMBIO DE ESCENA
# =====================================================================
func _on_post_timer_timeout() -> void:
	# Ocultamos el countdown antes de cambiar de escena
	if is_instance_valid(countdown_sprite):
		countdown_sprite.hide()
	
	print("⚔️ Iniciando batalla automáticamente...")
	get_tree().change_scene_to_file("res://src/PantallaAtaque/campoBatalla.tscn")

# =====================================================================
# 🖥️ ACTUALIZACIÓN UI Y MULTIJUGADOR
# =====================================================================
func _update_label() -> void:
	var minutes : int = floori(remaining_time / 60.0)
	var seconds : int = (int) (remaining_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

	# Colores y advertencias
	if not battle_declared_to_me: # Solo actualizamos si la batalla NO ha sido declarada
		if remaining_time <= FINAL_WARN:
			timer_label.modulate    = Color.RED
			warning_label.modulate = Color.RED
			warning_label.text      = "¡Llega la última batalla!"
			warning_label.visible  = true
			if (remaining_time == FINAL_WARN):
				GDSync.player_set_data("set_to_FINAL_WARN", true)
		elif remaining_time <= SIGNAL_AT:
			timer_label.modulate    = Color.GREEN
			warning_label.visible  = false
		else:
			timer_label.modulate    = Color.WHITE
			warning_label.text      = "No puedes atacar."
			warning_label.visible  = true
	else:
		# Cuando la batalla ha sido declarada, ocultamos la advertencia normal
		warning_label.visible = false 

func _on_player_data_changed(client_id : int, key : String, value):
	if client_id != GDSync.get_client_id() : 
		print("Recibido de %d: %s = %s" % [client_id, key, str(value)])
		print("Sincronizando timers.")
		if key == "set_to_FINAL_WARN" :
			remaining_time = min(remaining_time, FINAL_WARN)
			
		# Nota: La recepción real de la señal de ataque se maneja en GameState.gd
		# y luego se propaga a este script a través de GameState.battle_declared_against_player.
