extends Control

@onready var texto := $TextoEstado
@onready var anim := $Rueda

func _ready():
	texto.text = "Inicializando..."
	anim.play("girar")

	# Pedir al MultiplayerManager que empiece a buscar partida
	MultiplayerManager.iniciar_busqueda_partida(self)


func _on_estado_matchmaking(msg: String):
	texto.text = msg
