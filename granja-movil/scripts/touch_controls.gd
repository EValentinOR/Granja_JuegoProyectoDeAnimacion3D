extends Control

@export var tamano_joystick := 208.0
@export var tamano_boton := 112.0
@export var separacion_botones := 16.0
@export var elevacion_joystick := 56.0

@onready var base_joystick: Panel = %JoystickBase
@onready var perilla_joystick: Panel = %JoystickKnob
@onready var boton_interactuar: Panel = %BotonTactilInteractuar
@onready var boton_bolsa: Panel = %BotonTactilBolsa
@onready var boton_pausa: Panel = %BotonTactilPausa
@onready var etiqueta_pausa: Label = $BotonTactilPausa/EtiquetaPausa

var _toque_joystick := -1
var _acciones_por_toque: Dictionary = {}
var _valor_joystick := Vector2.ZERO
var _tamano_aplicado := -1.0
var _opacidad_aplicada := -1.0
var _modo_aplicado := ""

const ACCIONES_MOVIMIENTO := ["move_left", "move_right", "move_up", "move_down"]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_actualizar_distribucion)
	_actualizar_ajustes()
	_actualizar_distribucion()
	_actualizar_visibilidad()


func _process(_delta: float) -> void:
	_actualizar_visibilidad()
	if not is_equal_approx(_tamano_aplicado, Global.touch_size) or not is_equal_approx(_opacidad_aplicada, Global.touch_opacity):
		_actualizar_ajustes()
	_actualizar_modo()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if _iniciar_toque(event.index, event.position):
				get_viewport().set_input_as_handled()
		else:
			_terminar_toque(event.index)
	elif event is InputEventScreenDrag and event.index == _toque_joystick:
		_actualizar_joystick(event.position)
		get_viewport().set_input_as_handled()


func _iniciar_toque(id: int, posicion: Vector2) -> bool:
	if base_joystick.visible and base_joystick.get_global_rect().has_point(posicion) and _toque_joystick == -1:
		_toque_joystick = id
		_actualizar_joystick(posicion)
		return true
	for panel in [boton_interactuar, boton_bolsa, boton_pausa]:
		if panel.visible and panel.get_global_rect().has_point(posicion):
			var accion := _accion_de_boton(panel)
			if _accion_permitida(accion):
				_acciones_por_toque[id] = accion
				Input.action_press(accion)
				_actualizar_feedback_boton(panel, true)
			return true
	return false


func _terminar_toque(id: int) -> void:
	if id == _toque_joystick:
		_toque_joystick = -1
		_valor_joystick = Vector2.ZERO
		_actualizar_direcciones(Vector2.ZERO)
		_centrar_perilla()
		get_viewport().set_input_as_handled()
	if _acciones_por_toque.has(id):
		var accion: String = _acciones_por_toque[id]
		_acciones_por_toque.erase(id)
		var sigue_presionada := false
		for otra_accion in _acciones_por_toque.values():
			if otra_accion == accion:
				sigue_presionada = true
				break
		if not sigue_presionada:
			Input.action_release(accion)
			_actualizar_feedback_boton(_panel_de_accion(accion), false)
		get_viewport().set_input_as_handled()


func _actualizar_joystick(posicion: Vector2) -> void:
	var centro := base_joystick.get_global_rect().get_center()
	var radio := maxf(1.0, tamano_joystick * Global.touch_size * 0.5 - perilla_joystick.size.x * 0.5)
	var valor := ((posicion - centro) / radio).limit_length(1.0)
	var magnitud := valor.length()
	var zona_muerta := clampf(Global.touch_deadzone, 0.0, 0.5)
	if magnitud <= zona_muerta:
		valor = Vector2.ZERO
	else:
		var salida_analogica := (magnitud - zona_muerta) / (1.0 - zona_muerta)
		# Input.get_vector aplica tambien el deadzone del Input Map; compensarlo evita una zona muerta doble.
		var deadzone_input := 0.0
		for accion in ACCIONES_MOVIMIENTO:
			deadzone_input += InputMap.action_get_deadzone(accion)
		deadzone_input /= ACCIONES_MOVIMIENTO.size()
		var fuerza_entrada := deadzone_input + salida_analogica * (1.0 - deadzone_input)
		valor = valor.normalized() * fuerza_entrada
	_valor_joystick = valor
	perilla_joystick.position = (base_joystick.size - perilla_joystick.size) * 0.5 + valor * radio
	_actualizar_direcciones(valor)
	get_viewport().set_input_as_handled()


