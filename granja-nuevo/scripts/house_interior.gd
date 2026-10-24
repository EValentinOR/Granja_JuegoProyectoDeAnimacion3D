extends Node2D
## Vista independiente de la habitacion y los muebles colocados.

var muebles: Array[Dictionary] = []
var estilo_piso := 0
const ESTILOS_PISO := [
	{"suelo": Color("#a86f47"), "junta": Color("#75472f")},
	{"suelo": Color("#c49a68"), "junta": Color("#8e6948")},
	{"suelo": Color("#765744"), "junta": Color("#49382f")},
	{"suelo": Color("#b87978"), "junta": Color("#845352")},
]


func mostrar_muebles(elementos: Array[Dictionary]) -> void:
	muebles = elementos.duplicate(true)
	queue_redraw()


func set_floor_style(indice: int) -> void:
	estilo_piso = clampi(indice, 0, ESTILOS_PISO.size() - 1)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("#d9b27e"))
	draw_rect(Rect2(28, 84, 652, 492), Color("#5e392a"))
	draw_rect(Rect2(38, 94, 632, 472), Color("#efcea0"))
	draw_rect(Rect2(700, 84, 550, 492), Color("#5e392a"))
	draw_rect(Rect2(710, 94, 530, 472), Color("#f1d9b0"))
	draw_rect(Rect2(40, 96, 628, 270), Color("#eaca9a"))
	var paleta: Dictionary = ESTILOS_PISO[estilo_piso]
	draw_rect(Rect2(40, 368, 628, 196), paleta.suelo)
	for y in range(400, 565, 34):
		draw_line(Vector2(40, y), Vector2(668, y), paleta.junta, 2.0)
		for x in range(60 + (90 if int(y / 34) % 2 == 0 else 0), 668, 200):
			draw_line(Vector2(x, y - 34), Vector2(x, y), paleta.junta, 2.0)
	draw_rect(Rect2(72, 132, 116, 92), Color("#5e392a"))
	draw_rect(Rect2(80, 140, 100, 76), Color("#88c8c2"))
	draw_rect(Rect2(127, 140, 7, 76), Color("#f1d9b0"))
	draw_rect(Rect2(80, 174, 100, 7), Color("#f1d9b0"))
	for mueble in muebles:
		var tam: Vector2 = mueble.size
		var posicion: Vector2 = mueble.position
		var caja := Rect2(posicion - tam * 0.5, tam)
		if str(mueble.get("tipo", "piso")) == "pared":
			var marco: Color = mueble.get("marco", Color("#8b6848"))
			if bool(mueble.get("repisa", false)):
				draw_rect(Rect2(caja.position.x, caja.end.y - 16, caja.size.x, 13), Color("#5e392a"))
				draw_rect(Rect2(caja.position.x, caja.end.y - 22, caja.size.x, 10), marco)
				draw_texture_rect_region(mueble.texture, Rect2(posicion - Vector2(21, 21), Vector2(42, 42)), mueble.region)
			else:
				draw_rect(caja, Color("#5e392a"))
				draw_rect(caja.grow(-5), marco)
				draw_rect(caja.grow(-12), Color("#f1d9b0"))
				draw_texture_rect_region(mueble.texture, Rect2(posicion - Vector2(21, 21), Vector2(42, 42)), mueble.region)
			continue
		draw_texture_rect_region(mueble.texture, caja, mueble.region)
