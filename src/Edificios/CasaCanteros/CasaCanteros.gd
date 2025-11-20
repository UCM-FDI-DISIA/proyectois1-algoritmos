extends Node2D
class_name CasaCanteros

# ============================================================
# 🔧 VARIABLES EDITABLES
# ============================================================
@export var coste_nuevo_cantero := 25          # COSTE del nuevo trabajador
@export var max_canteros := 5                  # Máximo permitidos
@export var canteros_iniciales := 2            # Aparecen por defecto

# ============================================================
# 🎮 ESTADO
# ============================================================
var canteros_actuales := 0
var jugador_dentro := false

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
		push_error("[CasaCanteros] ResourceManager no encontrado")
		return

	# Registrar canteros iniciales
	resource_manager.add_stone_workers(canteros_actuales)

	# Conectar señales
	area_interaccion.body_entered.connect(_on_player_enter)
	area_interaccion.body_exited.connect(_on_player_exit)
	boton_cantero.pressed.connect(_on_comprar_cantero)

	# Ocultar botón por defecto
	boton_cantero.visible = false

	print("[CasaCanteros] Casa creada con %d canteros." % canteros_actuales)


# ============================================================
# 🚪 DETECCIÓN DE JUGADOR
# ============================================================
func _on_player_enter(body):
	if body.name == "Jugador": # Ajusta al nombre real de tu player
		jugador_dentro = true
		_actualizar_boton()


func _on_player_exit(body):
	if body.name == "Player":
		jugador_dentro = false
		boton_cantero.visible = false


# ============================================================
# 🛠️ ACTUALIZAR BOTÓN
# ============================================================
func _actualizar_boton():
	if jugador_dentro and canteros_actuales < max_canteros:
		boton_cantero.visible = true
	else:
		boton_cantero.visible = false


# ============================================================
# 💰 COMPRAR NUEVO CANTERO
# ============================================================
func _on_comprar_cantero():
	if canteros_actuales >= max_canteros:
		print("[CasaCanteros] Límite de canteros alcanzado.")
		return

	# Comprobar recursos
	if resource_manager.get_stone() < coste_nuevo_cantero:
		print("[CasaCanteros] No hay piedra suficiente para añadir un cantero.")
		return

	# Restar recursos
	resource_manager.remove_stone(coste_nuevo_cantero)

	# Añadir cantero
	canteros_actuales += 1
	resource_manager.add_stone_workers(1)

	print("[CasaCanteros] Nuevo cantero añadido. Total: %d" % canteros_actuales)

	# Actualizar visibilidad del botón
	_actualizar_boton()


# ============================================================
# 🧹 AL ELIMINAR CASA
# ============================================================
func _exit_tree() -> void:
	if resource_manager:
		resource_manager.remove_stone_workers(canteros_actuales)

	print("[CasaCanteros] Casa destruida. Se eliminaron %d canteros." %
		canteros_actuales)
