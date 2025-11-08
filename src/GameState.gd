extends Node

signal collected_time_changed(seconds: float)

var _instance: GameState = null

var collected_seconds: float = 0.0

var troop_counts := {
	"Archer": 0,
	"Lancer": 0,
	"Monk": 0,
	"Warrior": 0
}

var collection_timer: Timer = null


# -----------------------------
# SINGLETON / INSTANCIA ÚNICA
# -----------------------------
static func get_instance() -> GameState:
	if _instance == null:
		_instance = GameState.new()
	return _instance


func _ready() -> void:
	if _instance == null:
		_instance = self
		get_tree().root.add_child(self)
		self.owner = null
		print("✅ [GameState] Inicializado y persistente entre escenas.")
	else:
		queue_free()


# -----------------------------
# TEMPORIZADOR DE RECOLECCIÓN
# -----------------------------
func start_timer() -> void:
	if collection_timer != null:
		return

	collection_timer = Timer.new()
	collection_timer.wait_time = 1.0
	collection_timer.one_shot = false
	collection_timer.timeout.connect(_on_timer_timeout)
	add_child(collection_timer)
	collection_timer.start()


func _on_timer_timeout() -> void:
	collected_seconds += 1.0
	emit_signal("collected_time_changed", collected_seconds)
	print("[GameState] Tiempo recolectado: ", collected_seconds)


func get_collected_seconds() -> float:
	return collected_seconds


func reset_collected_time() -> void:
	collected_seconds = 0.0
	emit_signal("collected_time_changed", collected_seconds)


# -----------------------------
# TROPAS
# -----------------------------
func set_troop_count(type: String, count: int) -> void:
	if not troop_counts.has(type):
		return
	troop_counts[type] = max(0, count)


func get_troop_count(type: String) -> int:
	if troop_counts.has(type):
		return troop_counts[type]
	return 0


func get_all_troop_counts() -> Dictionary:
	return troop_counts.duplicate(true)


func add_troops(type: String, amount: int) -> void:
	if not troop_counts.has(type):
		return
	troop_counts[type] = max(0, troop_counts[type] + amount)
	emit_signal("collected_time_changed", collected_seconds)
