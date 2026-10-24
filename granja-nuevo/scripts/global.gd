extends Node
## Estado global del juego (autoload "Global").
## Aqui estan las constantes que puedes ajustar para balancear el juego.

signal prices_changed
signal leveled_up(new_level: int, unlocks: String)
signal saves_changed
signal shared_save_loaded(success: bool, state: Dictionary, message: String)

const PRICE_INTERVAL := 600.0   # cada 10 minutos cambian los precios
const GROW_TIME := 20.0         # segundos que tarda una planta en crecer
const LEVEL_UP_COINS := 100     # monedas que se reciben al subir de nivel
const SETTINGS_PATH := "user://settings.cfg"
const SAVES_PATH := "user://partidas.json"
const MAX_SAVE_SLOTS := 3
const SUPABASE_URL := "https://bocfrblrvsuvqygcshwe.supabase.co"
const SUPABASE_PUBLISHABLE_KEY := "sb_publishable_mUrGzEV9JR6pbRX4gZnaDA_BF9oZ2wP" # Clave publica; nunca uses la clave secreta aqui.
const DATABASE_ENDPOINT := "https://bocfrblrvsuvqygcshwe.supabase.co/functions/v1/game-saves"
const MUSIC_PATH := "res://assets/musica_granja.wav"
const MUSIC_LOOP_DURATION := 24.0

# "datos" apunta al recurso con las imagenes (4 etapas + icono). Se edita en el Inspector.
const CROPS := [
    {"id": "maiz",   "name": "Trigo",   "price": 12, "xp": 25, "level": 1, "color": Color(1.0, 0.9, 0.2),  "datos": "res://data/maiz.tres"},
    {"id": "tomate", "name": "Tomate", "price": 20, "xp": 30, "level": 4, "color": Color(0.9, 0.15, 0.15), "datos": "res://data/tomate.tres"},
	{"id": "fresa", "name": "Fresa", "price": 28, "xp": 35, "level": 10, "color": Color(0.9, 0.2, 0.35), "datos": "res://data/fresa.tres"},
	{"id": "zanahoria", "name": "Zanahoria", "price": 36, "xp": 40, "level": 17, "color": Color(1.0, 0.45, 0.1), "datos": "res://data/zanahoria.tres"},
	{"id": "calabaza", "name": "Calabaza", "price": 48, "xp": 50, "level": 25, "color": Color(1.0, 0.5, 0.12), "datos": "res://data/calabaza.tres"},
]

# Animales que se compran en el mercado para decorar la casa.
const ANIMALES := {
    "vaca":  {"nombre": "Vaca",  "precio": 400},
    "pollo": {"nombre": "Pollo", "precio": 150},
}

var volume := 0.8
var coins := 0
var xp := 0
var level := 1
var selected := 0
var inventory := {}
var prices := {}
var last_prices := {}
var animales: Array[String] = []     # animales comprados, en orden de compra
var player_name := "Granjero"
var current_slot := -1
var current_game_id := ""
var animal_products := {"leche": 0, "huevo": 0}
var save_slots: Array = []
var pending_save: Dictionary = {}
var database_player_id := ""
var supabase_access_token := ""
var supabase_refresh_token := ""
var supabase_user_id := ""
var sync_ids_pendientes: Dictionary = {}
var solicitud_id_pendiente := ""
var price_timer: Timer
var music_player: AudioStreamPlayer
var _datos_cache := {}


func _ready() -> void:
    _setup_input()
    _load_settings()
    _start_music()
    _load_saves()
    _cargar_partidas_remotas()
    price_timer = Timer.new()
    price_timer.one_shot = false
    price_timer.wait_time = PRICE_INTERVAL
    add_child(price_timer)
    price_timer.timeout.connect(_on_price_timer)
    new_game()


# ---------- Partida ----------

