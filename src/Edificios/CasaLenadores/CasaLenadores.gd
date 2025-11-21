extends Node2D
class_name CasaLenadores

# ============================================================
# 🔧 VARIABLES EDITABLES
# ============================================================
@export var coste_nuevo_lenador := 25
@export var max_lenadores := 5
@export var lenadores_iniciales := 2
@export var UI_OFFSET := Vector2(-45, -292) # Posición del botón sobre la casa

# ============================================================
# 🎮 ESTADO
# ============================================================
var lenadores_actuales := 0
var jugador_dentro := false
var debug := true

# ============================================================
# 🧩 NODOS
# ============================================================
@onready var boton_lenador := $UI/ComprarLenador
@onready var area_interaccion := $interaccion
@onready var resource_manager := get_node("/root/Main/ResourceManager")

# ============================================================
# ⚙️ READY
# ============================================================
func _ready() -> void:
	lenadores_actuales = lenadores_iniciales

	if resource_manager == null:
		push_error("[CasaLenadores] ERROR: ResourceManager no encontrado.")
		return

	resource_manager.add_resource("wood", 0) # asegura inicialización

	# Conectar señales
	area_interaccion.body_entered.connect(_on_player_enter)
	area_interaccion.body_exited.connect(_on_player_exit)
	boton_lenador.pressed.connect(_on_comprar_lenador)

	# Posicionar botón sobre la casa
	boton_lenador.position = UI_OFFSET
	boton_lenador.z_index = 100
	boton_lenador.visible = false

	if debug:
		print("[CasaLenadores] Casa creada con %d leñadores." % lenadores_actuales)
		print("[CasaLenadores] Botón posición local:", boton_lenador.position)
		print("[CasaLenadores] Botón visible:", boton_lenador.visible)
		print("[CasaLenadores] Botón z_index:", boton_lenador.z_index)

# ============================================================
# 🚪 DETECCIÓN DE JUGADOR
# ============================================================
func _on_player_enter(body):
	if body.is_in_group("jugador"):
		jugador_dentro = true
		_actualizar_boton()
		if debug:
			print("[CasaLenadores] Jugador entró. Botón actualizado.")

func _on_player_exit(body):
	if body.is_in_group("jugador"):
		jugador_dentro = false
		boton_lenador.visible = false
		if debug:
			print("[CasaLenadores] Jugador salió. Botón oculto.")

# ============================================================
# 🛠️ ACTUALIZAR BOTÓN
# ============================================================
func _actualizar_boton():
	boton_lenador.visible = jugador_dentro and lenadores_actuales < max_lenadores
	if debug:
		print("[CasaLenadores] _actualizar_boton() → visible:", boton_lenador.visible)
		print("[CasaLenadores] Botón global_position:", boton_lenador.global_position)
		print("[CasaLenadores] Botón rect_size:", boton_lenador.rect_size if boton_lenador.has_method("rect_size") else "N/A")

# ============================================================
# 💰 COMPRAR NUEVO LEÑADOR
# ============================================================
func _on_comprar_lenador():
	if lenadores_actuales >= max_lenadores:
		print("[CasaLenadores] Límite de leñadores alcanzado.")
		return

	var madera : int = resource_manager.get_resource("wood")
	if madera < coste_nuevo_lenador:
		print("[CasaLenadores] No hay madera suficiente (%d/%d)." %
			[madera, coste_nuevo_lenador])
		return

	resource_manager.remove_resource("wood", coste_nuevo_lenador)
	lenadores_actuales += 1
	print("[CasaLenadores] Nuevo leñador añadido. Total: %d" % lenadores_actuales)

	_actualizar_boton()

# ============================================================
# 🧹 AL ELIMINAR CASA
# ============================================================
func _exit_tree() -> void:
	print("[CasaLenadores] Casa destruida. Se perdieron %d leñadores." %
		lenadores_actuales)
