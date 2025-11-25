extends Node
class_name ResourceManager

signal ResourceUpdated(resource_name: String, new_value: int)
signal VillagerCapacityUpdated()
signal SoldierUpdated(type: String, count: int)

const VILLAGERS_PER_HOUSE := 50
const TIEMPO_CRECIMIENTO := 10.0
const MAX_RESOURCE := 99

# -------------------- COSTES -------------------------
# CASA NORMAL
const CASA_WOOD_COST := 2
const CASA_GOLD_COST := 5
const CASA_STONE_COST := 5

# CASA CANTEROS
const CANTEROS_WOOD_COST := 0
const CANTEROS_GOLD_COST := 0
const CANTEROS_STONE_COST := 0
const CANTEROS_VILLAGER_COST := 1; 

# CASA LEÑADORES
const LENADORES_WOOD_COST := 0
const LENADORES_GOLD_COST := 0
const LENADORES_STONE_COST := 0
const LENADORES_VILLAGER_COST := 1; 

# CASA MINEROS
const MINEROS_WOOD_COST := 0
const MINEROS_GOLD_COST := 0
const MINEROS_STONE_COST := 0
const MINEROS_VILLAGER_COST := 1; 

# PUENTES
const PUENTES_WOOD_COST := 5
const PUENTES_GOLD_COST := 1;

const SOLDIER_COSTS := {
	"Warrior": { "villager": 1, "gold": 1, "wood": 0, "stone": 0 },
	"Archer": { "villager": 1, "gold": 2, "wood": 0, "stone": 0 },
	"Lancer": { "villager": 1, "gold": 3, "wood": 0, "stone": 0 },
	"Monk": { "villager": 1, "gold": 5, "wood": 0, "stone": 0 }
}
# -----------------------------------------------------

@export var contenedor_casas: Node2D
@export var casa_scene: PackedScene
@export var casa_canteros_scene : PackedScene
@export var casa_lenadores_scene : PackedScene
@export var casa_mineros_scene : PackedScene

var house_count: int = 0
var canteros_house_count: int = 0
var lenadores_house_count: int = 0
var mineros_house_count: int = 0

var crecimiento_aldeanos: int = 0
var actualizar_timer: Timer

# 💡 CORRECCIÓN: Inicialización de recursos de forma segura al inicio
# Define los recursos que deben existir, el valor inicial puede ser 0
var resources: Dictionary = { "wood": 0, "stone": 0, "gold": 0, "villager": 0 }
var soldiers: Dictionary = { "Warrior": 0, "Archer": 0, "Lancer": 0, "Monk": 0 }

# -------------------- PUENTES -------------------------
const PUENTE_COSTS := {
	"puente1": { "wood": 1, "stone": 0, "gold": 0, "villager": 0 },
	"puente2": { "wood": 2, "stone": 0, "gold": 0, "villager": 0 },
	"puente3": { "wood": 3, "stone": 0, "gold": 0, "villager": 0 },
	"puente4": { "wood": 4, "stone": 0, "gold": 0, "villager": 0 },
}

# =====================================================================
# ⚙️ INICIALIZACIÓN (READY)
# =====================================================================
func _ready() -> void:
	# 💡 CORRECCIÓN: Asegura que el timer se crea en _ready
	actualizar_timer = Timer.new()
	actualizar_timer.wait_time = TIEMPO_CRECIMIENTO
	actualizar_timer.one_shot = false
	actualizar_timer.timeout.connect(_on_actualizar_timeout)
	add_child(actualizar_timer)
# -----------------------------------------------------
# PUENTES
# -----------------------------------------------------
func get_puentes_wood_cost() -> int: return PUENTES_WOOD_COST

func get_puentes_gold_cost() -> int: return PUENTES_GOLD_COST

## 🏡 Lógica de Casas
# -----------------------------------------------------
#  CASA NORMAL
# -----------------------------------------------------
func get_casa_wood_cost() -> int: return CASA_WOOD_COST
func get_casa_gold_cost() -> int: return CASA_GOLD_COST
func get_casa_stone_cost() -> int: return CASA_STONE_COST

func add_house() -> void:
	house_count += 1
	VillagerCapacityUpdated.emit()

func remove_house() -> void:
	house_count = max(0, house_count - 1)
	VillagerCapacityUpdated.emit()

func get_house_count() -> int:
	return house_count

# -----------------------------------------------------
#  CASA CANTEROS
# -----------------------------------------------------
func get_canteros_wood_cost() -> int: return CANTEROS_WOOD_COST
func get_canteros_gold_cost() -> int: return CANTEROS_GOLD_COST
func get_canteros_stone_cost() -> int: return CANTEROS_STONE_COST

func add_canteros_house() -> void:
	canteros_house_count += 1

func remove_canteros_house() -> void:
	canteros_house_count = max(0, canteros_house_count - 1)

func get_canteros_house_count() -> int:
	return canteros_house_count

func get_canteros_villager_cost() -> int:
	return CANTEROS_VILLAGER_COST

# -----------------------------------------------------
#  CASA LEÑADORES
# -----------------------------------------------------
func get_lenadores_wood_cost() -> int:
	return LENADORES_WOOD_COST

func get_lenadores_gold_cost() -> int:
	return LENADORES_GOLD_COST

func get_lenadores_stone_cost() -> int:
	return LENADORES_STONE_COST

func get_lenadores_villager_cost() -> int:
	return LENADORES_VILLAGER_COST

func add_lenadores_house() -> void:
	lenadores_house_count += 1

func remove_lenadores_house() -> void:
	lenadores_house_count = max(0, lenadores_house_count - 1)

func get_lenadores_house_count() -> int:
	return lenadores_house_count
# -----------------------------------------------------