func new_game(nombre: String = "Granjero", slot: int = -1) -> void:
    pending_save = {}
    current_game_id = _nuevo_id_partida()
    player_name = nombre.strip_edges() if not nombre.strip_edges().is_empty() else "Granjero"
    current_slot = slot
    coins = 0
    xp = 0
    level = 1
    selected = 0
    inventory.clear()
    animales.clear()
    animal_products = {"leche": 0, "huevo": 0}
    prices.clear()
    last_prices.clear()
    for c in CROPS:
        prices[c["id"]] = c["price"]
        last_prices[c["id"]] = c["price"]
    price_timer.start(PRICE_INTERVAL)


func _on_price_timer() -> void:
    roll_prices()


func roll_prices() -> void:
    last_prices = prices.duplicate()
    for c in CROPS:
        prices[c["id"]] = maxi(1, roundi(c["price"] * randf_range(0.6, 1.6)))
    prices_changed.emit()


# ---------- Datos visuales de los cultivos ----------

func datos_cultivo(i: int):
    var id: String = CROPS[i]["id"]
    if not _datos_cache.has(id):
        var path: String = CROPS[i]["datos"]
        _datos_cache[id] = load(path) if ResourceLoader.exists(path) else null
    return _datos_cache[id]


func textura_etapa(i: int, etapa: int) -> Texture2D:
    var d = datos_cultivo(i)
    if d == null or etapa < 0 or etapa >= d.etapas.size():
        return null
    return d.etapas[etapa]


func icono_cultivo(i: int) -> Texture2D:
    var d = datos_cultivo(i)
    if d == null:
        return null
    return d.icono


# ---------- Experiencia y niveles ----------

func xp_needed() -> int:
    return 100 * level


func add_xp(amount: int) -> void:
    xp += amount
    while xp >= xp_needed():
        xp -= xp_needed()
        level += 1
        coins += LEVEL_UP_COINS
        leveled_up.emit(level, unlocks_text(level))


func unlocks_text(lvl: int) -> String:
    var names: Array = []
    for c in CROPS:
        if c["level"] == lvl:
            names.append("semilla de " + c["name"])
    return ", ".join(names)


func is_unlocked(crop_index: int) -> bool:
    return level >= CROPS[crop_index]["level"]


# ---------- Cosecha y venta ----------

func harvest(crop_index: int) -> void:
    var c = CROPS[crop_index]
    inventory[c["id"]] = inventory.get(c["id"], 0) + 1
    add_xp(c["xp"])


func inventory_count() -> int:
    var n := 0
    for id in inventory:
        n += inventory[id]
    return n


func inventory_value() -> int:
    var total := 0
    for id in inventory:
        total += inventory[id] * int(prices.get(id, product_price(str(id))))
    return total


func sell_all() -> int:
    var total := inventory_value()
    coins += total
    inventory.clear()
    animal_products = {"leche": 0, "huevo": 0}
    return total


func product_price(id: String) -> int:
    match id:
        "leche": return 35
        "huevo": return 22
    return int(CROPS[0]["price"])


