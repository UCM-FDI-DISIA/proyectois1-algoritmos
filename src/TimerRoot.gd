extends Control

signal tiempo_especifico_alcanzado

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var START_TIME := 120.0          # duración total (segundos)
@export var SIGNAL_AT   := 90.0          # segundo en el que se emite la señal
@export var FINAL_WARN  := 15.0          # últimos segundos con advertencia roja
@export var POST_DELAY  := 3.0           # Tiempo que dura el mensaje ANTES del cambio de escena.
@export var GRACE_PERIOD := 0.0          # No se usa.

# =====================================================================
# 🧾 NODOS PRINCIPALES DEL TIMER
# =====================================================================
@onready var timer_label: Label   = $TimerLabel
@onready var warning_label: Label = $WarningLabel
@onready var main_timer: Timer    = $CountdownTimer

# =====================================================================
# 🚨 NODOS COUNTDOWN Y GRACE PERIOD (CRÍTICO: REVISAR RUTAS)
# =====================================================================
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
var battle_declared_to_me := false 


# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	
	# --- Inicialización y Ocultamiento de la UI de Aviso ---
	if is_instance_valid(countdown_sprite):
		countdown_sprite.hide() # Ocultamos la animación de 3, 2, 1.
	
	if is_instance_valid(ribbon_message):
		ribbon_message.hide()
	
	if is_instance_valid(grace_label):
		grace_label.hide()
	
	# --- Conexión al GameState (el singleton) ---
	if Engine.has_singleton("GameState") and GameState.has_signal("battle_declared_against_player"):
		GameState.battle_declared_against_player.connect(_on_battle_declared_against_player)
	
	GDSync.player_data_changed.connect(_on_player_data_changed)
	remaining_time = START_TIME

	main_timer.timeout.connect(_on_timer_timeout)
	main_timer.start()
	_update_label()

	# Timer post-finalización (espera los 3 segundos)
	post_timer = Timer.new()
	post_timer.one_shot = true
	post_timer.timeout.connect(_on_post_timer_timeout)
	add_child(post_timer)


# =====================================================================
# 🆕 FUNCIÓN DE RECEPCIÓN DE BATALLA (Punto de entrada: DEFENSOR)
# =====================================================================
func _on_battle_declared_against_player():
	if battle_declared_to_me: return 
	
	battle_declared_to_me = true
	main_timer.stop() # Congela el reloj de tiempo recolectado
	
	print("🚨 DEFENSOR: ¡Batalla declarada! Mostrando aviso por %d segundos." % POST_DELAY)
	
	# 1. Mostrar mensaje de aviso (Ribbon y Label)
	if is_instance_valid(ribbon_message) and is_instance_valid(grace_label):
		grace_label.text = "¡ALERTA! ¡ESTÁS SIENDO ATACADO!"
		ribbon_message.show()
		grace_label.show()
	
	# 2. Iniciar la espera de 3 segundos
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
		
		# Si el tiempo se acaba, también vamos a la batalla (3 segundos de aviso visual)
		_start_final_countdown()

	_update_label()

	if not signal_fired and remaining_time <= SIGNAL_AT:
		tiempo_especifico_alcanzado.emit()
		signal_fired = true


# =====================================================================
# ⚔️ AVISO DE 3s Y SALTO DE ESCENA (UNIFICADO)
# =====================================================================
func _start_final_countdown():
	# Ocultar la UI de aviso si no está siendo usada por la declaración de batalla
	if not battle_declared_to_me: 
		if is_instance_valid(ribbon_message):
			ribbon_message.hide()
		if is_instance_valid(grace_label):
			grace_label.hide()
		
	# Aseguramos que el sprite de countdown no se vea
	if is_instance_valid(countdown_sprite): 
		countdown_sprite.hide()
		
	# Iniciar el timer que realmente espera los 3 segundos y cambia de escena
	post_timer.start(POST_DELAY)
	print("Esperando %d s antes de la batalla (POST_DELAY)..." % POST_DELAY)


# =====================================================================
# 🚪 CAMBIO DE ESCENA (FIN DEL JUEGO PARA EL DEFENSOR)
# =====================================================================
func _on_post_timer_timeout() -> void:
	# Ocultamos todos los elementos de aviso antes de saltar
	if is_instance_valid(countdown_sprite):
		countdown_sprite.hide()
	if is_instance_valid(ribbon_message):
		ribbon_message.hide()
	if is_instance_valid(grace_label):
		grace_label.hide()
	
	print("⚔️ Iniciando batalla automáticamente...")
	
	# 🚨 CORRECCIÓN: Usamos el gestor de escenas personalizado (SceneManager) si está disponible, 
	# ya que es la forma recomendada cuando tienes transiciones.
	if Engine.has_singleton("SceneManager"):
		SceneManager.change_scene("res://src/PantallaAtaque/campoBatalla.tscn")
	else:
		# Fallback al método nativo
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
			warning_label.text     = "¡Llega la última batalla!"
			warning_label.visible  = true
			if (remaining_time == FINAL_WARN):
				GDSync.player_set_data("set_to_FINAL_WARN", true)
		elif remaining_time <= SIGNAL_AT:
			timer_label.modulate    = Color.GREEN
			warning_label.visible  = false
		else:
			timer_label.modulate    = Color.WHITE
			warning_label.text     = "No puedes atacar."
			warning_label.visible  = true
	else:
		# Cuando la batalla ha sido declarada, ocultamos la advertencia normal
		warning_label.visible = false 

func _on_player_data_changed(client_id : int, key : String, _value):
	if client_id != GDSync.get_client_id() : 
		if key == "set_to_FINAL_WARN" :
			remaining_time = min(remaining_time, FINAL_WARN)
