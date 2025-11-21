extends Node2D
class_name CasaMineros

# ============================================================
# 🔧 VARIABLES EDITABLES
# ============================================================
@export var coste_nuevo_minero := 25
@export var max_mineros := 5
@export var mineros_iniciales := 2

# ============================================================
# 🎮 ESTADO
# ============================================================
var mineros_actuales := 0 # Cambiado a mineros_actuales
var jugador_dentro := false

# ============================================================
# 🧩 NODOS
# ============================================================
@onready var boton_minero := $UI/ComprarMinero # Ajustado el nombre del nodo del botón
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

	# Registrar mineros iniciales → suman producción de ORO (o el recurso que produzcan)
	resource_manager.add_resource("gold", 0) # asegura inicialización de oro (o "stone" si produce piedra)
	# Si quieres producción automática, deberás programarla en ResourceManager

	# Conectar señales
	area_interaccion.body_entered.connect(_on_player_enter)
	area_interaccion.body_exited.connect(_on_player_exit)
	boton_minero.pressed.connect(_on_comprar_minero) # Conexión cambiada

	# Ocultar botón por defecto
	boton_minero.visible = false

	print("[CasaMineros] Casa creada con %d mineros." % mineros_actuales) # Mensaje cambiado


# ============================================================
# 🚪 DETECCIÓN DE JUGADOR
# ============================================================
func _on_player_enter(body):
	if body.name == "Jugador": 
		jugador_dentro = true
		_actualizar_boton()

func _on_player_exit(body):
	if body.name == "Jugador":
		jugador_dentro = false
		boton_minero.visible = false # Botón cambiado


# ============================================================
# 🛠️ ACTUALIZAR BOTÓN
# ============================================================
func _actualizar_boton():
	boton_minero.visible = jugador_dentro and mineros_actuales < max_mineros # Variables cambiadas


# ============================================================
# 💰 COMPRAR NUEVO MINERO
# ============================================================
func _on_comprar_minero(): # Función cambiada
	if mineros_actuales >= max_mineros: # Variable cambiada
		print("[CasaMineros] Límite de mineros alcanzado.")
		return

	# Comprobación con el ResourceManager REAL
	var oro : int # Recurso de pago cambiado a ORO
	oro = resource_manager.get_resource("gold")
	if oro < coste_nuevo_minero: # Variable cambiada
		print("[CasaMineros] No hay oro suficiente (%d/%d)." %
			[oro, coste_nuevo_minero])
		return

	# Resta el recurso (ORO)
	resource_manager.remove_resource("gold", coste_nuevo_minero)

	# Añade un minero
	mineros_actuales += 1 # Variable cambiada
	print("[CasaMineros] Nuevo minero añadido. Total: %d" % mineros_actuales)

	# Actualización botón
	_actualizar_boton()


# ============================================================
# 🧹 AL ELIMINAR CASA
# ============================================================
func _exit_tree() -> void:
	print("[CasaMineros] Casa destruida. Se perdieron %d mineros." %
		mineros_actuales) # Variable cambiada