func _load_saves() -> void:
    save_slots.clear()
    for _i in MAX_SAVE_SLOTS:
        save_slots.append({})
    if not FileAccess.file_exists(SAVES_PATH):
        return
    var file := FileAccess.open(SAVES_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Array:
        for i in mini(parsed.size(), MAX_SAVE_SLOTS):
            if parsed[i] is Dictionary:
                save_slots[i] = parsed[i]
                if not save_slots[i].is_empty() and str(save_slots[i].get("game_id", "")).is_empty():
                    save_slots[i]["game_id"] = _nuevo_id_partida()
    _escribir_guardados_locales()


func _nuevo_id_partida() -> String:
    return Crypto.new().generate_random_bytes(16).hex_encode()


func _escribir_guardados_locales() -> void:
    var file := FileAccess.open(SAVES_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(save_slots, "\t"))


func save_slot(slot: int, state: Dictionary) -> bool:
    if slot < -1 or slot >= MAX_SAVE_SLOTS:
        return false
    if current_game_id.is_empty():
        current_game_id = _nuevo_id_partida()
    state["game_id"] = current_game_id
    state["name"] = player_name
    state["updated_at"] = Time.get_unix_time_from_system()
    state["coins"] = coins
    state["xp"] = xp
    state["level"] = level
    state["selected"] = selected
    state["inventory"] = inventory.duplicate(true)
    state["animals"] = animales.duplicate()
    state["animal_products"] = animal_products.duplicate(true)
    if slot >= 0:
        save_slots[slot] = state.duplicate(true)
        var file := FileAccess.open(SAVES_PATH, FileAccess.WRITE)
        if file == null:
            push_error("No se pudieron guardar las partidas: " + error_string(FileAccess.get_open_error()))
            return false
        file.store_string(JSON.stringify(save_slots, "\t"))
    current_slot = slot
    saves_changed.emit()
    _guardar_id_remoto(current_game_id, state.duplicate(true))
    return true


func load_slot(slot: int) -> Dictionary:
    if slot < 0 or slot >= save_slots.size() or save_slots[slot].is_empty():
        return {}
    var state: Dictionary = save_slots[slot].duplicate(true)
    player_name = str(state.get("name", "Granjero"))
    coins = int(state.get("coins", 0))
    xp = int(state.get("xp", 0))
    level = int(state.get("level", 1))
    selected = int(state.get("selected", 0))
    inventory = state.get("inventory", {}).duplicate(true)
    animales.clear()
    for animal in state.get("animals", []):
        animales.append(str(animal))
    animal_products = state.get("animal_products", {"leche": 0, "huevo": 0}).duplicate(true)
    current_slot = slot
    current_game_id = str(state.get("game_id", ""))
    if current_game_id.is_empty():
        current_game_id = _nuevo_id_partida()
        state["game_id"] = current_game_id
    pending_save = state.duplicate(true)
    return state


func delete_slot(slot: int) -> void:
    if slot < 0 or slot >= save_slots.size():
        return
    save_slots[slot] = {}
    var file := FileAccess.open(SAVES_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(save_slots, "\t"))
    saves_changed.emit()


func _database_url(action: String) -> String:
    if DATABASE_ENDPOINT.strip_edges().is_empty() or SUPABASE_URL.strip_edges().is_empty() or SUPABASE_PUBLISHABLE_KEY.strip_edges().is_empty():
        return ""
    return DATABASE_ENDPOINT + ("&" if DATABASE_ENDPOINT.contains("?") else "?") + "action=" + action


func _cargar_partidas_remotas() -> void:
    if _database_url("save").is_empty():
        return
    if not supabase_refresh_token.is_empty():
        _renovar_sesion_supabase()
    else:
        _iniciar_sesion_anonima_supabase()


func _iniciar_sesion_anonima_supabase() -> void:
    var request := HTTPRequest.new()
    request.request_completed.connect(_on_sesion_supabase_recibida.bind(request))
    add_child(request)
    var headers := PackedStringArray(["Content-Type: application/json", "apikey: " + SUPABASE_PUBLISHABLE_KEY])
    var error := request.request(SUPABASE_URL.rstrip("/") + "/auth/v1/signup", headers, HTTPClient.METHOD_POST, JSON.stringify({"data": {}}))
    if error != OK:
        request.queue_free()
        push_warning("No se pudo iniciar la sesion remota; se usaran las partidas locales.")


func _renovar_sesion_supabase() -> void:
    var request := HTTPRequest.new()
    request.request_completed.connect(_on_sesion_supabase_recibida.bind(request))
    add_child(request)
    var headers := PackedStringArray(["Content-Type: application/json", "apikey: " + SUPABASE_PUBLISHABLE_KEY])
    var url := SUPABASE_URL.rstrip("/") + "/auth/v1/token?grant_type=refresh_token"
    var error := request.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify({"refresh_token": supabase_refresh_token}))
    if error != OK:
        request.queue_free()
        _iniciar_sesion_anonima_supabase()


