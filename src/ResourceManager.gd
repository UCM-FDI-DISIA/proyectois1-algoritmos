extends Node
class_name ResourceManager

signal ResourceUpdated(resource_name: String, new_value: int)
signal VillagerCapacityUpdated()
signal SoldierUpdated(type: String, count: int)

const VILLAGERS_PER_HOUSE := 50
const TIEMPO_CRECIMIENTO  := 10.0
const MAX_RESOURCE        := 99

# -------------------- COSTES -------------------------
const CASA_WOOD_COST  := 2
const CASA_GOLD_COST  := 5
const CASA_STONE_COST := 5

# -------------------- COSTES CASA CANTEROS -------------------------
const CANTEROS_WOOD_COST  := 5
const CANTEROS_GOLD_COST  := 5
const CANTEROS_STONE_COST := 15

# -------------------- COSTES CASA LEÑADORES -------------------------
const LENADORES_WOOD_COST  := 20
const LENADORES_GOLD_COST  := 0
const LENADORES_STONE_COST := 5

# -------------------- COSTES CASA MINEROS -------------------------
const MINEROS_WOOD_COST  := 10
const MINEROS_GOLD_COST  := 20
const MINEROS_STONE_COST := 10

const SOLDIER_COSTS := {
	"Warrior": { "villager": 1, "gold": 1, "wood": 0, "stone": 0 },
	"Archer":  { "villager": 1, "gold": 2, "wood": 0, "stone": 0 },
	"Lancer":  { "villager": 1, "gold": 3, "wood": 0, "stone": 0 },
	"Monk":    { "villager": 1, "gold": 5, "wood": 0, "stone": 0 }
}
# -----------------------------------------------------

@export var contenedor_casas: Node2D
@export var casa_scene: PackedScene

var house_count: int = 0
var canteros_house_count: int = 0
var lenadores_house_count: int = 0
var mineros_house_count: int = 0

var crecimiento_aldeanos: int = 0
var actualizar_timer: Timer
var resources: Dictionary = { "wood": 0, "stone": 0, "gold": 0, "villager": 0 }
var soldiers: Dictionary = { "Warrior": 0, "Archer": 0, "Lancer": 0, "Monk": 0 }

# -----------------------------------------------------
#  CASA
# -----------------------------------------------------
func get_casa_wood_cost() -> int: return CASA_WOOD_COST
func get_casa_gold_cost()  -> int: return CASA_GOLD_COST
func get_casa_stone_cost() -> int: return CASA_STONE_COST

# -----------------------------------------------------
#  CASA CANTEROS
# -----------------------------------------------------
func get_canteros_wood_cost() -> int: return CANTEROS_WOOD_COST
func get_canteros_gold_cost() -> int: return CANTEROS_GOLD_COST
func get_canteros_stone_cost() -> int: return CANTEROS_STONE_COST

func add_house() -> void:
	house_count += 1
	VillagerCapacityUpdated.emit()

func add_canteros_house() -> void:
	canteros_house_count += 1

func remove_house() -> void:
	house_count = max(0, house_count - 1)
	VillagerCapacityUpdated.emit()

func remove_canteros_house() -> void:
	canteros_house_count = max(0, canteros_house_count - 1)

func get_house_count() -> int:
	return house_count
	
func get_canteros_house_count() -> int:
	return canteros_house_count

func get_villager_capacity() -> int:
	return house_count * VILLAGERS_PER_HOUSE

# -----------------------------------------------------
#  SOLDADOS
# -----------------------------------------------------
func get_soldier_costs(type: String) -> Dictionary:
	return SOLDIER_COSTS.get(type, {})

func can_reclutar(type: String) -> bool:
	var costs: Dictionary = get_soldier_costs(type)
	for res in costs:
		if get_resource(res) < costs[res]:
			return false
	return true

func reclutar_soldado(type: String) -> void:
	if not can_reclutar(type):
		print("No hay suficientes recursos para reclutar %s" % type)
		return

	var costs: Dictionary = get_soldier_costs(type)
	for res in costs:
		remove_resource(res, costs[res])

	soldiers[type] += 1
	SoldierUpdated.emit(type, soldiers[type])
	print("Reclutado 1 %s. Total: %d" % [type, soldiers[type]])

func get_soldier_count(type: String) -> int:
	return soldiers.get(type, 0)

func get_all_soldier_counts() -> Dictionary:
	return soldiers.duplicate()

# -----------------------------------------------------
#  RECURSOS GENÉRICOS
# -----------------------------------------------------
func add_resource(res_name: String, amount: int = 1) -> void:
	if not resources.has(res_name): return
	if res_name == "villager":
		resources[res_name] = min(resources[res_name] + amount, get_villager_capacity())
	else:
		resources[res_name] = min(resources[res_name] + amount, MAX_RESOURCE)
	ResourceUpdated.emit(res_name, resources[res_name])

func remove_resource(res_name: String, amount: int) -> bool:
	if not resources.has(res_name) or resources[res_name] < amount: return false
	resources[res_name] -= amount
	ResourceUpdated.emit(res_name, resources[res_name])
	return true

func get_resource(res_name: String) -> int:
	return resources.get(res_name, 0)

# -----------------------------------------------------
#  TIEMPO / ALDEANOS
# -----------------------------------------------------
func actualizar_aldeanos(n: int) -> void:
	crecimiento_aldeanos = n
	bucle_aldeanos()

func _on_actualizar_timeout() -> void:
	if crecimiento_aldeanos > 0:
		var current := get_resource("villager")
		var max_v   := get_villager_capacity()
		if current < max_v:
			add_resource("villager", crecimiento_aldeanos)

func bucle_aldeanos() -> void:
	if crecimiento_aldeanos > 0: actualizar_timer.start()
	else: actualizar_timer.stop()

# -----------------------------------------------------
#  UTILIDADES
# -----------------------------------------------------
func _ready() -> void:
	actualizar_timer = Timer.new()
	actualizar_timer.wait_time = TIEMPO_CRECIMIENTO
	actualizar_timer.one_shot = false
	actualizar_timer.timeout.connect(_on_actualizar_timeout)
	add_child(actualizar_timer)

# -----------------------------------------------------
#  CONSTRUCCIÓN DE CASAS
# -----------------------------------------------------
func puedo_comprar_casa() -> bool:
	# Verifica si hay suficientes materiales para una casa
	return (
		get_resource("wood")  >= CASA_WOOD_COST and
		get_resource("stone") >= CASA_STONE_COST and
		get_resource("gold")  >= CASA_GOLD_COST
	)
	
func puedo_comprar_casa_canteros() -> bool:
	return (
		get_resource("wood")  >= CANTEROS_WOOD_COST and
		get_resource("stone") >= CANTEROS_STONE_COST and
		get_resource("gold")  >= CANTEROS_GOLD_COST
	)

func pagar_casa() -> bool:
	# Intenta restar los recursos, devuelve true si se pudo pagar
	if not puedo_comprar_casa():
		return false

	# Resta de forma segura usando remove_resource
	remove_resource("wood",  CASA_WOOD_COST)
	remove_resource("stone", CASA_STONE_COST)
	remove_resource("gold",  CASA_GOLD_COST)

	return true

func pagar_casa_canteros() -> bool:
	if not puedo_comprar_casa_canteros():
		return false

	remove_resource("wood",  CANTEROS_WOOD_COST)
	remove_resource("stone", CANTEROS_STONE_COST)
	remove_resource("gold",  CANTEROS_GOLD_COST)

	return true
