extends Node2D

@onready var reproductor: AudioStreamPlayer = $AudioStreamPlayer
var registrados := {}

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_registrar_arbol", get_tree().current_scene)
	if Global.has_signal("button_volume_changed"):
		Global.button_volume_changed.connect(_actualizar_volumen)
	_actualizar_volumen(Global.button_volume)

func _registrar_arbol(nodo: Node) -> void:
	if nodo == null:
		return
	_registrar(nodo)
	for hijo in nodo.get_children():
		_registrar_arbol(hijo)

func _on_node_added(nodo: Node) -> void:
	if nodo is BaseButton:
		_registrar(nodo)

func _registrar(nodo: Node) -> void:
	if not nodo is BaseButton:
		return
	var id := nodo.get_instance_id()
	if registrados.has(id):
		return
	registrados[id] = weakref(nodo)
	(nodo as BaseButton).button_down.connect(_reproducir)

func _reproducir() -> void:
	if Global.button_volume <= 0.001:
		return
	reproductor.stop()
	reproductor.play()

func _actualizar_volumen(valor: float) -> void:
	reproductor.volume_db = linear_to_db(maxf(valor, 0.0001))