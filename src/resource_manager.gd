# ResourceManager.gd
extends Node

# Diccionario para llevar cuenta de los recursos
var resources = {  #Guarda cuántos recursos hay
	"wood": 0,
	"stone": 0,
	"iron": 0,
	"gold": 0
}

# Señal que se emitirá cuando un recurso cambie
signal resource_updated(resource_name, new_value)

func add_resource(resource_name: String, amount: int = 1) -> void:
	if resource_name in resources:
		resources[resource_name] += amount
		emit_signal("resource_updated", resource_name, resources[resource_name]) 
		#Cada vez que se suma, emite una señal con el nombre del recurso y su nuevo valor.
