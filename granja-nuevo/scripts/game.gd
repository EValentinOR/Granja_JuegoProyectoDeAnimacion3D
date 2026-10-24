extends Node2D
## Escena principal de la granja, sus parcelas y la tienda de Nando.

const PlotScript = preload("res://scripts/plot.gd")
const PLOT_SCENE = preload("res://scenes/plot.tscn")
const TEXTURA_MUEBLES: Texture2D = preload("res://Sprout Lands - Sprites - Basic pack/Objects/Basic Furniture.png")
const TEXTURA_PLANTAS: Texture2D = preload("res://Sprout Lands - Sprites - Basic pack/Objects/Basic Plants.png")
const TEXTURA_DECORACION: Texture2D = preload("res://Sprout Lands - Sprites - Basic pack/Objects/Basic Grass Biom things 1.png")
const TEXTURA_HUEVO: Texture2D = preload("res://Sprout Lands - Sprites - Basic pack/Objects/Egg_item.png")
const TEXTURA_LECHE: Texture2D = preload("res://Sprout Lands - Sprites - Basic pack/Objects/Simple_Milk_and_grass_item.png")
const ESCENAS_ANIMAL := {
	"vaca": preload("res://scenes/vaca.tscn"),
	"pollo": preload("res://scenes/pollo.tscn"),
}

@export var rango_parcela := 70.0
@export var max_animales := 10
@export var margen_animales := 20.0
const CASA_TIEMPO_CONSTRUCCION := 300.0
const PRECIO_SEGUNDO_RANCHO := 2500
const PRECIOS_PARCELAS := [200, 350, 550, 800, 1100, 1500, 1900, 2400, 3000, 3700, 4500, 5400, 6400, 7500, 8700, 10000, 11500, 13100]
const PRECIOS_PARCELAS_RANCHO_DOS := [500, 750, 1050, 1400, 1800, 2250, 2750, 3300, 3900, 4550, 5250, 6000]
const TIEMPO_ENTRE_ENCARGOS := 300.0
const CICLO_ENCARGOS := [
	{"item": "maiz", "cantidad": 2, "recompensa": 120},
	{"item": "tomate", "cantidad": 2, "recompensa": 160},
	{"item": "huevo", "cantidad": 3, "recompensa": 180},
	{"item": "leche", "cantidad": 2, "recompensa": 200},
]
const NOMBRES_VECINOS := ["Rosa", "Edith", "Rubi", "Mara", "Ines", "Carla", "Elena", "Julia", "Teresa", "Lucia"]

@onready var jugador: CharacterBody2D = %Jugador
@onready var camara_jugador: Camera2D = $Jugador/Camera2D
@onready var corral: Node2D = $Corral
@onready var mercado: Node2D = %Mercado
@onready var vista_casa: Node2D = $VistaCasa
@onready var panel_mochila: Control = %Mochila
@onready var vendedor: Node2D = $Mercado/Nando
@onready var cara_vendedor: Sprite2D = $HUD/Tienda/CaraVendedor
@onready var colision_casa: CollisionShape2D = $Casa/ColisionCasa/Pared
@onready var punto_decoracion: Marker2D = $Casa/PuntoDecoracion
@onready var zona_animales: ReferenceRect = $Corral/ZonaAnimales
@onready var animales_nodo: Node2D = %Animales
@onready var productos_suelo_nodo: Node2D = %ProductosSuelo
@onready var parcelas: Array[Node] = %Parcelas.get_children()
@onready var nivel_label: Label = %NivelLabel
@onready var barra_xp: TextureProgressBar = %BarraXP
@onready var xp_label: Label = %XPLabel
@onready var monedas_label: Label = %MonedasLabel
@onready var icono_moneda: TextureRect = %MonedaIcono
@onready var lista_misiones: RichTextLabel = %ListaMisiones
@onready var vaca_label: Label = %VacaLabel
@onready var temporizador_label: Label = %TemporizadorLabel
@onready var filas: Array[Node] = %Filas.get_children()
@onready var mochila_label: Label = %MochilaLabel
@onready var animales_label: Label = %AnimalesLabel
@onready var mensaje_label: Label = %Mensaje
@onready var aviso_label: Label = %Aviso
@onready var ayuda_label: Label = $HUD/PanelPrecios/AyudaLabel
@onready var catalogo_muebles: VBoxContainer = VBoxContainer.new()
var selector_color_piso: OptionButton
var lista_catalogo_muebles: VBoxContainer
var interfaz_casa: Control
var monedas_casa_label: Label
var fondo_menu_venta: PanelContainer
var menu_vender: VBoxContainer
var lista_venta: VBoxContainer
@onready var botones_semilla: Array[Node] = %BarraSemillas.get_children()
@onready var barra_semillas: Control = %BarraSemillas
@onready var tienda: Control = %Tienda
@onready var titulo_vendedor: Label = %TituloVendedor
@onready var texto_dialogo: Label = %DialogoMercado
@onready var opciones_tienda: Control = %Opciones
@onready var menu_comprar: Control = %MenuComprar
@onready var boton_vender: Button = %BotonVender
@onready var boton_comprar: Button = %BotonComprar
@onready var boton_salir_mercado: Button = %BotonSalirMercado
@onready var boton_rancho_dos: Button = %BotonRanchoDos
@onready var boton_vaca: Button = %BotonVaca
@onready var boton_pollo: Button = %BotonPollo
@onready var boton_atras: Button = %BotonAtras
@onready var boton_ajustes: Button = %BotonAjustes
@onready var boton_bolsa: Button = %BotonBolsa
@onready var ajustes: Control = %ConfiguracionJuego
@onready var ajustes_slider: HSlider = %AjustesSlider
@onready var ajustes_label: Label = %AjustesVolumenLabel
@onready var boton_cerrar_ajustes: Button = %BotonCerrarAjustes
@onready var boton_menu_principal: Button = %BotonMenuPrincipal

var nearest := {}
var comprando := false
var mercado_abierto := false
var dialog_mode := "market"
var texto_mercado := "Hola, granjero. ¿Que quieres hacer hoy?"
var active_lot := -1
var segundo_rancho_comprado := false
var parcelas_rancho_dos: Array[Node] = []
@onready var casa_rancho_dos: Node2D = $CasaRanchoDos
var lot_states: Array[Dictionary] = []
var lot_visuals: Array[Node2D] = []
var tiempo_autoguardado := 0.0
var tiempo_muestra_recorrido := 0.0
var recorrido_jugador: Array = []
var texto_misiones_actual := ""
var obstaculos_animales: Array[Rect2] = []
var productos_suelo: Array[Node2D] = []
var toast_tween: Tween
var tween_contador_monedas: Tween
var monedas_mostradas := -1
var prompt_interaccion: PanelContainer
var prompt_tecla: Label
var prompt_accion: Label
var anuncio_panel: PanelContainer
var anuncio_titulo: Label
var anuncio_texto: Label
var anuncio_tween: Tween
var dentro_casa := false
var decorando_segunda_casa := false
var muebles_comprados: Array[String] = []
var muebles_colocados: Array[Dictionary] = []
var muebles_colocados_primera: Array[Dictionary] = []
var muebles_colocados_segunda: Array[Dictionary] = []
var mueble_seleccionado := ""
var mueble_seleccionado_indice := -1
var estilo_piso := 0
var estilo_piso_primera := 0
var estilo_piso_segunda := 0
var objeto_arrastrado := -1
const MUEBLES := [
	{"nombre": "Cama", "precio": 100, "region": Rect2(0, 16, 16, 32), "tam": Vector2(64, 112), "hoja": "muebles"},
	{"nombre": "Comoda", "precio": 90, "region": Rect2(48, 32, 16, 16), "tam": Vector2(56, 56), "hoja": "muebles"},
	{"nombre": "Silla hacia abajo", "precio": 60, "region": Rect2(96, 32, 16, 16), "tam": Vector2(48, 56), "hoja": "muebles"},
	{"nombre": "Silla izquierda", "precio": 60, "region": Rect2(80, 32, 16, 16), "tam": Vector2(48, 56), "hoja": "muebles"},
	{"nombre": "Silla hacia arriba", "precio": 60, "region": Rect2(112, 32, 16, 16), "tam": Vector2(48, 56), "hoja": "muebles"},
	{"nombre": "Silla derecha", "precio": 60, "region": Rect2(64, 32, 16, 16), "tam": Vector2(48, 56), "hoja": "muebles"},
	{"nombre": "Mesa", "precio": 75, "region": Rect2(48, 48, 16, 16), "tam": Vector2(56, 56), "hoja": "muebles"},
	{"nombre": "Reloj con diseno", "precio": 70, "region": Rect2(80, 48, 16, 16), "tam": Vector2(64, 56), "hoja": "muebles", "tipo": "pared", "marco": Color("#c77b55")},
	{"nombre": "Reloj", "precio": 80, "region": Rect2(112, 48, 16, 16), "tam": Vector2(64, 56), "hoja": "muebles", "tipo": "pared", "marco": Color("#8b6848")},
	{"nombre": "Alfombra verde", "precio": 85, "region": Rect2(48, 80, 32, 16), "tam": Vector2(112, 40), "hoja": "muebles"},
	{"nombre": "Alfombra rosa", "precio": 95, "region": Rect2(80, 80, 32, 16), "tam": Vector2(112, 40), "hoja": "muebles"},
	{"nombre": "Alfombra azul", "precio": 105, "region": Rect2(112, 80, 32, 16), "tam": Vector2(112, 40), "hoja": "muebles"},
	{"nombre": "Banquito", "precio": 55, "region": Rect2(64, 48, 16, 16), "tam": Vector2(48, 40), "hoja": "muebles"},
	{"nombre": "Flor amarilla", "precio": 65, "region": Rect2(48, 0, 16, 16), "tam": Vector2(44, 48), "hoja": "muebles"},
	{"nombre": "Flor verde", "precio": 65, "region": Rect2(64, 0, 16, 16), "tam": Vector2(44, 48), "hoja": "muebles"},
	{"nombre": "Flor azul", "precio": 70, "region": Rect2(80, 0, 16, 16), "tam": Vector2(44, 48), "hoja": "muebles"},
	{"nombre": "Lampara verde", "precio": 75, "region": Rect2(48, 16, 16, 16), "tam": Vector2(44, 48), "hoja": "muebles"},
	{"nombre": "Lampara azul", "precio": 75, "region": Rect2(64, 16, 16, 16), "tam": Vector2(44, 48), "hoja": "muebles"},
	{"nombre": "Lampara rosa", "precio": 80, "region": Rect2(80, 16, 16, 16), "tam": Vector2(44, 48), "hoja": "muebles"},
	{"nombre": "Hongo rosa", "precio": 45, "region": Rect2(80, 0, 16, 16), "tam": Vector2(48, 48), "hoja": "decoracion"},
	{"nombre": "Hongo azul", "precio": 45, "region": Rect2(112, 0, 16, 16), "tam": Vector2(48, 48), "hoja": "decoracion"},
]
const MUEBLES_ANTERIORES := [
	{"nombre": "Sillon", "precio": 130, "region": Rect2(112, 32, 16, 16), "tam": Vector2(64, 64), "hoja": "muebles"},
	{"nombre": "Piedra pequena", "precio": 35, "region": Rect2(96, 16, 16, 16), "tam": Vector2(48, 40), "hoja": "decoracion"},
	{"nombre": "Piedras grandes", "precio": 55, "region": Rect2(112, 16, 32, 16), "tam": Vector2(72, 40), "hoja": "decoracion"},
	{"nombre": "Arbusto con flores", "precio": 60, "region": Rect2(0, 48, 16, 16), "tam": Vector2(56, 48), "hoja": "decoracion"},
	{"nombre": "Arbusto verde", "precio": 55, "region": Rect2(16, 48, 16, 16), "tam": Vector2(56, 48), "hoja": "decoracion"},
	{"nombre": "Tronco decorativo", "precio": 50, "region": Rect2(0, 64, 32, 16), "tam": Vector2(72, 40), "hoja": "decoracion"},
	{"nombre": "Cuadro floral", "precio": 70, "region": Rect2(64, 0, 16, 16), "tam": Vector2(64, 56), "hoja": "plantas", "tipo": "pared", "marco": Color("#c77b55")},
	{"nombre": "Cuadro de planta", "precio": 80, "region": Rect2(80, 0, 16, 16), "tam": Vector2(64, 56), "hoja": "plantas", "tipo": "pared", "marco": Color("#8b6848")},
	{"nombre": "Repisa de pared", "precio": 120, "region": Rect2(80, 0, 16, 16), "tam": Vector2(76, 52), "hoja": "plantas", "tipo": "pared", "marco": Color("#a86f47"), "repisa": true},
]
const DECORACIONES_RETIRADAS := ["Cuadro floral", "Cuadro de planta", "Repisa de pared"]
const ESCALA_MUEBLES_CASA := 1.35
var botones_catalogo: Array[Button] = []
var botones_guardar_catalogo: Array[Button] = []
var etiquetas_catalogo: Array[Label] = []
var icono_leche: AtlasTexture
var ultima_interaccion_msec := -1000
const TIEMPO_BUFFER_INTERACCION := 0.22
var tiempo_buffer_interaccion := 0.0
var screenshake_tween: Tween
var tutorial_step := 0
var tutorial_panel: PanelContainer
var tutorial_avatar: TextureRect
var tutorial_titulo: Label
var tutorial_label: Label
var tutorial_boton_omitir: Button
var tutorial_flecha: Label
var tutorial_parcela: Node
var tutorial_pos_inicial := Vector2.ZERO
var tutorial_final_tiempo := 0.0


