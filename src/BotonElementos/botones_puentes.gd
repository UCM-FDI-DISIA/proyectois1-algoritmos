extends Node2D
class_name Puentes

# ==========================================================
#  CONFIG POR PUENTE (coordenadas inicio y final)
# ==========================================================
@export var p1_start: Vector2i = Vector2i(13, -2)
@export var p1_end:   Vector2i = Vector2i(13, -7)

@export var p2_start: Vector2i = Vector2i(20, -14)
@export var p2_end:   Vector2i = Vector2i(26, -14)

@export var p3_start: Vector2i = Vector2i(-15, -3)
@export var p3_end:   Vector2i = Vector2i(-23, -3)

@export var p4_start: Vector2i = Vector2i(-34, 11)
@export var p4_end:   Vector2i = Vector2i(-34, 5)

# ==========================================================
#   REFERENCIAS
# ==========================================================
@export var tile_map_path: NodePath = NodePath("/root/Main/Mapa/Decoracion")
@export var suelo_map_path: NodePath = NodePath("/root/Main/Mapa/Suelo")
@export var source_id: int = 9
@export var source_suelo_id: int = 10
@onready var tilemap: TileMapLayer = get_node(tile_map_path)
@onready var suelo_map: TileMapLayer = get_node(suelo_map_path)
@onready var rm: ResourceManager = get_node("/root/Main/ResourceManager")

# ==========================================================
#   INICIALIZACIÓN
# ==========================================================
func _ready() -> void:
	for i in range(1, 5):
		var btn: TextureButton = get_node("Puente%d" % i)
		if not btn:
			continue

		var cost_id := "puente3" if i >= 3 else "puente%d" % i
		btn.tooltip_text = _tooltip(rm.get_puente_costs(cost_id))
		btn.pressed.connect(_on_puente_pressed.bind(i))

# ==========================================================
#   AL PULSAR UN BOTÓN
# ==========================================================
func _on_puente_pressed(id: int) -> void:
	# Ocultar el botón pulsado
	get_node("Puente%d" % id).visible = false

	# Construcción según puente
	match id:
		1:
			await _build_single(1, p1_start, p1_end)
		2:
			await _build_single(2, p2_start, p2_end)
		3:
			await _build_single(3, p3_start, p3_end)
		4:
			await _build_single(4, p4_start, p4_end)
		_:
			return

# ==========================================================
#   CONSTRUIR UN PUENTE INDIVIDUAL
# ==========================================================
func _build_single(id: int, start: Vector2i, end: Vector2i) -> void:
	var cost_id := "puente1" if id == 1 else "puente2" if id == 2 else "puente3"

	# Comprobar recursos
	var cost := rm.get_puente_costs(cost_id)
	for res in cost:
		if rm.get_resource(res) < cost[res]:
			print("Faltan recursos para", cost_id)
			return

	for res in cost:
		rm.remove_resource(res, cost[res])

	# Construcción visual
	await _construir_puente(id, start, end)

# ==========================================================
#   CONSTRUCCIÓN PROGRESIVA DEL PUENTE
# ==========================================================
func _construir_puente(id: int, start: Vector2i, end: Vector2i) -> void:
	var delay := 0.5

	# Atlas según tu lógica
	var atlas_inicio: Vector2i
	var atlas_medio: Vector2i
	var atlas_final: Vector2i

	match id:
		1:
			atlas_inicio = Vector2i(0,3)
			atlas_medio  = Vector2i(0,2)
			atlas_final  = Vector2i(0,1)
		2:
			atlas_inicio = Vector2i(0,0)
			atlas_medio  = Vector2i(1,0)
			atlas_final  = Vector2i(2,0)
		3:
			atlas_inicio = Vector2i(2,0)
			atlas_medio  = Vector2i(1,0)
			atlas_final  = Vector2i(0,0)
		4:
			atlas_inicio = Vector2i(0,3)
			atlas_medio  = Vector2i(0,2)
			atlas_final  = Vector2i(0,1)

	# Construir inicio
	tilemap.set_cell(start, source_id, atlas_inicio)
	await get_tree().create_timer(delay).timeout

	# Construir partes intermedias
	var delta := end - start
	var dir := Vector2i(
		0 if delta.x == 0 else 1 if delta.x > 0 else -1,
		0 if delta.y == 0 else 1 if delta.y > 0 else -1
	)

	var pos := start + dir
	while pos != end:
		tilemap.set_cell(pos, source_id, atlas_medio)
		await get_tree().create_timer(delay).timeout
		pos += dir

	# Construir final
	tilemap.set_cell(end, source_id, atlas_final)

	# Cambiar inicio y final en TileMap "Suelo"
	suelo_map.set_cell(start, source_suelo_id, Vector2i(1,1))
	suelo_map.set_cell(end, source_suelo_id, Vector2i(1,1))

# ==========================================================
#   UTILS
# ==========================================================
func _tooltip(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	for res in cost:
		if cost[res] > 0:
			parts.append("%s %d" % [res.capitalize(), cost[res]])
	return "Coste: " + ", ".join(parts) if parts.size() else "Gratis"
