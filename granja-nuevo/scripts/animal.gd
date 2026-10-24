extends "res://scripts/visual_slot.gd"
## Animales con movimiento y ciclos de caminar desde sus hojas de sprites.

@export var velocidad := 60.0
@export var cambio_min := 0.4
@export var cambio_max := 1.6
@export var prob_pausa := 0.2
@export var animacion_fps := 7.0
@export var radio_colision := 18.0

var area := Rect2()
var obstaculos: Array[Rect2] = []
var direccion := Vector2.ZERO
var factor := 1.0
var restante := 0.0
var tiempo_animacion := 0.0
var producto_restante := 60.0
var producto_listo := false
var aviso_producto: Label
@onready var sprite: Sprite2D = get_node_or_null("Sprite") as Sprite2D


func _ready() -> void:
	super()
	producto_restante = randf_range(50.0, 70.0)
	aviso_producto = Label.new()
	aviso_producto.position = Vector2(-10, -58)
	aviso_producto.add_theme_font_size_override("font_size", 22)
	aviso_producto.text = "!"
	aviso_producto.visible = false
	add_child(aviso_producto)
	_nuevo_rumbo()


func iniciar(zona: Rect2, bloqueos: Array[Rect2] = []) -> void:
	area = zona
	obstaculos = bloqueos
	for _intento in 100:
		var candidata := Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
		if not _posicion_bloqueada(candidata):
			global_position = candidata
			return
	global_position = area.position + Vector2(30, 30)


func _nuevo_rumbo() -> void:
	restante = randf_range(cambio_min, cambio_max)
	if randf() < prob_pausa:
		direccion = Vector2.ZERO
	else:
		direccion = Vector2.from_angle(randf() * TAU)
		factor = randf_range(0.5, 1.6)


func _process(delta: float) -> void:
	if not producto_listo:
		producto_restante -= delta
		if producto_restante <= 0.0:
			producto_listo = true
			aviso_producto.visible = true
	restante -= delta
	if restante <= 0.0:
		_nuevo_rumbo()
	if direccion != Vector2.ZERO and area.size != Vector2.ZERO:
		var siguiente := global_position + direccion * velocidad * factor * delta
		if _posicion_bloqueada(siguiente):
			direccion = -direccion
			restante = 0.0
		else:
			global_position = siguiente
	_animar(delta)


func producto_disponible() -> bool:
	return producto_listo


func recoger_producto() -> String:
	if not producto_listo:
		return ""
	producto_listo = false
	producto_restante = 60.0
	if aviso_producto != null:
		aviso_producto.visible = false
	return "leche" if str(get_meta("tipo", "pollo")) == "vaca" else "huevo"


func _posicion_bloqueada(posicion: Vector2) -> bool:
	if not area.has_point(posicion):
		return true
	for obstaculo in obstaculos:
		if obstaculo.grow(radio_colision).has_point(posicion):
			return true
	return false


func _animar(delta: float) -> void:
	if sprite == null or sprite.hframes <= 1:
		return
	var fila := 0
	if direccion != Vector2.ZERO:
		fila = 1 if absf(direccion.y) >= absf(direccion.x) and sprite.vframes > 1 else 0
		if absf(direccion.x) > 0.1:
			sprite.flip_h = direccion.x < 0.0
			fila = 0
	if direccion == Vector2.ZERO:
		tiempo_animacion = 0.0
		sprite.frame = fila * sprite.hframes
	else:
		tiempo_animacion += delta * animacion_fps
		# Los dos primeros cuadros de la fila superior del pollo estan vacios.
		var es_pollo := sprite.hframes == 4 and sprite.vframes == 2
		var cuadros_validos := 2 if es_pollo and fila == 0 else sprite.hframes
		sprite.frame = fila * sprite.hframes + int(tiempo_animacion) % cuadros_validos
