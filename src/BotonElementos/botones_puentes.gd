extends Node2D
class_name Puentes

# ==========================================================
#  CONFIG POR PUENTE
# ==========================================================
@export_group("Puente 1 (2 celdas)")
@export var p1_cells: Array[Vector2i] = [
	Vector2i(13, -5),
	Vector2i(13, -4)
]
@export var p1_atlas: Vector2i = Vector2i(0, 2)

@export_group("Puente 2")
@export var p2_cells: Array[Vector2i] = [
	Vector2i(22, -14), Vector2i(23, -14), Vector2i(24, -14)
]
@export var p2_atlas: Vector2i = Vector2i(1, 0)

@export_group("Puente 3+4 (6 celdas)")
@export var p34_cells: Array[Vector2i] = [
	Vector2i(-18, -3), Vector2i(-19, -3), Vector2i(-20, -3),
	Vector2i(-34, 7),  Vector2i(-34, 8),  Vector2i(-34, 9)
]

# ----------------------------------------------------------
#  REFERENCIAS
# ----------------------------------------------------------
@export var tile_map_path: NodePath = NodePath("/root/Main/Mapa/Decoracion")
@export var source_id: int = 9
@onready var tilemap: TileMapLayer = get_node(tile_map_path)
@onready var rm: ResourceManager = get_node("/root/Main/ResourceManager")

# ----------------------------------------------------------
#  INICIALIZACIÓN
# ----------------------------------------------------------
func _ready() -> void:
	for i in range(1, 5):
		var btn: TextureButton = get_node("Puente%d" % i)
		if not btn:
			continue
		var cost_id := "puente3" if i >= 3 else "puente%d" % i
		btn.tooltip_text = _tooltip(rm.get_puente_costs(cost_id))
		btn.pressed.connect(_on_puente_pressed.bind(i))

# ----------------------------------------------------------
#  COMPRA Y COLOCADO
# ----------------------------------------------------------
func _on_puente_pressed(id: int) -> void:
	var cells: Array[Vector2i]
	var atlas: Vector2i
	var cost_id: String

	match id:
		1:
			cells = p1_cells; atlas = p1_atlas; cost_id = "puente1"
		2:
			cells = p2_cells; atlas = p2_atlas; cost_id = "puente2"
		3, 4:
			cells = p34_cells; cost_id = "puente3"
		_:
			return

	# ------------------------------------------------------
	# ⭐ OCULTAR BOTONES ANTES DE EMPEZAR LA ANIMACIÓN
	# ------------------------------------------------------
	var btn: TextureButton = get_node("Puente%d" % id)
	btn.visible = false
	if id in [3, 4]:
		for i in [3, 4]:
			get_node("Puente%d" % i).visible = false

	# ------------------------------------------------------
	# RECURSOS
	# ------------------------------------------------------
	var cost := rm.get_puente_costs(cost_id)
	for res in cost:
		if rm.get_resource(res) < cost[res]:
			print("Faltan recursos para %s" % cost_id)
			return
	for res in cost:
		rm.remove_resource(res, cost[res])

	# Construcción progresiva
	await _colocar_puente_con_delay(id, cells, atlas)

# ----------------------------------------------------------
#  APARICIÓN PROGRESIVA (0.5 s entre tiles)
# ----------------------------------------------------------
func _colocar_puente_con_delay(id: int, cells: Array[Vector2i], atlas: Vector2i) -> void:
	var delay := 0.5

	if id == 3 or id == 4:
		for i in range(3):
			tilemap.set_cell(cells[i], source_id, Vector2i(1, 0))
			await get_tree().create_timer(delay).timeout

		for i in range(3, 6):
			tilemap.set_cell(cells[i], source_id, Vector2i(0, 2))
			await get_tree().create_timer(delay).timeout

	else:
		for c in cells:
			tilemap.set_cell(c, source_id, atlas)
			await get_tree().create_timer(delay).timeout

# ----------------------------------------------------------
#  UTILS
# ----------------------------------------------------------
func _tooltip(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	for res in cost:
		if cost[res] > 0:
			parts.append("%s %d" % [res.capitalize(), cost[res]])
	return "Coste: " + ", ".join(parts) if parts.size() else "Gratis"
