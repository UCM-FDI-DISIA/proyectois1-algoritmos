extends Control

signal tiempo_especifico_alcanzado

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var START_TIME := 120.0        # duración total (segundos)
@export var SIGNAL_AT  := 90.0        # segundo en el que se emite la señal
@export var FINAL_WARN := 15.0        # últimos segundos con advertencia roja
@export var POST_DELAY := 3.0          # Tiempo que dura la animación (3s)

# =====================================================================
# 🧾 NODOS PRINCIPALES DEL TIMER
# =====================================================================
@onready var timer_label: Label     = $TimerLabel
@onready var warning_label: Label = $WarningLabel
@onready var main_timer: Timer      = $CountdownTimer

# =====================================================================
# 🚨 NODOS COUNTDOWN Y GRACE PERIOD
# =====================================================================
@onready var countdown_layer: CanvasLayer = $CuentaAtrasCanvasLayer
@onready var notification_layer: CanvasLayer = $NotificacionAtaqueCanvasLayer # Referencia a la capa padre de las etiquetas
@onready var ribbon_message: Sprite2D = $NotificacionAtaqueCanvasLayer/RibbonMessage
@onready var grace_label: Label = $NotificacionAtaqueCanvasLayer/GraceLabel
@onready var countdown_sprite: AnimatedSprite2D = $CuentaAtrasCanvasLayer/Countdown


# =====================================================================
# 🎮 ESTADO
# =====================================================================
var remaining_time: float
var signal_fired := false
var time_over    := false
var battle_declared_to_me := false # True si el ataque es contra mí o yo he atacado


# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	print("DEBUG: 1. Countdown.gd _ready() iniciado.") # DEBUG
	
	# --- Inicialización y Ocultamiento de la UI de Aviso ---
	if is_instance_valid(countdown_sprite):
		countdown_sprite.hide()
	
	if is_instance_valid(ribbon_message):
		ribbon_message.hide()
	
	if is_instance_valid(grace_label):
		grace_label.hide()
	
	# Asegurarse de que las capas CanvasLayer están ocultas al inicio.
	if is_instance_valid(countdown_layer):
		countdown_layer.hide()
	if is_instance_valid(notification_layer):
		notification_layer.hide()
	
	# --- Conexión al GameState (el singleton) ---
	# CORRECCIÓN: Accedemos directamente al nodo Autoload a través de la raíz del árbol.
	var gs_node = get_tree().root.get_node_or_null("GameState")
	
	if gs_node != null:
		print("DEBUG: 2. Singleton GameState encontrado (vía get_node).") # DEBUG
		
		# Usamos la referencia del nodo para la conexión.
		if gs_node.has_signal("start_battle_countdown"):
			gs_node.start_battle_countdown.connect(_on_battle_countdown_started)
			print("DEBUG: 3. Señal 'start_battle_countdown' conectada correctamente.") # DEBUG
		else:
			print("ERROR: La señal 'start_battle_countdown' NO existe en GameState (verificar la definición en GameState.gd).") # DEBUG
	else:
		# Mantenemos el mensaje de error para que verifique el Autoload
		print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		print("ERROR CRÍTICO: El nodo 'GameState' NO se ha encontrado en la raíz del árbol.")
		print("ACCIÓN REQUERIDA: Vuelve a verificar la configuración de 'Autoload' para:")
		print("1. RUTA: Que apunte a 'GameState.gd'.")
		print("2. NOMBRE: Que el nombre sea exactamente 'GameState' (distingue mayúsculas).")
		print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
		
	
	GDSync.player_data_changed.connect(_on_player_data_changed)
	
	remaining_time = START_TIME

	main_timer.timeout.connect(_on_timer_timeout)
	main_timer.start()
	_update_label()


# =====================================================================
# 🆕 FUNCIÓN DE RECEPCIÓN DE BATALLA (Inicia la UI de 3s)
# =====================================================================
func _on_battle_countdown_started(is_attacker: bool):
	print("DEBUG: 4. Función _on_battle_countdown_started llamada. (¡Se recibió la señal!)") # DEBUG
	if battle_declared_to_me: 
		print("DEBUG: Batalla ya declarada, ignorando llamada repetida.") # DEBUG
		return  
	
	battle_declared_to_me = true
	main_timer.stop() # Congela el reloj

	print("🚨 COUNTDOWN UI: Iniciando animación y mostrando etiquetas.")
	
	# Mostrar la capa de notificación.
	if is_instance_valid(notification_layer):
		notification_layer.show()
	
	# 1. Mostrar mensaje y Ribbon
	if is_instance_valid(ribbon_message) and is_instance_valid(grace_label):
		if is_attacker:
			grace_label.text = "ATACANDO..."
		else:
			grace_label.text = "¡ALERTA! SIENDO ATACADO..."
			
		ribbon_message.show()
		grace_label.show()
	
	# 2. Iniciar la animación de la cuenta atrás
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
		
		# NOTA: En este caso, si el tiempo se acaba, el GameState debería forzar
		# la señal de cambio y el delay, si es que el tiempo agotado fuerza la batalla.
		
	_update_label()

	if not signal_fired and remaining_time <= SIGNAL_AT:
		tiempo_especifico_alcanzado.emit()
		signal_fired = true


# =====================================================================
# ⚔️ AVISO DE 3s Y ANIMACIÓN (SIN CAMBIO DE ESCENA AQUÍ)
# =====================================================================
func _start_final_countdown():
	print("DEBUG: 5. Función _start_final_countdown llamada.") # DEBUG
	# Mostrar la capa de cuenta atrás.
	if is_instance_valid(countdown_layer):
		countdown_layer.show()
		
	# Asegurar que los elementos de aviso sean visibles 
	if is_instance_valid(ribbon_message):
		ribbon_message.show()
	if is_instance_valid(grace_label):
		grace_label.show()
	
	# Mostrar y reproducir el sprite de la cuenta atrás
	if is_instance_valid(countdown_sprite): 
		countdown_sprite.show()
		countdown_sprite.play("Contador") # Inicia la animación 3, 2, 1
		print("DEBUG: 6. Sprite de cuenta atrás mostrado y 'Contador' animado iniciado.") # DEBUG
	else:
		print("ERROR: 'countdown_sprite' NO es válido (Comprueba la ruta del nodo).") # DEBUG
		
	# El GameState es quien tiene el delay y cambia la escena.
	# Esta función solo se preocupa por la interfaz.


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

func _on_player_data_changed(client_id : int, key : String, value):
	if client_id != GDSync.get_client_id() : 
		if key == "set_to_FINAL_WARN" :
			remaining_time = min(remaining_time, FINAL_WARN)
