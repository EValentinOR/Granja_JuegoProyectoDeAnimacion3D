@tool
extends Node2D
## Mapa por casillas: cada Rect2i representa una franja de tiles de tierra.

const TAM_CELDA := 32
const AGUA := Color("#397f9f")
const ARENA := Color("#e9d08c")
const RUTA_MADERA := Color("#70513a")
const TILE_GRASS := Vector2i.ZERO
const TILE_WATER := Vector2i.ZERO

@export_group("Mapa en casillas editables")
@export var franjas_tierra: Array[Rect2i] = [
	Rect2i(13, 0, 44, 3), Rect2i(0, 3, 61, 3), Rect2i(-4, 6, 68, 3),
	Rect2i(-5, 9, 69, 9), Rect2i(-4, 18, 64, 8), Rect2i(0, 26, 56, 6),
	Rect2i(5, 32, 44, 6), Rect2i(12, 38, 29, 6), Rect2i(20, 44, 14, 2),
	# Isla pequeña, segundo puente y terreno reservado para el segundo rancho.
	Rect2i(70, 13, 12, 4), Rect2i(69, 17, 14, 4), Rect2i(70, 21, 13, 6),
	Rect2i(62, 16, 9, 2), Rect2i(83, 17, 7, 2),
	Rect2i(90, 12, 22, 18)
]:
	set(value):
		franjas_tierra = value
		if is_inside_tree():
			_reconstruir_mapa()
@export_group("Assets de los tiles")
@export var textura_agua: Texture2D = preload("res://Sprout Lands - Sprites - Basic pack/Tilesets/Water.png")
@export var textura_tierra: Texture2D = preload("res://Sprout Lands - Sprites - Basic pack/Tilesets/Grass1.png")

var celdas_tierra: Dictionary = {}
var capa_agua: TileMapLayer
var capa_tierra: TileMapLayer


func _ready() -> void:
	_reconstruir_mapa()


func _reconstruir_mapa() -> void:
	z_index = 0
	for hijo in get_children():
		if hijo is TileMapLayer or hijo is StaticBody2D:
			remove_child(hijo)
			hijo.free()
	_generar_celdas()
	_crear_capas_de_tiles()
	_crear_colisiones_de_borde()
	queue_redraw()


func _generar_celdas() -> void:
	celdas_tierra.clear()
	for franja in franjas_tierra:
		# game.tscn guarda el puente en y=17; alinealo con el valor nuevo y=16.
		var inicio_y := franja.position.y
		if franja == Rect2i(62, 17, 9, 2):
			inicio_y -= 1
		for y in range(inicio_y, inicio_y + franja.size.y):
			for x in range(franja.position.x, franja.end.x):
				celdas_tierra[Vector2i(x, y)] = true


func _crear_capas_de_tiles() -> void:
	capa_agua = _crear_capa("AguaTiles", textura_agua, -2)
	capa_tierra = _crear_capa("TierraTiles", textura_tierra, -1)
	# Extension de agua alrededor de la isla; la tierra cubre casilla por casilla.
	for y in range(-8, 54):
		for x in range(-12, 114):
			capa_agua.set_cell(Vector2i(x, y), 0, TILE_WATER)
	for celda: Vector2i in celdas_tierra:
		# Deja visible el tile de agua en las casillas donde estaban los puentes.
		# Las casillas siguen siendo tierra para el movimiento y las colisiones.
		var bajo_puente := (
			(celda.x >= 64 and celda.x < 69 and celda.y >= 16 and celda.y < 18)
			or (celda.x >= 83 and celda.x < 90 and celda.y >= 17 and celda.y < 19)
		)
		if not bajo_puente:
			capa_tierra.set_cell(celda, 0, TILE_GRASS)


