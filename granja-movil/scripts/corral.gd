@tool
extends Node2D
## Corral independiente: se puede mover desde game.tscn con el Inspector o el gizmo 2D.
const ANCHO := 340.0
const ALTO := 230.0
const COLOR_CERCA := Color("#75472f")

@onready var zona_animales: ReferenceRect = $ZonaAnimales


func _ready() -> void:
	if not has_node("Colisiones"):
		_crear_colisiones()
	queue_redraw()


func _draw() -> void:
	# La cerca visible de la granja ya esta hecha con los sprites del mapa.
	# Este nodo solo delimita donde aparecen los animales durante el juego;
	# dibujar otra cerca aqui la superpone y parece un segundo corral.
	if not Engine.is_editor_hint():
		return
	# Dos travesaños y postes; la abertura central coincide con la puerta del mapa.
	draw_line(Vector2(0, 0), Vector2(ANCHO, 0), COLOR_CERCA, 4.0)
	draw_line(Vector2(0, 16), Vector2(ANCHO, 16), COLOR_CERCA, 3.0)
	draw_line(Vector2(0, 0), Vector2(0, ALTO), COLOR_CERCA, 4.0)
	draw_line(Vector2(ANCHO, 0), Vector2(ANCHO, ALTO), COLOR_CERCA, 4.0)
	draw_line(Vector2(0, ALTO - 16), Vector2(130, ALTO - 16), COLOR_CERCA, 3.0)
	draw_line(Vector2(200, ALTO - 16), Vector2(ANCHO, ALTO - 16), COLOR_CERCA, 3.0)
	draw_line(Vector2(0, ALTO), Vector2(130, ALTO), COLOR_CERCA, 4.0)
	draw_line(Vector2(200, ALTO), Vector2(ANCHO, ALTO), COLOR_CERCA, 4.0)
	for x in range(0, int(ANCHO) + 1, 32):
		draw_line(Vector2(x, 0), Vector2(x, 20), COLOR_CERCA, 3.0)
		if x <= 130 or x >= 200:
			draw_line(Vector2(x, ALTO - 20), Vector2(x, ALTO), COLOR_CERCA, 3.0)


func _crear_colisiones() -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.name = "Colisiones"
	add_child(cuerpo)
	_agregar_segmento(cuerpo, Vector2(0, 0), Vector2(ANCHO, 0))
	_agregar_segmento(cuerpo, Vector2(0, 0), Vector2(0, ALTO))
	_agregar_segmento(cuerpo, Vector2(ANCHO, 0), Vector2(ANCHO, ALTO))
	_agregar_segmento(cuerpo, Vector2(0, ALTO), Vector2(130, ALTO))
	_agregar_segmento(cuerpo, Vector2(200, ALTO), Vector2(ANCHO, ALTO))


func _agregar_segmento(cuerpo: StaticBody2D, inicio: Vector2, fin: Vector2) -> void:
	var forma := SegmentShape2D.new()
	forma.a = inicio
	forma.b = fin
	var colision := CollisionShape2D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
