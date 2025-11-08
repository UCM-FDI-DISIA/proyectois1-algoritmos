extends Area2D

# =====================================================================
# 🧾 NODOS
# =====================================================================
@onready var battle_button: TextureButton = get_node("UI/BattleButton")
@onready var battle_icon: Sprite2D        = get_node("UI/BattleButton/BattleIcon")
@onready var player: CharacterBody2D      = get_tree().get_first_node_in_group("jugador")

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var player_in_area := false

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	print("🧠 [RockBattleArea] Script cargado (modo mundo)")

	if player == null:
		push_error("❌ No se encontró jugador en el grupo 'jugador'")

	# Botón oculto/deshabilitado por defecto
	battle_button.visible  = false
	battle_button.disabled = true
	battle_button.tooltip_text = "Aún no puedes atacar ⚔️"

	# Conexiones UI
	battle_button.mouse_entered.connect(_on_button_hover)
	battle_button.mouse_exited.connect(_on_button_exit)
	battle_button.pressed.connect(_on_battle_button_pressed)

	# Ajustar forma de colisión al tamaño del botón
	var collision: CollisionShape2D = get_node("UI/BattleButton/StaticBody2D/CollisionShape2D")
	var texture_size := battle_button.texture_normal.get_size()
	collision.shape = RectangleShape2D.new()
	collision.shape.size = texture_size * 2.0
	collision.position   = battle_button.position + texture_size / 2.0

	# Señales del área
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Timer para habilitar el botón
	var timer_node = get_node_or_null("../../Timer/Panel/TimerRoot")
	if timer_node:
		timer_node.connect("tiempo_especifico_alcanzado", Callable(self, "_on_tiempo_especifico_alcanzado"))
	else:
		push_error("❌ TimerRoot no encontrado")

# =====================================================================
# 📡 EVENTOS PERSONALIZADOS
# =====================================================================
func _on_tiempo_especifico_alcanzado() -> void:
	print("✅ Señal recibida — ¡Botón habilitado!")
	battle_button.disabled = false
	battle_icon.visible    = true
	battle_button.tooltip_text = "Entrar al combate ⚔️"

# =====================================================================
# 🚪 EVENTOS DE ÁREA
# =====================================================================
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
		battle_icon.visible   = false
		print("🏃 Jugador '%s' salió del área -> botón oculto" % player.name)

# =====================================================================
# 🖱️ EVENTOS DE INTERFAZ
# =====================================================================
func _on_button_hover() -> void:
	battle_button.tooltip_text = "Entrar al combate ⚔️" if not battle_button.disabled else "Aún no puedes atacar ⚔️"

func _on_button_exit() -> void:
	battle_button.tooltip_text = ""

func _on_battle_button_pressed() -> void:
	if battle_button.disabled:
		print("🚫 Botón presionado pero aún deshabilitado.")
		return

	print("✅ Botón presionado — cambiando a escena 'campoBatalla.tscn'...")
	get_tree().change_scene_to_file("res://src/PantallaAtaque/campoBatalla.tscn")