func _centrar_perilla() -> void:
	perilla_joystick.position = (base_joystick.size - perilla_joystick.size) * 0.5


func _actualizar_direcciones(valor: Vector2) -> void:
	var intensidades := {
		"move_left": maxf(0.0, -valor.x),
		"move_right": maxf(0.0, valor.x),
		"move_up": maxf(0.0, -valor.y),
		"move_down": maxf(0.0, valor.y),
	}
	for accion in ACCIONES_MOVIMIENTO:
		var fuerza: float = intensidades[accion]
		if fuerza > 0.0:
			Input.action_press(accion, fuerza)
		else:
			Input.action_release(accion)


func _actualizar_ajustes() -> void:
	var escala := Global.touch_size
	base_joystick.size = Vector2.ONE * tamano_joystick * escala
	perilla_joystick.size = Vector2.ONE * 76.0 * escala
	for panel in [boton_interactuar, boton_bolsa, boton_pausa]:
		panel.size = Vector2.ONE * tamano_boton * escala
		panel.modulate.a = _opacidad_visual_botones()
	base_joystick.modulate.a = Global.touch_opacity * 0.78
	perilla_joystick.modulate.a = Global.touch_opacity
	_tamano_aplicado = Global.touch_size
	_opacidad_aplicada = Global.touch_opacity
	_actualizar_distribucion()
	_centrar_perilla()
	for panel in [boton_interactuar, boton_bolsa, boton_pausa]:
		if not _boton_tiene_toque(_accion_de_boton(panel)):
			_actualizar_feedback_boton(panel, false)


func actualizar_ajustes() -> void:
	_actualizar_ajustes()
	_actualizar_visibilidad()


func _actualizar_distribucion() -> void:
	if not is_node_ready():
		return
	var area := get_viewport_rect().size
	var insets := _margenes_zona_segura(area)
	var escala := Global.touch_size
	var diametro := tamano_boton * escala
	var joystick_diametro := tamano_joystick * escala
	var margen := 24.0
	var espacio_abajo := 40.0
	var modo := _modo_juego()
	if modo == "gameplay":
		base_joystick.position = Vector2(insets.x + margen, area.y - insets.w - espacio_abajo - joystick_diametro - elevacion_joystick)
		_centrar_perilla()
		boton_interactuar.position = Vector2(area.x - insets.z - diametro - margen, area.y - insets.w - espacio_abajo - diametro)
	elif modo == "bolsa":
		boton_bolsa.position = Vector2(area.x - insets.z - diametro * 2.0 - margen, area.y - insets.w - margen - diametro)
		boton_pausa.position = Vector2(area.x - insets.z - diametro - margen, area.y - insets.w - margen - diametro)
	elif modo in ["ajustes", "mercado", "casa"]:
		boton_pausa.position = Vector2(area.x - insets.z - diametro - margen, area.y - insets.w - margen - diametro)