func _on_sesion_supabase_recibida(resultado: int, codigo: int, _headers: PackedStringArray, cuerpo: PackedByteArray, request: HTTPRequest) -> void:
    request.queue_free()
    var respuesta = JSON.parse_string(cuerpo.get_string_from_utf8())
    if resultado != HTTPRequest.RESULT_SUCCESS or codigo < 200 or codigo >= 300 or not respuesta is Dictionary:
        push_warning("No se pudo autenticar con Supabase; se usaran las partidas locales.")
        return
    supabase_access_token = str(respuesta.get("access_token", ""))
    supabase_refresh_token = str(respuesta.get("refresh_token", ""))
    var usuario: Dictionary = respuesta.get("user", {})
    supabase_user_id = str(usuario.get("id", ""))
    if supabase_access_token.is_empty() or supabase_refresh_token.is_empty() or supabase_user_id.is_empty():
        push_warning("Supabase no devolvio una sesion valida; se usaran las partidas locales.")
        return
    database_player_id = supabase_user_id
    _guardar_configuracion()
    for game_id in sync_ids_pendientes.keys():
        _guardar_id_remoto(str(game_id), sync_ids_pendientes[game_id])
    sync_ids_pendientes.clear()
    if not solicitud_id_pendiente.is_empty():
        _solicitar_partida_por_id(solicitud_id_pendiente)


func _guardar_configuracion() -> void:
    var cfg := ConfigFile.new()
    cfg.load(SETTINGS_PATH)
    cfg.set_value("audio", "volume", volume)
    cfg.set_value("database", "player_id", database_player_id)
    cfg.set_value("database", "access_token", supabase_access_token)
    cfg.set_value("database", "refresh_token", supabase_refresh_token)
    cfg.set_value("database", "user_id", supabase_user_id)
    cfg.save(SETTINGS_PATH)


