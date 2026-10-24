extends CharacterBody2D

@export var speed := 260.0
@export var limites := Rect2(-180, -120, 3940, 1680)
@export var margen := 26.0
@export var fps := 8.0           # velocidad de la animacion
@export var fila_abajo := 0      # fila de la hoja para cada direccion
@export var fila_arriba := 1
@export var fila_izquierda := 2
@export var fila_derecha := 3

@onready var sprite: Sprite2D = %Sprite

var fila := 0
var tiempo := 0.0
var tiempo_siguiente_polvo := 0.0


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("mover_izq", "mover_der", "mover_arr", "mover_aba")
	velocity = dir * speed
	var paso := velocity * delta
	if not is_zero_approx(dir.x) and not is_zero_approx(dir.y):
		paso *= 0.70710678
	var posicion_anterior := global_position
	if not is_zero_approx(paso.x):
		move_and_collide(Vector2(paso.x, 0.0))
		if not _posicion_valida():
			global_position = posicion_anterior
			velocity.x = 0.0
	var antes_de_mover_y := global_position
	if not is_zero_approx(paso.y):
		move_and_collide(Vector2(0.0, paso.y))
		if not _posicion_valida():
			global_position = antes_de_mover_y
			velocity.y = 0.0
	position = position.clamp(limites.position + Vector2(margen, margen), limites.end - Vector2(margen, margen))
	if velocity.length_squared() > 1.0:
		tiempo_siguiente_polvo -= delta
		if tiempo_siguiente_polvo <= 0.0:
			_crear_polvo()
			tiempo_siguiente_polvo = 0.09
	else:
		tiempo_siguiente_polvo = 0.0

	var cuadro := 0
	if dir != Vector2.ZERO:
		if absf(dir.x) > absf(dir.y):
			fila = fila_derecha if dir.x > 0.0 else fila_izquierda
		else:
			fila = fila_abajo if dir.y > 0.0 else fila_arriba
		tiempo += delta * fps
		cuadro = int(tiempo) % sprite.hframes
	else:
		tiempo = 0.0
	sprite.frame = fila * sprite.hframes + cuadro


func _crear_polvo() -> void:
	var contenedor := get_tree().current_scene
	if contenedor == null:
		contenedor = get_parent()
	if contenedor == null:
		return
	var polvo := Node2D.new()
	polvo.z_index = 2
	contenedor.add_child(polvo)
	polvo.global_position = global_position - velocity.normalized() * 8.0 + Vector2(randf_range(-5.0, 5.0), 14.0)
	var tween := create_tween().set_parallel(true)
	for i in 3:
		var nube := Polygon2D.new()
		var puntos := PackedVector2Array()
		var radio := randf_range(6.0, 9.0)
		for punto in 12:
			var angulo := TAU * float(punto) / 12.0
			puntos.append(Vector2(cos(angulo), sin(angulo)) * radio)
		nube.polygon = puntos
		nube.position = Vector2(randf_range(-7.0, 7.0), randf_range(-3.0, 3.0))
		nube.color = Color(0.91, 0.82, 0.66, randf_range(0.68, 0.82))
		polvo.add_child(nube)
		tween.tween_property(nube, "color:a", 0.0, 0.58)
	tween.tween_property(polvo, "scale", Vector2(1.7, 1.45), 0.58)
	tween.tween_property(polvo, "global_position", polvo.global_position + Vector2(0.0, -9.0), 0.58)
	tween.chain().tween_callback(polvo.queue_free)


func _posicion_valida() -> bool:
	var mapa := get_parent()
	if mapa.has_method("can_stand_at"):
		return mapa.can_stand_at(global_position, 14.0)
	if mapa.has_method("is_on_land"):
		return mapa.is_on_land(global_position)
	return true
