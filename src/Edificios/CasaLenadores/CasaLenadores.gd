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
# ⬇️ UI_OFFSET: Ahora representa la posición VERTICAL desde el centro (X=0)
@export var UI_OFFSET := Vector2(0, -292) 

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
@onready var max_lenadores_button: Button = $UI/MaxLenadoresButton 
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
	
	boton_lenador.mouse_entered.connect(_on_boton_mouse_entered)
	boton_lenador.mouse_exited.connect(_on_boton_mouse_exited)

	# 🔄 CENTRADO: Reposicionar UI al cargar
	_reposition_ui()
	
	boton_lenador.visible = false
	boton_lenador.tooltip_text = ""
	
	# ➡️ CONFIGURACIÓN del botón de mensaje de límite
	max_lenadores_button.visible = false
	max_lenadores_button.disabled = true
	max_lenadores_button.text = "¡Máximo de leñadores alcanzado: %d/%d!" % [max_lenadores, max_lenadores]
	
	# 🎨 CORRECCIÓN DE CONTRASTE: Forzar el color del texto a blanco
	# Esto requiere un 'Theme Override' para 'Font Color' en el Inspector,
	# pero lo forzamos por código para máxima compatibilidad:
	var style_box = max_lenadores_button.get_theme_stylebox("disabled")
	if style_box:
		# Si no puedes modificar el StyleBox, usa un override de Color:
		max_lenadores_button.add_theme_color_override("font_color", Color.WHITE)
	else:
		# Fallback para el color de fuente normal si el StyleBox no se aplica o no existe
		max_lenadores_button.add_theme_color_override("font_color", Color.WHITE)

	print("[Casa] Inicializado correctamente.\n")
	z_as_relative = false

# 📏 CÁLCULO DE POSICIONAMIENTO CENTRAL
func _reposition_ui():
	# Asume que el nodo de colisión (CollisionShape2D) está centrado en (0, 0).
	# Si la casa tiene una textura, el centro es global_position.
	
	# Calculamos el centro horizontal (X) de la UI.
	# Si UI_OFFSET.x era -45, ahora lo movemos a 0 y centramos el botón.
	var center_offset_x = 0
	
	# Ajustar la posición X del botón para que esté centrado
	# (Se asume que la posición de los nodos UI es relativa al StaticBody2D)
	
	# 1. Botón de compra (ComprarLenador)
	var final_pos_lenador = UI_OFFSET + Vector2(center_offset_x - boton_lenador.size.x / 2, 0)
	boton_lenador.position = final_pos_lenador
	
	# 2. Botón de mensaje (MaxLenadoresButton)
	var final_pos_max = UI_OFFSET + Vector2(center_offset_x - max_lenadores_button.size.x / 2, 0)
	max_lenadores_button.position = final_pos_max


# ⏱️ PROCESS
func _process(_delta: float) -> void:
	pass

# 🌳 CHEQUEO DE COLISIÓN REAL (CircleShape2D)
func _is_position_free(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state

	var shape := CircleShape2D.new()
	shape.radius = NPC_COLLISION_RADIUS

	var vartransform := Transform2D(0, pos)

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape
	params.transform = vartransform
	params.collide_with_areas = true
	params.collide_with_bodies = true
	params.exclude = [area_interaccion.get_rid()]

	var result = space_state.intersect_shape(params, 10)

	if debug:
		print("[Casa] Chequeando posición ", pos, " → colisiones: ", result.size())

	return result.is_empty()

# 📍 NUEVA POSICIÓN ALEATORIA SEGURA
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

# 🧱 SPAWNEAR LEÑADOR
func _spawn_lenador() -> void:
	var npc = lenador_scene.instantiate()
	npc.global_position = _get_random_spawn_position()
	
	var npcs_parent = get_node("/root/Main/Objetos/NPCs")
	npcs_parent.add_child(npc)
	
	npc.z_index = int(npc.global_position.y)
	
	if npc.has_node("AnimatedSprite2D"):
		var _sprite = npc.get_node("AnimatedSprite2D") as AnimatedSprite2D
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
	
# 💰 COMPRAR LEÑADOR
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

	_actualizar_boton()
	
# 🚪 DETECCIÓN DE JUGADOR
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
		max_lenadores_button.visible = false 

# 🖱️ ACTUALIZACIÓN POR MOUSE HOVER
func _on_boton_mouse_entered():
	_actualizar_estado_y_tooltip()

func _on_boton_mouse_exited():
	pass 

# 🧰 BOTÓN (Lógica de Visibilidad y Estado)
func _actualizar_estado_y_tooltip():
	var wood = resource_manager.get_resource("wood")
	var vil = resource_manager.get_resource("villager")
	
	var max_alcanzado = lenadores_actuales >= max_lenadores
	var recursos_suficientes = (wood >= coste_madera_lenador) and (vil >= coste_aldeano_lenador)

	if not jugador_dentro or max_alcanzado:
		return
	
	boton_lenador.disabled = not recursos_suficientes
	
	var tooltip_msg = "Comprar Leñador:\n Madera: %d (Tienes: %d)\n Aldeanos: %d (Tienes: %d)" % [
		coste_madera_lenador, wood,
		coste_aldeano_lenador, vil
	]
	
	if not recursos_suficientes:
		tooltip_msg += "\n🛑¡Recursos insuficientes!"
		
	boton_lenador.tooltip_text = tooltip_msg
	
func _actualizar_boton():
	var max_alcanzado = lenadores_actuales >= max_lenadores
	
	# 1. VISIBILIDAD y LÍMITE:
	if max_alcanzado:
		# Oculta el botón de compra
		boton_lenador.visible = false
		# Muestra el botón de mensaje de límite
		max_lenadores_button.visible = jugador_dentro
		return
	
	# Si no está al máximo:
	# Oculta el botón de mensaje de límite
	max_lenadores_button.visible = false
	
	# La visibilidad del botón de compra depende solo de si el jugador está dentro
	boton_lenador.visible = jugador_dentro
	
	# Actualizamos el estado de los recursos (solo si el jugador está dentro)
	if jugador_dentro:
		_actualizar_estado_y_tooltip()