func _margenes_zona_segura(area: Vector2) -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var pantalla := DisplayServer.screen_get_size()
	if pantalla.x <= 0 or pantalla.y <= 0:
		return Vector4.ZERO
	var segura := DisplayServer.get_display_safe_area()
	var ventana_pos := DisplayServer.window_get_position()
	var ventana_tam := DisplayServer.window_get_size()
	var escala := area / Vector2(ventana_tam) if ventana_tam.x > 0 and ventana_tam.y > 0 else area / Vector2(pantalla)
	var izquierda := maxf(0.0, float(segura.position.x - ventana_pos.x)) * escala.x
	var arriba := maxf(0.0, float(segura.position.y - ventana_pos.y)) * escala.y
	var derecha := maxf(0.0, float(ventana_pos.x + ventana_tam.x - segura.end.x)) * escala.x
	var abajo := maxf(0.0, float(ventana_pos.y + ventana_tam.y - segura.end.y)) * escala.y
	return Vector4(izquierda, arriba, derecha, abajo)


func _modo_juego() -> String:
	var juego := get_parent().get_parent()
	if juego.get_node("HUD/ConfiguracionJuego").visible:
		return "ajustes"
	if juego.get_node("HUD/Mochila").visible:
		return "bolsa"
	if bool(juego.get("mercado_abierto")):
		return "mercado"
	if bool(juego.get("dentro_casa")):
		return "casa"
	return "gameplay"


func _actualizar_modo() -> void:
	var modo := _modo_juego()
	if modo == _modo_aplicado:
		return
	if _modo_aplicado == "gameplay" and modo != "gameplay":
		_liberar_entradas()
	_modo_aplicado = modo
	base_joystick.visible = modo == "gameplay"
	boton_interactuar.visible = modo == "gameplay"
	# Bolsa y configuracion se abren desde los botones del HUD. En la capa
	# tactil dejamos solo USAR para evitar controles redundantes en pantalla.
	boton_bolsa.visible = false
	boton_pausa.visible = false
	if modo == "casa":
		etiqueta_pausa.text = "SALIR"
	elif modo in ["ajustes", "mercado", "bolsa"]:
		etiqueta_pausa.text = "CERRAR"
	else:
		etiqueta_pausa.text = "CONFIG"
	_actualizar_distribucion()


func _actualizar_visibilidad() -> void:
	# Algunos equipos Windows tienen pantalla tactil; eso no debe activar el HUD movil en PC.
	var deberia_mostrar := OS.has_feature("mobile") or Global.debug_touch_controls
	if visible == deberia_mostrar:
		return
	visible = deberia_mostrar
	if not visible:
		_liberar_entradas()
	else:
		_actualizar_distribucion()


func _accion_de_boton(panel: Panel) -> String:
	if panel == boton_interactuar:
		return "interactuar"
	if panel == boton_bolsa:
		return "abrir_bolsa"
	return "pausa"


func _panel_de_accion(accion: String) -> Panel:
	match accion:
		"interactuar":
			return boton_interactuar
		"abrir_bolsa":
			return boton_bolsa
		_:
			return boton_pausa


func _boton_tiene_toque(accion: String) -> bool:
	return accion in _acciones_por_toque.values()


func _actualizar_feedback_boton(panel: Panel, presionado: bool) -> void:
	if not is_instance_valid(panel):
		return
	var opacidad := _opacidad_visual_botones()
	var tinte := Color(1.08, 1.04, 0.92, opacidad) if presionado else Color(1.0, 1.0, 1.0, opacidad)
	panel.modulate = tinte


func _opacidad_visual_botones() -> float:
	return Global.touch_opacity * 0.78


func _accion_permitida(accion: String) -> bool:
	var modo := _modo_juego()
	if accion == "interactuar":
		return modo == "gameplay"
	if accion == "abrir_bolsa":
		return modo in ["gameplay", "bolsa"]
	return true


func _liberar_entradas() -> void:
	_toque_joystick = -1
	_valor_joystick = Vector2.ZERO
	_actualizar_direcciones(Vector2.ZERO)
	for accion in _acciones_por_toque.values():
		Input.action_release(str(accion))
		_actualizar_feedback_boton(_panel_de_accion(str(accion)), false)
	_acciones_por_toque.clear()
