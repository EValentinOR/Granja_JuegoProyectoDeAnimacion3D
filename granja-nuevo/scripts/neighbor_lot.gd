extends Node2D
## Parcela vecinal: muestra el terreno y, al terminar la construccion, la casa y su residente.

@export var textura_terreno: Texture2D
@export var tamano_terreno := Vector2(96, 96)
@onready var temporizador_construccion: Label = $TemporizadorConstruccion
@onready var casa_vecina: Node2D = $CasaVecina
@onready var nombre_vecina: Label = $CasaVecina/NombreVecina
@onready var colision_terreno: CollisionShape2D = $ColisionTerrenoConstruido/Hitbox
var _segundos_construccion_mostrados := -1


func _ready() -> void:
	# Suelo y caminos quedan bajo el jugador; la casa permanece delante.
	z_index = -1
	casa_vecina.z_index = 2
	_actualizar_terreno()


func _actualizar_terreno() -> void:
	var suelo := get_node_or_null("Suelo") as Polygon2D
	if suelo == null:
		return
	var mitad := tamano_terreno * 0.5
	suelo.polygon = PackedVector2Array([
		Vector2(-mitad.x, -mitad.y), Vector2(mitad.x, -mitad.y),
		Vector2(mitad.x, mitad.y), Vector2(-mitad.x, mitad.y),
	])
	suelo.color = Color.WHITE if textura_terreno != null else Color("#9a6842")
	suelo.texture = textura_terreno


func crear_casa(nombre_vecina: String) -> void:
	if casa_vecina.visible:
		return
	self.nombre_vecina.text = nombre_vecina
	casa_vecina.visible = true
	colision_terreno.set_deferred("disabled", false)
	temporizador_construccion.visible = false
	_segundos_construccion_mostrados = -1


func actualizar_temporizador_construccion(segundos_restantes: int) -> void:
	if casa_vecina.visible or segundos_restantes <= 0:
		temporizador_construccion.visible = false
		_segundos_construccion_mostrados = -1
		return
	temporizador_construccion.visible = true
	if segundos_restantes != _segundos_construccion_mostrados:
		temporizador_construccion.text = "Casa lista en %d:%02d" % [floori(float(segundos_restantes) / 60.0), segundos_restantes % 60]
		_segundos_construccion_mostrados = segundos_restantes
