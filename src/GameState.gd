extends Node

# ===================================================
# GameState.gd
# ===================================================
# Este script se añade como Autoload (singleton)
# ===================================================

var collected_seconds: float = 0
var troop_counts : Dictionary = {
	"Archer": 0,
	"Lancer": 0,
	"Monk": 0,
	"Warrior": 0
}

signal collected_time_changed(seconds: float)


func _ready() -> void:
	print("✅ GameState listo y accesible como singleton.")


func start_timer() -> void:
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()


func _on_timer_timeout() -> void:
	collected_seconds += 1.0
	emit_signal("collected_time_changed", collected_seconds)
	print("[GameState] Tiempo recolectado:", collected_seconds)


# ===========================
# TROPAS
# ===========================
func set_troop_count(type: String, count: int) -> void:
	if troop_counts.has(type):
		troop_counts[type] = max(0, count)


func get_troop_count(type: String) -> int:
	if troop_counts.has(type):
		return troop_counts[type]
	return 0


func get_all_troop_counts() -> Dictionary:
	return troop_counts.duplicate()


func add_troops(type: String, amount: int) -> void:
	if troop_counts.has(type):
		troop_counts[type] += amount
	GDSync.player_set_data("troops_by_client", troop_counts)
	print("Alguien es un poco mas millonario ", troop_counts)
