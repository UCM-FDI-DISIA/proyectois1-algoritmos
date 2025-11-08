extends Control

signal tiempo_especifico_alcanzado

# ----------------------------
# VARIABLES
# ----------------------------
@onready var timer_label: Label = $TimerLabel
@onready var warning_label: Label = $WarningLabel
@onready var main_timer: Timer = $CountdownTimer

var post_timer: Timer
var remaining_time: float = 60.0  # 1 minuto
const SEGUNDO_TIEMPO := 30
const ULTIMOS_SEGUNDOS := 20
const WARNING_1 := "No puedes atacar."
const WARNING_2 := "¡Llega la última batalla!"

var senal_ya_enviada := false
var tiempo_terminado := false

# ----------------------------
# READY
# ----------------------------
func _ready() -> void:
	print("🕒 [TimerRoot] Iniciado correctamente.")

	main_timer.timeout.connect(_on_timer_timeout)
	main_timer.start()
	_update_label()

	# Crear el segundo temporizador (no está en escena)
	post_timer = Timer.new()
	post_timer.one_shot = true
	post_timer.wait_time = 5.0
	add_child(post_timer)
	post_timer.timeout.connect(_on_post_timer_timeout)

# ----------------------------
# EVENTOS
# ----------------------------
func _on_timer_timeout() -> void:
	if tiempo_terminado:
		return

	remaining_time -= 1

	if remaining_time <= 0:
		remaining_time = 0
		main_timer.stop()
		_update_label()

		print("⏰ Tiempo terminado. Comienza cuenta atrás de 5 segundos antes de batalla.")
		tiempo_terminado = true
		post_timer.start()
		return

	_update_label()

	if not senal_ya_enviada and remaining_time <= SEGUNDO_TIEMPO:
		print("TimerRoot: El tiempo ha llegado a 30s. ¡Emitiendo señal!")
		emit_signal("tiempo_especifico_alcanzado")
		senal_ya_enviada = true

func _on_post_timer_timeout() -> void:
	print("⚔️ Pasaron los 5 segundos extra. Iniciando batalla automáticamente...")
	_ir_a_campo_de_batalla()

# ----------------------------
# CAMBIO DE ESCENA
# ----------------------------
func _ir_a_campo_de_batalla() -> void:
	get_tree().change_scene_to_file("res://src/PantallaAtaque/campoBatalla.tscn")

# ----------------------------
# UI
# ----------------------------
func _update_label() -> void:
	var minutes := int(remaining_time) / 60
	var seconds := int(remaining_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

	if remaining_time > SEGUNDO_TIEMPO:
		timer_label.modulate = Color.WHITE
	elif remaining_time < ULTIMOS_SEGUNDOS:
		warning_label.modulate = Color.RED
		timer_label.modulate = Color.RED
	else:
		timer_label.modulate = Color.GREEN

	warning_label.visible = remaining_time > SEGUNDO_TIEMPO or remaining_time < ULTIMOS_SEGUNDOS
	warning_label.text = WARNING_2 if remaining_time < ULTIMOS_SEGUNDOS else WARNING_1
