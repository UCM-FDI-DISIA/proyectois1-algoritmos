extends Control

signal tiempo_especifico_alcanzado

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var START_TIME := 120.0         # duración total (segundos)
@export var SIGNAL_AT   := 90.0         # segundo en el que se emite la señal
@export var FINAL_WARN  := 15.0          # últimos segundos con advertencia roja
@export var POST_DELAY  := 3.0          # segundos extra antes de cambiar de escena

# =====================================================================
# 🧾 NODOS
# =====================================================================
@onready var timer_label: Label   = $TimerLabel
@onready var warning_label: Label = $WarningLabel
@onready var main_timer: Timer    = $CountdownTimer

# =====================================================================
# 🚨 NUEVOS NODOS PARA EL COUNTDOWN (CORREGIDO EL NOMBRE DEL CANVASLAYER)
# =====================================================================
# ASUMIENDO LA RUTA: Control -> CuentaAtrasCanvasLayer -> Countdown
@onready var countdown_layer: CanvasLayer = $CuentaAtrasCanvasLayer
@onready var countdown_sprite: AnimatedSprite2D = $CuentaAtrasCanvasLayer/Countdown

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var remaining_time: float
var post_timer: Timer
var signal_fired := false
var time_over    := false
var countdown_started := false # Bandera para evitar repetir el countdown

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	# OCULTAR: Añadimos chequeo para evitar error si no encuentra el nodo en el editor
	if is_instance_valid(countdown_sprite):
		# 1. Aseguramos que la animación inicial está cargada, aunque esté oculto.
		countdown_sprite.play("Contador") 
		countdown_sprite.stop()
		countdown_sprite.set_frame(0) # Forzamos al frame '3' (asumiendo que es el frame 0)
		countdown_sprite.hide()
	else:
		push_error("Error de instancia: No se pudo ocultar el Countdown. La ruta es incorrecta.")
		
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
# 🔁 BUCLE PRINCIPAL
# =====================================================================
func _on_timer_timeout() -> void:
	if time_over: return

	remaining_time -= 1.0
	if remaining_time <= 0:
		remaining_time = 0
		main_timer.stop()
		time_over = true
		
		# =====================================================
		# 💥 ACTIVACIÓN DEL COUNTDOWN ANTES DE LA BATALLA
		# =====================================================
		# Solo iniciar el contador animado si el nodo existe y hay 3s de retraso
		if POST_DELAY >= 3.0 and is_instance_valid(countdown_sprite): 
			_start_countdown_animation()
			print("⏰ Tiempo terminado — iniciando countdown...")
		else:
			print("⏰ Tiempo terminado — sin countdown animado o POST_DELAY insuficiente.")
		# =====================================================
		
		post_timer.start(POST_DELAY)
		print("Esperando %d s antes de la batalla..." % POST_DELAY)

	_update_label()

	# Señal configurable
	if not signal_fired and remaining_time <= SIGNAL_AT:
		print("TimerRoot: llegamos a %d s — emitiendo señal" % SIGNAL_AT)
		tiempo_especifico_alcanzado.emit()
		signal_fired = true

# =====================================================================
# ⚔️ COUNTDOWN ANIMADO
# =====================================================================

func _start_countdown_animation() -> void:
	# Ya verificamos que el sprite es válido en _on_timer_timeout
	if countdown_started: return 
	
	countdown_started = true
	
	# Asegurar posición central (si no se hizo en el editor)
	countdown_sprite.global_position = get_viewport().size / 2
	
	# 1. Configurar y mostrar el sprite
	countdown_sprite.set_frame(0) # Volvemos a forzar el '3' (frame 0)
	countdown_sprite.show()
	
	# 2. Reproducir la animación (Asumimos que "contador" es 1 FPS y no hace loop)
	countdown_sprite.play("Contador") 

# =====================================================================
# 🚪 CAMBIO DE ESCENA
# =====================================================================
func _on_post_timer_timeout() -> void:
	# SOLUCIÓN: Añadimos el chequeo de instancia para evitar el error de 'null'
	if is_instance_valid(countdown_sprite):
		countdown_sprite.hide()
	else:
		# Este error solo se vería si la ruta está mal, pero no detiene el juego
		push_error("Error de instancia: No se pudo ocultar el Countdown. La ruta es incorrecta.")
	
	print("⚔️ Iniciando batalla automáticamente...")
	get_tree().change_scene_to_file("res://src/PantallaAtaque/campoBatalla.tscn")

# =====================================================================
# 🖥️ ACTUALIZACIÓN UI
# =====================================================================
func _update_label() -> void:
	var minutes : int = floori(remaining_time / 60.0)
	var seconds : int = (int) (remaining_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

	# Colores y advertencias
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

func _on_player_data_changed(client_id : int, key : String, value):
	if client_id != GDSync.get_client_id() : 
		print("Recibido de %d: %s = %s" % [client_id, key, str(value)])
		print("Sincronizando timers.")
		if key == "set_to_FINAL_WARN" :
			remaining_time = min(remaining_time, FINAL_WARN)
