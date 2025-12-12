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

@export var p5_start: Vector2i = Vector2i(114, -2)
@export var p5_end:   Vector2i = Vector2i(114, -7)

@export var p6_start: Vector2i = Vector2i(107, -14)
@export var p6_end:   Vector2i = Vector2i(101, -14)

@export var p7_start: Vector2i = Vector2i(142, -3)
@export var p7_end:   Vector2i = Vector2i(150, -3)

@export var p8_start: Vector2i = Vector2i(161, 11)
@export var p8_end:   Vector2i = Vector2i(161, 5)

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

# sonidos añadidos
@onready var wood_sound: AudioStreamPlayer = $WoodPlace
@onready var ding_sound: AudioStreamPlayer = $Ding

# ==========================================================
#   INICIALIZACIÓN
# ==========================================================
func _ready() -> void:
	for i in range(1, 9):
		var btn: TextureButton = get_node("Puente%d" % i)
		if not btn:
			continue

		var cost_id := "puente3" if i in [3,4,7] else "puente1" if i in [1,5] else "puente2" if i in [2,6] else "puente3"

		btn.tooltip_text = _tooltip(rm.get_puente_costs(cost_id))
		btn.disabled = not _hay_recursos(cost_id)

		btn.pressed.connect(_on_puente_pressed.bind(i))

# ==========================================================
#   ACTUALIZACIÓN DINÁMICA DE BOTONES
# ==========================================================
func _process(_delta: float) -> void:
	for i in range(1, 9):
		var btn: TextureButton = get_node("Puente%d" % i)
		if not btn or not btn.visible:
			continue
		var cost_id := "puente3" if i in [3,4,7] else "puente1" if i in [1,5] else "puente2"
		btn.disabled = not _hay_recursos(cost_id)

# ==========================================================
#   UTIL PARA COMPROBAR RECURSOS
# ==========================================================
func _hay_recursos(cost_id: String) -> bool:
	var cost := rm.get_puente_costs(cost_id)
	for res in cost:
		if rm.get_resource(res) < cost[res]:
			return false
	return true

# ==========================================================
#   AL PULSAR UN BOTÓN
# ==========================================================
func _on_puente_pressed(id: int) -> void:
	var start: Vector2i
	var end: Vector2i
	var cost_id: String

	match id:
		1:
			start = p1_start; end = p1_end; cost_id = "puente1"
		2:
			start = p2_start; end = p2_end; cost_id = "puente2"
		3:
			start = p3_start; end = p3_end; cost_id = "puente3"
		4:
			start = p4_start; end = p4_end; cost_id = "puente3"
		5:
			start = p5_start; end = p5_end; cost_id = "puente1"
		6:
			start = p6_start; end = p6_end; cost_id = "puente2"
		7:
			start = p7_start; end = p7_end; cost_id = "puente3"
		8:
			start = p8_start; end = p8_end; cost_id = "puente3"
		_:
			return

	if not _hay_recursos(cost_id):
		print("Faltan recursos para", cost_id)
		return

	var cost := rm.get_puente_costs(cost_id)
	for res in cost:
		rm.remove_resource(res, cost[res])

	get_node("Puente%d" % id).visible = false

	await _construir_puente(id, start, end)

# ==========================================================
#   CONSTRUCCIÓN PROGRESIVA DEL PUENTE (WoodPlace + Ding)
# ==========================================================
func _construir_puente(id: int, start: Vector2i, end: Vector2i) -> void:
	var delay := 0.5

	var atlas_inicio: Vector2i
	var atlas_medio: Vector2i
	var atlas_final: Vector2i

	match id:
		1,5:
			atlas_inicio = Vector2i(0,3)
			atlas_medio  = Vector2i(0,2)
			atlas_final  = Vector2i(0,1)

		4,8:
			atlas_inicio = Vector2i(0,3)
			atlas_medio  = Vector2i(0,2)
			atlas_final  = Vector2i(0,1)

		2,6:
			atlas_inicio = Vector2i(2,0)
			atlas_medio  = Vector2i(1,0)
			atlas_final  = Vector2i(0,0)

		3,7:
			atlas_inicio = Vector2i(0,0)
			atlas_medio  = Vector2i(1,0)
			atlas_final  = Vector2i(2,0)

	# --- pieza inicial ---
	tilemap.set_cell(start, source_id, atlas_inicio)
	wood_sound.play()
	await get_tree().create_timer(delay).timeout

	# --- piezas intermedias ---
	var delta := end - start
	var dir := Vector2i(
		0 if delta.x == 0 else 1 if delta.x > 0 else -1,
		0 if delta.y == 0 else 1 if delta.y > 0 else -1
	)

	var pos := start + dir
	while pos != end:
		tilemap.set_cell(pos, source_id, atlas_medio)
		wood_sound.play()
		await get_tree().create_timer(delay).timeout
		pos += dir

	# --- pieza final ---
	tilemap.set_cell(end, source_id, atlas_final)
	wood_sound.play()

	# terreno
	suelo_map.set_cell(start, source_suelo_id, Vector2i(1,1))
	suelo_map.set_cell(end, source_suelo_id, Vector2i(1,1))

	# --- sonido final ---
	ding_sound.play()

# ==========================================================
#   UTILS
# ==========================================================
func _tooltip(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	for res in cost:
		if cost[res] > 0:
			parts.append("%s %d" % [res.capitalize(), cost[res]])
	return "Coste: " + ", ".join(parts) if parts.size() else "Gratis"
