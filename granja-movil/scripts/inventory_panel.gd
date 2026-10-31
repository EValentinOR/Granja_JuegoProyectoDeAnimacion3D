extends Control
## Mochila con celdas preparadas para conectar sprites propios desde el Inspector.

@export_group("Assets de productos animales")
@export var icono_leche: Texture2D
@export var icono_huevo: Texture2D

var _celdas: Array[Dictionary] = []
var _tiempo_actualizacion := 0.0
@onready var cuadricula: Control = %CeldasInventario
@onready var ayuda: Label = %Ayuda
@onready var titulo: Label = %Titulo
@onready var panel_misiones: Control = %PanelMisionesTab
@onready var texto_misiones: RichTextLabel = %TextoMisionesTab


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_crear_interfaz()
	actualizar_contenido()


func _process(delta: float) -> void:
	if not visible:
		return
	_tiempo_actualizacion += delta
	if _tiempo_actualizacion >= 0.25:
		_tiempo_actualizacion = 0.0
		actualizar_contenido()


func actualizar_contenido() -> void:
	if _celdas.is_empty():
		return
	for indice in _celdas.size():
		var celda: Dictionary = _celdas[indice]
		var producto: Dictionary = {}
		if indice < Global.CROPS.size():
			if not Global.is_unlocked(indice):
				celda.panel.visible = false
				continue
			producto = {
				"id": str(Global.CROPS[indice].id),
				"nombre": str(Global.CROPS[indice].name),
				"icono": Global.icono_cultivo(indice),
			}
		elif indice == Global.CROPS.size():
			producto = {"id": "leche", "nombre": "Leche", "icono": icono_leche}
		elif indice == Global.CROPS.size() + 1:
			producto = {"id": "huevo", "nombre": "Huevo", "icono": icono_huevo}
		else:
			celda.panel.visible = false
			continue
		celda.panel.visible = true
		celda.nombre.visible = true
		celda.nombre.text = str(producto.nombre)
		celda.cantidad.text = "× %d" % int(Global.inventory.get(producto.id, 0))
		celda.icono.texture = producto.icono
		celda.placeholder.visible = producto.icono == null

func _crear_interfaz() -> void:
	for celda_panel in cuadricula.get_children():
		var icono := celda_panel.get_node("Fila/IconSlot/IconoProducto") as TextureRect
		var placeholder := celda_panel.get_node("Fila/IconSlot/PuntoParaAsset") as Label
		var nombre := celda_panel.get_node("Fila/Texto/NombreProducto") as Label
		var cantidad := celda_panel.get_node("Fila/Texto/CantidadProducto") as Label
		_celdas.append({"panel": celda_panel, "icono": icono, "placeholder": placeholder, "nombre": nombre, "cantidad": cantidad})
	%BotonCerrar.pressed.connect(_cerrar)
	cuadricula.visible = true
	panel_misiones.visible = true
	ayuda.visible = true


func actualizar_misiones(texto: String) -> void:
	panel_misiones.visible = true
	texto_misiones.visible = true
	if texto_misiones.text != texto:
		texto_misiones.text = texto

func _cerrar() -> void:
	visible = false
	var juego := get_parent().get_parent()
	juego.call("cerrar_mochila")