func _guardar_id_remoto(game_id: String, state: Dictionary) -> void:
    if game_id.is_empty() or state.is_empty():
        return
    if supabase_access_token.is_empty():
        sync_ids_pendientes[game_id] = state.duplicate(true)
        return
    var request := HTTPRequest.new()
    request.request_completed.connect(_on_guardado_remoto.bind(request))
    add_child(request)
    var headers := PackedStringArray(["Content-Type: application/json", "apikey: " + SUPABASE_PUBLISHABLE_KEY, "Authorization: Bearer " + supabase_access_token])
    var payload := {"game_id": game_id, "state": state}
    var error := request.request(_database_url("save"), headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
    if error != OK:
        request.queue_free()


func load_shared_save(game_id: String) -> void:
    var normalized_id := game_id.strip_edges().to_lower()
    if normalized_id.length() != 32 or not normalized_id.is_valid_hex_number(false):
        shared_save_loaded.emit(false, {}, "El ID debe tener 32 caracteres hexadecimales.")
        return
    solicitud_id_pendiente = normalized_id
    if not supabase_access_token.is_empty():
        _solicitar_partida_por_id(normalized_id)


func _solicitar_partida_por_id(game_id: String) -> void:
    solicitud_id_pendiente = ""
    var request := HTTPRequest.new()
    request.request_completed.connect(_on_partida_por_id_recibida.bind(request, game_id))
    add_child(request)
    var headers := PackedStringArray(["Content-Type: application/json", "apikey: " + SUPABASE_PUBLISHABLE_KEY, "Authorization: Bearer " + supabase_access_token])
    var error := request.request(_database_url("load_by_id"), headers, HTTPClient.METHOD_POST, JSON.stringify({"game_id": game_id}))
    if error != OK:
        request.queue_free()
        shared_save_loaded.emit(false, {}, "No se pudo iniciar la solicitud a Supabase.")


func _on_partida_por_id_recibida(resultado: int, codigo: int, _headers: PackedStringArray, cuerpo: PackedByteArray, request: HTTPRequest, game_id: String) -> void:
    request.queue_free()
    var respuesta = JSON.parse_string(cuerpo.get_string_from_utf8())
    if resultado == HTTPRequest.RESULT_SUCCESS and codigo == 200 and respuesta is Dictionary and respuesta.get("state", {}) is Dictionary:
        var state: Dictionary = respuesta.get("state", {})
        state["game_id"] = game_id
        shared_save_loaded.emit(true, state, "")
    elif codigo == 404:
        shared_save_loaded.emit(false, {}, "No existe una partida con ese ID.")
    else:
        shared_save_loaded.emit(false, {}, "No se pudo recuperar la partida. Revisa tu conexión e intenta otra vez.")


func load_shared_state(state: Dictionary) -> void:
    current_game_id = str(state.get("game_id", ""))
    current_slot = -1
    for i in save_slots.size():
        if str(save_slots[i].get("game_id", "")) == current_game_id:
            current_slot = i
            break
        if current_slot < 0 and save_slots[i].is_empty():
            current_slot = i
    if current_slot >= 0:
        save_slots[current_slot] = state.duplicate(true)
        _escribir_guardados_locales()
    player_name = str(state.get("name", "Granjero"))
    coins = int(state.get("coins", 0))
    xp = int(state.get("xp", 0))
    level = int(state.get("level", 1))
    selected = int(state.get("selected", 0))
    inventory = state.get("inventory", {}).duplicate(true)
    animales.clear()
    for animal in state.get("animals", []):
        animales.append(str(animal))
    animal_products = state.get("animal_products", {"leche": 0, "huevo": 0}).duplicate(true)
    pending_save = state.duplicate(true)


func _on_guardado_remoto(resultado: int, codigo: int, _headers: PackedStringArray, _cuerpo: PackedByteArray, request: HTTPRequest) -> void:
    request.queue_free()
    if resultado != HTTPRequest.RESULT_SUCCESS or codigo < 200 or codigo >= 300:
        push_warning("No se pudo sincronizar la partida por ID; la copia local sigue guardada.")


# ---------- Animales ----------

func comprar_animal(tipo: String) -> bool:
    var precio: int = ANIMALES[tipo]["precio"]
    if coins < precio:
        return false
    coins -= precio
    animales.append(tipo)
    return true


# ---------- Vaca (bonus) ----------

# ---------- Configuracion ----------

func _start_music() -> void:
    var stream := load(MUSIC_PATH) as AudioStreamWAV
    if stream == null:
        push_warning("No se pudo cargar la musica: " + MUSIC_PATH)
        return
    stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    stream.loop_begin = 0
    stream.loop_end = int(stream.mix_rate * MUSIC_LOOP_DURATION)
    music_player = AudioStreamPlayer.new()
    music_player.name = "MusicaAmbiente"
    music_player.bus = "Master"
    music_player.stream = stream
    add_child(music_player)
    music_player.play()

func set_volume(v: float) -> void:
    volume = clampf(v, 0.0, 1.0)
    AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
    AudioServer.set_bus_mute(0, volume <= 0.001)
    _guardar_configuracion()


func _load_settings() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(SETTINGS_PATH) == OK:
        volume = cfg.get_value("audio", "volume", 0.8)
        database_player_id = str(cfg.get_value("database", "player_id", ""))
        supabase_access_token = str(cfg.get_value("database", "access_token", ""))
        supabase_refresh_token = str(cfg.get_value("database", "refresh_token", ""))
        supabase_user_id = str(cfg.get_value("database", "user_id", ""))
    if not supabase_user_id.is_empty():
        database_player_id = supabase_user_id
    if database_player_id.is_empty():
        database_player_id = Crypto.new().generate_random_bytes(16).hex_encode()
        cfg.set_value("database", "player_id", database_player_id)
        cfg.set_value("audio", "volume", volume)
        cfg.save(SETTINGS_PATH)
    AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
    AudioServer.set_bus_mute(0, volume <= 0.001)


# ---------- Controles (flechas y WASD) ----------

func _setup_input() -> void:
    _add_action("mover_izq", [KEY_LEFT, KEY_A])
    _add_action("mover_der", [KEY_RIGHT, KEY_D])
    _add_action("mover_arr", [KEY_UP, KEY_W])
    _add_action("mover_aba", [KEY_DOWN, KEY_S])
    _add_action("interactuar", [KEY_E, KEY_SPACE])


func _add_action(action: String, keys: Array) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    for k in keys:
        var ev := InputEventKey.new()
        ev.physical_keycode = k
        InputMap.action_add_event(action, ev)
