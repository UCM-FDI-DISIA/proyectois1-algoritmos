extends Node

# =====================
# VARIABLES
# =====================
var soldiers := {
	"warrior": 0,
	"archer": 0,
	"lancer": 0,
	"monk": 0
}

# Señal equivalente a SoldierUpdated
signal soldier_updated(type: String, count: int)

var resource_manager : ResourceManager

# Costes de cada tipo de soldado
var costs := {
	"warrior": { "villager": 3, "gold": 3, "stone": 3 },
	"archer":  { "villager": 1, "wood": 10 },
	"lancer":  { "villager": 1, "wood": 3, "stone": 5 },
	"monk":    { "villager": 3, "gold": 5 }
}

# =====================
# INICIALIZACIÓN
# =====================
func _ready() -> void:
	resource_manager = get_node("/root/Main/ResourceManager")
	if resource_manager == null:
		push_error("ResourceManager no encontrado")

# =====================
# MÉTODOS
# =====================
func can_afford(type: String) -> bool:
	if not costs.has(type):
		return false

	for res_key in costs[type].keys():
		if resource_manager.get_resource(res_key) < costs[type][res_key]:
			return false
	return true

func add_soldier(type: String) -> void:
	if not can_afford(type):
		print("No hay suficientes recursos para crear %s" % type)
		return

	# Restar recursos
	for res_key in costs[type].keys():
		resource_manager.remove_resource(res_key, costs[type][res_key])

	# Sumar soldado
	soldiers[type] += 1
	emit_signal("soldier_updated", type, soldiers[type])
	print("Se ha creado un %s. Total: %d" % [type, soldiers[type]])

func get_soldier_count(type: String) -> int:
	return soldiers.get(type, 0)
