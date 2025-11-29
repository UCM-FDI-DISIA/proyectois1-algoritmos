extends Node

# ----------------------------------------------------
#  MODO DE JUEGO
# ----------------------------------------------------
var is_pve: bool = false         # true = PVE local, false = PVP online
var game_mode: String = "PVP"     # solo por claridad / debug

# ====================================================
# ⚔️ CONSTANTES DE BATALLA COMPARTIDAS
# ====================================================
const GRACE_PERIOD = 10.0 # Tiempo que tiene el defensor para preparar sus tropas.
const POST_DELAY = 3.0    # Tiempo del "3, 2, 1, GO!" (countdown visual).
const TOTAL_ATTACKER_WAIT_TIME = GRACE_PERIOD + POST_DELAY # 13.0 segundos

# ----------------------------------------------------
#  TIEMPO Y TROPAS
# ----------------------------------------------------
var collected_seconds: float = 0
var troop_counts : Dictionary = {
	"Archer": 0,
	"Lancer": 0,
	"Monk": 0,
	"Warrior": 0
}

signal collected_time_changed(seconds: float)
signal battle_declared_against_player # Señal usada por TimerRoot (DEFENSOR)


func _ready() -> void:
	# Sigue escuchando cambios de datos de jugadores (solo útil en PVP)
	if GDSync.has_signal("player_data_changed"):
		GDSync.player_data_changed.connect(_on_player_data_changed)

	print("✅ GameState listo y accesible como singleton. Modo:", game_mode)

func reset() -> void:
	is_pve = false           # true = PVE local, false = PVP online
	game_mode = "PVP"      # solo por claridad / debug
	collected_seconds = 0
	troop_counts = {
		"Archer": 0,
		"Lancer": 0,
		"Monk": 0,
		"Warrior": 0
	}
	GDSync.player_set_data("troops_by_client", {
			"Archer": 0,
			"Lancer": 0,
			"Monk": 0,
			"Warrior": 0
		})

func set_PVE() -> void:
	game_mode = "PVE"
	is_pve = true

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
	# print("[GameState] Tiempo recolectado:", collected_seconds) # Desactivado para evitar spam en la consola


# ===========================
#   TROPAS
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

	# Solo tiene sentido en PVP, pero no pasa nada si se llama también en PVE
	GDSync.player_set_data("troops_by_client", troop_counts)
	print("Tropas actualizadas:", troop_counts)


# ===========================
#   ATAQUE (LÓGICA DEL ATACANTE)
# ===========================
func attack_other() -> void:
	if is_pve:
		print("Iniciando ataque PVE local → cambio solo mi escena.")
		# Se usa la función nativa para evitar el error de SceneManager.
		get_tree().change_scene_to_file("res://src/PantallaAtaque/campoBatalla.tscn")
	else:
		print("⚔️ ATACANTE: Notificando ataque. Esperando %d segundos." % TOTAL_ATTACKER_WAIT_TIME)
		
		# 1. Notificar a todos los jugadores (incluido el defensor)
		GDSync.player_set_data("cambio_campo_batalla", true)
		
		# 2. El ATACANTE espera el tiempo total (10s de gracia + 3s de countdown)
		# Esto asegura que el defensor haya tenido tiempo para prepararse y cambiar.
		await get_tree().create_timer(TOTAL_ATTACKER_WAIT_TIME).timeout
		
		# 3. El ATACANTE cambia de escena después de esperar.
		# Se usa la función nativa para evitar el error de SceneManager.
		get_tree().change_scene_to_file("res://src/PantallaAtaque/campoBatalla.tscn")


func _on_player_data_changed(client_id: int, key: String, value) -> void:
	# LÓGICA DEL DEFENSOR (recibiendo la notificación)
	if is_pve:
		return

	if client_id != GDSync.get_client_id():
		print("Recibido de %d: %s = %s" % [client_id, key, str(value)])

		if key == "cambio_campo_batalla":
			print("Cambiando a la escena de Batalla: campoBatalla.tscn")
			get_tree().change_scene_to_file("res://src/PantallaAtaque/campoBatalla.tscn")
