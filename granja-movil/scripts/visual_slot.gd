extends Node2D
## Ranura para assets. Estructura esperada (hijos directos):
##   Placeholder  -> figura provisional de colores planos (cualquier nodo)
##   Sprite       -> Sprite2D vacio: arrastra aqui tu imagen
## Si "Sprite" tiene textura, el juego oculta el Placeholder y muestra tu imagen.


func _ready() -> void:
    var sprite := get_node_or_null("Sprite") as Sprite2D
    var placeholder := get_node_or_null("Placeholder") as CanvasItem
    var tiene := sprite != null and sprite.texture != null
    if sprite != null:
        sprite.visible = tiene
    if placeholder != null:
        placeholder.visible = not tiene
