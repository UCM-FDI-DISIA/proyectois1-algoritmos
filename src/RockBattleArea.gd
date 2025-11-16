extends Area2D

# =====================================================================
# 🧾 NODOS
# =====================================================================
@onready var battle_button: TextureButton
@onready var battle_icon: Sprite2D        

# =====================================================================
# 🎮 ESTADO
# =====================================================================
var player_in_area := false

# =====================================================================
# ⚙️ REFERENCIA AL JUGADOR (asignar en el editor)
# =====================================================================
@onready var player: CharacterBody2D = get_node("/root/Main/Objetos/Player")

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	var quadrant : int = MultiplayerManager.get_my_quadrant()
	match (quadrant):
		0: battle_button = get_node("/root/Main/Objetos/BotonBatalla1") 
		pass
		1: battle_button = get_node("/root/Main/Objetos/BotonBatalla2") 
		pass
		2: battle_button = get_node("/root/Main/Objetos/BotonBatalla3")
		pass
		3: battle_button = get_node("/root/Main/Objetos/BotonBatalla4")
		pass
	battle_icon = battle_button.get_node("BattleIcon")
	
	if player == null:
		push_error("❌ Asigna el nodo jugador al export var 'player' en el editor")
	
	# Botón oculto/deshabilitado por defecto
	battle_button.visible  = true
	battle_button.disabled = true
	battle_button.tooltip_text = "Aún no puedes atacar ⚔️"

	# Conexiones UI
	battle_button.mouse_entered.connect(_on_button_hover)
	battle_button.mouse_exited.connect(_on_button_exit)
	battle_button.pressed.connect(_on_battle_button_pressed)

	# Señales del área
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Timer opcional para habilitar el botón
	var timer_node = get_node_or_null("/root/Main/ElementosPantalla/Timer/Panel/TimerRoot")
	if timer_node:
		timer_node.connect("tiempo_especifico_alcanzado", Callable(self, "_on_tiempo_especifico_alcanzado"))
	else:
		push_warning("⚠️ TimerRoot no encontrado, el botón permanecerá deshabilitado hasta habilitarlo manualmente")

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
	GameState.attack_other()
