extends Node2D
class_name Puentes

# ==========================================================
#  CONFIG POR PUENTE – editable desde el inspector
# ==========================================================
@export_group("Puente 1")
@export var p1_cells: Array[Vector2i] = [Vector2i(13, 5), Vector2i(13, -4)]
@export var p1_atlas_coord: Vector2i = Vector2i(0, 2)

@export_group("Puente 2")
@export var p2_cells: Array[Vector2i] = [
	Vector2i(22, -14), Vector2i(23, -14), Vector2i(24, -14)
]
@export var p2_atlas_coord: Vector2i = Vector2i(1, 0)

@export_group("Puente 3+4 (mismo puente, 6 celdas)")
@export var p34_cells: Array[Vector2i] = [
	Vector2i(-18, -3), Vector2i(-19, -3), Vector2i(-20, -3),  # ← 3 primeras
	Vector2i(-34, 7), Vector2i(-34, 8), Vector2i(-34, 9)     # ← 3 últimas
]

# ----------------------------------------------------------
#  REFERENCIAS
# ----------------------------------------------------------
@export var tile_map_path: NodePath = NodePath("../Mapa/Decoracion")
@onready var tilemap: TileMapLayer = get_node_or_null("/root/Main/Mapa/Decoracion")
@onready var rm: ResourceManager = get_node("/root/Main/ResourceManager")

const SOURCE_ID := 9  # Bridge_All.png

func _ready() -> void:
	for i in range(1, 5):
		var btn: TextureButton = get_node("Puente%d" % i)
		if btn:
			var cost_id := "puente3" if i >= 3 else "puente%d" % i
			var cost := rm.get_puente_costs(cost_id)
			btn.tooltip_text = _build_tooltip(cost)
			btn.pressed.connect(_on_puente_pressed.bind(i))

func _build_tooltip(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	for res in cost:
		if cost[res] > 0:
			parts.append("%s %d" % [res.capitalize(), cost[res]])
	return "Coste: " + ", ".join(parts) if parts.size() > 0 else "Gratis"

func _on_puente_pressed(id: int) -> void:
	var cells: Array[Vector2i]
	var atlas_coord: Vector2i
	var cost_id: String

	match id:
		1:
			cells = p1_cells
			atlas_coord = Vector2i(0, 2)
			cost_id = "puente1"
		2:
			cells = p2_cells
			atlas_coord = Vector2i(1, 0)
			cost_id = "puente2"
		3, 4:
			cells = p34_cells
			cost_id = "puente3"
		_:
			return

	var cost := rm.get_puente_costs(cost_id)
	for res in cost:
		if rm.get_resource(res) < cost[res]:
			print("Faltan recursos para %s" % cost_id)
			return

	for res in cost:
		rm.remove_resource(res, cost[res])

	# Aplicamos tiles según botón
	if id == 3:
		# Puente 3 → primeras 3 celdas con (0,2)
		for i in range(3):
			tilemap.set_cell(cells[i], SOURCE_ID, Vector2i(0, 2))
	elif id == 4:
		# Puente 4 → últimas 3 celdas con (1,0)
		for i in range(3, 6):
			tilemap.set_cell(cells[i], SOURCE_ID, Vector2i(1, 0))
	else:
		# Puente 1 y 2 → todas sus celdas con su tile
		for c in cells:
			print("=== ANTES DE SET_CELL ===")
			print("tilemap: ", tilemap)
			print("¿es null? ", tilemap == null)
			print("¿es TileMapLayer? ", tilemap is TileMapLayer)
			print("cells: ", cells)
			print("SOURCE_ID: ", SOURCE_ID)
			tilemap.set_cell(c, SOURCE_ID, atlas_coord)

	# Oculta el botón pulsado
	var btn: TextureButton = get_node("Puente%d" % id)
	btn.visible = false

	# Si es 3 o 4, oculta ambos
	if id in [3, 4]:
		for i in [3, 4]:
			var other: TextureButton = get_node("Puente%d" % i)
			if other:
				other.visible = false
