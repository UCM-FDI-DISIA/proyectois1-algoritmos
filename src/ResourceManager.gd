extends Node
class_name ResourceManager

signal ResourceUpdated(resource_name, new_value)
signal VillagerCapacityUpdated()

const VILLAGERS_PER_HOUSE := 50
const TIEMPO_CRECIMIENTO := 10.0
const MAX_RESOURCE := 99

# -------------------- COSTES DE CONSTRUCCIÓN -------------------------
const CASA_WOOD_COST := 20
const CASA_GOLD_COST := 5
const CASA_STONE_COST := 5
# --------------------------------------------------------------------

# -------------------- COSTES DE SOLDADOS ----------------------------
const SOLDIER_COSTS := {
	"Warrior": { "villager": 1, "gold": 1, "wood": 1, "stone": 0 },
	"Archer":  { "villager": 1, "gold": 2, "wood": 0, "stone": 0 },
	"Lancer":  { "villager": 1, "gold": 3, "wood": 0, "stone": 0 },
	"Monk":    { "villager": 1, "gold": 5, "wood": 0, "stone": 0 }
}
# --------------------------------------------------------------------

@export var contenedor_casas: Node2D
@export var casa_scene: PackedScene

var house_count := 0
var crecimiento_aldeanos := 0
var actualizar_timer: Timer
var resources := {"wood":0, "stone":0, "gold":0, "villager":0}

# -------------- getters casa ---------------------------------------
func get_casa_wood_cost() -> int: return CASA_WOOD_COST
func get_casa_gold_cost()  -> int: return CASA_GOLD_COST
func get_casa_stone_cost() -> int: return CASA_STONE_COST
# --------------------------------------------------------------------

# -------------- getter soldados -------------------------------------
func get_soldier_costs(type: String) -> Dictionary:
	return SOLDIER_COSTS.get(type, {})

# --------------------------------------------------------------------
func _ready() -> void:
	actualizar_timer = Timer.new()
	actualizar_timer.wait_time = TIEMPO_CRECIMIENTO
	actualizar_timer.one_shot = false
	actualizar_timer.timeout.connect(_on_actualizar_timeout)
	add_child(actualizar_timer)

func add_resource(name: String, amount := 1) -> void:
	if not resources.has(name): return
	if name == "villager":
		resources[name] = min(resources[name]+amount, get_villager_capacity())
	else:
		resources[name] = min(resources[name]+amount, MAX_RESOURCE)
	ResourceUpdated.emit(name, resources[name])

func remove_resource(name: String, amount: int) -> bool:
	if not resources.has(name) or resources[name]<amount: return false
	resources[name] -= amount
	ResourceUpdated.emit(name, resources[name])
	return true

func get_resource(name: String) -> int:
	return resources.get(name, 0)

func puedo_comprar_casa() -> bool:
	return resources.wood >= CASA_WOOD_COST and \
		   resources.gold >= CASA_GOLD_COST and \
		   resources.stone>= CASA_STONE_COST

func pagar_casa() -> void:
	remove_resource("wood", CASA_WOOD_COST)
	remove_resource("gold", CASA_GOLD_COST)
	remove_resource("stone",CASA_STONE_COST)

func add_house() -> void:
	house_count += 1
	VillagerCapacityUpdated.emit()

func remove_house() -> void:
	house_count = max(0, house_count-1)
	VillagerCapacityUpdated.emit()

func get_villager_capacity() -> int:
	return house_count * VILLAGERS_PER_HOUSE

func get_house_count() -> int:
	return house_count

func actualizar_aldeanos(n: int) -> void:
	crecimiento_aldeanos = n
	bucle_aldeanos()

func _on_actualizar_timeout() -> void:
	if crecimiento_aldeanos>0:
		var current = resources.villager
		var max_v = get_villager_capacity()
		if current < max_v:
			add_resource("villager", crecimiento_aldeanos)

func bucle_aldeanos() -> void:
	if crecimiento_aldeanos>0: actualizar_timer.start()
	else: actualizar_timer.stop()
