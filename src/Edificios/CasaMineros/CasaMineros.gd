extends Node2D
class_name CasaMineros # ⬅️ CLASE CAMBIADA

# ============================================================
# 🔧 VARIABLES EDITABLES
# ============================================================
@export var minero_scene: PackedScene # ⬅️ NPC CAMBIADO
@export var coste_hierro_minero := 1 # ⬅️ RECURSO Y PRECIO CAMBIADO (Ej: 8)
@export var coste_aldeano_minero := 1 # ⬅️ NPC CAMBIADO (Sigue siendo 1 aldeano)
@export var max_mineros := 5 # ⬅️ NOMBRE CAMBIADO
@export var mineros_iniciales := 1 # ⬅️ NOMBRE CAMBIADO
@export var UI_OFFSET := Vector2(-45, -292) 

@export var SPAWN_RADIUS := 400.0 
@export var MIN_DISTANCE := 190.0
@export var COLLISION_CHECK_RADIUS := 10.0 
@export_range(1, 15, 1) var MAX_SPAWN_ATTEMPTS := 10 

# ============================================================
# 🎮 ESTADO 
# ============================================================
var mineros_actuales := 0 # ⬅️ NOMBRE CAMBIADO
var jugador_dentro := false
var debug := true
var spawned_positions: Array[Vector2] = []
var initial_spawn_complete := false

# ============================================================
# 🧩 NODOS
# ============================================================
@onready var boton_minero := $UI/ComprarMinero # ⬅️ NOMBRE CAMBIADO (Deberás renombrar el nodo botón en tu escena)
@onready var area_interaccion := $interaccion
@onready var resource_manager := get_node("/root/Main/ResourceManager")

# ============================================================
# ⚙️ READY
# ============================================================
func _ready() -> void:
	randomize()

	if resource_manager == null:
		push_error("[CasaMineros] ResourceManager no encontrado.") # ⬅️ NOMBRE CAMBIADO
		return

	if minero_scene == null:
		push_error("[CasaMineros] No se asignó la escena del Minero.") # ⬅️ NOMBRE CAMBIADO
	
	# Asegura que los recursos iniciales existen en el manager
	resource_manager.add_resource("iron", 0) # ⬅️ RECURSO CAMBIADO (Iron/Hierro)
	resource_manager.add_resource("villager", 0)


	area_interaccion.body_entered.connect(_on_player_enter)
	area_interaccion.body_exited.connect(_on_player_exit)
	boton_minero.pressed.connect(_on_comprar_minero) # ⬅️ CONEXIÓN CAMBIADA

	boton_minero.position = UI_OFFSET
	boton_minero.z_index = 100
	boton_minero.visible = false

	if debug:
		print("[CasaMineros] Inicializado correctamente.") # ⬅️ NOMBRE CAMBIADO

func spawn_initial_mineros_on_build() -> void: # ⬅️ NOMBRE MANTENIDO POR COMPATIBILIDAD CON LA LÓGICA DE CONSTRUCCIÓN
	if initial_spawn_complete: 
		return 
	
	spawned_positions.clear() 
	
	var aldeanos_actuales : int = resource_manager.get_resource("villager") 
	var num_a_spawnear = mineros_iniciales # ⬅️ NOMBRE CAMBIADO
	
	var mineros_pagables = floor(float(aldeanos_actuales) / coste_aldeano_minero) # ⬅️ NOMBRE CAMBIADO
	num_a_spawnear = min(num_a_spawnear, max_mineros, mineros_pagables) # ⬅️ NOMBRE CAMBIADO
	
	for i in range(num_a_spawnear): 
		resource_manager.remove_resource("villager", coste_aldeano_minero) # ⬅️ NOMBRE CAMBIADO
		_spawn_minero() # ⬅️ LLAMADA A FUNCIÓN CAMBIADA
		mineros_actuales += 1 # ⬅️ NOMBRE CAMBIADO
		
	if debug: 
		print("[CasaMineros] Spawn inicial completado. Mineros totales: %d." % mineros_actuales) # ⬅️ NOMBRE CAMBIADO
		
	initial_spawn_complete = true

