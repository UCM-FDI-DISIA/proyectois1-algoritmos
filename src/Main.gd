extends Node2D
# =====================
# 🧱 CAPAS DEL MAPA
# =====================
@onready var capa_suelo: TileMapLayer = $Mapa/Suelo_0
@onready var capa_objetos: Node2D = $Mapa/Objetos

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	capa_suelo  = get_node("Mapa/Suelo")  # descomenta cuando exista
	capa_objetos = get_node("Objetos/Recursos") # descomenta cuando exista
	pass