func _ready() -> void:
	var estado_guardado := Global.pending_save.duplicate(true)
	tutorial_step = 1 if estado_guardado.is_empty() else int(estado_guardado.get("tutorial_step", 0))
	recorrido_jugador = estado_guardado.get("player_route", []).duplicate(true)
	$HUD.visible = true
	if Global.pending_save.is_empty():
		lot_states = _lotes_nuevos()
	else:
		lot_states = _normalizar_lotes(Global.pending_save.get("lots", []))
	segundo_rancho_comprado = bool(estado_guardado.get("second_ranch", false))
	$Mercado.position = Vector2(200, 238)
	icono_moneda.texture = _crear_textura_moneda()
	monedas_label.pivot_offset = monedas_label.size * 0.5
	icono_leche = AtlasTexture.new()
	icono_leche.atlas = TEXTURA_LECHE
	icono_leche.region = Rect2(0, 0, 16, 16)
	_crear_interfaz_casa()
	_crear_catalogo_muebles()
	_crear_menu_venta()
	_crear_letreros_lugares()
	_crear_prompt_interaccion()
	_crear_panel_tutorial()
	_crear_lotes()
	_agregar_parcelas_extras()
	_crear_parcelas_rancho_dos()
	_conectar_senales_tutorial()
	_configurar_precios_parcelas()
	_crear_filas_precio_extra()
	_crear_semillas_extra()
	if not estado_guardado.is_empty():
		_restaurar_terrenos(estado_guardado)
		if tutorial_step == 3:
			var indice_parcela_tutorial := int(estado_guardado.get("tutorial_plot", -1))
			if indice_parcela_tutorial >= 0 and indice_parcela_tutorial < parcelas.size():
				tutorial_parcela = parcelas[indice_parcela_tutorial]
	_calcular_obstaculos_animales()
	for i in botones_semilla.size():
		botones_semilla[i].pressed.connect(_on_seed_pressed.bind(i))
	boton_vender.pressed.connect(_vender)
	boton_comprar.pressed.connect(_dialog_boton.bind(1))
	boton_salir_mercado.pressed.connect(_dialog_boton.bind(2))
	boton_rancho_dos.pressed.connect(_dialog_boton.bind(3))
	boton_vender.pressed.disconnect(_vender)
	boton_vender.pressed.connect(_dialog_boton.bind(0))
	boton_atras.pressed.connect(_cerrar_compra)
	boton_vaca.pressed.connect(_comprar.bind("vaca"))
	boton_pollo.pressed.connect(_comprar.bind("pollo"))
	boton_ajustes.pressed.connect(_toggle_ajustes)
	boton_bolsa.pressed.connect(_toggle_bolsa)
	boton_cerrar_ajustes.pressed.connect(_cerrar_ajustes)
	boton_menu_principal.pressed.connect(_regresar_menu_principal)
	_crear_boton_id_partida()
	ajustes_slider.value = Global.volume * 100.0
	_actualizar_ajustes_label(ajustes_slider.value)
	ajustes_slider.value_changed.connect(_on_ajustes_volumen_changed)
	for tipo in Global.animales:
		_crear_animal(tipo, false)
	_restaurar_productos_suelo(estado_guardado.get("ground_products", []))
	Global.leveled_up.connect(_on_level_up)
	Global.prices_changed.connect(_on_prices_changed)
	_toast("¡Bienvenido, %s!" % Global.player_name)
	var camera := jugador.get_node_or_null("Camera2D") as Camera2D
	if camera != null:
		camera.enabled = true
	if not Global.current_game_id.is_empty():
		if not estado_guardado.is_empty():
			var posicion: Array = estado_guardado.get("player_pos", [430, 380])
			jugador.position = Vector2(float(posicion[0]), float(posicion[1]))
		_autoguardar()
	tutorial_pos_inicial = jugador.global_position
	_actualizar_panel_tutorial()
	Global.pending_save.clear()
	_toast("¡Tu granja esta lista!" if tutorial_step > 0 else "Rancho listo. Usa E para interactuar", 3.0)


func _crear_boton_id_partida() -> void:
	var panel := $HUD/ConfiguracionJuego
	var etiqueta := Label.new()
	etiqueta.name = "IdPartidaLabel"
	etiqueta.position = Vector2(460, 388)
	etiqueta.size = Vector2(360, 24)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", 13)
	etiqueta.text = "ID de partida: " + Global.current_game_id
	panel.add_child(etiqueta)
	var copiar := Button.new()
	copiar.name = "BotonCopiarIdPartida"
	copiar.text = "Copiar ID"
	copiar.position = Vector2(520, 414)
	copiar.size = Vector2(240, 34)
	copiar.pressed.connect(func():
		DisplayServer.clipboard_set(Global.current_game_id)
		_toast("ID copiado. Compártelo para recuperar esta partida.")
	)
	panel.add_child(copiar)
	$HUD/ConfiguracionJuego/BotonCerrarAjustes.position.y = 450
	$HUD/ConfiguracionJuego/BotonMenuPrincipal.position.y = 506


func _crear_panel_tutorial() -> void:
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.position = Vector2(285, 58)
	tutorial_panel.size = Vector2(710, 104)
	tutorial_panel.z_index = 120
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#e6c798")
	estilo.border_color = Color("#8b6038")
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(10)
	estilo.content_margin_left = 10.0
	estilo.content_margin_right = 12.0
	estilo.content_margin_top = 8.0
	estilo.content_margin_bottom = 8.0
	tutorial_panel.add_theme_stylebox_override("panel", estilo)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	tutorial_panel.add_child(fila)
	var marco_avatar := PanelContainer.new()
	marco_avatar.custom_minimum_size = Vector2(78, 78)
	var estilo_avatar := StyleBoxFlat.new()
	estilo_avatar.bg_color = Color("#735044")
	estilo_avatar.border_color = Color("#bd8a54")
	estilo_avatar.set_border_width_all(2)
	estilo_avatar.set_corner_radius_all(6)
	estilo_avatar.content_margin_left = 5.0
	estilo_avatar.content_margin_right = 5.0
	estilo_avatar.content_margin_top = 5.0
	estilo_avatar.content_margin_bottom = 5.0
	marco_avatar.add_theme_stylebox_override("panel", estilo_avatar)
	fila.add_child(marco_avatar)
	tutorial_avatar = TextureRect.new()
	tutorial_avatar.custom_minimum_size = Vector2(64, 64)
	tutorial_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tutorial_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tutorial_avatar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var textura_dialogo := cara_vendedor.texture as AtlasTexture
	if textura_dialogo != null:
		var recorte_avatar := AtlasTexture.new()
		recorte_avatar.atlas = textura_dialogo.atlas
		recorte_avatar.region = Rect2(textura_dialogo.region.position, Vector2(textura_dialogo.region.size.x / 2.0, textura_dialogo.region.size.y))
		tutorial_avatar.texture = recorte_avatar
	marco_avatar.add_child(tutorial_avatar)
	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna.alignment = BoxContainer.ALIGNMENT_CENTER
	columna.add_theme_constant_override("separation", 3)
	fila.add_child(columna)
	tutorial_titulo = Label.new()
	tutorial_titulo.add_theme_color_override("font_color", Color("#57391f"))
	tutorial_titulo.add_theme_font_size_override("font_size", 18)
	columna.add_child(tutorial_titulo)
	tutorial_label = Label.new()
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tutorial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.add_theme_color_override("font_color", Color("#382817"))
	tutorial_label.add_theme_font_size_override("font_size", 15)
	columna.add_child(tutorial_label)
	tutorial_boton_omitir = Button.new()
	tutorial_boton_omitir.text = "Omitir"
	tutorial_boton_omitir.custom_minimum_size = Vector2(86, 40)
	tutorial_boton_omitir.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tutorial_boton_omitir.focus_mode = Control.FOCUS_NONE
	var estilo_boton := StyleBoxFlat.new()
	estilo_boton.bg_color = Color("#8b6038")
	estilo_boton.border_color = Color("#634326")
	estilo_boton.set_border_width_all(2)
	estilo_boton.set_corner_radius_all(6)
	tutorial_boton_omitir.add_theme_stylebox_override("normal", estilo_boton)
	var estilo_boton_hover := estilo_boton.duplicate() as StyleBoxFlat
	estilo_boton_hover.bg_color = Color("#a87847")
	tutorial_boton_omitir.add_theme_stylebox_override("hover", estilo_boton_hover)
	tutorial_boton_omitir.add_theme_color_override("font_color", Color("#fff1d2"))
	tutorial_boton_omitir.add_theme_color_override("font_hover_color", Color.WHITE)
	tutorial_boton_omitir.pressed.connect(_omitir_tutorial)
	fila.add_child(tutorial_boton_omitir)
	tutorial_panel.visible = false
	$HUD.add_child(tutorial_panel)
	tutorial_flecha = Label.new()
	tutorial_flecha.name = "TutorialFlecha"
	tutorial_flecha.text = "▼"
	tutorial_flecha.size = Vector2(36, 34)
	tutorial_flecha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_flecha.add_theme_color_override("font_color", Color("#ffd45e"))
	tutorial_flecha.add_theme_color_override("font_outline_color", Color("#55351c"))
	tutorial_flecha.add_theme_constant_override("outline_size", 4)
	tutorial_flecha.add_theme_font_size_override("font_size", 27)
	tutorial_flecha.z_index = 119
	tutorial_flecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_flecha.visible = false
	$HUD.add_child(tutorial_flecha)


func _conectar_senales_tutorial() -> void:
	for parcela in parcelas:
		if parcela.has_signal("planted"):
			parcela.connect("planted", _on_tutorial_siembra.bind(parcela))
		if parcela.has_signal("harvested"):
			parcela.connect("harvested", _on_tutorial_cosecha.bind(parcela))


func _on_tutorial_siembra(_indice: int, parcela: Node) -> void:
	if tutorial_step != 2:
		return
	tutorial_parcela = parcela
	tutorial_step = 3
	_actualizar_panel_tutorial()


func _on_tutorial_cosecha(_indice: int, parcela: Node) -> void:
	if tutorial_step != 3 or parcela != tutorial_parcela:
		return
	tutorial_step = 4
	_actualizar_panel_tutorial()


func _actualizar_panel_tutorial() -> void:
	if tutorial_panel == null or tutorial_step <= 0:
		return
	tutorial_panel.visible = true
	tutorial_boton_omitir.visible = true
	match tutorial_step:
		1:
			tutorial_titulo.text = "Paso 1 de 4 · Movimiento"
			tutorial_label.text = "Muevete con WASD o las flechas para explorar tu granja."
		2:
			tutorial_titulo.text = "Paso 2 de 4 · Plantar"
			tutorial_label.text = "Selecciona una semilla (1–5) y presiona E en una parcela vacia."
		3:
			if is_instance_valid(tutorial_parcela) and int(tutorial_parcela.get("state")) == PlotScript.State.READY:
				tutorial_titulo.text = "Paso 3 de 4 · Cosechar"
				tutorial_label.text = "¡Tu cultivo esta listo! Acercate y presiona E para cosecharlo."
			else:
				tutorial_titulo.text = "Paso 3 de 4 · Cosechar"
				tutorial_label.text = "Espera a que el cultivo madure. La flecha señala donde lo sembraste."
		4:
			tutorial_titulo.text = "Paso 4 de 4 · Vender"
			if mercado_abierto:
				tutorial_label.text = "Elige Vender y selecciona cuanta cosecha quieres cambiar por monedas."
			else:
				tutorial_label.text = "Sigue la flecha hasta la tienda y habla con Nando para vender tu cosecha."
	_actualizar_flecha_tutorial()


func _objetivo_tutorial() -> Node2D:
	if tutorial_step == 3 and is_instance_valid(tutorial_parcela):
		return tutorial_parcela as Node2D
	if tutorial_step == 4:
		return vendedor
	if tutorial_step != 2:
		return null
	var parcela_cercana: Node2D
	var distancia := INF
	for parcela in parcelas:
		if not parcela.is_visible_in_tree() or not bool(parcela.get("desbloqueada")) or int(parcela.get("state")) != PlotScript.State.EMPTY:
			continue
		var distancia_actual := jugador.global_position.distance_to(parcela.global_position)
		if distancia_actual < distancia:
			distancia = distancia_actual
			parcela_cercana = parcela as Node2D
	return parcela_cercana


func _actualizar_flecha_tutorial() -> void:
	if tutorial_flecha == null:
		return
	var objetivo := _objetivo_tutorial()
	if objetivo == null or dentro_casa or (tutorial_step == 4 and mercado_abierto):
		tutorial_flecha.visible = false
		return
	var posicion_pantalla := get_viewport().get_canvas_transform() * objetivo.global_position
	var area := get_viewport_rect()
	var pulso := Time.get_ticks_msec() / 180.0
	tutorial_flecha.position = Vector2(
		clampf(posicion_pantalla.x - 18.0, 8.0, area.size.x - 44.0),
		clampf(posicion_pantalla.y - 48.0 + sin(pulso) * 5.0, 166.0, area.size.y - 42.0)
	)
	tutorial_flecha.modulate.a = 0.55 + 0.45 * absf(sin(pulso))
	tutorial_flecha.visible = true


func _completar_tutorial() -> void:
	if tutorial_step != 4:
		return
	tutorial_step = 0
	tutorial_final_tiempo = 4.0
	tutorial_panel.visible = true
	tutorial_boton_omitir.visible = false
	tutorial_titulo.text = "¡Tutorial completado!"
	tutorial_label.text = "Ya sabes plantar, cosechar y vender. ¡Que disfrutes tu granja!"
	tutorial_flecha.visible = false
	_autoguardar()


func _omitir_tutorial() -> void:
	if tutorial_step <= 0:
		return
	tutorial_step = 0
	tutorial_final_tiempo = 0.0
	tutorial_panel.visible = false
	tutorial_flecha.visible = false
	_autoguardar()


func _crear_letreros_lugares() -> void:
	_crear_letrero($Mercado, "TIENDA", Vector2(-50, -91), 100.0)
	_crear_letrero($Casa, "CASA", Vector2(50, -47), 100.0)
	var letrero_anterior := casa_rancho_dos.get_node_or_null("Letrero") as Label
	if letrero_anterior != null:
		letrero_anterior.visible = false
	_crear_letrero(casa_rancho_dos, "RANCHO 2", Vector2(-55, -90), 110.0)


