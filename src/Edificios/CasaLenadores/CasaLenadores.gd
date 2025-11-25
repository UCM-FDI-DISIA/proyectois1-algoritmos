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

# Nuevo: tamaño real para colisiones
@export var NPC_COLLISION_RADIUS := 12.0

# ============================================================
# 🎮 ESTADO 
# ============================================================
var lenadores_actuales := 0
var jugador_dentro := false
var debug := true
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

	if debug:
		print("[Casa] READY → Inicializando")

	if resource_manager == null:
		push_error("[Casa] ERROR: ResourceManager no encontrado.")
		return

	if lenador_scene == null:
		push_error("[Casa] ERROR: No se asignó la escena del leñador.")
	
	area_interaccion.body_entered.connect(_on_player_enter)
	area_interaccion.body_exited.connect(_on_player_exit)
	boton_lenador.pressed.connect(_on_comprar_lenador)

	boton_lenador.position = UI_OFFSET
	boton_lenador.visible = false

	print("[Casa] Inicializado correctamente.\n")

# ============================================================
# 🔍 CHEQUEO DE COLISIÓN REAL (CircleShape2D)
# ============================================================
func _is_position_free(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state

	var shape := CircleShape2D.new()
	shape.radius = NPC_COLLISION_RADIUS

	var transform := Transform2D(0, pos)

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = transform
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.exclude = [area_interaccion.get_rid()]

	var result = space_state.intersect_shape(params, 10)

	if debug:
		print("[Casa] Chequeando posición ", pos, " → colisiones: ", result.size())

	return result.is_empty()

# ============================================================
# 📍 NUEVA POSICIÓN ALEATORIA SEGURA
# ============================================================
func _get_random_spawn_position() -> Vector2:
	var center := global_position
	var attempts := 0

	while attempts < MAX_SPAWN_ATTEMPTS:

		var angle = randf_range(PI / 2.0, 3.0 * PI / 2.0)
		var distance = randf_range(MIN_DISTANCE, SPAWN_RADIUS) 
		
		var pos = center + Vector2(cos(angle), sin(angle)) * distance

		if debug:
			print("[Casa] Intento ", attempts, " → probando ", pos)

		var too_close := false
		for prev in spawned_positions:
			if prev.distance_to(pos) < MIN_DISTANCE:
				too_close = true
				break

		if too_close:
			attempts += 1
			continue

		if _is_position_free(pos):
			spawned_positions.append(pos)
			print("[Casa] Posición válida encontrada → ", pos)
			return pos

		attempts += 1

	push_warning("[Casa] No se encontró posición válida → usando fallback")
	return center + Vector2(0, SPAWN_RADIUS)

# ============================================================
# 🧱 SPAWNEAR LEÑADOR
# ============================================================
func _spawn_lenador() -> void:
	print("[Casa] Intentando crear leñador")

	var npc = lenador_scene.instantiate()
	npc.global_position = _get_random_spawn_position()

	get_parent().add_child(npc)

	print("[Casa] Leñador creado en ", npc.global_position)

func spawn_initial_lenadores_on_build() -> void:
	if initial_spawn_complete:
		return
	spawned_positions.clear()
	var aldeanos_actuales : int = resource_manager.get_resource("villager")
	var num_a_spawnear = lenadores_iniciales
	var lenadores_pagables = floor(float(aldeanos_actuales) / coste_aldeano_lenador)
	
	num_a_spawnear = min(num_a_spawnear, max_lenadores, lenadores_pagables)

	for i in range(num_a_spawnear):
		resource_manager.remove_resource("villager", coste_aldeano_lenador)
		_spawn_lenador()
		lenadores_actuales += 1

	if debug:
		print("[CasaLenadores] Spawn inicial completado. Leñadores totales: %d." % lenadores_actuales)

	initial_spawn_complete = true
# ============================================================
# 💰 COMPRAR LEÑADOR
# ============================================================
func _on_comprar_lenador():
	print("[Casa] Comprar leñador presionado")

	if lenadores_actuales >= max_lenadores:
		print("[Casa] Máximo alcanzado")
		return

	var wood = resource_manager.get_resource("wood")
	var vil = resource_manager.get_resource("villager")

	if wood < coste_madera_lenador:
		print("[Casa] No hay madera suficiente")
		return
	if vil < coste_aldeano_lenador:
		print("[Casa] No hay aldeanos suficientes")
		return

	resource_manager.remove_resource("wood", coste_madera_lenador)
	resource_manager.remove_resource("villager", coste_aldeano_lenador)

	_spawn_lenador()
	lenadores_actuales += 1

	_actualizar_boton()

# ============================================================
# 🚪 DETECCIÓN DE JUGADOR
# ============================================================
func _on_player_enter(body):
	if body.is_in_group("jugador"):
		print("[Casa] Jugador entró en rango")
		jugador_dentro = true
		_actualizar_boton()

func _on_player_exit(body):
	if body.is_in_group("jugador"):
		print("[Casa] Jugador salió de rango")
		jugador_dentro = false
		boton_lenador.visible = false

# ============================================================
# 🧰 BOTÓN
# ============================================================
func _actualizar_boton():
	boton_lenador.visible = jugador_dentro and lenadores_actuales < max_lenadores
