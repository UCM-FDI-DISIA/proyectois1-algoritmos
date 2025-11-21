extends Node2D
class_name CasaMineros

# ============================================================
# 🔧 VARIABLES EDITABLES
# ============================================================
@export var coste_nuevo_minero := 25
@export var max_mineros := 5
@export var mineros_iniciales := 2
@export var UI_OFFSET := Vector2(-45, -292) # Posición del botón sobre la casa

# ============================================================
# 🎮 ESTADO
# ============================================================
var mineros_actuales := 0
var jugador_dentro := false
var debug := true

# ============================================================
# 🧩 NODOS
# ============================================================
@onready var boton_minero := $UI/ComprarMinero
@onready var area_interaccion := $interaccion
@onready var resource_manager := get_node("/root/Main/ResourceManager")

# ============================================================
# ⚙️ READY
# ============================================================
func _ready() -> void:
	mineros_actuales = mineros_iniciales

	if resource_manager == null:
		push_error("[CasaMineros] ERROR: ResourceManager no encontrado.")
		return

	resource_manager.add_resource("gold", 0) # asegura inicialización de oro

	# Conectar señales
	area_interaccion.body_entered.connect(_on_player_enter)
	area_interaccion.body_exited.connect(_on_player_exit)
	boton_minero.pressed.connect(_on_comprar_minero)

	# Posicionar botón sobre la casa
	boton_minero.position = UI_OFFSET
	boton_minero.z_index = 100
	boton_minero.visible = false

	if debug:
		print("[CasaMineros] Casa creada con %d mineros." % mineros_actuales)
		print("[CasaMineros] Botón posición local:", boton_minero.position)
		print("[CasaMineros] Botón visible:", boton_minero.visible)
		print("[CasaMineros] Botón z_index:", boton_minero.z_index)

# ============================================================
# 🚪 DETECCIÓN DE JUGADOR
# ============================================================
func _on_player_enter(body):
	if body.is_in_group("jugador"):
		jugador_dentro = true
		_actualizar_boton()
		if debug:
			print("[CasaMineros] Jugador entró. Botón actualizado.")

func _on_player_exit(body):
	if body.is_in_group("jugador"):
		jugador_dentro = false
		boton_minero.visible = false
		if debug:
			print("[CasaMineros] Jugador salió. Botón oculto.")

# ============================================================
# 🛠️ ACTUALIZAR BOTÓN
# ============================================================
func _actualizar_boton():
	boton_minero.visible = jugador_dentro and mineros_actuales < max_mineros
	if debug:
		print("[CasaMineros] _actualizar_boton() → visible:", boton_minero.visible)
		print("[CasaMineros] Botón global_position:", boton_minero.global_position)
		print("[CasaMineros] Botón rect_size:", boton_minero.rect_size if boton_minero.has_method("rect_size") else "N/A")

# ============================================================
# 💰 COMPRAR NUEVO MINERO
# ============================================================
func _on_comprar_minero():
	if mineros_actuales >= max_mineros:
		print("[CasaMineros] Límite de mineros alcanzado.")
		return

	var oro : int = resource_manager.get_resource("gold")
	if oro < coste_nuevo_minero:
		print("[CasaMineros] No hay oro suficiente (%d/%d)." %
			[oro, coste_nuevo_minero])
		return

	resource_manager.remove_resource("gold", coste_nuevo_minero)
	mineros_actuales += 1
	print("[CasaMineros] Nuevo minero añadido. Total: %d" % mineros_actuales)

	_actualizar_boton()

# ============================================================
# 🧹 AL ELIMINAR CASA
# ============================================================
func _exit_tree() -> void:
	print("[CasaMineros] Casa destruida. Se perdieron %d mineros." %
		mineros_actuales)
