extends Control
## Pantalla de inicio. Todos los nodos estan en scenes/menu.tscn.
## Busca los botones por nombre, asi sigue funcionando aunque cambies la jerarquia
## (siempre que conserven sus nombres: BotonJugar, BotonConfig, BotonSalir, BotonVolver,
## MenuPrincipal, Configuracion, VolumenLabel y VolumenSlider).

const TEXTURA_AVATAR_NANDO: Texture2D = preload("res://Sprout Lands - UI Pack - Basic pack/Sprout Lands - UI Pack - Basic pack/Sprite sheets/Dialouge UI/Emotes/Teemo Basic emote animations sprite sheet.png")

var menu_principal: Control
var configuracion: Control
var titulo: Label
var volumen_label: Label
var volumen_slider: HSlider
var save_menu: VBoxContainer
var welcome_box: VBoxContainer
var name_input: LineEdit
var welcome_text: Label
var recover_id_input: LineEdit
var recover_status: Label
var selected_slot := -1
var slot_to_delete := -1
var dialogo_eliminar: ConfirmationDialog


func _ready() -> void:
	menu_principal = find_child("MenuPrincipal", true, false)
	configuracion = find_child("Configuracion", true, false)
	titulo = find_child("Titulo", true, false)
	volumen_label = find_child("VolumenLabel", true, false)
	volumen_slider = find_child("VolumenSlider", true, false)

	_conectar("BotonJugar", _on_play)
	_conectar("BotonConfig", _on_open_settings)
	_conectar("BotonSalir", _on_quit)
	_conectar("BotonVolver", _on_back)

	if volumen_slider != null:
		volumen_slider.value = Global.volume * 100.0
		_actualizar_label(volumen_slider.value)
		volumen_slider.value_changed.connect(_on_volumen_changed)
	else:
		push_warning("menu.gd: no encuentro el nodo VolumenSlider")
	_crear_menu_partidas()
	Global.saves_changed.connect(_actualizar_partidas)
	Global.shared_save_loaded.connect(_on_shared_save_loaded)


func _conectar(nombre: String, callback: Callable) -> void:
	var b := find_child(nombre, true, false) as BaseButton
	if b == null:
		push_warning("menu.gd: no encuentro el boton " + nombre)
		return
	b.pressed.connect(callback)


func _actualizar_label(v: float) -> void:
	if volumen_label != null:
		volumen_label.text = "Volumen: %d%%" % int(v)


func _on_volumen_changed(v: float) -> void:
	Global.set_volume(v / 100.0)
	_actualizar_label(v)


func _on_play() -> void:
	if menu_principal != null:
		menu_principal.visible = false
	if configuracion != null:
		configuracion.visible = false
	if titulo != null:
		titulo.visible = false
	_actualizar_partidas()
	save_menu.visible = true
	welcome_box.visible = false


func _crear_menu_partidas() -> void:
	var pila := find_child("Pila", true, false) as VBoxContainer
	if pila == null:
		return
	save_menu = VBoxContainer.new()
	save_menu.name = "Partidas"
	save_menu.visible = false
	save_menu.custom_minimum_size = Vector2(430, 300)
	save_menu.add_theme_constant_override("separation", 12)
	pila.add_child(save_menu)
	var encabezado := Label.new()
	encabezado.text = "ELIGE TU PARTIDA"
	encabezado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	encabezado.add_theme_font_size_override("font_size", 26)
	save_menu.add_child(encabezado)
	for i in Global.MAX_SAVE_SLOTS:
		var fila := HBoxContainer.new()
		fila.name = "FilaPartida%d" % i
		fila.custom_minimum_size = Vector2(400, 48)
		fila.add_theme_constant_override("separation", 8)
		save_menu.add_child(fila)
		var boton := Button.new()
		boton.name = "Partida%d" % i
		boton.custom_minimum_size = Vector2(320, 48)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.add_theme_font_size_override("font_size", 18)
		boton.pressed.connect(_seleccionar_partida.bind(i))
		fila.add_child(boton)
		var borrar := Button.new()
		borrar.name = "BorrarPartida%d" % i
		borrar.text = "Borrar"
		borrar.custom_minimum_size = Vector2(72, 48)
		borrar.tooltip_text = "Eliminar solo la copia local; la copia de Supabase permanece"
		borrar.pressed.connect(_solicitar_eliminar_partida.bind(i))
		fila.add_child(borrar)
	var recuperar_titulo := Label.new()
	recuperar_titulo.text = "¿Tienes un ID? Recupera tu partida"
	recuperar_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_menu.add_child(recuperar_titulo)
	recover_id_input = LineEdit.new()
	recover_id_input.placeholder_text = "Pega aquí el ID de 32 caracteres"
	recover_id_input.max_length = 32
	recover_id_input.custom_minimum_size = Vector2(360, 40)
	recover_id_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	recover_id_input.text_submitted.connect(_recuperar_partida_por_id)
	save_menu.add_child(recover_id_input)
	var recuperar := Button.new()
	recuperar.text = "Recuperar partida por ID"
	recuperar.custom_minimum_size = Vector2(280, 44)
	recuperar.pressed.connect(_recuperar_partida_por_id.bind(recover_id_input.text))
	save_menu.add_child(recuperar)
	recover_status = Label.new()
	recover_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recover_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_menu.add_child(recover_status)
	var volver := Button.new()
	volver.text = "Volver"
	volver.custom_minimum_size = Vector2(280, 48)
	volver.pressed.connect(_volver_a_menu)
	save_menu.add_child(volver)
	dialogo_eliminar = ConfirmationDialog.new()
	dialogo_eliminar.title = "Eliminar partida"
	dialogo_eliminar.ok_button_text = "Eliminar"
	dialogo_eliminar.dialog_text = "Solo se borrara la copia local. La copia de Supabase seguira disponible mediante su ID."
	dialogo_eliminar.confirmed.connect(_confirmar_eliminar_partida)
	add_child(dialogo_eliminar)
	welcome_box = VBoxContainer.new()
	welcome_box.name = "NuevaPartida"
	welcome_box.visible = false
	welcome_box.custom_minimum_size = Vector2(430, 300)
	welcome_box.add_theme_constant_override("separation", 10)
	pila.add_child(welcome_box)
	var caja_dialogo := NinePatchRect.new()
	caja_dialogo.name = "CajaDialogoNuevoGranjero"
	caja_dialogo.texture = load("res://Sprout Lands - UI Pack - Basic pack/Sprout Lands - UI Pack - Basic pack/Sprite sheets/Dialouge UI/Premade dialog box medium.png")
	caja_dialogo.custom_minimum_size = Vector2(430, 150)
	caja_dialogo.patch_margin_left = 24
	caja_dialogo.patch_margin_top = 24
	caja_dialogo.patch_margin_right = 24
	caja_dialogo.patch_margin_bottom = 24
	welcome_box.add_child(caja_dialogo)
	var avatar := TextureRect.new()
	avatar.name = "AvatarNando"
	avatar.position = Vector2(17, 26)
	avatar.size = Vector2(66, 92)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var textura_avatar := AtlasTexture.new()
	textura_avatar.atlas = TEXTURA_AVATAR_NANDO
	textura_avatar.region = Rect2(32, 96, 32, 34.4)
	avatar.texture = textura_avatar
	caja_dialogo.add_child(avatar)
	welcome_text = Label.new()
	welcome_text.position = Vector2(96, 20)
	welcome_text.size = Vector2(315, 112)
	welcome_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	welcome_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	welcome_text.add_theme_color_override("font_color", Color("#332716"))
	caja_dialogo.add_child(welcome_text)
	name_input = LineEdit.new()
	name_input.placeholder_text = "Tu nombre de granjero"
	name_input.custom_minimum_size = Vector2(360, 42)
	name_input.max_length = 24
	welcome_box.add_child(name_input)
	var comenzar := Button.new()
	comenzar.text = "Comenzar aventura"
	comenzar.custom_minimum_size = Vector2(280, 52)
	comenzar.pressed.connect(_comenzar_nueva_partida)
	welcome_box.add_child(comenzar)
	var cancelar := Button.new()
	cancelar.text = "Volver a partidas"
	cancelar.custom_minimum_size = Vector2(280, 42)
	cancelar.pressed.connect(_volver_a_partidas)
	welcome_box.add_child(cancelar)


