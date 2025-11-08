extends Node2D

# =====================================================================
# 🔧 VARIABLES EDITABLES
# =====================================================================

# =====================
# 🧱 CAPAS DEL MAPA
# =====================
@onready var capa_suelo: TileMapLayer = $Mapa/Suelo_0
@onready var capa_objetos: Node2D = $Mapa/Objetos

# =====================================================================
# ⚙️ INICIALIZACIÓN
# =====================================================================
func _ready() -> void:
	# Las referencias ya se obtienen automáticamente con @onready
	pass