# ============================================================
# 🔍 CHEQUEO DE COLISIONES (Sin cambios necesarios)
# ============================================================
func _is_position_free(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state

	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	query.exclude = [area_interaccion.get_rid()]

	var result = space_state.intersect_point(query, 1)
	return result.is_empty()


# ============================================================
# 📍 NUEVA POSICIÓN ALEATORIA VÁLIDA (Sin cambios necesarios)
# ============================================================
func _get_random_spawn_position() -> Vector2:
	var center := global_position
	var attempts := 0

	while attempts < MAX_SPAWN_ATTEMPTS:

		var angle = randf_range(PI / 2.0, 3.0 * PI / 2.0)
		var distance = randf_range(MIN_DISTANCE, SPAWN_RADIUS) 
		
		var offset = Vector2(cos(angle), sin(angle)) * distance
		var pos = center + offset

		# 1. Distancia con NPCs previos
		var ok := true
		for prev in spawned_positions:
			if prev.distance_to(pos) < MIN_DISTANCE:
				ok = false
				break

		# 2. Chequeo de colisión del mundo
		if ok and _is_position_free(pos):
			spawned_positions.append(pos)
			return pos

		attempts += 1

	if debug:
		push_warning("[CasaMineros] Advertencia: No se encontró posición válida tras %d intentos en %s. Usando fallback." % [MAX_SPAWN_ATTEMPTS, center]) # ⬅️ NOMBRE CAMBIADO

	return center + Vector2(0, SPAWN_RADIUS)


# ============================================================
# 🧱 SPAWNEAR MINERO
# ============================================================
func _spawn_minero() -> void: # ⬅️ FUNCIÓN CAMBIADA
	var npc = minero_scene.instantiate() # ⬅️ ESCENA CAMBIADA

	npc.global_position = _get_random_spawn_position()

	if get_parent() != null:
		get_parent().add_child(npc)
	else:
		push_error("[CasaMineros] ERROR: No se pudo añadir el minero al árbol.") # ⬅️ NOMBRE CAMBIADO
		npc.queue_free()
		return

	var anim := npc.get_node_or_null("AnimatedSprite2D")
	if anim:
		anim.play("Idle")

	if debug:
		print("[CasaMineros] Nuevo minero en %s" % npc.global_position) # ⬅️ NOMBRE CAMBIADO


# ============================================================
# 💰 COMPRAR MINERO
# ============================================================
func _on_comprar_minero(): # ⬅️ FUNCIÓN CAMBIADA
	if mineros_actuales >= max_mineros: # ⬅️ NOMBRE CAMBIADO
		print("[CasaMineros] Máximo alcanzado.") # ⬅️ NOMBRE CAMBIADO
		return

	var gold : int = resource_manager.get_resource("gold") 
	var villagers :int = resource_manager.get_resource("villager")

	if gold < coste_hierro_minero: # ⬅️ RECURSO Y COSTO CAMBIADO
		print("[CasaMineros] No hay hierro suficiente.") # ⬅️ RECURSO CAMBIADO
		return
	if villagers < coste_aldeano_minero: # ⬅️ COSTO CAMBIADO
		print("[CasaMineros] No hay aldeanos disponibles.") 
		return

	resource_manager.remove_resource("gold", coste_hierro_minero) # ⬅️ RECURSO Y COSTO CAMBIADO
	resource_manager.remove_resource("villager", coste_aldeano_minero) 

	_spawn_minero() # ⬅️ LLAMADA A FUNCIÓN CAMBIADA

	mineros_actuales += 1 # ⬅️ NOMBRE CAMBIADO
	_actualizar_boton()

# ============================================================
# 🚪 DETECCIÓN DE JUGADOR (Sin cambios)
# ============================================================
func _on_player_enter(body):
	if body.is_in_group("jugador"):
		jugador_dentro = true
		_actualizar_boton()

func _on_player_exit(body):
	if body.is_in_group("jugador"):
		jugador_dentro = false
		boton_minero.visible = false # ⬅️ NOMBRE CAMBIADO


# ============================================================
# 🧰 BOTÓN (Sin cambios)
# ============================================================
func _actualizar_boton():
	boton_minero.visible = jugador_dentro and mineros_actuales < max_mineros # ⬅️ NOMBRE CAMBIADO
