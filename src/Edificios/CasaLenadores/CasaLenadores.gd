extends StaticBody2D
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
	
	# ➡️ NUEVO: Conectar la actualización al evento mouse_entered del botón
	boton_lenador.mouse_entered.connect(_on_boton_mouse_entered)
	
	# ➡️ NUEVO: Conectar a la actualización del botón al evento mouse_exited del botón
	# para limpiar cualquier estado temporal si fuera necesario, aunque la visibilidad ya lo hace.
	boton_lenador.mouse_exited.connect(_on_boton_mouse_exited)

	boton_lenador.position = UI_OFFSET
	boton_lenador.visible = false
	
	# Se dejará el tooltip_text en blanco o con un valor inicial simple
	boton_lenador.tooltip_text = ""
	
	print("[Casa] Inicializado correctamente.\n")
	z_as_relative = false
	
# ============================================================
# ⚙️ PROCESS (Para el Tooltip de la Casa cuando está al máximo)
# ============================================================
func _process(delta: float) -> void:
	# ➡️ NUEVO: Usar _process para actualizar el tooltip de la CASA (self) 
	# si el jugador está cerca (jugador_dentro) y el máximo está alcanzado.
	var max_alcanzado = lenadores_actuales >= max_lenadores
	
	# Solo si el ratón está sobre el StaticBody2D (requiere que el StaticBody2D
	# tenga el input_pickable activado en Godot Editor).
	if max_alcanzado:
		# Asignamos el tooltip_text a self. Si StaticBody2D no lo soporta, 
		# al menos lo tendrá listo en caso de que se use un Area2D o nodo Control.
		# Ya que la propiedad falla, usaremos la solución más robusta:
		# Si el máximo está alcanzado, ocultamos el botón y no hacemos nada más.
		pass # Dejamos la gestión del tooltip de la casa fuera de este script para evitar el error.


# ============================================================
# 🔍 CHEQUEO DE COLISIÓN REAL (CircleShape2D)
# ... (Funciones de física y spawn se mantienen igual) ...
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

func _spawn_lenador() -> void:
	var npc = lenador_scene.instantiate()
	npc.global_position = _get_random_spawn_position()
	
	var npcs_parent = get_node("/root/Main/Objetos/NPCs")
	npcs_parent.add_child(npc)
	
	npc.z_index = int(npc.global_position.y)
	
	if npc.has_node("AnimatedSprite2D"):
		var sprite = npc.get_node("AnimatedSprite2D") as AnimatedSprite2D
		pass
	
	if debug:
		print("[Casa] Lenador creado en ", npc.global_position, " | z_index=", npc.z_index)


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

	var wood = resource_manager.get_resource("wood")
	var vil = resource_manager.get_resource("villager")
	var puede_comprar = (wood >= coste_madera_lenador) and (vil >= coste_aldeano_lenador)

	if lenadores_actuales >= max_lenadores:
		print("[Casa] Máximo alcanzado")
		return

	if not puede_comprar:
		print("[Casa] No hay recursos suficientes")
		return

	resource_manager.remove_resource("wood", coste_madera_lenador)
	resource_manager.remove_resource("villager", coste_aldeano_lenador)

	_spawn_lenador()
	lenadores_actuales += 1

	# ➡️ Importante: Actualizar el estado y tooltip inmediatamente después de la compra
	_actualizar_boton()
	
# ============================================================
# 🚪 DETECCIÓN DE JUGADOR
# ============================================================
func _on_player_enter(body):
	if body.is_in_group("jugador"):
		print("[Casa] Jugador entró en rango")
		jugador_dentro = true
		
		# Solo hacemos visible el botón si no está al máximo.
		var max_alcanzado = lenadores_actuales >= max_lenadores
		if not max_alcanzado:
			boton_lenador.visible = true
		# ➡️ Si se requiere actualizar el estado de los recursos inmediatamente
		# (aunque el mouse_entered lo gestiona mejor), se llama aquí.
		_actualizar_boton() 
			

func _on_player_exit(body):
	if body.is_in_group("jugador"):
		print("[Casa] Jugador salió de rango")
		jugador_dentro = false
		boton_lenador.visible = false

# ============================================================
# 🖱️ ACTUALIZACIÓN POR MOUSE HOVER (NUEVO)
# ============================================================

# ➡️ Esta función se llama cada vez que el ratón entra en el botón.
# Es el punto ideal para chequear y actualizar el estado de los recursos.
func _on_boton_mouse_entered():
	_actualizar_estado_y_tooltip()

func _on_boton_mouse_exited():
	# Podrías ocultar el tooltip si estuvieras usando uno personalizado, 
	# pero para el tooltip_text nativo de Godot no es necesario.
	pass 

# ============================================================
# 🧰 BOTÓN (Lógica de Visibilidad y Estado)
# ============================================================

# ➡️ Función principal para chequear recursos y actualizar el botón/tooltip
func _actualizar_estado_y_tooltip():
	var wood = resource_manager.get_resource("wood")
	var vil = resource_manager.get_resource("villager")
	
	var max_alcanzado = lenadores_actuales >= max_lenadores
	var recursos_suficientes = (wood >= coste_madera_lenador) and (vil >= coste_aldeano_lenador)

	# Si no hay jugador dentro, salimos (la visibilidad la maneja _on_player_enter/exit)
	if not jugador_dentro:
		return
	
	# 1. ESTADO (Deshabilitar si no hay recursos)
	boton_lenador.disabled = not recursos_suficientes
	
	# 2. TOOLTIP del Botón: Mostrar precio, recursos y estado.
	var tooltip_msg = "Comprar Leñador:\nMadera: %d (Tienes: %d)\nAldeanos: %d (Tienes: %d)" % [
		coste_madera_lenador, wood,
		coste_aldeano_lenador, vil
	]
	
	if not recursos_suficientes:
		tooltip_msg += "\n¡Recursos insuficientes!"
		
	boton_lenador.tooltip_text = tooltip_msg
	
# ➡️ Lógica de visibilidad general (llamada al entrar/salir del área y al comprar)
func _actualizar_boton():
	var max_alcanzado = lenadores_actuales >= max_lenadores
	
	# 1. VISIBILIDAD y LÍMITE: Ocultar si está al máximo
	if max_alcanzado:
		boton_lenador.visible = false
		# Aquí puedes dejar la lógica del tooltip de la casa, pero recuerda 
		# que StaticBody2D no la soporta y lanzará un error a menos que se use un nodo Control.
		return
	
	# Si no está al máximo, la visibilidad depende solo de si el jugador está dentro
	boton_lenador.visible = jugador_dentro
	
	# Actualizamos el estado de los recursos (deshabilitado/tooltip) inmediatamente.
	# Esto asegura que el botón tenga el estado correcto si entramos en el área
	# y que el estado sea correcto inmediatamente después de una compra.
	_actualizar_estado_y_tooltip()