func _crear_capa(nombre: String, textura: Texture2D, profundidad: int) -> TileMapLayer:
	var atlas := TileSetAtlasSource.new()
	atlas.texture = textura
	atlas.texture_region_size = Vector2i(16, 16)
	atlas.create_tile(Vector2i.ZERO)
	var conjunto := TileSet.new()
	conjunto.tile_size = Vector2i(16, 16)
	conjunto.add_source(atlas, 0)
	var capa := TileMapLayer.new()
	capa.name = nombre
	capa.z_index = profundidad
	capa.scale = Vector2(2, 2)
	capa.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	capa.tile_set = conjunto
	add_child(capa)
	return capa


func _draw() -> void:
	# Borde de arena trazado en los lados expuestos de cada casilla de tierra.
	for celda: Vector2i in celdas_tierra:
		var origen := Vector2(celda * TAM_CELDA)
		if not _tiene_tierra(celda + Vector2i.UP):
			draw_line(origen, origen + Vector2(TAM_CELDA, 0), ARENA, 5.0)
		if not _tiene_tierra(celda + Vector2i.DOWN):
			draw_line(origen + Vector2(0, TAM_CELDA), origen + Vector2(TAM_CELDA, TAM_CELDA), ARENA, 5.0)
		if not _tiene_tierra(celda + Vector2i.LEFT):
			draw_line(origen, origen + Vector2(0, TAM_CELDA), ARENA, 5.0)
		if not _tiene_tierra(celda + Vector2i.RIGHT):
			draw_line(origen + Vector2(TAM_CELDA, 0), origen + Vector2(TAM_CELDA, TAM_CELDA), ARENA, 5.0)
	# Puente de madera sobre las casillas que conectan las dos masas de tierra.
	#draw_rect(Rect2(1984, 512, 288, 64), RUTA_MADERA)
	#for x in range(1992, 2272, 24):
	#	draw_line(Vector2(x, 512), Vector2(x, 576), Color("#d2a66a"), 3.0)
	#	draw_line(Vector2(x + 2, 512), Vector2(x + 2, 576), Color("#493b31"), 1.0)
	#draw_rect(Rect2(2656, 544, 224, 64), RUTA_MADERA)
	#for x in range(2664, 2880, 24):
	#	draw_line(Vector2(x, 544), Vector2(x, 608), Color("#d2a66a"), 3.0)
	#	draw_line(Vector2(x + 2, 544), Vector2(x + 2, 608), Color("#493b31"), 1.0)
func _tiene_tierra(celda: Vector2i) -> bool:
	return celdas_tierra.has(celda)


func contains_world_position(world_position: Vector2) -> bool:
	var celda := Vector2i(floori(world_position.x / TAM_CELDA), floori(world_position.y / TAM_CELDA))
	return _tiene_tierra(celda)


func _crear_colisiones_de_borde() -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.name = "ColisionBordeIsla"
	add_child(cuerpo)
	for celda: Vector2i in celdas_tierra:
		var origen := Vector2(celda * TAM_CELDA)
		if not _tiene_tierra(celda + Vector2i.UP):
			_agregar_segmento(cuerpo, origen, origen + Vector2(TAM_CELDA, 0))
		if not _tiene_tierra(celda + Vector2i.DOWN):
			_agregar_segmento(cuerpo, origen + Vector2(0, TAM_CELDA), origen + Vector2(TAM_CELDA, TAM_CELDA))
		if not _tiene_tierra(celda + Vector2i.LEFT):
			_agregar_segmento(cuerpo, origen, origen + Vector2(0, TAM_CELDA))
		if not _tiene_tierra(celda + Vector2i.RIGHT):
			_agregar_segmento(cuerpo, origen + Vector2(TAM_CELDA, 0), origen + Vector2(TAM_CELDA, TAM_CELDA))
func _agregar_segmento(cuerpo: StaticBody2D, inicio: Vector2, fin: Vector2) -> void:
	var forma := SegmentShape2D.new()
	forma.a = inicio
	forma.b = fin
	var colision := CollisionShape2D.new()
	colision.shape = forma
	cuerpo.add_child(colision)