func _crear_letrero(edificio: Node2D, texto: String, posicion: Vector2, ancho: float) -> void:
	var letrero := PanelContainer.new()
	letrero.name = "Letrero%s" % texto.capitalize()
	letrero.position = posicion
	letrero.size = Vector2(ancho, 30)
	letrero.z_index = 5
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#e6c98f")
	estilo.border_color = Color("#73502f")
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(4)
	estilo.content_margin_left = 4.0
	estilo.content_margin_top = 2.0
	estilo.content_margin_right = 4.0
	estilo.content_margin_bottom = 2.0
	letrero.add_theme_stylebox_override("panel", estilo)
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.add_theme_color_override("font_color", Color("#3c2918"))
	etiqueta.add_theme_font_size_override("font_size", 14)
	letrero.add_child(etiqueta)
	edificio.add_child(letrero)


func _agregar_parcelas_extras() -> void:
	# Los terrenos extra forman una ampliacion contigua a la zona inicial.
	var posiciones := []
	for y in [801, 891, 981, 1071]:
		for x in [757, 847, 937]:
			posiciones.append(Vector2(x, y))
	for i in posiciones.size():
		var parcela := PLOT_SCENE.instantiate() as Node2D
		parcela.name = "ParcelaExtra%d" % (i + 1)
		parcela.position = posiciones[i]
		parcela.set("desbloqueada", false)
		parcela.set("precio_desbloqueo", 0)
		%Parcelas.add_child(parcela)
		parcelas.append(parcela)


func _configurar_precios_parcelas() -> void:
	# Los seis espacios bloqueados del area inicial encabezan la progresion.
	for i in 6:
		parcelas[9 + i].set("precio_desbloqueo", PRECIOS_PARCELAS[i])
	for i in 12:
		parcelas[15 + i].set("precio_desbloqueo", PRECIOS_PARCELAS[6 + i])
	for i in parcelas_rancho_dos.size():
		parcelas_rancho_dos[i].set("precio_desbloqueo", PRECIOS_PARCELAS_RANCHO_DOS[i])


func _crear_parcelas_rancho_dos() -> void:
	var posiciones := [
		Vector2(2940, 430), Vector2(3030, 430), Vector2(3120, 430),
		Vector2(2940, 520), Vector2(3030, 520), Vector2(3120, 520),
		Vector2(2940, 610), Vector2(3030, 610), Vector2(3120, 610),
		Vector2(2940, 700), Vector2(3030, 700), Vector2(3120, 700),
	]
	for i in posiciones.size():
		var parcela := PLOT_SCENE.instantiate() as Node2D
		parcela.name = "ParcelaRancho2_%d" % (i + 1)
		parcela.position = posiciones[i]
		parcela.set("desbloqueada", false)
		parcela.set("precio_desbloqueo", 0)
		parcela.visible = segundo_rancho_comprado
		%Parcelas.add_child(parcela)
		parcelas.append(parcela)
		parcelas_rancho_dos.append(parcela)
	casa_rancho_dos.visible = segundo_rancho_comprado


func _crear_filas_precio_extra() -> void:
	var filas_necesarias := Global.CROPS.size() + 2
	while filas.size() < filas_necesarias:
		var fila := HBoxContainer.new()
		fila.name = "FilaCultivo%d" % (filas.size() + 1)
		fila.add_theme_constant_override("separation", 8)
		var icono := TextureRect.new()
		icono.name = "Icono"
		icono.custom_minimum_size = Vector2(32, 32)
		icono.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fila.add_child(icono)
		var texto := Label.new()
		texto.name = "Texto"
		texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		texto.add_theme_font_size_override("font_size", 14)
		fila.add_child(texto)
		%Filas.add_child(fila)
		filas.append(fila)


func _crear_semillas_extra() -> void:
	while botones_semilla.size() < Global.CROPS.size():
		var indice := botones_semilla.size()
		var boton := Button.new()
		boton.name = "Semilla%d" % (indice + 1)
		boton.custom_minimum_size = Vector2(170, 52)
		boton.focus_mode = Control.FOCUS_NONE
		boton.expand_icon = true
		barra_semillas.add_child(boton)
		botones_semilla.append(boton)


func _lotes_nuevos() -> Array[Dictionary]:
	var posiciones := [
		Vector2(1120, 410), Vector2(1450, 850), Vector2(1770, 530), Vector2(2460, 650),
		Vector2(1250, 700), Vector2(1510, 400), Vector2(1660, 1100),
		Vector2(1930, 900), Vector2(2290, 500), Vector2(2360, 780),
	]
	var precios_terreno := [350, 450, 550, 700, 800, 900, 1000, 1100, 1200, 1300]
	var precios_casa := [600, 750, 900, 1100, 1250, 1400, 1550, 1700, 1850, 2000]
	var recompensas := [140, 0, 220, 300, 180, 200, 220, 240, 260, 280]
	var nombres: Array = NOMBRES_VECINOS.duplicate()
	nombres.shuffle()
	var lotes: Array[Dictionary] = []
	for i in posiciones.size():
		var encargo: Dictionary = CICLO_ENCARGOS[i % CICLO_ENCARGOS.size()]
		var lote: Dictionary = {
			"nombre": nombres[i],
			"pos": [posiciones[i].x, posiciones[i].y],
			"precio": precios_terreno[i],
			"casa_precio": precios_casa[i],
			"terreno": false,
			"ready_at": 0.0,
			"quest_item": encargo.item,
			"quest_count": encargo.cantidad,
			"reward": "dinero",
			"reward_amount": recompensas[i],
			"completada": false,
		}
		if i == 1:
			lote.reward = "mueble"
			lote.reward_item = "Silla hacia abajo"
		lotes.append(lote)
	return lotes


func _normalizar_lotes(guardados: Array) -> Array[Dictionary]:
	var base := _lotes_nuevos()
	var cantidad_guardada := mini(guardados.size(), base.size())
	var usados: Array[String] = []
	for i in cantidad_guardada:
		var datos: Dictionary = guardados[i]
		for clave in datos:
			base[i][clave] = datos[clave]
		var nombre_guardado := _quitar_acentos(str(base[i].get("nombre", "")))
		if not nombre_guardado.is_empty():
			base[i]["nombre"] = nombre_guardado
			usados.append(nombre_guardado)
		if base[i].has("reward_item"):
			base[i]["reward_item"] = _normalizar_nombre_mueble(str(base[i]["reward_item"]))
	var nombres_disponibles: Array = NOMBRES_VECINOS.duplicate()
	for nombre in usados:
		nombres_disponibles.erase(nombre)
	nombres_disponibles.shuffle()
	for i in range(cantidad_guardada, base.size()):
		if not nombres_disponibles.is_empty():
			base[i].nombre = nombres_disponibles.pop_back()
	return base


func _quitar_acentos(texto: String) -> String:
	return texto.replace(String.chr(0xE1), "a").replace(String.chr(0xE9), "e").replace(String.chr(0xED), "i").replace(String.chr(0xF3), "o").replace(String.chr(0xFA), "u").replace(String.chr(0xC1), "A").replace(String.chr(0xC9), "E").replace(String.chr(0xCD), "I").replace(String.chr(0xD3), "O").replace(String.chr(0xDA), "U")


func is_on_land(posicion: Vector2) -> bool:
	return $Mapa/FormaIsla.contains_world_position(posicion)


func can_stand_at(posicion: Vector2, radio: float) -> bool:
	if not is_on_land(posicion):
		return false
	for muestra in 8:
		var angulo := TAU * float(muestra) / 8.0
		if not is_on_land(posicion + Vector2(cos(angulo), sin(angulo)) * radio):
			return false
	return true


func _crear_lotes() -> void:
	lot_visuals.clear()
	var contenedor: Node2D = $TerrenosVecinales
	for indice in mini(lot_states.size(), contenedor.get_child_count()):
		var parcela := contenedor.get_child(indice) as Node2D
		if parcela == null:
			continue
		lot_visuals.append(parcela)
		var estado: Dictionary = lot_states[indice]
		# La posicion editada en Game es la referencia para interaccion y guardado.
		estado.pos = [parcela.position.x, parcela.position.y]
		lot_states[indice] = estado
		if float(estado.get("ready_at", 0.0)) > 0.0 and Time.get_unix_time_from_system() >= float(estado.ready_at):
			_crear_casa_vecina(indice, false)


func _crear_casa_vecina(indice: int, avisar := true) -> void:
	if indice < 0 or indice >= lot_visuals.size():
		return
	var parcela: Node2D = lot_visuals[indice]
	var casa := parcela.get_node_or_null("CasaVecina") as Node2D
	var casa_nueva := casa != null and not casa.visible
	parcela.call("crear_casa", str(lot_states[indice].nombre))
	if casa_nueva and avisar:
		_anuncio_grande("¡Casa desbloqueada! La casa de %s ya esta lista." % str(lot_states[indice].nombre))


func _restaurar_terrenos(estado: Dictionary) -> void:
	var parcelas_guardadas: Array = estado.get("plots", [])
	for i in mini(parcelas_guardadas.size(), parcelas.size()):
		var datos: Dictionary = parcelas_guardadas[i]
		var parcela = parcelas[i]
		parcela.desbloqueada = bool(datos.get("unlocked", parcela.desbloqueada))
		parcela.state = int(datos.get("state", PlotScript.State.EMPTY))
		# En partidas previas los extras se otorgaban abiertos; ahora se compran.
		# Conserva abiertos los que ya tengan un cultivo para no perder progreso.
		if i >= 15 and parcela.state == PlotScript.State.EMPTY:
			parcela.desbloqueada = false
		parcela.crop_index = int(datos.get("crop", -1))
		parcela.growth = float(datos.get("growth", 0.0))
		parcela.call("_actualizar")
	muebles_comprados.clear()
	for nombre_guardado in estado.get("furniture", []):
		if str(nombre_guardado) not in ["Planta", "Flores"]:
			muebles_comprados.append(_normalizar_nombre_mueble(str(nombre_guardado)))
	muebles_colocados_primera = _deserializar_muebles(estado.get("placed_furniture", []))
	muebles_colocados = muebles_colocados_primera.duplicate(true)
	estilo_piso_primera = clampi(int(estado.get("floor_style", 0)), 0, 3)
	estilo_piso = estilo_piso_primera
	muebles_colocados_segunda = _deserializar_muebles(estado.get("second_placed_furniture", []))
	estilo_piso_segunda = clampi(int(estado.get("second_floor_style", 0)), 0, 3)
	if selector_color_piso != null:
		selector_color_piso.select(estilo_piso)


func _deserializar_muebles(lista: Array) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for objeto_guardado in lista:
		var nombre_guardado := _normalizar_nombre_mueble(str(objeto_guardado.get("nombre", "")))
		if nombre_guardado in ["Planta", "Flores"] or DECORACIONES_RETIRADAS.has(nombre_guardado):
			continue
		var posicion: Array = objeto_guardado.get("pos", [350, 320])
		resultado.append({"nombre": _normalizar_nombre_mueble(str(objeto_guardado.get("nombre", "Cama"))), "pos": Vector2(float(posicion[0]), float(posicion[1]))})
	return resultado


func _serializar_muebles(lista: Array[Dictionary]) -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for objeto in lista:
		resultado.append({"nombre": str(objeto.nombre), "pos": [objeto.pos.x, objeto.pos.y]})
	return resultado


func _guardar_decoracion_activa() -> void:
	if decorando_segunda_casa:
		muebles_colocados_segunda = muebles_colocados.duplicate(true)
		estilo_piso_segunda = estilo_piso
	else:
		muebles_colocados_primera = muebles_colocados.duplicate(true)
		estilo_piso_primera = estilo_piso


func _aplicar_guardado(estado: Dictionary) -> void:
	_restaurar_terrenos(estado)
	_restaurar_productos_suelo(estado.get("ground_products", []))
	for animal in animales_nodo.get_children():
		animal.queue_free()
	for tipo in Global.animales:
		_crear_animal(tipo, false)


func _autoguardar() -> void:
	if Global.current_game_id.is_empty():
		return
	if dentro_casa:
		_guardar_decoracion_activa()
	var datos_parcelas: Array[Dictionary] = []
	for parcela in parcelas:
		datos_parcelas.append({"unlocked": parcela.desbloqueada, "state": parcela.state, "crop": parcela.crop_index, "growth": parcela.growth})
	var estado := {"plots": datos_parcelas, "lots": lot_states.duplicate(true), "furniture": muebles_comprados.duplicate(), "placed_furniture": _serializar_muebles(muebles_colocados_primera), "floor_style": estilo_piso_primera, "second_placed_furniture": _serializar_muebles(muebles_colocados_segunda), "second_floor_style": estilo_piso_segunda, "player_pos": [jugador.position.x, jugador.position.y], "player_route": recorrido_jugador.duplicate(true), "second_ranch": segundo_rancho_comprado, "ground_products": _serializar_productos_suelo(), "tutorial_step": tutorial_step, "tutorial_plot": parcelas.find(tutorial_parcela) if tutorial_step == 3 else -1}
	Global.save_slot(Global.current_slot, estado)


func _serializar_productos_suelo() -> Array[Dictionary]:
	var guardados: Array[Dictionary] = []
	for objeto in productos_suelo:
		if not is_instance_valid(objeto):
			continue
		guardados.append({"item": str(objeto.get_meta("producto", "")), "pos": [objeto.global_position.x, objeto.global_position.y]})
	return guardados


func _restaurar_productos_suelo(guardados: Array) -> void:
	for hijo in productos_suelo_nodo.get_children():
		productos_suelo_nodo.remove_child(hijo)
		hijo.free()
	productos_suelo.clear()
	for datos in guardados:
		var id := str(datos.get("item", ""))
		if id not in ["leche", "huevo"]:
			continue
		var posicion: Array = datos.get("pos", [0.0, 0.0])
		if posicion.size() < 2:
			continue
		_crear_producto_suelo(id, Vector2(float(posicion[0]), float(posicion[1])), false)


