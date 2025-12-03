extends CanvasLayer

@onready var texto := $AvisarPlayer

func _ready():
	texto.text = "Modo de juego: " + GameState.game_mode
	texto.visible = true
	print("[Label Avisos] Listo para avisar al jugador")

	# Pedir al MultiplayerManager que empiece a mostrar mensajes
	MultiplayerManager.conectar_con_label_avisos(self)
	await get_tree().create_timer(5.0).timeout
	texto.visible = false

func _on_avisando_jugador():
	print("[Label Avisos] Voy a avisar al jugador...")
	texto.visible = true
	texto.text = 	"Oh no... ¡Tu enemigo ha abandonado! \n Ahora juegas en modo PVE"
	
	await get_tree().create_timer(10.0).timeout
	texto.visible = false
