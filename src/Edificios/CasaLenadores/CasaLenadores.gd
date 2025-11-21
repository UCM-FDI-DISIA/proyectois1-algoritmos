extends Node2D
class_name CasaLenadores

# ============================================================
# 🔧 VARIABLES EDITABLES
# ============================================================
@export var coste_nuevo_lenador := 25	 	 	 # COSTE del nuevo trabajador (usaremos madera)
@export var max_lenadores := 5	 	 	 	     # Máximo permitidos
@export var lenadores_iniciales := 2	 	 	 # Aparecen por defecto

# ============================================================
# 🎮 ESTADO
# ============================================================
var lenadores_actuales := 0
var jugador_dentro := false

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

	# Registrar recurso para el leñador (Madera)
	resource_manager.add_resource("wood", 0) # asegura inicialización
	# La lógica de producción automática debe ser manejada en ResourceManager o un Timer

	# Conectar señales
	area_interaccion.body_entered.connect(_on_player_enter)
	area_interaccion.body_exited.connect(_on_player_exit)
	boton_lenador.pressed.connect(_on_comprar_lenador)

	# Ocultar botón por defecto
	boton_lenador.visible = false

	print("[CasaLenadores] Casa creada con %d leñadores." % lenadores_actuales)


# ============================================================
# 🚪 DETECCIÓN DE JUGADOR
# ============================================================
func _on_player_enter(body):
	# Verificamos si es el jugador. Se puede usar un grupo "jugador" o verificar por nombre.
	if body.is_in_group("jugador") or body.name == "Jugador": 
		jugador_dentro = true
		_actualizar_boton()

func _on_player_exit(body):
	if body.is_in_group("jugador") or body.name == "Jugador":
		jugador_dentro = false
		boton_lenador.visible = false


# ============================================================
# 🛠️ ACTUALIZAR BOTÓN
# ============================================================
func _actualizar_boton():
	# El botón es visible si el jugador está dentro Y no se ha alcanzado el máximo
	boton_lenador.visible = jugador_dentro and lenadores_actuales < max_lenadores
	
	# También puedes actualizar el texto del botón aquí para reflejar el coste y el límite
	if boton_lenador.visible:
		boton_lenador.text = "Comprar Leñador\n(%d Madera)" % coste_nuevo_lenador


# ============================================================
# 💰 COMPRAR NUEVO LEÑADOR (Lógica de coste en Madera)
# ============================================================
func _on_comprar_lenador():
	if lenadores_actuales >= max_lenadores:
		print("[CasaLenadores] Límite de leñadores alcanzado.")
		_actualizar_boton() # Oculta el botón por si acaso
		return

	# Comprobación de recurso (Madera - "wood")
	var madera : int; 
	madera = resource_manager.get_resource("wood")
	if madera < coste_nuevo_lenador:
		print("[CasaLenadores] No hay madera suficiente (%d/%d)." %
			[madera, coste_nuevo_lenador])
		return

	# Resta el recurso
	resource_manager.remove_resource("wood", coste_nuevo_lenador)

	# Añade un leñador (Incrementa el estado de producción)
	lenadores_actuales += 1
	
	# Llamar a un método en ResourceManager para registrar al nuevo trabajador
	# resource_manager.register_new_lenador() # Si tienes esta función

	print("[CasaLenadores] Nuevo leñador añadido. Total: %d" % lenadores_actuales)

	# Actualización botón
	_actualizar_boton()


# ============================================================
# 🧹 AL ELIMINAR CASA
# ============================================================
func _exit_tree() -> void:
	# Aquí podrías restar la producción de todos los leñadores al ResourceManager
	print("[CasaLenadores] Casa destruida. Se perdieron %d leñadores." %
		lenadores_actuales)