func _crear_producto_suelo(id: String, posicion: Vector2, animar := true) -> void:
	var objeto := Node2D.new()
	objeto.name = "ProductoSuelo_%s" % id.capitalize()
	objeto.set_meta("producto", id)
	objeto.global_position = posicion
	var sprite := Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = icono_leche if id == "leche" else TEXTURA_HUEVO
	sprite.scale = Vector2(2.0, 2.0)
	sprite.position = Vector2(0, -28) if animar else Vector2.ZERO
	sprite.z_index = 2
	objeto.add_child(sprite)
	productos_suelo_nodo.add_child(objeto)
	objeto.global_position = posicion
	productos_suelo.append(objeto)
	if animar:
		var animacion := create_tween()
		animacion.tween_property(sprite, "position", Vector2.ZERO, 0.24).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _recoger_producto_suelo(objeto: Node2D) -> void:
	if not is_instance_valid(objeto):
		return
	var id := str(objeto.get_meta("producto", ""))
	if id not in ["leche", "huevo"]:
		return
	Global.inventory[id] = int(Global.inventory.get(id, 0)) + 1
	Global.animal_products[id] = int(Global.animal_products.get(id, 0)) + 1
	productos_suelo.erase(objeto)
	objeto.queue_free()
	_toast("Recogiste %s" % _nombre_producto(id))


func _guardar_punto_recorrido(delta: float) -> void:
	if dentro_casa or mercado_abierto or ajustes.visible or panel_mochila.visible:
		return
	tiempo_muestra_recorrido += delta
	if tiempo_muestra_recorrido < 1.25:
		return
	tiempo_muestra_recorrido = 0.0
	var posicion := jugador.global_position
	if not recorrido_jugador.is_empty():
		var anterior: Array = recorrido_jugador[-1].get("pos", [])
		if anterior.size() == 2 and posicion.distance_to(Vector2(float(anterior[0]), float(anterior[1]))) < 18.0:
			return
	recorrido_jugador.append({"pos": [roundi(posicion.x), roundi(posicion.y)], "at": int(Time.get_unix_time_from_system())})
	while recorrido_jugador.size() > 2000:
		recorrido_jugador.pop_front()


func _actualizar_misiones() -> void:
	if lista_misiones == null:
		return
	var lineas: Array[String] = []
	var ahora := int(Time.get_unix_time_from_system())
	for datos in lot_states:
		if not bool(datos.get("terreno", false)):
			continue
		var nombre := str(datos.get("nombre", "Vecino"))
		if bool(datos.get("completada", false)):
			var restante := maxi(0, int(float(datos.get("next_quest_at", 0.0)) - ahora))
			lineas.append("%s: siguiente mision en %d:%02d" % [nombre, floori(float(restante) / 60.0), restante % 60])
		else:
			var id_articulo := str(datos.get("quest_item", "maiz"))
			var articulo := _nombre_producto(id_articulo)
			var requerido := int(datos.get("quest_count", 1))
			var actual := int(Global.inventory.get(id_articulo, 0))
			if id_articulo == "leche" or id_articulo == "huevo":
				actual = int(Global.animal_products.get(id_articulo, 0))
			lineas.append("%s: %s %d/%d" % [nombre, articulo, mini(actual, requerido), requerido])
	var texto := "\n".join(PackedStringArray(lineas)) if not lineas.is_empty() else "Compra un terreno vecino para aceptar sus misiones."
	if texto != texto_misiones_actual:
		lista_misiones.text = texto
		texto_misiones_actual = texto


func _calcular_obstaculos_animales() -> void:
	obstaculos_animales.clear()
	if colision_casa.shape is RectangleShape2D:
		var forma := colision_casa.shape as RectangleShape2D
		var tam := forma.size * colision_casa.global_scale
		obstaculos_animales.append(Rect2(colision_casa.global_position - tam * 0.5, tam))
	obstaculos_animales.append(Rect2(mercado.global_position + Vector2(-96, -96), Vector2(192, 192)))
	for contenedor in [$Mapa/Decoracion, $Mapa/DecoracionAmbiental]:
		for decoracion in contenedor.get_children():
			var hitbox := decoracion.get_node_or_null("ColisionArbol/Hitbox") as CollisionShape2D
			if hitbox != null and hitbox.shape is RectangleShape2D:
				var tam_hitbox := (hitbox.shape as RectangleShape2D).size * hitbox.global_scale
				obstaculos_animales.append(Rect2(hitbox.global_position - tam_hitbox * 0.5, tam_hitbox))
			elif decoracion.name.begins_with("Arbusto"):
				obstaculos_animales.append(Rect2(decoracion.global_position - Vector2(16, 16), Vector2(32, 32)))
	for parcela in parcelas:
		var suelo := parcela.get_node("Suelo") as Control
		obstaculos_animales.append(suelo.get_global_rect())


func _abrir_compra() -> void:
	if mercado_abierto:
		comprando = true
		texto_mercado = "¿Algo te ha llamado la atencion?"


func _abrir_menu_casa() -> void:
	mercado_abierto = true
	comprando = false
	dialog_mode = "farm_house"
	titulo_vendedor.text = "Casa de la granja"
	texto_mercado = "Entra a decorar tu casa o revisa la expansion del rancho."
	boton_vender.text = "Decorar casa (1)"
	boton_comprar.text = "Segundo rancho (2)"
	boton_salir_mercado.text = "Salir (3)"
	boton_vender.visible = true
	boton_comprar.visible = true
	boton_salir_mercado.visible = true
	boton_vender.disabled = false
	boton_comprar.disabled = false
	boton_salir_mercado.disabled = false
	jugador.set_physics_process(false)


func _abrir_menu_segundo_rancho() -> void:
	dialog_mode = "second_ranch"
	titulo_vendedor.text = "Expansion del rancho"
	boton_vender.text = "Comprar segundo rancho ($%d) (1)" % PRECIO_SEGUNDO_RANCHO
	boton_comprar.text = "Volver (2)"
	boton_salir_mercado.text = "Salir (3)"
	boton_vender.disabled = segundo_rancho_comprado or Global.coins < PRECIO_SEGUNDO_RANCHO
	boton_comprar.disabled = false
	boton_salir_mercado.disabled = false
	texto_mercado = "Compra una nueva zona de cultivo al este del puente por $%d." % PRECIO_SEGUNDO_RANCHO if not segundo_rancho_comprado else "El segundo rancho ya es tuyo. Cruza el puente hacia el este para llegar."
	mercado_abierto = true
	comprando = false
	jugador.set_physics_process(false)


func _cerrar_compra() -> void:
	comprando = false
	texto_mercado = "¿Quieres hacer algo mas?"


func _vender() -> void:
	if not mercado_abierto:
		return
	dialog_mode = "sell"
	comprando = false
	texto_mercado = "Selecciona que producto y que cantidad quieres vender."
	_actualizar_menu_venta()


func _crear_menu_venta() -> void:
	fondo_menu_venta = PanelContainer.new()
	fondo_menu_venta.name = "FondoMenuVender"
	fondo_menu_venta.position = Vector2(10, 144)
	fondo_menu_venta.size = Vector2(700, 232)
	var estilo_fondo := StyleBoxFlat.new()
	estilo_fondo.bg_color = Color("#d8bc8a")
	estilo_fondo.border_color = Color("#765533")
	estilo_fondo.set_border_width_all(3)
	estilo_fondo.set_corner_radius_all(8)
	estilo_fondo.content_margin_left = 8.0
	estilo_fondo.content_margin_top = 8.0
	estilo_fondo.content_margin_right = 8.0
	estilo_fondo.content_margin_bottom = 8.0
	fondo_menu_venta.add_theme_stylebox_override("panel", estilo_fondo)
	fondo_menu_venta.visible = false
	tienda.add_child(fondo_menu_venta)
	menu_vender = VBoxContainer.new()
	menu_vender.name = "MenuVenderSeleccion"
	menu_vender.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_vender.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_vender.add_theme_constant_override("separation", 6)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(660, 160)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_vender.add_child(scroll)
	lista_venta = VBoxContainer.new()
	lista_venta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista_venta.add_theme_constant_override("separation", 4)
	scroll.add_child(lista_venta)
	var boton_volver := Button.new()
	boton_volver.text = "Volver (Esc)"
	boton_volver.custom_minimum_size = Vector2(180, 42)
	boton_volver.pressed.connect(_cerrar_menu_venta)
	menu_vender.add_child(boton_volver)
	fondo_menu_venta.add_child(menu_vender)


func _actualizar_menu_venta() -> void:
	for hijo in lista_venta.get_children():
		lista_venta.remove_child(hijo)
		hijo.queue_free()
	var hay_productos := false
	var productos: Array[Dictionary] = []
	for cultivo in Global.CROPS:
		productos.append({"id": str(cultivo.id), "nombre": str(cultivo.name)})
	productos.append_array([
		{"id": "leche", "nombre": "Leche"},
		{"id": "huevo", "nombre": "Huevo"},
	])
	for producto in productos:
		var id: String = producto.id
		var cantidad := int(Global.inventory.get(id, 0))
		if cantidad > 0:
			hay_productos = true
		var precio := int(Global.prices.get(id, Global.product_price(id)))
		var fila := HBoxContainer.new()
		fila.custom_minimum_size = Vector2(660, 38)
		fila.add_theme_constant_override("separation", 8)
		var icono := TextureRect.new()
		icono.custom_minimum_size = Vector2(32, 32)
		icono.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.texture = _icono_producto_venta(id)
		fila.add_child(icono)
		var etiqueta := Label.new()
		etiqueta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		etiqueta.text = "%s ×%d · $%d c/u" % [str(producto.nombre), cantidad, precio]
		etiqueta.add_theme_color_override("font_color", Color("#342517"))
		fila.add_child(etiqueta)
		var selector := SpinBox.new()
		selector.custom_minimum_size = Vector2(82, 36)
		selector.min_value = 1
		selector.max_value = maxi(1, cantidad)
		selector.step = 1
		selector.value = 1
		selector.editable = cantidad > 0
		selector.modulate.a = 1.0 if cantidad > 0 else 0.55
		fila.add_child(selector)
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(112, 36)
		boton.text = "Vender"
		boton.disabled = cantidad <= 0
		boton.pressed.connect(_vender_producto.bind(id, selector))
		fila.add_child(boton)
		lista_venta.add_child(fila)
	if not hay_productos:
		var sin_productos := Label.new()
		sin_productos.text = "No tienes productos en la mochila para vender."
		sin_productos.add_theme_color_override("font_color", Color("#342517"))
		lista_venta.add_child(sin_productos)


func _icono_producto_venta(id: String) -> Texture2D:
	for i in Global.CROPS.size():
		if str(Global.CROPS[i].id) == id:
			return Global.icono_cultivo(i)
	if id == "leche":
		return icono_leche
	if id == "huevo":
		return TEXTURA_HUEVO
	return null


func _vender_producto(id: String, selector: SpinBox) -> void:
	if not mercado_abierto or dialog_mode != "sell":
		return
	var disponible := int(Global.inventory.get(id, 0))
	if disponible <= 0:
		_actualizar_menu_venta()
		return
	var cantidad := mini(disponible, int(selector.value))
	var precio := int(Global.prices.get(id, Global.product_price(id)))
	var total := cantidad * precio
	Global.coins += total
	var restante := disponible - cantidad
	if restante > 0:
		Global.inventory[id] = restante
	else:
		Global.inventory.erase(id)
	if id in ["leche", "huevo"]:
		Global.animal_products[id] = maxi(0, int(Global.animal_products.get(id, 0)) - cantidad)
	if tutorial_step == 4:
		for cultivo in Global.CROPS:
			if str(cultivo.id) == id:
				_completar_tutorial()
				break
	texto_mercado = "Vendiste %d %s y recibiste $%d. Elige otro producto o vuelve." % [cantidad, _nombre_producto(id), total]
	_actualizar_menu_venta()
	_autoguardar()


func _cerrar_menu_venta() -> void:
	if dialog_mode != "sell":
		return
	dialog_mode = "market"
	texto_mercado = "¿Quieres hacer algo mas?"


func _comprar(tipo: String) -> void:
	if not mercado_abierto or not comprando:
		return
	var nombre: String = Global.ANIMALES[tipo]["nombre"]
	var precio: int = Global.ANIMALES[tipo]["precio"]
	if Global.animales.size() >= max_animales:
		texto_mercado = "Ya tienes el maximo de animales. ¿Quieres hacer algo mas?"
		comprando = false
		return
	if not Global.comprar_animal(tipo):
		texto_mercado = "No tienes monedas suficientes para %s ($%d). ¿Quieres hacer algo mas?" % [nombre, precio]
		comprando = false
		return
	_crear_animal(tipo, true)
	comprando = false
	texto_mercado = "¡Muchas gracias por tu compra de %s! ¿Quieres hacer algo mas?" % nombre
	_autoguardar()


func _crear_animal(tipo: String, desde_mercado: bool) -> void:
	var animal: Node2D = ESCENAS_ANIMAL[tipo].instantiate()
	animal.set_meta("tipo", tipo)
	animales_nodo.add_child(animal)
	animal.iniciar(zona_animales.get_global_rect().grow(-margen_animales), obstaculos_animales)
	if desde_mercado:
		_autoguardar()


func _on_seed_pressed(i: int) -> void:
	if Global.is_unlocked(i):
		Global.selected = i


