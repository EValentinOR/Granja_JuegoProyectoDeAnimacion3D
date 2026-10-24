extends Resource
## Datos visuales de un cultivo. Se edita en el Inspector (abre data/maiz.tres o data/tomate.tres).
##  - etapas: las 4 imagenes del crecimiento, en orden (semilla -> brote -> creciendo -> lista).
##  - icono: imagen del producto para el panel de precios y la barra de semillas.
## Si una etapa o el icono estan vacios, el juego usa la figura de color provisional.

@export var nombre := ""
@export var etapas: Array[Texture2D] = []
@export var icono: Texture2D
