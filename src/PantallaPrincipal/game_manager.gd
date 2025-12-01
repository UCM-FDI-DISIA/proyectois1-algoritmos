extends Node

var dinero = 1000  # Dinero inicial del jugador
const PRECIO_CASA = 500  # Precio de cada casa

# Nodo contenedor de casas
#onready var contenedor_casas = get_node("Objetos/Edificios/CasasCompradas")  # Ajusta la ruta si es necesario

# Escena de la casa
var casa_scene = preload("res://src/Edificios/Casa/CasaAnimada.tscn")

func comprar_casa():
	if dinero >= PRECIO_CASA:
		dinero -= PRECIO_CASA
		var nueva_casa = casa_scene.instantiate()
		nueva_casa.position = Vector2(200, 200)  # posición inicial
		#contenedor_casas.add_child(nueva_casa)
		print("Casa comprada! Dinero restante:", dinero)
	else:
		print("No tienes suficiente dinero!")
