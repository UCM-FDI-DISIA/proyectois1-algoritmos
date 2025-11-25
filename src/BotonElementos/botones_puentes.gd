extends Node2D
class_name Puentes

# ==========================================================
#  CONFIG POR PUENTE – editable desde el inspector
# ==========================================================
@export_group("Puente 1")
@export var p1_cells: Array[Vector2i] = [Vector2i(13, 5), Vector2i(13, -4)]
@export var p1_source_id: int = 0
@export var p1_atlas_coord: Vector2i = Vector2i(4, 2)
@export var p1_cost_id: String = "puente1"

@export_group("Puente 2")
@export var p2_cells: Array[Vector2i] = [
	Vector2i(22, -14), Vector2i(23, -14), Vector2i(24, -14)
]
@export var p2_source_id: int = 0
@export var p2_atlas_coord: Vector2i = Vector2i(4, 2)
@export var p2_cost_id: String = "puente2"

@export_group("Puente 3+4 (mismo puente)")
@export var p34_cells: Array[Vector2i] = [
	Vector2i(-18, -3), Vector2i(-19, -3), Vector2i(-20, -3),
	Vector2i(-34, 7), Vector2i(-34, 8), Vector2i(-34, 9)
]
@export var p34_source_id: int = 0
@export var p34_atlas_coord: Vector2i = Vector2i(4, 2)
@export var p34_cost_id: String = "puente3"  # mismo coste para ambos botones

# ----------------------------------------------------------
#  REFERENCIAS
# ----------------------------------------------------------
@export var tile_map_path: NodePath = NodePath("../Mapa/Decoración")
@onready var tilemap: TileMap = get_node(tile_map_path)
@onready var rm: ResourceManager = get_node("/root/Main/ResourceManager")

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
	var source_id: int
	var atlas_coord: Vector2i
	var cost_id: String

	match id:
		1:
			cells = p1_cells
			source_id = p1_source_id
			atlas_coord = p1_atlas_coord
			cost_id = p1_cost_id
		2:
			cells = p2_cells
			source_id = p2_source_id
			atlas_coord = p2_atlas_coord
			cost_id = p2_cost_id
		3, 4:
			cells = p34_cells
			source_id = p34_source_id
			atlas_coord = p34_atlas_coord
			cost_id = p34_cost_id
		_:
			return

	var cost := rm.get_puente_costs(cost_id)
	for res in cost:
		if rm.get_resource(res) < cost[res]:
			print("Faltan recursos para %s" % cost_id)
			return

	for res in cost:
		rm.remove_resource(res, cost[res])

	for c in cells:
		tilemap.set_cell(0, c, source_id, atlas_coord)

	# Oculta el botón pulsado
	var btn: TextureButton = get_node("Puente%d" % id)
	btn.visible = false

	# Si es 3 o 4, oculta ambos
	if id in [3, 4]:
		for i in [3, 4]:
			var other: TextureButton = get_node("Puente%d" % i)
			if other:
				other.visible = false