func _refresh_hud() -> void:
	
	nivel_label.text = "Nv %d" % Global.level
	barra_xp.max_value = Global.xp_needed()
	barra_xp.value = Global.xp
	xp_label.text = "%d / %d XP" % [Global.xp, Global.xp_needed()]
	if monedas_mostradas != Global.coins:
		monedas_label.text = "Monedas: $%d" % Global.coins
		if monedas_mostradas >= 0:
			var cambio_monedas := Global.coins - monedas_mostradas
			_animar_contador_monedas()
			if cambio_monedas > 0:
				_mostrar_texto_flotante("+$%d" % cambio_monedas, jugador.global_position + Vector2(0, -30), Color("#ffd45e"))
		monedas_mostradas = Global.coins
	vaca_label.text = "Corral %d · L %d · H %d" % [Global.animales.size(), Global.inventory.get("leche", 0), Global.inventory.get("huevo", 0)]
	var restante: float = Global.price_timer.time_left
	temporizador_label.text = "Cambian en %02d:%02d" % [floori(restante / 60.0), int(restante) % 60]
	for i in Global.CROPS.size():
		var crop = Global.CROPS[i]
		var fila: Node = filas[i]
		var label: Label = fila.get_node("Texto")
		var icono: TextureRect = fila.get_node("Icono")
		fila.visible = true
		if Global.is_unlocked(i):
			icono.texture = Global.icono_cultivo(i)
			var cambio: int = Global.prices[crop["id"]] - Global.last_prices[crop["id"]]
			var delta := "="
			var color := Color("#4b321f")
			if cambio > 0:
				delta = "+%d" % cambio
				color = Color("#456b2d")
			elif cambio < 0:
				delta = "%d" % cambio
				color = Color("#963f37")
			label.text = "%s  $%d" % [crop["name"], Global.prices[crop["id"]]]
			label.add_theme_color_override("font_color", color)
		else:
			icono.texture = null
			label.text = "??? (Nv %d)" % crop["level"]
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	for datos_producto in [
		{"fila": Global.CROPS.size(), "id": "huevo", "nombre": "Huevo", "icono": TEXTURA_HUEVO},
		{"fila": Global.CROPS.size() + 1, "id": "leche", "nombre": "Leche", "icono": icono_leche},
	]:
		var fila_producto: Node = filas[int(datos_producto.fila)]
		fila_producto.visible = true
		fila_producto.get_node("Icono").texture = datos_producto.icono
		var texto_producto := fila_producto.get_node("Texto") as Label
		texto_producto.text = "%s  $%d" % [datos_producto.nombre, Global.product_price(datos_producto.id)]
		(fila_producto.get_node("Texto") as Label).add_theme_color_override("font_color", Color("#38291a"))
	mochila_label.text = "Mochila: %d ($%d)" % [Global.inventory_count(), Global.inventory_value()]
	animales_label.text = "Animales: %d/%d" % [Global.animales.size(), max_animales]
	if dentro_casa:
		ayuda_label.visible = false
		aviso_label.visible = false
		catalogo_muebles.visible = true
		_actualizar_catalogo_muebles()
	else:
		ayuda_label.visible = true
		aviso_label.visible = true
		catalogo_muebles.visible = false
		ayuda_label.text = "CONTROLES\nWASD / flechas: mover\nE: interactuar / casa\nB: abrir mochila\n1-5: elegir semilla\nTienda: E para hablar\nEsc: configuracion\nCada nivel da $100."
	ayuda_label.visible = false
	aviso_label.visible = false
	for i in mini(botones_semilla.size(), Global.CROPS.size()):
		var boton: Button = botones_semilla[i]
		var icono_semilla: Texture2D = Global.icono_cultivo(i)
		if icono_semilla != null:
			boton.icon = icono_semilla
		if Global.is_unlocked(i):
			boton.text = "%d %s" % [i + 1, Global.CROPS[i]["name"]]
			boton.disabled = false
			boton.modulate = Color(1, 1, 0.4) if i == Global.selected else Color.WHITE
		else:
			boton.text = "Nv %d" % Global.CROPS[i]["level"]
			boton.disabled = true
			boton.modulate = Color.WHITE
	if dialog_mode == "market":
		titulo_vendedor.text = "Nando, el vendedor"
		boton_rancho_dos.text = "SEGUNDO RANCHO (4)"
	texto_dialogo.text = texto_mercado
	opciones_tienda.visible = not comprando and dialog_mode != "sell"
	menu_comprar.visible = comprando
	fondo_menu_venta.visible = dialog_mode == "sell"
	boton_rancho_dos.visible = dialog_mode == "market" and not comprando
	var precio_vaca: int = Global.ANIMALES["vaca"]["precio"]
	var precio_pollo: int = Global.ANIMALES["pollo"]["precio"]
	var lleno := Global.animales.size() >= max_animales
	if dialog_mode == "market":
		boton_vender.text = "Vender (1)"
		boton_comprar.text = "Comprar (2)"
		boton_salir_mercado.text = "Nada gracias (3)"
	boton_vaca.text = "Vaca $%d (1)" % precio_vaca
	boton_pollo.text = "Pollo $%d (2)" % precio_pollo
	boton_atras.text = "Volver (3)"
	boton_vaca.disabled = lleno or Global.coins < precio_vaca
	boton_pollo.disabled = lleno or Global.coins < precio_pollo


func _crear_textura_moneda() -> Texture2D:
	var imagen := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	imagen.fill(Color(0, 0, 0, 0))
	for y in 24:
		for x in 24:
			var distancia := Vector2(float(x) - 11.5, float(y) - 11.5).length()
			if distancia <= 11.0:
				var color := Color("#80521e")
				if distancia <= 9.0:
					color = Color("#e5a92f")
				if distancia <= 7.0:
					color = Color("#ffdc72")
				if x >= 6 and x <= 8 and y >= 5 and y <= 8 and distancia <= 9.0:
					color = Color("#fff0ad")
				imagen.set_pixel(x, y, color)
	return ImageTexture.create_from_image(imagen)


func _animar_contador_monedas() -> void:
	if tween_contador_monedas != null and tween_contador_monedas.is_valid():
		tween_contador_monedas.kill()
	monedas_label.scale = Vector2.ONE
	monedas_label.pivot_offset = monedas_label.size * 0.5
	tween_contador_monedas = create_tween()
	tween_contador_monedas.tween_property(monedas_label, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_contador_monedas.tween_property(monedas_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)


func _mostrar_texto_flotante(texto: String, posicion_mundo: Vector2, color: Color) -> void:
	var etiqueta := Label.new()
	etiqueta.text = texto
	etiqueta.size = Vector2(180, 34)
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", 20)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_color_override("font_outline_color", Color("#382a20"))
	etiqueta.add_theme_constant_override("outline_size", 4)
	etiqueta.z_index = 80
	var posicion_pantalla := get_viewport().get_canvas_transform() * posicion_mundo
	etiqueta.position = posicion_pantalla - Vector2(etiqueta.size.x * 0.5, etiqueta.size.y * 0.5)
	$HUD.add_child(etiqueta)
	var animacion := create_tween()
	animacion.set_parallel(true)
	animacion.tween_property(etiqueta, "position", etiqueta.position + Vector2(0, -48), 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	animacion.tween_property(etiqueta, "modulate:a", 0.0, 0.85)
	animacion.set_parallel(false)
	animacion.tween_callback(etiqueta.queue_free)


func _toast(text: String, duration := 2.5) -> void:
	mensaje_label.text = text
	mensaje_label.modulate.a = 1.0
	mensaje_label.scale = Vector2(0.96, 0.96)
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_property(mensaje_label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.tween_interval(duration)
	toast_tween.tween_property(mensaje_label, "modulate:a", 0.0, 0.5)


func _crear_anuncio_grande() -> void:
	anuncio_panel = PanelContainer.new()
	anuncio_panel.name = "AnuncioGrande"
	anuncio_panel.visible = false
	anuncio_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anuncio_panel.z_index = 20
	anuncio_panel.anchor_left = 0.5
	anuncio_panel.anchor_right = 0.5
	anuncio_panel.anchor_top = 0.5
	anuncio_panel.anchor_bottom = 0.5
	anuncio_panel.offset_left = -320.0
	anuncio_panel.offset_right = 320.0
	anuncio_panel.offset_top = -82.0
	anuncio_panel.offset_bottom = 82.0
	anuncio_panel.pivot_offset = Vector2(320.0, 82.0)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.16, 0.12, 0.08, 0.96)
	fondo.border_color = Color(0.96, 0.76, 0.35, 1.0)
	fondo.set_border_width_all(3)
	fondo.set_corner_radius_all(18)
	fondo.set_content_margin_all(18.0)
	fondo.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	fondo.shadow_size = 10
	anuncio_panel.add_theme_stylebox_override("panel", fondo)
	var contenido := VBoxContainer.new()
	contenido.add_theme_constant_override("separation", 6)
	anuncio_titulo = Label.new()
	anuncio_titulo.text = "¡FELICIDADES!"
	anuncio_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anuncio_titulo.add_theme_font_size_override("font_size", 27)
	anuncio_titulo.add_theme_color_override("font_color", Color(1.0, 0.84, 0.48))
	anuncio_titulo.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04))
	anuncio_titulo.add_theme_constant_override("outline_size", 3)
	contenido.add_child(anuncio_titulo)
	anuncio_texto = Label.new()
	anuncio_texto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anuncio_texto.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	anuncio_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	anuncio_texto.add_theme_font_size_override("font_size", 21)
	anuncio_texto.add_theme_color_override("font_color", Color(1.0, 0.97, 0.89))
	contenido.add_child(anuncio_texto)
	anuncio_panel.add_child(contenido)
	$HUD.add_child(anuncio_panel)


