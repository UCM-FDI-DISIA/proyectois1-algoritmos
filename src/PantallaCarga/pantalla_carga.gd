extends Control

@onready var texto = $TextoEstado
@onready var lobby = $LobbyUnido

func _ready():
	texto.text = "Inicializando..."
	print("[PantallaCarga] _ready → iniciando búsqueda de partida")

	# Pedir al MultiplayerManager que empiece a mostrar mensajes sobre la búsqueda de partida
	MultiplayerManager.iniciar_busqueda_partida(self)

func _on_estado_matchmaking(msg: String):
	texto.text = msg
	print("[PantallaCarga] estado_matchmaking:", msg)
	
func _on_lobby_unido(num: String, ok: bool):
	if ok: lobby.text = "Unido al lobby: " + num
	else : lobby.text = num
