extends Control
## Mochila con celdas preparadas para conectar sprites propios desde el Inspector.

@export_group("Assets de productos animales")
@export var icono_leche: Texture2D
@export var icono_huevo: Texture2D

var _celdas: Array[Dictionary] = []
var _tiempo_actualizacion := 0.0
@onready var cuadricula: GridContainer = %CeldasInventario


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
	var productos: Array[Dictionary] = []
	for indice in Global.CROPS.size():
		productos.append({
			"id": str(Global.CROPS[indice].id),
			"nombre": str(Global.CROPS[indice].name),
			"icono": Global.icono_cultivo(indice),
		})
	productos.append({"id": "leche", "nombre": "Leche", "icono": icono_leche})
	productos.append({"id": "huevo", "nombre": "Huevo", "icono": icono_huevo})
	for indice in _celdas.size():
		var celda: Dictionary = _celdas[indice]
		var tiene_producto := indice < productos.size()
		celda.nombre.visible = true
		if tiene_producto:
			var producto: Dictionary = productos[indice]
			celda.nombre.text = str(producto.nombre)
			celda.cantidad.text = "× %d" % int(Global.inventory.get(producto.id, 0))
			celda.icono.texture = producto.icono
			celda.placeholder.visible = producto.icono == null
		else:
			celda.nombre.text = "Espacio para asset"
			celda.cantidad.text = ""
			celda.icono.texture = null
			celda.placeholder.visible = true


func _crear_interfaz() -> void:
	for celda_panel in cuadricula.get_children():
		var icono := celda_panel.get_node("Fila/IconSlot/IconoProducto") as TextureRect
		var placeholder := celda_panel.get_node("Fila/IconSlot/PuntoParaAsset") as Label
		var nombre := celda_panel.get_node("Fila/Texto/NombreProducto") as Label
		var cantidad := celda_panel.get_node("Fila/Texto/CantidadProducto") as Label
		_celdas.append({"icono": icono, "placeholder": placeholder, "nombre": nombre, "cantidad": cantidad})
	%BotonCerrar.pressed.connect(_cerrar)


func _cerrar() -> void:
	visible = false
	var juego := get_parent().get_parent()
	juego.call("cerrar_mochila")
