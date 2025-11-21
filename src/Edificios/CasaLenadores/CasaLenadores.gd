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

@export var SPAWN_RADIUS := 100.0 
@export var MIN_DISTANCE := 50.0
@export var COLLISION_CHECK_RADIUS := 10.0 
@export_range(1, 15, 1) var MAX_SPAWN_ATTEMPTS := 10 

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

	if resource_manager == null:
		push_error("[CasaLenadores] ResourceManager no encontrado.")
		return

	if lenador_scene == null:
		push_error("[CasaLenadores] No se asignó la escena del Leñador.")

	area_interaccion.body_entered.connect(_on_player_enter)
	area_interaccion.body_exited.connect(_on_player_exit)
	boton_lenador.pressed.connect(_on_comprar_lenador)

	boton_lenador.position = UI_OFFSET
	boton_lenador.visible = false

	if debug:
		print("[CasaLenadores] Inicializado correctamente.")

func spawn_initial_lenadores_on_build() -> void: 
	if initial_spawn_complete: 
		return 
	lenadores_actuales = 0 
	spawned_positions.clear() 
	var num_a_spawnear = lenadores_iniciales 
	for _i in range(num_a_spawnear): 
		resource_manager.remove_resource("villager", coste_aldeano_lenador) 
		_spawn_lenador() 
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
	query.exclude = [self]  # ← para evitar que choque con la propia casa

	var result = space_state.intersect_point(query, 1)
	return result.is_empty()


# ============================================================
# 📍 NUEVA POSICIÓN ALEATORIA VÁLIDA
# ============================================================
func _get_random_spawn_position() -> Vector2:
	var center := global_position
	var attempts := 0

	while attempts < MAX_SPAWN_ATTEMPTS:

		var angle = randf_range(0, TAU)
		var distance = randf_range(MIN_DISTANCE, SPAWN_RADIUS)
		var pos = center + Vector2(cos(angle), sin(angle)) * distance

		# 1. Distancia con leñadores previos
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

	# Si no encuentra hueco:
	if debug:
		print("[CasaLenadores] No se encontró posición válida tras %d intentos." % MAX_SPAWN_ATTEMPTS)

	return center + Vector2(0, SPAWN_RADIUS)


# ============================================================
# 🧱 SPAWNEAR LEÑADOR
# ============================================================
func _spawn_lenador() -> void:
	var npc = lenador_scene.instantiate()

	npc.global_position = _get_random_spawn_position()

	get_parent().add_child(npc)

	var anim := npc.get_node_or_null("AnimatedSprite2D")
	if anim:
		anim.play("Idle")

	if debug:
		print("[CasaLenadores] Nuevo leñador en %s" % npc.global_position)


# ============================================================
# 🚪 DETECCIÓN DE JUGADOR
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
# 🧰 BOTÓN
# ============================================================
func _actualizar_boton():
	boton_lenador.visible = jugador_dentro and lenadores_actuales < max_lenadores


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

	lenadores_actuales += 1
	_actualizar_boton()
