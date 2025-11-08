extends Area2D

# =====================
# VARIABLES Y NODOS
# =====================
var battle_button : TextureButton
var battle_icon : Sprite2D
var player : CharacterBody2D

var player_in_area := false

# =====================
# INICIALIZACIÓN
# =====================
func _ready() -> void:
	print("🧠 [RockBattleArea] Script cargado correctamente (modo mundo)")

	player = get_tree().get_first_node_in_group("jugador") as CharacterBody2D
	if player != null:
		print("✅ Jugador encontrado:", player.name)
	else:
		push_error("❌ No se encontró jugador en el grupo 'jugador'")

	battle_button = get_node_or_null("UI/BattleButton")
	battle_icon = get_node_or_null("UI/BattleButton/BattleIcon")

	if battle_icon:
		battle_icon.visible = false
	else:
		push_error("❌ No se encontró BattleIcon")

	if battle_button == null:
		push_error("❌ No se encontró 'UI/BattleButton'")
	else:
		battle_button.visible = false
		battle_button.disabled = true
		battle_button.tooltip_text = "Aún no puedes atacar ⚔️"

		# Conexiones de señales
		battle_button.mouse_entered.connect(_on_button_hover)
		battle_button.mouse_exited.connect(_on_button_exit)
		battle_button.pressed.connect(_on_battle_button_pressed)

		print("✅ Botón inicializado en posición mundial:", battle_button.global_position)

	# Configurar colisión
	var collision = get_node("UI/BattleButton/StaticBody2D/CollisionShape2D")
	var texture_size = battle_button.texture_normal.get_size()
	var shape = RectangleShape2D.new()
	shape.size = texture_size * 2.0
	collision.shape = shape
	collision.position = battle_button.position + texture_size / 2.0

	# Conectar señales del área
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Conectar con el temporizador
	var timer_node = get_node_or_null("../../Timer/Panel/TimerRoot")
	if timer_node == null:
		push_error("❌ No se pudo encontrar el nodo TimerRoot en la ruta especificada.")
		return

	timer_node.connect("tiempo_especifico_alcanzado", Callable(self, "_on_tiempo_especifico_alcanzado"))


# =====================
# EVENTOS PERSONALIZADOS
# =====================
func _on_tiempo_especifico_alcanzado() -> void:
	print("✅ Señal recibida — ¡Botón habilitado!")
	battle_button.disabled = false
	battle_icon.visible = true
	battle_button.tooltip_text = "Entrar al combate ⚔️"


# =====================
# EVENTOS DE ÁREA
# =====================
func _on_body_entered(body: Node) -> void:
	if body == player:
		player_in_area = true
		battle_button.visible = true
		if not battle_button.disabled:
			battle_icon.visible = true
		print("⚔️ Jugador '%s' entró al área -> botón visible" % player.name)


func _on_body_exited(body: Node) -> void:
	if body == player:
		player_in_area = false
		battle_button.visible = false
		battle_icon.visible = false
		print("🏃 Jugador '%s' salió del área -> botón oculto" % player.name)


# =====================
# EVENTOS DE INTERFAZ
# =====================
func _on_button_hover() -> void:
	if battle_button.disabled:
		battle_button.tooltip_text = "Aún no puedes atacar ⚔️"
	else:
		battle_button.tooltip_text = "Entrar al combate ⚔️"


func _on_button_exit() -> void:
	battle_button.tooltip_text = ""


func _on_battle_button_pressed() -> void:
	if battle_button.disabled:
		print("🚫 Botón presionado pero aún deshabilitado.")
		return

	print("✅ Botón presionado — cambiando a escena 'campoBatalla.tscn'...")
	get_tree().change_scene_to_file("res://src/PantallaAtaque/campoBatalla.tscn")
