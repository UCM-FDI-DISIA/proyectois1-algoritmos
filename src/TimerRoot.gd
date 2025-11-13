extends Control

signal tiempo_especifico_alcanzado

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================
@export var START_TIME := 60.0        # duración total (segundos)
@export var SIGNAL_AT   := 20.0       # segundo en el que se emite la señal
@export var FINAL_WARN  := 10.0       # últimos segundos con advertencia roja
@export var POST_DELAY  := 5.0        # segundos extra antes de cambiar de escena

# =====================================================================
# 🧾 NODOS
# =====================================================================
@onready var timer_label: Label   = $TimerLabel
@onready var warning_label: Label = $WarningLabel
@onready var main_timer: Timer    = $CountdownTimer

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var remaining_time: float
var post_timer: Timer
var signal_fired := false
var time_over    := false

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
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
		post_timer.start(POST_DELAY)
		print("⏰ Tiempo terminado — esperando %d s antes de la batalla..." % POST_DELAY)

	_update_label()

	# Señal configurable
	if not signal_fired and remaining_time <= SIGNAL_AT:
		print("TimerRoot: llegamos a %d s — emitiendo señal" % SIGNAL_AT)
		tiempo_especifico_alcanzado.emit()
		signal_fired = true

# =====================================================================
# 🚪 CAMBIO DE ESCENA
# =====================================================================
func _on_post_timer_timeout() -> void:
	print("⚔️ Iniciando batalla automáticamente...")
	get_tree().change_scene_to_file("res://src/PantallaAtaque/campoBatalla.tscn")

# =====================================================================
# 🖥️ ACTUALIZACIÓN UI
# =====================================================================
func _update_label() -> void:
	var minutes := int(remaining_time) / 60
	var seconds := int(remaining_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

	# Colores y advertencias
	if remaining_time <= FINAL_WARN:
		timer_label.modulate   = Color.RED
		warning_label.modulate = Color.RED
		warning_label.text     = "¡Llega la última batalla!"
		warning_label.visible  = true
	elif remaining_time <= SIGNAL_AT:
		timer_label.modulate   = Color.GREEN
		warning_label.visible  = false
	else:
		timer_label.modulate   = Color.WHITE
		warning_label.text     = "No puedes atacar."
		warning_label.visible  = true