# -----------------------------------------------------
#  CASA MINEROS
# -----------------------------------------------------
func get_mineros_wood_cost() -> int:
	return MINEROS_WOOD_COST

func get_mineros_gold_cost() -> int:
	return MINEROS_GOLD_COST

func get_mineros_stone_cost() -> int:
	return MINEROS_STONE_COST

func add_mineros_house() -> void:
	mineros_house_count += 1

func remove_mineros_house() -> void:
	mineros_house_count = max(0, mineros_house_count - 1)

func get_mineros_house_count() -> int:
	return mineros_house_count

func get_mineros_villager_cost() -> int:
	return MINEROS_VILLAGER_COST
# -----------------------------------------------------

func get_villager_capacity() -> int:
	# Solo la casa normal contribuye a la capacidad de aldeanos
	return house_count * VILLAGERS_PER_HOUSE


## ⚔️ Lógica de Soldados
# -----------------------------------------------------
#  SOLDADOS
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
		# Utilizamos remove_resource para restar y emitir la señal
		remove_resource(res, costs[res]) 

	soldiers[type] += 1
	SoldierUpdated.emit(type, soldiers[type])
	print("Reclutado 1 %s. Total: %d" % [type, soldiers[type]])

func get_soldier_count(type: String) -> int:
	return soldiers.get(type, 0)

func get_all_soldier_counts() -> Dictionary:
	return soldiers.duplicate()


## 💎 Lógica de Recursos
# -----------------------------------------------------
#  RECURSOS GENÉRICOS
# -----------------------------------------------------
func add_resource(res_name: String, amount: int = 1) -> void:
	# Utilizamos get para evitar un error si la clave no existe, aunque se inicializa en _ready
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
	# 💡 CORRECCIÓN: Usamos .get(key, default) para devolver 0 si la clave no existe.
	# Esto evita el error si el diccionario no se ha inicializado o si se pide un recurso no definido.
	return resources.get(res_name, 0)


## ⏱️ Lógica de Tiempo y Aldeanos
# -----------------------------------------------------
#  TIEMPO / ALDEANOS
# -----------------------------------------------------
func actualizar_aldeanos(n: int) -> void:
	crecimiento_aldeanos = n
	bucle_aldeanos()

func _on_actualizar_timeout() -> void:
	if crecimiento_aldeanos > 0:
		var current := get_resource("villager")
		var max_v := get_villager_capacity()
		if current < max_v:
			add_resource("villager", crecimiento_aldeanos)

func bucle_aldeanos() -> void:
	# Se comprueba que el timer existe antes de usarlo
	if actualizar_timer:
		if crecimiento_aldeanos > 0: actualizar_timer.start()
		else: actualizar_timer.stop()


## 🏗️ Lógica de Construcción
# -----------------------------------------------------
#  CONSTRUCCIÓN DE CASAS
# -----------------------------------------------------
func puedo_comprar_casa() -> bool:
	# Casa Normal
	return (
		get_resource("wood") >= CASA_WOOD_COST and
		get_resource("stone") >= CASA_STONE_COST and
		get_resource("gold") >= CASA_GOLD_COST
	)
	
func puedo_comprar_casa_canteros() -> bool:
	# Casa Canteros
	return (
		get_resource("wood") >= CANTEROS_WOOD_COST and
		get_resource("stone") >= CANTEROS_STONE_COST and
		get_resource("gold") >= CANTEROS_GOLD_COST and 
		get_resource("villager") >= CANTEROS_VILLAGER_COST
	)

func puedo_comprar_casa_lenadores() -> bool:
	# Casa Leñadores
	return (
		get_resource("wood") >= LENADORES_WOOD_COST and
		get_resource("stone") >= LENADORES_STONE_COST and
		get_resource("gold") >= LENADORES_GOLD_COST and 
		get_resource("villager") >= LENADORES_VILLAGER_COST
	)
	
func puedo_comprar_casa_mineros() -> bool:
	# Casa Mineros
	return (
		get_resource("wood") >= MINEROS_WOOD_COST and
		get_resource("stone") >= MINEROS_STONE_COST and
		get_resource("gold") >= MINEROS_GOLD_COST and 
		get_resource("villager") >= MINEROS_VILLAGER_COST
	)

func pagar_casa() -> bool:
	if not puedo_comprar_casa():
		return false

	remove_resource("wood", CASA_WOOD_COST)
	remove_resource("stone", CASA_STONE_COST)
	remove_resource("gold", CASA_GOLD_COST)
	
	add_house()

	return true

func pagar_casa_canteros() -> bool:
	if not puedo_comprar_casa_canteros():
		return false

	remove_resource("wood", CANTEROS_WOOD_COST)
	remove_resource("stone", CANTEROS_STONE_COST)
	remove_resource("gold", CANTEROS_GOLD_COST)
	
	add_canteros_house()

	return true
	
func pagar_casa_lenadores() -> bool:
	if not puedo_comprar_casa_lenadores():
		return false

	remove_resource("wood", LENADORES_WOOD_COST)
	remove_resource("stone", LENADORES_STONE_COST)
	remove_resource("gold", LENADORES_GOLD_COST)
	
	add_lenadores_house()

	return true

func pagar_casa_mineros() -> bool:
	if not puedo_comprar_casa_mineros():
		return false

	remove_resource("wood", MINEROS_WOOD_COST)
	remove_resource("stone", MINEROS_STONE_COST)
	remove_resource("gold", MINEROS_GOLD_COST)
	
	add_mineros_house()

	return true
# -----------------------------------------------------
#  CONSTRUCCIÓN DE PUENTES
# -----------------------------------------------------

func get_puente_costs(id: String) -> Dictionary:
	return PUENTE_COSTS.get(id, {})
