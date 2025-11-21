extends Node

var players: Array[int] = []            # IDs conectados
var quadrants_by_client: Dictionary = {} # client_id -> cuadrante
var my_quadrant_id: int = -1
var game_started: bool = false


func _ready() -> void:
	print("✅ MultiplayerManager iniciado.")

	GDSync.client_joined.connect(_on_client_joined)
	GDSync.client_left.connect(_on_client_left)
	GDSync.lobby_joined.connect(_on_lobby_joined)

	GDSync.expose_func(_receive_quadrant_assignment)
	


# ------------------------------------------------
# 🔹 Eventos de GD-Sync
# ------------------------------------------------
func _on_lobby_joined(lobby_name: String) -> void:
	print("MultiplayerManager: entré al lobby:", lobby_name)
	var my_id := GDSync.get_client_id()
	if my_id > 0 and my_id not in players:
		players.append(my_id)

	if GDSync.is_host():
		_check_start_condition()


func _on_client_joined(client_id: int) -> void:
	print("Cliente unido:", client_id)
	if client_id not in players:
		players.append(client_id)

	if GDSync.is_host():
		_check_start_condition()


func _on_client_left(client_id: int) -> void:
	print("Cliente salió: ", client_id)
	# players.erase(client_id)
	# quadrants_by_client.erase(client_id)


# ------------------------------------------------
# 🔹 Inicio de partida (solo el host)
# ------------------------------------------------
func _check_start_condition() -> void:
	if not GDSync.is_host() or game_started:
		return

	print("Jugadores actuales en lobby:", players)

	if players.size() >= 2:
		print("✅ Dos jugadores detectados. Asignando cuadrantes y arrancando partida...")
		_assign_quadrants()
		
		game_started = true

		await get_tree().create_timer(1.0).timeout
		print("🌍 Ejecutando cambio de escena sincronizado...")
		GDSync.change_scene("res://src/main.tscn")  # ✅ ruta correcta
	else:
		print("Esperando más jugadores antes de iniciar...")

# ------------------------------------------------
#  AJUSTES UN JUGADOR
# ------------------------------------------------
func _adjust_for_one_player() -> void:
	my_quadrant_id = 0
	
	var myid : int = GDSync.get_client_id()
	
	if myid <= 0:
		push_error("No se puede iniciar PVE sin un client_id válido")
		return
		
	print("PVE -> tengo un 'client_id' ", myid, " y mi cuadrante es ", my_quadrant_id)
	players = [myid]
	quadrants_by_client = { myid : my_quadrant_id }
	
	# Guardar datos del jugador
	GDSync.player_set_data("quadrants_by_client", quadrants_by_client)
	GDSync.player_set_data("quadrant_id", my_quadrant_id)
	
	# Cambiar escena (usar el mismo método que en PVP para consistencia)
	print("🌍 Cambiando a escena principal para PVE...")
	await get_tree().create_timer(0.5).timeout  # Pequeña espera para asegurar sincronización
	get_tree().change_scene_to_file("res://src/main.tscn")

# ------------------------------------------------
# 🔹 Asignación de cuadrantes
# ------------------------------------------------
func _assign_quadrants() -> void:
	if not GDSync.is_host():
		return

	players.sort()
	var available_quadrants = [0, 1]

	for i in range(min(players.size(), available_quadrants.size())):
		var client_id: int = players[i]
		var q: int = available_quadrants[i]
		quadrants_by_client[client_id] = q
		
		GDSync.player_set_data("quadrants_by_client", quadrants_by_client)
		
		print(" -> Jugador ", client_id, " tiene cuadrante ", q)
		GDSync.call_func_on(client_id, _receive_quadrant_assignment, [q])


# ------------------------------------------------
# 🔹 Recepción del cuadrante en cada cliente
# ------------------------------------------------
func _receive_quadrant_assignment(q_id: int) -> void:
	my_quadrant_id = q_id
	
	print("Me asignaron el cuadrante:", my_quadrant_id)
	GDSync.player_set_data("quadrant_id", q_id)


# ------------------------------------------------
# 🔹 Utilidades
# ------------------------------------------------
func get_my_quadrant() -> int:
	return my_quadrant_id

func get_player_quadrant(client_id: int) -> int:
	return quadrants_by_client.get(client_id, -1)

func get_enemy_id(client_id: int) -> int:
	var enemy_id : int = players[0]
	if (enemy_id == client_id) : enemy_id = players[1]
	print(players, " mi enemigo es ", enemy_id)
	return enemy_id
