extends Node2D
class_name CasaCanteros

# ============================================================
# 🔧 VARIABLES EDITABLES
# ============================================================
@export var coste_nuevo_cantero := 25
@export var max_canteros := 5
@export var canteros_iniciales := 2
@export var UI_OFFSET := Vector2(-45, -292) # Posición del botón sobre la casa

# ============================================================
# 🎮 ESTADO
# ============================================================
var canteros_actuales := 0
var jugador_dentro := false
var debug := true

# ============================================================
# 🧩 NODOS
# ============================================================
@onready var boton_cantero := $UI/ComprarCantero
@onready var area_interaccion := $interaccion
@onready var resource_manager := get_node("/root/Main/ResourceManager")

# ============================================================
# ⚙️ READY
# ============================================================
func _ready() -> void:
	canteros_actuales = canteros_iniciales

	if resource_manager == null:
		push_error("[CasaCanteros] ERROR: ResourceManager no encontrado.")
		return

	resource_manager.add_resource("stone", 0)

	# Conectar señales
	area_interaccion.body_entered.connect(_on_player_enter)
	area_interaccion.body_exited.connect(_on_player_exit)
	boton_cantero.pressed.connect(_on_comprar_cantero)

	# Posicionar botón sobre la casa
	boton_cantero.position = UI_OFFSET
	boton_cantero.z_index = 100
	boton_cantero.visible = false

	if debug:
		print("[CasaCanteros] Casa creada con %d canteros." % canteros_actuales)
		print("[CasaCanteros] Botón posición local:", boton_cantero.position)
		print("[CasaCanteros] Botón visible:", boton_cantero.visible)
		print("[CasaCanteros] Botón z_index:", boton_cantero.z_index)

# ============================================================
# 🚪 DETECCIÓN DE JUGADOR
# ============================================================
func _on_player_enter(body):
	if body.is_in_group("jugador"):
		jugador_dentro = true
		_actualizar_boton()
		if debug:
			print("[CasaCanteros] Jugador entró. Botón actualizado.")

func _on_player_exit(body):
	if body.is_in_group("jugador"):
		jugador_dentro = false
		boton_cantero.visible = false
		if debug:
			print("[CasaCanteros] Jugador salió. Botón oculto.")



# ============================================================
# 🛠️ ACTUALIZAR BOTÓN
# ============================================================
func _actualizar_boton():
	boton_cantero.visible = jugador_dentro and canteros_actuales < max_canteros
	if debug:
		print("[CasaCanteros] _actualizar_boton() → visible:", boton_cantero.visible)
		print("[CasaCanteros] Botón global_position:", boton_cantero.global_position)
		print("[CasaCanteros] Botón rect_size:", boton_cantero.rect_size if boton_cantero.has_method("rect_size") else "N/A")


# ============================================================
# 💰 COMPRAR NUEVO CANTERO
# ============================================================
func _on_comprar_cantero():
	if canteros_actuales >= max_canteros:
		print("[CasaCanteros] Límite de canteros alcanzado.")
		return

	var piedra : int = resource_manager.get_resource("stone")
	if piedra < coste_nuevo_cantero:
		print("[CasaCanteros] No hay piedra suficiente (%d/%d)." %
			[piedra, coste_nuevo_cantero])
		return

	resource_manager.remove_resource("stone", coste_nuevo_cantero)
	canteros_actuales += 1
	print("[CasaCanteros] Nuevo cantero añadido. Total: %d" % canteros_actuales)

	_actualizar_boton()


# ============================================================
# 🧹 AL ELIMINAR CASA
# ============================================================
func _exit_tree() -> void:
	print("[CasaCanteros] Casa destruida. Se perdieron %d canteros." %
		canteros_actuales)