func _actualizar_partidas() -> void:
	for i in Global.MAX_SAVE_SLOTS:
		var fila := save_menu.get_node("FilaPartida%d" % i)
		var boton := fila.get_node("Partida%d" % i) as Button
		var borrar := fila.get_node("BorrarPartida%d" % i) as Button
		var partida: Dictionary = Global.save_slots[i]
		boton.text = "Partida %d — %s" % [i + 1, str(partida.get("name", "Vacia")) if not partida.is_empty() else "Vacia"]
		borrar.disabled = partida.is_empty()


func _solicitar_eliminar_partida(indice: int) -> void:
	if indice < 0 or indice >= Global.save_slots.size() or Global.save_slots[indice].is_empty():
		return
	slot_to_delete = indice
	dialogo_eliminar.dialog_text = "¿Eliminar la copia local de %s? La copia de Supabase seguira disponible mediante su ID." % str(Global.save_slots[indice].get("name", "Granjero"))
	dialogo_eliminar.popup_centered()


func _recuperar_partida_por_id(texto: String = "") -> void:
	if texto.is_empty():
		texto = recover_id_input.text
	recover_status.text = "Conectando con Supabase…"
	Global.load_shared_save(texto)


func _on_shared_save_loaded(success: bool, state: Dictionary, message: String) -> void:
	if not success:
		recover_status.text = message
		return
	Global.load_shared_state(state)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _confirmar_eliminar_partida() -> void:
	if slot_to_delete >= 0:
		Global.delete_slot(slot_to_delete)
	slot_to_delete = -1


func _seleccionar_partida(indice: int) -> void:
	var partida: Dictionary = Global.save_slots[indice]
	if not partida.is_empty():
		Global.load_slot(indice)
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		return
	selected_slot = indice
	save_menu.visible = false
	welcome_box.visible = true
	name_input.text = ""
	welcome_text.text = "Hola. Estas a punto de entrar al juego: seras un nuevo granjero. ¿Como te llamas? Espero trabajar muy duro contigo y ayudarte a hacer crecer tu rancho."
	name_input.grab_focus()


func _comenzar_nueva_partida() -> void:
	Global.new_game(name_input.text, selected_slot)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _volver_a_menu() -> void:
	save_menu.visible = false
	welcome_box.visible = false
	if menu_principal != null:
		menu_principal.visible = true
	if titulo != null:
		titulo.visible = true


func _volver_a_partidas() -> void:
	welcome_box.visible = false
	save_menu.visible = true


func _on_open_settings() -> void:
	if menu_principal != null and configuracion != null:
		menu_principal.visible = false
		configuracion.visible = true
		if titulo != null:
			titulo.visible = false


func _on_back() -> void:
	if menu_principal != null and configuracion != null:
		configuracion.visible = false
		menu_principal.visible = true
		if titulo != null:
			titulo.visible = true


func _on_quit() -> void:
	get_tree().quit()
