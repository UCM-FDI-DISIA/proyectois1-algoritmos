extends Node

# ----------------------------
# SEÑALES
# ----------------------------
signal ResourceUpdated(resource_name, new_value)
signal VillagerCapacityUpdated()

# ----------------------------
# VARIABLES DE CASAS Y ALDEANOS
# ----------------------------
var house_count := 0
const VILLAGERS_PER_HOUSE := 50

var crecimiento_aldeanos := 0
const TIEMPO_CRECIMIENTO := 10.0
var actualizar_timer : Timer

# ----------------------------
# RECURSOS Y LÍMITES
# ----------------------------
const MAX_RESOURCE := 99

# Costes de construcción de casa
const CASA_WOOD_COST := 20
const CASA_GOLD_COST := 10
const CASA_STONE_COST := 5

# Referencias externas
@export var contenedor_casas : Node2D
@export var casa_scene : PackedScene

# Diccionario de recursos
var resources := {
	"wood": 0,
	"stone": 0,
	"gold": 0,
	"villager": 0
}

# ----------------------------
# GETTERS DE COSTES DE CASA
# ----------------------------
func get_casa_wood_cost() -> int:
	return CASA_WOOD_COST

func get_casa_gold_cost() -> int:
	return CASA_GOLD_COST

func get_casa_stone_cost() -> int:
	return CASA_STONE_COST

# ----------------------------
# INICIALIZACIÓN
# ----------------------------
func _ready() -> void:
	print("[ResourceManager] Iniciando...")

	if contenedor_casas == null:
		push_error("contenedorCasas no asignado.")
	if casa_scene == null:
		push_error("casaScene no asignada.")

	actualizar_timer = Timer.new()
	actualizar_timer.wait_time = TIEMPO_CRECIMIENTO
	actualizar_timer.one_shot = false
	actualizar_timer.timeout.connect(_on_actualizar_timeout)
	add_child(actualizar_timer)

# ----------------------------
# GESTIÓN DE RECURSOS
# ----------------------------
func add_resource(name: String, amount: int = 1) -> void:
	if not resources.has(name):
		return

	if name == "villager":
		resources[name] = min(resources[name] + amount, get_villager_capacity())
	else:
		resources[name] = min(resources[name] + amount, MAX_RESOURCE)

	emit_signal("ResourceUpdated", name, resources[name])

func remove_resource(name: String, amount: int) -> bool:
	if not resources.has(name) or resources[name] < amount:
		return false

	resources[name] -= amount
	emit_signal("ResourceUpdated", name, resources[name])
	return true

func get_resource(name: String) -> int:
	return resources.get(name, 0)

# ----------------------------
# GESTIÓN DE CASAS
# ----------------------------
func puedo_comprar_casa() -> bool:
	return resources["wood"] >= CASA_WOOD_COST and resources["gold"] >= CASA_GOLD_COST and resources["stone"] >= CASA_STONE_COST

func pagar_casa() -> void:
	remove_resource("wood", CASA_WOOD_COST)
	remove_resource("gold", CASA_GOLD_COST)
	remove_resource("stone", CASA_STONE_COST)

func add_house() -> void:
	house_count += 1
	emit_signal("VillagerCapacityUpdated")

func remove_house() -> void:
	house_count = max(0, house_count - 1)
	emit_signal("VillagerCapacityUpdated")

func get_villager_capacity() -> int:
	return house_count * VILLAGERS_PER_HOUSE

func get_house_count() -> int:
	return house_count

# ----------------------------
# CRECIMIENTO DE ALDEANOS
# ----------------------------
func actualizar_aldeanos(n: int) -> void:
	crecimiento_aldeanos = n
	if not actualizar_timer.is_stopped():
		bucle_aldeanos()
	else:
		bucle_aldeanos()

func _on_actualizar_timeout() -> void:
	if crecimiento_aldeanos > 0:
		var current = resources["villager"]
		var max_villagers = get_villager_capacity()
		if current < max_villagers:
			add_resource("villager", crecimiento_aldeanos)

func bucle_aldeanos() -> void:
	if crecimiento_aldeanos > 0:
		actualizar_timer.start()
	else:
		actualizar_timer.stop()
