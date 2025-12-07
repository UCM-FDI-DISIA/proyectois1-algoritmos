extends Node

# ----------------------------------------------------
#  MODO DE JUEGO
# ----------------------------------------------------
var is_pve: bool = false       # true = PVE local, false = PVP online
var game_mode: String = "PVP"      # solo por claridad / debug

# ----------------------------------------------------
#  VARIABLES DE PARTIDAS GANADAS
# ----------------------------------------------------
@export var partidas_win: int = 0
@export var partidas_tie: int = 0
@export var partidas_loose: int = 0

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
# Esta señal se emite para que el Countdown.gd (Timeroot) inicie la animación y las etiquetas.
signal start_battle_countdown(is_attacker: bool) 

func _ready() -> void:
	# Sigue escuchando cambios de datos de jugadores (solo útil en PVP)
	if GDSync.has_signal("player_data_changed"):
		GDSync.player_data_changed.connect(_on_player_data_changed)

	print("✅ GameState listo y accesible como singleton. Modo:", game_mode)

func reset() -> void:
	collected_seconds = 0
	troop_counts = {
		"Archer": 0,
		"Lancer": 0,
		"Monk": 0,
		"Warrior": 0
	}
	if !is_pve :
		GDSync.player_set_data("troops_by_client", {
			"Archer": 0,
			"Lancer": 0,
			"Monk": 0,
			"Warrior": 0
		})
	is_pve = false              # true = PVE local, false = PVP online
	game_mode = "PVP"           # solo por claridad / debug
	

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
	print("[GameState] Tiempo recolectado:", collected_seconds)


# ===========================
#    TROPAS (Sin cambios)
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
	if !GameState.is_pve : GDSync.player_set_data("troops_by_client", troop_counts)
	print("Tropas actualizadas:", troop_counts)


# ===========================
#    ATAQUE (Lógica de Delay para el ATACANTE)
# ===========================
func attack_other() -> void:
		print("Atacante: Notificando a todos los jugadores e iniciando 3s de retraso.")
		
		# 1. Notificar a la red (esto hace que el DEFENSOR active su lógica de delay)
		if !GameState.is_pve : GDSync.player_set_data("cambio_campo_batalla", true)
		
		# 2. Notificar al Countdown local (Timeroot) para la UI/Animación (Yo soy el ATACANTE)
		emit_signal("start_battle_countdown", true) 
		
		# 3. Esperar 3 segundos (implementación del delay)
		await get_tree().create_timer(3.0).timeout
		
		# 4. Cambiar de escena tras el delay
		SceneManager.change_scene("res://src/PantallaAtaque/campoBatalla.tscn", {
			"pattern": "squares",
			"speed": 2.0,
			"wait_time": 0.3
		})


func _on_player_data_changed(client_id: int, key: String, value) -> void:
	# Solo reacciona en PVP
	if is_pve:
		return

	if client_id != GDSync.get_client_id():
		print("Recibido de %d: %s = %s" % [client_id, key, str(value)])

		if key == "cambio_campo_batalla":
			# 1. Notificar al Countdown local (Timeroot) para la UI/Animación (Yo soy el DEFENSOR)
			emit_signal("start_battle_countdown", false) 

			# 2. Esperar 3 segundos (implementación del delay)
			await get_tree().create_timer(3.0).timeout
			
			# 3. Cambiar de escena tras el delay
			print("Defensor: Cambiando a la escena de Batalla: campoBatalla.tscn")
			SceneManager.change_scene("res://src/PantallaAtaque/campoBatalla.tscn", {
				"pattern": "squares",
				"speed": 2.0,
				"wait_time": 0.3
			})


# =====================================================================
# 📊 RESULTADOS DE BATALLA (AÑADIDOS)
# =====================================================================
# Variable para almacenar los resultados detallados de la última batalla.
var battle_results: Dictionary = {}

## Guarda los resultados de la batalla para que la pantalla de resultados los use.
## @param data: Diccionario con la estructura de resultados.
func set_battle_results(data: Dictionary) -> void:
	battle_results = data
	print("✅ Resultados de batalla guardados en GameState.")

## Obtiene los resultados de la última batalla.
## @return Diccionario con los resultados.
func get_battle_results() -> Dictionary:
	return battle_results
