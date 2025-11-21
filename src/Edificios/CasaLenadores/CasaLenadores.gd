extends Node2D
class_name CasaLenadores

# ============================================================
# 🔧 VARIABLES EDITABLES
# ============================================================
@export var lenador_scene: PackedScene 
@export var coste_madera_lenador := 5 
@export var coste_aldeano_lenador := 1 
@export var max_lenadores := 5
@export var lenadores_iniciales := 1 
@export var UI_OFFSET := Vector2(-45, -292) 

@export var SPAWN_RADIUS := 300.0 
@export var MIN_DISTANCE := 190.0
@export var COLLISION_CHECK_RADIUS := 10.0 
@export_range(1, 15, 1) var MAX_SPAWN_ATTEMPTS := 10 

# ============================================================
# 🎮 ESTADO 
# ============================================================
var lenadores_actuales := 0
var jugador_dentro := false
var debug := true
# 💡 ESTA LISTA DEBE MANTENER TODAS LAS POSICIONES SPAWNEADAS.
var spawned_positions: Array[Vector2] = []
var initial_spawn_complete := false

# ============================================================
# 🧩 NODOS
# ============================================================
@onready var boton_lenador := $UI/ComprarLenador
@onready var area_interaccion := $interaccion
@onready var resource_manager := get_node("/root/Main/ResourceManager")

# ============================================================
# ⚙️ READY
# ============================================================
func _ready() -> void:
	randomize()

	if resource_manager == null:
		push_error("[CasaLenadores] ResourceManager no encontrado.")
		return

	if lenador_scene == null:
		push_error("[CasaLenadores] No se asignó la escena del Leñador.")
	
	resource_manager.add_resource("wood", 0)
	resource_manager.add_resource("villager", 0)


	area_interaccion.body_entered.connect(_on_player_enter)
	area_interaccion.body_exited.connect(_on_player_exit)
	boton_lenador.pressed.connect(_on_comprar_lenador)

	boton_lenador.position = UI_OFFSET
	boton_lenador.z_index = 100
	boton_lenador.visible = false

	if debug:
		print("[CasaLenadores] Inicializado correctamente.")

func spawn_initial_lenadores_on_build() -> void: 
	if initial_spawn_complete: 
		return 
	
	# La lista se limpia AQUÍ para el spawn inicial, pero no después.
	spawned_positions.clear() 
	
	var aldeanos_actuales : int = resource_manager.get_resource("villager") 
	var num_a_spawnear = lenadores_iniciales
	
	var lenadores_pagables = floor(float(aldeanos_actuales) / coste_aldeano_lenador)
	num_a_spawnear = min(num_a_spawnear, max_lenadores, lenadores_pagables)
	
	# Usar un for loop simple, ya que el contador lenadores_actuales se actualizará en _spawn_lenador
	for i in range(num_a_spawnear): 
		resource_manager.remove_resource("villager", coste_aldeano_lenador) 
		_spawn_lenador() 
		# lenadores_actuales += 1 ya se incrementará en _spawn_lenador si lo haces de forma más compleja.
		# Mejor incrementar aquí ya que _spawn_lenador no siempre devuelve un leñador (aunque aquí lo hace)
		lenadores_actuales += 1
		
	if debug: 
		print("[CasaLenadores] Spawn inicial completado. Leñadores totales: %d." % lenadores_actuales) 
		
	initial_spawn_complete = true

# ============================================================
# 🔍 CHEQUEO DE COLISIONES
# ============================================================
func _is_position_free(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state

	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	# 🚨 CORRECCIÓN AJUSTADA: Eliminamos la comprobación condicional ya que area_interaccion
	# debe ser un CollisionObject2D para funcionar con esta lógica.
	query.exclude = [area_interaccion.get_rid()]

	var result = space_state.intersect_point(query, 1)
	return result.is_empty()


# ============================================================
# 📍 NUEVA POSICIÓN ALEATORIA VÁLIDA
# ============================================================
func _get_random_spawn_position() -> Vector2:
	var center := global_position
	var attempts := 0

	while attempts < MAX_SPAWN_ATTEMPTS:

		# El rango angular ya está ajustado al semicírculo inferior (90° a 270°).
		var angle = randf_range(PI / 2.0, 3.0 * PI / 2.0)
		
		# La distancia aleatoria usa MIN_DISTANCE para asegurar que spawnee lejos.
		var distance = randf_range(MIN_DISTANCE, SPAWN_RADIUS) 
		
		var offset = Vector2(cos(angle), sin(angle)) * distance
		var pos = center + offset

		# 1. Distancia con leñadores previos
		var ok := true
		for prev in spawned_positions:
			# Comprueba que la nueva posición esté a una distancia mínima de cualquier posición previa.
			if prev.distance_to(pos) < MIN_DISTANCE:
				ok = false
				break

		# 2. Chequeo de colisión del mundo
		if ok and _is_position_free(pos):
			# 💡 AQUÍ SE AÑADE LA POSICIÓN A LA LISTA MANTENIDA
			spawned_positions.append(pos)
			return pos

		attempts += 1

	# Si no encuentra hueco (Falla la colisión):
	if debug:
		push_warning("[CasaLenadores] Advertencia: No se encontró posición válida tras %d intentos en %s. Usando fallback." % [MAX_SPAWN_ATTEMPTS, center])

	# Fallback: Posición directamente en el centro inferior
	return center + Vector2(0, SPAWN_RADIUS)


# ============================================================
# 🧱 SPAWNEAR LEÑADOR
# ============================================================
func _spawn_lenador() -> void:
	var npc = lenador_scene.instantiate()

	npc.global_position = _get_random_spawn_position()

	if get_parent() != null:
		get_parent().add_child(npc)
	else:
		push_error("[CasaLenadores] ERROR: No se pudo añadir el leñador al árbol.")
		npc.queue_free()
		return

	var anim := npc.get_node_or_null("AnimatedSprite2D")
	if anim:
		anim.play("Idle")

	if debug:
		print("[CasaLenadores] Nuevo leñador en %s" % npc.global_position)


# ============================================================
# 💰 COMPRAR LEÑADOR
# ============================================================
func _on_comprar_lenador():
	if lenadores_actuales >= max_lenadores:
		print("[CasaLenadores] Máximo alcanzado.")
		return

	var wood : int = resource_manager.get_resource("wood")
	var villagers :int = resource_manager.get_resource("villager")

	if wood < coste_madera_lenador:
		print("[CasaLenadores] No hay madera suficiente.")
		return
	if villagers < coste_aldeano_lenador:
		print("[CasaLenadores] No hay aldeanos disponibles.")
		return

	resource_manager.remove_resource("wood", coste_madera_lenador)
	resource_manager.remove_resource("villager", coste_aldeano_lenador)

	_spawn_lenador()

	# 🚨 CORRECCIÓN CRÍTICA: Se eliminó spawned_positions.clear() de aquí.
	# La lista DEBE mantenerse para que los leñadores comprados después
	# no se apilen con los ya existentes.

	lenadores_actuales += 1
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
		boton_lenador.visible = false


# ============================================================
# 🧰 BOTÓN (Sin cambios)
# ============================================================
func _actualizar_boton():
	boton_lenador.visible = jugador_dentro and lenadores_actuales < max_lenadores