func _anuncio_grande(text: String, duration := 4.5) -> void:
	if anuncio_panel == null:
		_crear_anuncio_grande()
	if anuncio_tween != null and anuncio_tween.is_valid():
		anuncio_tween.kill()
	anuncio_texto.text = text
	anuncio_panel.visible = true
	anuncio_panel.modulate.a = 0.0
	anuncio_panel.scale = Vector2(0.88, 0.88)
	anuncio_tween = create_tween()
	anuncio_tween.set_parallel(true)
	anuncio_tween.tween_property(anuncio_panel, "modulate:a", 1.0, 0.2)
	anuncio_tween.tween_property(anuncio_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	anuncio_tween.set_parallel(false)
	anuncio_tween.tween_interval(duration)
	anuncio_tween.tween_property(anuncio_panel, "modulate:a", 0.0, 0.45)
	anuncio_tween.tween_callback(func() -> void: anuncio_panel.visible = false)


func _screenshake(intensidad := 4.0, duracion := 0.2) -> void:
	if camara_jugador == null or not camara_jugador.enabled:
		return
	if screenshake_tween != null and screenshake_tween.is_valid():
		screenshake_tween.kill()
	camara_jugador.offset = Vector2.ZERO
	screenshake_tween = create_tween()
	for _pulso in 3:
		var desplazamiento := Vector2(randf_range(-intensidad, intensidad), randf_range(-intensidad, intensidad))
		screenshake_tween.tween_property(camara_jugador, "offset", desplazamiento, duracion / 6.0)
		screenshake_tween.tween_property(camara_jugador, "offset", Vector2.ZERO, duracion / 6.0)


func _process(_delta: float) -> void:
	if tiempo_buffer_interaccion > 0.0:
		tiempo_buffer_interaccion = maxf(0.0, tiempo_buffer_interaccion - _delta)
	if tutorial_step == 1:
		if jugador.global_position.distance_to(tutorial_pos_inicial) >= 12.0:
			tutorial_step = 2
			_actualizar_panel_tutorial()
			_autoguardar()
	if tutorial_final_tiempo > 0.0:
		tutorial_final_tiempo = maxf(0.0, tutorial_final_tiempo - _delta)
		if tutorial_final_tiempo == 0.0 and tutorial_step == 0 and tutorial_panel != null:
			tutorial_panel.visible = false
	_actualizar_construcciones()
	_actualizar_misiones()
	_guardar_punto_recorrido(_delta)
	tiempo_autoguardado += _delta
	if tiempo_autoguardado >= 30.0:
		tiempo_autoguardado = 0.0
		_autoguardar()
	if dentro_casa:
		monedas_casa_label.text = "MONEDAS: $%d" % Global.coins
		_actualizar_panel_tutorial()
		_update_prompt()
		_refresh_hud()
		return
	# Fuera de la tienda Nando usa su emote neutral; al hablar alterna los dos
	# cuadros de la fila 7 del atlas para simular que esta hablando.
	if mercado_abierto:
		cara_vendedor.frame = int(Time.get_ticks_msec() / 350) % 2
	else:
		cara_vendedor.frame = 0
	_ordenar_decoracion_por_profundidad()
	nearest = _find_nearest()
	if tiempo_buffer_interaccion > 0.0 and not nearest.is_empty():
		tiempo_buffer_interaccion = 0.0
		_interact()
	var tipo: String = nearest.get("type", "")
	if dialog_mode == "market" and tipo != "market" and mercado_abierto:
		_cerrar_mercado()
	for parcela in parcelas:
		parcela.highlight = nearest.get("node") == parcela
	tienda.visible = mercado_abierto
	_actualizar_panel_tutorial()
	_update_prompt()
	_refresh_hud()


func _ordenar_decoracion_por_profundidad() -> void:
	var pies_jugador := jugador.global_position.y + 12.0
	for contenedor in [$Mapa/Decoracion, $Mapa/DecoracionAmbiental]:
		for objeto in contenedor.get_children():
			if not objeto is Sprite2D:
				continue
			var sprite := objeto as Sprite2D
			var rect := sprite.get_rect()
			var escala_y := absf(sprite.global_scale.y)
			var base_objeto := sprite.global_position.y + rect.end.y * escala_y
			# Si el jugador esta al fondo del objeto, este se dibuja delante.
			sprite.z_index = 1 if pies_jugador < base_objeto else 0


func _find_nearest() -> Dictionary:
	var posicion := jugador.global_position
	if posicion.distance_to(vendedor.global_position) <= 90.0:
		return {"type": "market", "node": vendedor}
	if posicion.distance_to(punto_decoracion.global_position) <= 62.0:
		return {"type": "casa", "node": $Casa}
	if segundo_rancho_comprado and is_instance_valid(casa_rancho_dos) and posicion.distance_to(casa_rancho_dos.global_position + Vector2(0, 62)) <= 120.0:
		return {"type": "casa_dos", "node": casa_rancho_dos}
	var producto_cercano: Node2D
	var distancia_producto := 52.0
	for objeto in productos_suelo:
		if not is_instance_valid(objeto):
			continue
		var distancia_actual_producto := posicion.distance_to(objeto.global_position)
		if distancia_actual_producto < distancia_producto:
			distancia_producto = distancia_actual_producto
			producto_cercano = objeto
	if producto_cercano != null:
		return {"type": "ground_product", "node": producto_cercano}
	var distancia_animal := 58.0
	var animal_cercano: Node2D
	for animal in animales_nodo.get_children():
		var distancia_actual_animal: float = posicion.distance_to(animal.global_position)
		if distancia_actual_animal < distancia_animal:
			distancia_animal = distancia_actual_animal
			animal_cercano = animal
	if animal_cercano != null:
		return {"type": "animal", "node": animal_cercano}
	var mejor_lote := -1
	var distancia_lote := 82.0
	for i in lot_states.size():
		var datos: Dictionary = lot_states[i]
		var punto := Vector2(float(datos.pos[0]), float(datos.pos[1]))
		var distancia_actual_lote: float = posicion.distance_to(punto)
		if distancia_actual_lote < distancia_lote:
			distancia_lote = distancia_actual_lote
			mejor_lote = i
	if mejor_lote >= 0:
		var datos: Dictionary = lot_states[mejor_lote]
		if float(datos.ready_at) > 0.0 and Time.get_unix_time_from_system() >= float(datos.ready_at):
			return {"type": "neighbor", "node": lot_visuals[mejor_lote], "index": mejor_lote}
		return {"type": "lot", "node": lot_visuals[mejor_lote], "index": mejor_lote}
	var mejor: Node = null
	var distancia := rango_parcela
	for parcela in parcelas:
		if parcela is Node2D and not (parcela as Node2D).is_visible_in_tree():
			continue
		var actual: float = posicion.distance_to(parcela.global_position)
		if actual < distancia:
			distancia = actual
			mejor = parcela
	if mejor != null:
		var tipo_parcela := "plot" if mejor.desbloqueada else "plot_locked"
		return {"type": tipo_parcela, "node": mejor}
	return {}


func _update_prompt() -> void:
	var texto := ""
	if not nearest.is_empty():
		match nearest["type"]:
			"plot_locked":
				var parcela = nearest["node"]
				texto = "E: Desbloquear terreno ($%d)" % parcela.precio_desbloqueo
			"plot":
				var parcela = nearest["node"]
				if parcela.state == PlotScript.State.EMPTY:
					texto = "E: Plantar %s" % Global.CROPS[Global.selected]["name"]
				elif parcela.state == PlotScript.State.GROWING:
					texto = "Creciendo... %d s" % ceili(Global.GROW_TIME - parcela.growth)
				else:
					texto = "E: Cosechar %s" % Global.CROPS[parcela.crop_index]["name"]
			"market":
				if not mercado_abierto:
					texto = "E: Hablar con Nando"
				elif comprando:
					texto = "1: Vaca  |  2: Pollo  |  3: Volver"
				else:
					texto = "1: Vender  |  2: Comprar  |  3: Salir"
			"casa":
				texto = "E: Entrar y decorar casa 1"
			"casa_dos":
				texto = "E: Entrar y decorar rancho 2"
			"lot":
				var datos: Dictionary = lot_states[int(nearest.index)]
				if not bool(datos.terreno):
					texto = "E: Comprar este terreno ($%d)" % datos.precio
				elif float(datos.ready_at) <= 0.0:
					texto = "E: Elegir una casa ($%d)" % datos.casa_precio
				else:
					var faltan: int = maxi(0, int(float(datos.ready_at) - Time.get_unix_time_from_system()))
					texto = "Construccion: %d:%02d" % [floori(faltan / 60.0), faltan % 60]
			"neighbor":
				texto = "E: Hablar con %s" % lot_states[int(nearest.index)].nombre
			"animal":
				var animal = nearest.node
				var tipo: String = str(animal.get_meta("tipo", "pollo"))
				var producto := "leche" if tipo == "vaca" else "huevo"
				texto = "E: Soltar %s" % producto if animal.producto_disponible() else "%s: produciendo %s" % ["Vaca" if tipo == "vaca" else "Pollo", producto]
			"ground_product":
				var id_producto := str(nearest.node.get_meta("producto", ""))
				texto = "E: Recoger %s" % _nombre_producto(id_producto)
	if dentro_casa:
		texto = "Catalogo: comprar o mover\nArrastra objetos para mover" if mueble_seleccionado == "" else "Clic en el piso: colocar o mover\nE: cancelar"
	aviso_label.text = texto
	_actualizar_prompt_flotante(texto)


func _crear_prompt_interaccion() -> void:
	prompt_interaccion = PanelContainer.new()
	prompt_interaccion.name = "PromptInteraccion"
	prompt_interaccion.visible = false
	prompt_interaccion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_interaccion.z_index = 100
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color("#e6c798")
	fondo.border_color = Color("#8b6038")
	fondo.set_border_width_all(2)
	fondo.set_corner_radius_all(7)
	fondo.content_margin_left = 8
	fondo.content_margin_right = 10
	fondo.content_margin_top = 6
	fondo.content_margin_bottom = 6
	prompt_interaccion.add_theme_stylebox_override("panel", fondo)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	prompt_interaccion.add_child(fila)
	var tecla_panel := PanelContainer.new()
	var fondo_tecla := StyleBoxFlat.new()
	fondo_tecla.bg_color = Color("#8b6038")
	fondo_tecla.set_corner_radius_all(5)
	fondo_tecla.content_margin_left = 7
	fondo_tecla.content_margin_right = 7
	fondo_tecla.content_margin_top = 2
	fondo_tecla.content_margin_bottom = 2
	tecla_panel.add_theme_stylebox_override("panel", fondo_tecla)
	fila.add_child(tecla_panel)
	prompt_tecla = Label.new()
	prompt_tecla.text = "E"
	prompt_tecla.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_tecla.add_theme_color_override("font_color", Color("#fff1d2"))
	prompt_tecla.add_theme_font_size_override("font_size", 16)
	tecla_panel.add_child(prompt_tecla)
	prompt_accion = Label.new()
	prompt_accion.add_theme_color_override("font_color", Color("#382817"))
	prompt_accion.add_theme_font_size_override("font_size", 16)
	fila.add_child(prompt_accion)
	$HUD.add_child(prompt_interaccion)


func _actualizar_prompt_flotante(texto: String) -> void:
	if prompt_interaccion == null:
		return
	if dentro_casa or panel_mochila.visible or ajustes.visible or mercado_abierto or not texto.begins_with("E:"):
		prompt_interaccion.visible = false
		return
	prompt_accion.text = texto.trim_prefix("E: ")
	prompt_interaccion.reset_size()
	prompt_interaccion.size = prompt_interaccion.get_combined_minimum_size()
	var posicion_pantalla := get_viewport().get_canvas_transform() * _posicion_prompt_mundo()
	var tamano := prompt_interaccion.size
	var area := get_viewport_rect()
	var posicion := Vector2(posicion_pantalla.x - tamano.x * 0.5, posicion_pantalla.y - tamano.y - 28.0)
	posicion.x = clampf(posicion.x, 8.0, maxf(8.0, area.size.x - tamano.x - 8.0))
	posicion.y = clampf(posicion.y, 8.0, maxf(8.0, area.size.y - tamano.y - 8.0))
	prompt_interaccion.position = posicion
	prompt_interaccion.visible = true


func _posicion_prompt_mundo() -> Vector2:
	var tipo := str(nearest.get("type", ""))
	if tipo == "casa":
		return punto_decoracion.global_position
	if tipo == "casa_dos":
		return (casa_rancho_dos as Node2D).global_position + Vector2(0, -70)
	if tipo == "neighbor":
		var indice := int(nearest.index)
		var lote: Node2D = lot_visuals[indice]
		if lote.has_node("CasaVecina"):
			return (lote.get_node("CasaVecina") as Node2D).global_position + Vector2(0, -105)
		return lote.global_position + Vector2(0, -70)
	if tipo == "market":
		return vendedor.global_position + Vector2(0, -36)
	var nodo := nearest.get("node") as Node2D
	if nodo != null:
		return nodo.global_position + Vector2(0, -32)
	return jugador.global_position

func _actualizar_construcciones() -> void:
	var ahora := Time.get_unix_time_from_system()
	for indice in lot_states.size():
		var datos: Dictionary = lot_states[indice]
		var restantes_construccion := maxi(0, ceili(float(datos.get("ready_at", 0.0)) - ahora))
		if indice < lot_visuals.size():
			lot_visuals[indice].call("actualizar_temporizador_construccion", restantes_construccion)
		var nuevo_encargo_en := float(datos.get("next_quest_at", 0.0))
		if bool(datos.get("completada", false)) and (nuevo_encargo_en <= 0.0 or ahora >= nuevo_encargo_en):
			_preparar_siguiente_encargo(indice)
			if mercado_abierto and dialog_mode == "neighbor" and active_lot == indice:
				_abrir_dialogo_vecina(indice)
		var lista_en := float(datos.get("ready_at", 0.0))
		if lista_en > 0.0 and ahora >= lista_en:
			_crear_casa_vecina(indice)


func _abrir_dialogo_terreno(indice: int) -> void:
	boton_vender.visible = true
	boton_vender.disabled = false
	boton_comprar.visible = true
	boton_comprar.disabled = false
	boton_salir_mercado.visible = false
	active_lot = indice
	var datos: Dictionary = lot_states[indice]
	if not bool(datos.terreno):
		dialog_mode = "lot_land"
		titulo_vendedor.text = "Terreno disponible"
		texto_mercado = "Este terreno puede ser el inicio de un nuevo hogar. ¿Quieres comprarlo por $%d?" % datos.precio
		boton_vender.text = "Comprar terreno (1)"
		boton_comprar.text = "Luego (2)"
		boton_salir_mercado.visible = false
	elif float(datos.ready_at) <= 0.0:
		dialog_mode = "lot_house"
		titulo_vendedor.text = "Tu terreno"
		texto_mercado = "El terreno ya es tuyo. ¿Quieres comprar una casa por $%d? La construccion tardara 5 minutos." % datos.casa_precio
		boton_vender.text = "Comprar casa (1)"
		boton_comprar.text = "Luego (2)"
		boton_salir_mercado.visible = false
	else:
		_toast("La casa sigue en construccion.")
		return
	mercado_abierto = true
	jugador.set_physics_process(false)


func _abrir_dialogo_vecina(indice: int) -> void:
	if indice < 0 or indice >= lot_states.size():
		return
	var datos: Dictionary = lot_states[indice]
	var ahora := Time.get_unix_time_from_system()
	var nuevo_encargo_en := float(datos.get("next_quest_at", 0.0))
	if bool(datos.get("completada", false)) and (nuevo_encargo_en <= 0.0 or ahora >= nuevo_encargo_en):
		_preparar_siguiente_encargo(indice)
		datos = lot_states[indice]
	boton_vender.visible = true
	boton_vender.disabled = false
	boton_comprar.visible = true
	boton_comprar.disabled = false
	boton_salir_mercado.visible = false
	active_lot = indice
	dialog_mode = "neighbor"
	titulo_vendedor.text = str(datos.nombre)
	if bool(datos.completada):
		var segundos := maxi(0, int(ceil(float(datos.get("next_quest_at", ahora + TIEMPO_ENTRE_ENCARGOS)) - ahora)))
		texto_mercado = "¡Gracias por ayudarme! Preparare otro encargo. Vuelve en %d:%02d." % [floori(float(segundos) / 60.0), segundos % 60]
		boton_vender.text = "Encargo (1)"
		boton_vender.disabled = true
	else:
		var articulo: String = _nombre_producto(str(datos.quest_item))
		var saludo := ""
		if not bool(datos.get("bienvenida", false)):
			saludo = "¡Hola! Soy %s. Acabo de llegar a mi casa. " % str(datos.nombre)
			datos.bienvenida = true
			lot_states[indice] = datos
			_autoguardar()
		texto_mercado = "%s¿Me ayudas con %d %s? Te dare %s como agradecimiento." % [saludo, datos.quest_count, articulo, _texto_recompensa(datos)]
		boton_vender.text = "Entregar (1)"
	boton_comprar.text = "Adios (2)"
	mercado_abierto = true
	jugador.set_physics_process(false)


func _preparar_siguiente_encargo(indice: int) -> void:
	if indice < 0 or indice >= lot_states.size():
		return
	var datos: Dictionary = lot_states[indice]
	var indice_actual := 0
	for i in CICLO_ENCARGOS.size():
		if str(CICLO_ENCARGOS[i].item) == str(datos.get("quest_item", "maiz")):
			indice_actual = i
			break
	var siguiente: Dictionary = CICLO_ENCARGOS[(indice_actual + 1) % CICLO_ENCARGOS.size()]
	datos.quest_item = siguiente.item
	datos.quest_count = siguiente.cantidad
	datos.reward = "dinero"
	datos.reward_amount = siguiente.recompensa
	datos.erase("reward_item")
	datos.completada = false
	datos.next_quest_at = 0.0
	datos.bienvenida = true
	lot_states[indice] = datos
	_autoguardar()

func _dialog_boton(opcion: int) -> void:
	if not mercado_abierto:
		return
	match dialog_mode:
		"farm_house":
			if opcion == 0:
				_cerrar_mercado()
				_entrar_casa()
			elif opcion == 1:
				_abrir_menu_segundo_rancho()
			else:
				_cerrar_mercado()
		"second_ranch":
			if opcion == 0:
				if segundo_rancho_comprado:
					_toast("El segundo rancho ya esta comprado.")
					return
				if Global.coins < PRECIO_SEGUNDO_RANCHO:
					texto_mercado = "Necesitas $%d para comprar el segundo rancho." % PRECIO_SEGUNDO_RANCHO
					return
				Global.coins -= PRECIO_SEGUNDO_RANCHO
				segundo_rancho_comprado = true
				for parcela in parcelas_rancho_dos:
					parcela.visible = true
				casa_rancho_dos.visible = true
				_autoguardar()
				_toast("¡Compraste el segundo rancho! Cruza el puente hacia el este.", 4.0)
				_abrir_menu_segundo_rancho()
			elif opcion == 1:
				_abrir_menu_casa()
			else:
				_cerrar_mercado()
		"market":
			if opcion == 0:
				_vender()
			elif opcion == 1:
				_abrir_compra()
			elif opcion == 2:
				_cerrar_mercado()
			else:
				_abrir_menu_segundo_rancho()
		"lot_land":
			if opcion != 0:
				_cerrar_mercado()
				return
			var datos_terreno: Dictionary = lot_states[active_lot]
			if Global.coins < int(datos_terreno.precio):
				texto_mercado = "Aun necesitas $%d para comprar este terreno." % int(datos_terreno.precio)
				return
			Global.coins -= int(datos_terreno.precio)
			datos_terreno.terreno = true
			lot_states[active_lot] = datos_terreno
			_autoguardar()
			dialog_mode = "lot_house"
			titulo_vendedor.text = "Tu terreno"
			texto_mercado = "¡Felicidades! El terreno de %s ya es tuyo. ¿Quieres comprar una casa por $%d? Estara lista en 5 minutos." % [str(datos_terreno.nombre), int(datos_terreno.casa_precio)]
			boton_vender.text = "Comprar casa (1)"
			boton_comprar.text = "Luego (2)"
			boton_salir_mercado.visible = false
			_anuncio_grande("¡Felicidades! Adquiriste el terreno de %s." % str(datos_terreno.nombre))
		"lot_house":
			if opcion != 0:
				_cerrar_mercado()
				return
			var datos_casa: Dictionary = lot_states[active_lot]
			if Global.coins < int(datos_casa.casa_precio):
				texto_mercado = "Todavia necesitas $%d para pagar la casa." % int(datos_casa.casa_precio)
				return
			Global.coins -= int(datos_casa.casa_precio)
			datos_casa.ready_at = Time.get_unix_time_from_system() + CASA_TIEMPO_CONSTRUCCION
			lot_states[active_lot] = datos_casa
			_autoguardar()
			texto_mercado = "¡Casa de %s en construccion! Estara lista en 5 minutos." % str(datos_casa.nombre)
			_anuncio_grande("¡Construccion iniciada! La casa de %s estara lista en 5 minutos." % str(datos_casa.nombre))
			_cerrar_mercado()
		"neighbor":
			if opcion == 1:
				_cerrar_mercado()
				return
			if opcion != 0:
				return
			var datos_vecina: Dictionary = lot_states[active_lot]
			if bool(datos_vecina.get("completada", false)):
				var faltan := float(datos_vecina.get("next_quest_at", 0.0)) - Time.get_unix_time_from_system()
				if faltan > 0.0:
					return
				_preparar_siguiente_encargo(active_lot)
			_completar_encargo(active_lot)

func _completar_encargo(indice: int) -> void:
	var datos: Dictionary = lot_states[indice]
	if bool(datos.completada):
		return
	var producto: String = str(datos.quest_item)
	var cantidad: int = int(datos.quest_count)
	if int(Global.inventory.get(producto, 0)) < cantidad:
		texto_mercado = "Aun te faltan %d %s. Vuelve cuando los tengas." % [cantidad - int(Global.inventory.get(producto, 0)), _nombre_producto(producto)]
		return
	Global.inventory[producto] -= cantidad
	if Global.animal_products.has(producto):
		Global.animal_products[producto] = maxi(0, int(Global.animal_products[producto]) - cantidad)
	if Global.inventory[producto] <= 0:
		Global.inventory.erase(producto)
	if str(datos.reward) == "dinero":
		Global.coins += int(datos.reward_amount)
	else:
		var mueble: String = _normalizar_nombre_mueble(str(datos.get("reward_item", "Silla hacia abajo")))
		if not muebles_comprados.has(mueble):
			muebles_comprados.append(mueble)
			muebles_colocados.append({"nombre": mueble, "pos": Vector2(350, 330)})
	datos.completada = true
	datos.next_quest_at = Time.get_unix_time_from_system() + TIEMPO_ENTRE_ENCARGOS
	lot_states[indice] = datos
	texto_mercado = "¡Muchas gracias! %s es tu recompensa. Tendre otro encargo en 5 minutos." % _texto_recompensa(datos)
	boton_vender.text = "Encargo (1)"
	boton_vender.disabled = true
	_toast("Encargo completado con %s" % datos.nombre)
	_autoguardar()


func _texto_recompensa(datos: Dictionary) -> String:
	if str(datos.reward) == "dinero":
		return "$%d" % int(datos.reward_amount)
	return "el mueble %s" % _normalizar_nombre_mueble(str(datos.get("reward_item", "Silla hacia abajo")))


func _nombre_producto(id: String) -> String:
	match id:
		"maiz": return "trigo"
		"tomate": return "tomates"
		"leche": return "botellas de leche"
		"huevo": return "huevos"
	return id


func _recoger_producto(animal: Node) -> void:
	if not animal.producto_disponible():
		_toast("Todavia esta produciendo; vuelve mas tarde.")
		return
	var producto: String = animal.recoger_producto()
	if producto == "":
		return
	_crear_producto_suelo(producto, animal.global_position + Vector2(randf_range(-12.0, 12.0), 18.0))
	_toast("%s cayo al suelo. Acercate y presiona E para recogerlo." % ("La leche" if producto == "leche" else "El huevo"))
	_screenshake(3.0, 0.18)


func _input(event: InputEvent) -> void:
	if not dentro_casa or objeto_arrastrado < 0 or objeto_arrastrado >= muebles_colocados.size():
		return
	if event is InputEventMouseMotion:
		var objeto: Dictionary = muebles_colocados[objeto_arrastrado]
		objeto.pos = _limitar_posicion_mueble(event.position, objeto.nombre)
		muebles_colocados[objeto_arrastrado] = objeto
		_actualizar_vista_casa()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		objeto_arrastrado = -1
		_autoguardar()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			_toggle_bolsa()
			get_viewport().set_input_as_handled()
			return
		if panel_mochila.visible and event.keycode == KEY_ESCAPE:
			cerrar_mochila()
			get_viewport().set_input_as_handled()
			return
	if panel_mochila.visible:
		return
	if dentro_casa:
		if event.is_action_pressed("interactuar"):
			get_viewport().set_input_as_handled()
			var ahora := Time.get_ticks_msec()
			if ahora - ultima_interaccion_msec < 180:
				return
			ultima_interaccion_msec = ahora
			if mueble_seleccionado != "":
				mueble_seleccionado = ""
				mueble_seleccionado_indice = -1
				_actualizar_catalogo_muebles()
			else:
				_salir_casa()
			_actualizar_vista_casa()
			return
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			if mueble_seleccionado != "":
				mueble_seleccionado = ""
				mueble_seleccionado_indice = -1
				_actualizar_catalogo_muebles()
				_actualizar_vista_casa()
			else:
				_salir_casa()
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if mueble_seleccionado != "":
					if Rect2(40, 96, 628, 468).has_point(event.position):
						var posicion_final := _limitar_posicion_mueble(event.position, mueble_seleccionado)
						if mueble_seleccionado_indice >= 0 and mueble_seleccionado_indice < muebles_colocados.size():
							var objeto := muebles_colocados[mueble_seleccionado_indice]
							objeto.pos = posicion_final
							muebles_colocados[mueble_seleccionado_indice] = objeto
						else:
							muebles_colocados.append({"nombre": mueble_seleccionado, "pos": posicion_final})
						mueble_seleccionado = ""
						mueble_seleccionado_indice = -1
						_actualizar_vista_casa()
						_actualizar_catalogo_muebles()
						_autoguardar()
					return
				for i in range(muebles_colocados.size() - 1, -1, -1):
					var objeto: Dictionary = muebles_colocados[i]
					var tam_mueble := _tam_mueble(str(objeto.nombre))
					if Rect2(objeto.pos - tam_mueble * 0.5, tam_mueble).has_point(event.position):
						objeto_arrastrado = i
						return
			else:
				objeto_arrastrado = -1
				return
		return
	if ajustes.visible:
		if event.is_action_pressed("ui_cancel"):
			_cerrar_ajustes()
		return
	if mercado_abierto and event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		if dialog_mode == "sell" and event.keycode in [KEY_ESCAPE, KEY_3]:
			_cerrar_menu_venta()
			return
		if event.keycode == KEY_ESCAPE and dialog_mode != "market":
			_cerrar_mercado()
			return
		if dialog_mode == "market":
			_manejar_tecla_mercado(event.keycode)
		elif event.keycode in [KEY_1, KEY_2, KEY_3]:
			_dialog_boton(event.keycode - KEY_1)
		return
	if event.is_action_pressed("interactuar"):
		# E tambien esta asignada a espacio; guarda brevemente la pulsacion para
		# que alcance la interaccion cuando el objetivo entre en rango.
		get_viewport().set_input_as_handled()
		var ahora := Time.get_ticks_msec()
		if ahora - ultima_interaccion_msec < 180 or tiempo_buffer_interaccion > 0.0:
			return
		ultima_interaccion_msec = ahora
		tiempo_buffer_interaccion = TIEMPO_BUFFER_INTERACCION
	elif event.is_action_pressed("ui_cancel"):
		_toggle_ajustes()
	elif event is InputEventKey and event.pressed and not event.echo:
		var numero: int = event.keycode - KEY_1
		if numero >= 0 and numero < Global.CROPS.size() and Global.is_unlocked(numero):
			Global.selected = numero


func _interact() -> void:
	if nearest.is_empty():
		return
	match nearest["type"]:
		"plot_locked":
			var parcela = nearest["node"]
			if Global.coins < parcela.precio_desbloqueo:
				_toast("Necesitas $%d para este terreno." % parcela.precio_desbloqueo)
			else:
				Global.coins -= parcela.precio_desbloqueo
				parcela.desbloquear()
				_toast("¡Terreno desbloqueado! Presiona E para sembrar.")
				_screenshake(2.5, 0.16)
		"plot":
			var parcela = nearest["node"]
			if parcela.state == PlotScript.State.EMPTY:
				parcela.plant(Global.selected)
				_toast("Sembraste %s" % Global.CROPS[Global.selected]["name"])
			elif parcela.state == PlotScript.State.GROWING:
				_toast("Todavia esta creciendo...")
			else:
				var indice: int = parcela.harvest()
				var cultivo = Global.CROPS[indice]
				_toast("+1 %s (+%d XP)" % [cultivo["name"], cultivo["xp"]])
				_mostrar_texto_flotante("+%d XP" % int(cultivo["xp"]), parcela.global_position + Vector2(0, -22), Color("#70e077"))
				Global.harvest(indice)
		"market":
			if not mercado_abierto:
					boton_salir_mercado.visible = true
			if not mercado_abierto:
				mercado_abierto = true
				comprando = false
				texto_mercado = "Hola, granjero. ¿Que quieres hacer hoy?"
				jugador.set_physics_process(false)
		"casa":
			_entrar_casa()
		"casa_dos":
			_entrar_casa(true)
		"animal":
			_recoger_producto(nearest.node)
		"ground_product":
			_recoger_producto_suelo(nearest.node)
		"lot":
			_abrir_dialogo_terreno(int(nearest.index))
		"neighbor":
			_abrir_dialogo_vecina(int(nearest.index))
	_autoguardar()


func cerrar_mochila() -> void:
	panel_mochila.visible = false
	
	if not mercado_abierto and not ajustes.visible and not dentro_casa:
		jugador.set_physics_process(true)


func _toggle_bolsa() -> void:
	if panel_mochila.visible:
		cerrar_mochila()
	elif not mercado_abierto and not ajustes.visible:
		panel_mochila.visible = true
		jugador.set_physics_process(false)


func _entrar_casa(es_segunda: bool = false) -> void:
	dentro_casa = true
	decorando_segunda_casa = es_segunda
	if es_segunda:
		muebles_colocados = muebles_colocados_segunda.duplicate(true)
		estilo_piso = estilo_piso_segunda
	else:
		muebles_colocados = muebles_colocados_primera.duplicate(true)
		estilo_piso = estilo_piso_primera
	if selector_color_piso != null:
		selector_color_piso.select(estilo_piso)
	nearest = {}
	mercado_abierto = false
	comprando = false
	tienda.visible = false
	$HUD/BarraSuperior.visible = false
	$HUD/PanelPrecios.visible = false
	$HUD/PanelMisiones.visible = false
	boton_ajustes.visible = false
	
	interfaz_casa.visible = true
	vista_casa.visible = true
	# La habitacion debe quedar por delante de cualquier sprite del mapa exterior.
	vista_casa.z_index = 1000
	for i in muebles_colocados.size():
		var objeto: Dictionary = muebles_colocados[i]
		objeto.pos = _limitar_posicion_mueble(objeto.pos, objeto.nombre)
		muebles_colocados[i] = objeto
	for nodo in [$Mapa, $Casa, $Mercado, $TerrenosVecinales, %EspaciosDecoracion, %Parcelas, %Animales, $Corral]:
		nodo.visible = false
	casa_rancho_dos.visible = false
	barra_semillas.visible = false
	jugador.visible = false
	jugador.set_physics_process(false)
	camara_jugador.enabled = false
	_actualizar_vista_casa()
	var bienvenida := "Bienvenido a tu segundo rancho." if decorando_segunda_casa else "Bienvenido a tu casa."
	_toast("%s Compra muebles y haz clic para colocarlos." % bienvenida, 4.0)


func _salir_casa() -> void:
	_guardar_decoracion_activa()
	dentro_casa = false
	$HUD/PanelMisiones.visible = true
	interfaz_casa.visible = false
	vista_casa.visible = false
	vista_casa.z_index = 0
	$HUD/BarraSuperior.visible = true
	$HUD/PanelPrecios.visible = true
	boton_ajustes.visible = true
	
	for nodo in [$Mapa, $Casa, $Mercado, $TerrenosVecinales, %EspaciosDecoracion, %Parcelas, %Animales, $Corral]:
		nodo.visible = true
	casa_rancho_dos.visible = segundo_rancho_comprado
	barra_semillas.visible = true
	jugador.visible = true
	jugador.global_position = casa_rancho_dos.global_position + Vector2(0, 112) if decorando_segunda_casa else $Casa/PuntoSalida.global_position
	decorando_segunda_casa = false
	jugador.set_physics_process(true)
	camara_jugador.enabled = true
	camara_jugador.reset_smoothing()
	_actualizar_vista_casa()
	_autoguardar()


func _comprar_mueble(indice: int) -> void:
	var mueble: Dictionary = MUEBLES[indice]
	if muebles_comprados.has(mueble.nombre):
		if mueble_seleccionado == mueble.nombre:
			mueble_seleccionado = ""
			mueble_seleccionado_indice = -1
			_toast("Movimiento cancelado.")
		else:
			mueble_seleccionado = mueble.nombre
			mueble_seleccionado_indice = -1
			for i in range(muebles_colocados.size() - 1, -1, -1):
				if str(muebles_colocados[i].get("nombre", "")) == mueble.nombre:
					mueble_seleccionado_indice = i
					break
			if mueble_seleccionado_indice >= 0:
				_toast("Haz clic en el nuevo lugar para mover %s." % mueble.nombre)
			else:
				_toast("Elige un lugar en el piso para colocar %s." % mueble.nombre)
		_actualizar_catalogo_muebles()
		return
	if mueble_seleccionado == mueble.nombre:
		mueble_seleccionado = ""
		mueble_seleccionado_indice = -1
		_actualizar_catalogo_muebles()
		return
	if Global.coins < mueble.precio:
		_toast("Necesitas $%d para comprar %s." % [mueble.precio, mueble.nombre])
		return
	Global.coins -= mueble.precio
	muebles_comprados.append(mueble.nombre)
	mueble_seleccionado = mueble.nombre
	mueble_seleccionado_indice = -1
	_toast("Compraste %s. Haz clic en el piso para colocarlo." % mueble.nombre)
	_autoguardar()
	_actualizar_catalogo_muebles()
	_actualizar_vista_casa()


func _mueble_ya_colocado(nombre: String) -> bool:
	for objeto in muebles_colocados:
		if str(objeto.get("nombre", "")) == nombre:
			return true
	return false


func _textura_mueble(mueble: Dictionary) -> Texture2D:
	if mueble.hoja == "plantas":
		return TEXTURA_PLANTAS
	if mueble.hoja == "decoracion":
		return TEXTURA_DECORACION
	return TEXTURA_MUEBLES


func _datos_mueble(nombre: String) -> Dictionary:
	for mueble in MUEBLES:
		if mueble.nombre == nombre:
			return mueble
	for mueble in MUEBLES_ANTERIORES:
		if mueble.nombre == nombre:
			return mueble
	return MUEBLES[0]


func _normalizar_nombre_mueble(nombre: String) -> String:
	var normalizado := _quitar_acentos(nombre)
	if normalizado == "Silla":
		return "Silla hacia abajo"
	if normalizado == "Planta en maceta":
		return "Flor amarilla"
	if normalizado == "Maceta verde":
		return "Flor verde"
	if normalizado == "Flor azul en maceta":
		return "Flor azul"
	return normalizado


func _limitar_posicion_mueble(posicion: Vector2, nombre: String) -> Vector2:
	var info := _datos_mueble(nombre)
	var tam := _tam_mueble(nombre)
	if str(info.get("tipo", "piso")) == "pared":
		return Vector2(
			clampf(posicion.x, 215.0 + tam.x * 0.5, 660.0 - tam.x * 0.5),
			clampf(posicion.y, 100.0 + tam.y * 0.5, 350.0 - tam.y * 0.5)
		)
	return Vector2(
		clampf(posicion.x, 42.0 + tam.x * 0.5, 668.0 - tam.x * 0.5),
		clampf(posicion.y, 96.0 + tam.y * 0.5, 565.0 - tam.y * 0.5)
	)


func _tam_mueble(nombre: String) -> Vector2:
	var tam: Vector2 = _datos_mueble(nombre).tam
	return tam * ESCALA_MUEBLES_CASA


func _icono_mueble(mueble: Dictionary) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = _textura_mueble(mueble)
	atlas.region = mueble.region
	return atlas


func _crear_interfaz_casa() -> void:
	interfaz_casa = Control.new()
	interfaz_casa.name = "InterfazCasa"
	interfaz_casa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interfaz_casa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interfaz_casa.z_index = 10
	interfaz_casa.visible = false
	$HUD.add_child(interfaz_casa)
	var titulo := Label.new()
	titulo.text = "MI CASA"
	titulo.position = Vector2(32, 10)
	titulo.add_theme_font_size_override("font_size", 30)
	interfaz_casa.add_child(titulo)
	monedas_casa_label = Label.new()
	monedas_casa_label.position = Vector2(600, 20)
	monedas_casa_label.size = Vector2(300, 32)
	monedas_casa_label.add_theme_font_size_override("font_size", 18)
	interfaz_casa.add_child(monedas_casa_label)
	var salir := Button.new()
	salir.text = "SALIR [ESC]"
	salir.position = Vector2(1040, 12)
	salir.size = Vector2(210, 50)
	salir.focus_mode = Control.FOCUS_NONE
	salir.pressed.connect(_salir_casa)
	interfaz_casa.add_child(salir)


func _crear_catalogo_muebles() -> void:
	catalogo_muebles.name = "CatalogoMuebles"
	catalogo_muebles.position = Vector2(710, 103)
	catalogo_muebles.size = Vector2(520, 450)
	catalogo_muebles.add_theme_constant_override("separation", 5)
	interfaz_casa.add_child(catalogo_muebles)
	var titulo := Label.new()
	titulo.text = "MUEBLES"
	titulo.add_theme_font_size_override("font_size", 24)
	catalogo_muebles.add_child(titulo)
	var descripcion := Label.new()
	descripcion.text = "Compra adornos de pared y muebles para tu casa."
	descripcion.add_theme_font_size_override("font_size", 14)
	catalogo_muebles.add_child(descripcion)
	var fila_piso := HBoxContainer.new()
	fila_piso.add_theme_constant_override("separation", 8)
	catalogo_muebles.add_child(fila_piso)
	var etiqueta_piso := Label.new()
	etiqueta_piso.text = "Color del piso:"
	etiqueta_piso.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila_piso.add_child(etiqueta_piso)
	selector_color_piso = OptionButton.new()
	selector_color_piso.add_item("Madera calida")
	selector_color_piso.add_item("Roble claro")
	selector_color_piso.add_item("Nogal oscuro")
	selector_color_piso.add_item("Rosa campestre")
	selector_color_piso.select(0)
	selector_color_piso.item_selected.connect(_on_color_piso_seleccionado)
	fila_piso.add_child(selector_color_piso)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(510, 330)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalogo_muebles.add_child(scroll)
	lista_catalogo_muebles = VBoxContainer.new()
	lista_catalogo_muebles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lista_catalogo_muebles.add_theme_constant_override("separation", 5)
	scroll.add_child(lista_catalogo_muebles)
	for i in MUEBLES.size():
		var mueble: Dictionary = MUEBLES[i]
		var fila_catalogo := HBoxContainer.new()
		fila_catalogo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila_catalogo.add_theme_constant_override("separation", 5)
		lista_catalogo_muebles.add_child(fila_catalogo)
		var boton := Button.new()
		boton.custom_minimum_size = Vector2(420, 48)
		boton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		boton.focus_mode = Control.FOCUS_NONE
		boton.pressed.connect(_comprar_mueble.bind(i))
		var fila := HBoxContainer.new()
		fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_theme_constant_override("separation", 8)
		var icono := TextureRect.new()
		icono.texture = _icono_mueble(mueble)
		icono.custom_minimum_size = Vector2(40, 40)
		icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nombre := Label.new()
		nombre.name = "Nombre"
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nombre.add_theme_font_size_override("font_size", 17)
		nombre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.add_child(icono)
		fila.add_child(nombre)
		boton.add_child(fila)
		fila_catalogo.add_child(boton)
		botones_catalogo.append(boton)
		etiquetas_catalogo.append(nombre)
		var guardar := Button.new()
		guardar.text = "GUARDAR"
		guardar.custom_minimum_size = Vector2(82, 48)
		guardar.focus_mode = Control.FOCUS_NONE
		guardar.pressed.connect(_guardar_mueble.bind(i))
		fila_catalogo.add_child(guardar)
		botones_guardar_catalogo.append(guardar)


func _actualizar_catalogo_muebles() -> void:
	for i in etiquetas_catalogo.size():
		var nombre: Label = etiquetas_catalogo[i]
		var mueble: Dictionary = MUEBLES[i]
		var comprado := muebles_comprados.has(mueble.nombre)
		var colocado := _mueble_ya_colocado(mueble.nombre)
		var etiqueta := "%s  ·  $%d" % [mueble.nombre.to_upper(), mueble.precio]
		if comprado:
			etiqueta = "%s  ·  MOVER" % mueble.nombre.to_upper() if colocado else "%s  ·  COLOCAR" % mueble.nombre.to_upper()
		if mueble_seleccionado == mueble.nombre:
			etiqueta = "%s  ·  HAZ CLIC EN EL LUGAR" % mueble.nombre.to_upper()
		botones_catalogo[i].disabled = not comprado and Global.coins < mueble.precio
		botones_guardar_catalogo[i].visible = comprado and colocado
		nombre.text = etiqueta


func _guardar_mueble(indice: int) -> void:
	if indice < 0 or indice >= MUEBLES.size():
		return
	var nombre: String = str(MUEBLES[indice].nombre)
	for i in range(muebles_colocados.size() - 1, -1, -1):
		if str(muebles_colocados[i].get("nombre", "")) == nombre:
			muebles_colocados.remove_at(i)
			if mueble_seleccionado == nombre:
				mueble_seleccionado = ""
				mueble_seleccionado_indice = -1
			objeto_arrastrado = -1
			_toast("Guardaste %s." % nombre)
			_actualizar_vista_casa()
			_actualizar_catalogo_muebles()
			_autoguardar()
			return


func _actualizar_vista_casa() -> void:
	var elementos: Array[Dictionary] = []
	for mueble in muebles_colocados:
		var info: Dictionary = _datos_mueble(mueble.nombre)
		elementos.append({
			"texture": _textura_mueble(info),
			"position": mueble.pos,
			"size": _tam_mueble(str(mueble.nombre)),
			"region": info.region,
			"tipo": str(info.get("tipo", "piso")),
			"marco": info.get("marco", Color("#8b6848")),
			"repisa": bool(info.get("repisa", false)),
		})
	vista_casa.call("mostrar_muebles", elementos)
	vista_casa.call("set_floor_style", estilo_piso)


func _on_color_piso_seleccionado(indice: int) -> void:
	estilo_piso = clampi(indice, 0, 3)
	vista_casa.call("set_floor_style", estilo_piso)
	_autoguardar()


func _manejar_tecla_mercado(tecla: int) -> void:
	if comprando:
		if tecla in [KEY_1, KEY_V]:
			_comprar("vaca")
		elif tecla in [KEY_2, KEY_P]:
			_comprar("pollo")
		elif tecla in [KEY_3, KEY_C, KEY_ESCAPE]:
			_cerrar_compra()
		return
	if tecla in [KEY_1, KEY_V]:
		_vender()
	elif tecla in [KEY_2, KEY_C]:
		_abrir_compra()
	elif tecla in [KEY_3, KEY_ESCAPE]:
		_cerrar_mercado()
	elif tecla == KEY_4:
		_abrir_menu_segundo_rancho()


func _cerrar_mercado() -> void:
	boton_salir_mercado.visible = true
	boton_vender.visible = true
	boton_vender.disabled = false
	boton_comprar.visible = true
	boton_comprar.disabled = false
	boton_rancho_dos.visible = true
	mercado_abierto = false
	comprando = false
	dialog_mode = "market"
	texto_mercado = "Hola, granjero. ¿Que quieres hacer hoy?"
	jugador.set_physics_process(true)


func _exit_tree() -> void:
	_autoguardar()


func _toggle_ajustes() -> void:
	if ajustes.visible:
		_cerrar_ajustes()
		return
	_cerrar_mercado()
	ajustes_slider.value = Global.volume * 100.0
	_actualizar_ajustes_label(ajustes_slider.value)
	ajustes.visible = true
	jugador.set_physics_process(false)


func _cerrar_ajustes() -> void:
	ajustes.visible = false
	jugador.set_physics_process(true)


func _regresar_menu_principal() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _on_ajustes_volumen_changed(valor: float) -> void:
	Global.set_volume(valor / 100.0)
	_actualizar_ajustes_label(valor)


func _actualizar_ajustes_label(valor: float) -> void:
	ajustes_label.text = "Volumen: %d%%" % int(valor)


func _on_level_up(nivel: int, desbloqueos: String) -> void:
	var mensaje := "¡Nivel %d! +%d monedas" % [nivel, Global.LEVEL_UP_COINS]
	if desbloqueos != "":
		mensaje += " | Desbloqueaste: " + desbloqueos
	_toast(mensaje, 5.0)


func _on_prices_changed() -> void:
	_toast("¡Los precios del mercado cambiaron!", 4.0)
