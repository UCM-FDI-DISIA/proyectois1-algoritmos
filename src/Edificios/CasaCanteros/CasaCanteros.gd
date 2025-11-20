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
		push_error("[CasaCanteros] ERROR: ResourceManager no encontrado.")
		return

	# Registrar canteros iniciales → suman producción de piedra
	resource_manager.add_resource("stone", 0) # asegura inicialización
	# Si quieres producción automática, deberás programarla en ResourceManager

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
	if body.name == "Jugador": # Ajusta al nombre real
		jugador_dentro = true
		_actualizar_boton()

func _on_player_exit(body):
	if body.name == "Jugador":
		jugador_dentro = false
		boton_cantero.visible = false


# ============================================================
# 🛠️ ACTUALIZAR BOTÓN
# ============================================================
func _actualizar_boton():
	boton_cantero.visible = jugador_dentro and canteros_actuales < max_canteros


# ============================================================
# 💰 COMPRAR NUEVO CANTERO
# ============================================================
func _on_comprar_cantero():
	if canteros_actuales >= max_canteros:
		print("[CasaCanteros] Límite de canteros alcanzado.")
		return

	# Comprobación con el ResourceManager REAL
	var piedra : int; 
	piedra = resource_manager.get_resource("stone")
	if piedra < coste_nuevo_cantero:
		print("[CasaCanteros] No hay piedra suficiente (%d/%d)." %
			[piedra, coste_nuevo_cantero])
		return

	# Resta el recurso
	resource_manager.remove_resource("stone", coste_nuevo_cantero)

	# Añade un cantero
	canteros_actuales += 1
	print("[CasaCanteros] Nuevo cantero añadido. Total: %d" % canteros_actuales)

	# Actualización botón
	_actualizar_boton()


# ============================================================
# 🧹 AL ELIMINAR CASA
# ============================================================
func _exit_tree() -> void:
	# Aquí podrías quitar producción si implementas producción de piedra
	print("[CasaCanteros] Casa destruida. Se perdieron %d canteros." %
		canteros_actuales)
