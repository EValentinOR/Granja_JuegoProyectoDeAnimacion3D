extends Node2D
## Parcela de cultivo (scenes/plot.tscn).
## Muestra 4 etapas: 0, 1 y 2 mientras crece y 3 cuando esta lista.
## Las imagenes de cada etapa se asignan en data/maiz.tres y data/tomate.tres.
## Si falta una imagen, se muestra el cuadro de color provisional (nodo PlantaColor).

enum State { EMPTY, GROWING, READY }

signal planted(crop_index: int)
signal harvested(crop_index: int)

const ETAPAS := 4

@export var tamanos_provisionales: Array[float] = [10.0, 20.0, 30.0, 44.0]
@export var color_creciendo := Color(0.3, 0.75, 0.25)
@export var desbloqueada := true
@export var precio_desbloqueo := 100:
    set(value):
        precio_desbloqueo = value
        if is_node_ready():
            precio_bloqueo.text = "$%d" % precio_desbloqueo

@onready var planta: Sprite2D = %Planta
@onready var planta_color: ColorRect = %PlantaColor
@onready var barra: ProgressBar = %Barra
@onready var resalte: ReferenceRect = %Resalte
@onready var bloqueo: Control = %Bloqueo
@onready var precio_bloqueo: Label = %PrecioBloqueo

var state := State.EMPTY
var crop_index := -1
var growth := 0.0

var highlight := false:
    set(value):
        highlight = value
        if is_node_ready():
            resalte.visible = value


func _ready() -> void:
    resalte.visible = highlight
    precio_bloqueo.text = "$%d" % precio_desbloqueo
    _actualizar()


func plant(idx: int) -> void:
    if not desbloqueada:
        return
    crop_index = idx
    growth = 0.0
    state = State.GROWING
    _actualizar()
    planted.emit(idx)


## Cosecha la planta y devuelve el indice del cultivo.
func harvest() -> int:
    if not desbloqueada:
        return -1
    var idx := crop_index
    state = State.EMPTY
    crop_index = -1
    growth = 0.0
    _actualizar()
    harvested.emit(idx)
    return idx


func desbloquear() -> void:
    if desbloqueada:
        return
    desbloqueada = true
    _actualizar()

func _process(delta: float) -> void:
    if desbloqueada and state == State.GROWING:
        growth += delta
        if growth >= Global.GROW_TIME:
            growth = Global.GROW_TIME
            state = State.READY
        _actualizar()


func _etapa_actual() -> int:
    if state == State.READY:
        return ETAPAS - 1
    var p := growth / Global.GROW_TIME
    return clampi(int(p * (ETAPAS - 1)), 0, ETAPAS - 2)


func _mostrar(etapa: int) -> void:
    var tex: Texture2D = Global.textura_etapa(crop_index, etapa)
    if tex != null:
        planta.texture = tex
        planta.visible = true
        planta_color.visible = false
    else:
        var s: float = tamanos_provisionales[mini(etapa, tamanos_provisionales.size() - 1)]
        planta_color.size = Vector2(s, s)
        planta_color.position = -planta_color.size / 2.0
        if etapa == ETAPAS - 1:
            planta_color.color = Global.CROPS[crop_index]["color"]
        else:
            planta_color.color = color_creciendo
        planta.visible = false
        planta_color.visible = true


func _actualizar() -> void:
    precio_bloqueo.text = "$%d" % precio_desbloqueo
    bloqueo.visible = not desbloqueada
    if not desbloqueada:
        planta.visible = false
        planta_color.visible = false
        barra.visible = false
        return
    if state == State.EMPTY:
        planta.visible = false
        planta_color.visible = false
        barra.visible = false
        return
    _mostrar(_etapa_actual())
    barra.visible = (state == State.GROWING)
    barra.value = growth / Global.GROW_TIME * 100.0
