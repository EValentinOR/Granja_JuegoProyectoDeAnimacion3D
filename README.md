# Granja

Abre `project.godot` con Godot 4.x y presiona F5.

Controles: WASD / flechas = mover, E o Espacio = interactuar, 1-5 = elegir semilla, Esc = volver al menú.

## Escenas (todo son nodos editables)
- `scenes/menu.tscn`: Fondo, título, botones Jugar / Configuración / Salir y el slider de volumen.
- `scenes/game.tscn`: Mapa, Mercado, Vaca, Parcelas (18 instancias de plot.tscn), Jugador y HUD (barra de XP, monedas, panel de precios, mensajes, barra de semillas).
- `scenes/plot.tscn`: una parcela (Suelo, Planta, Barra de crecimiento, Resalte).
- `scenes/player.tscn`: el personaje (Cuerpo y Cabeza).

Para poner sprites: reemplaza o agrega un Sprite2D dentro de Jugador, Vaca, Mercado o Parcela (plot.tscn). Para más parcelas, duplica una instancia dentro de `Parcelas`.
Los valores de balance (tiempo de crecimiento, intervalo de precios, vaca, cultivos y XP) están al inicio de `scripts/global.gd`.

## Nuevas funciones
- El rancho inicial ahora está en una isla irregular rodeada por agua; la cámara sigue al jugador y hay una isla secundaria conectada por un puente.
- Los tres terrenos vecinos están a la venta. Después de comprar el terreno puedes encargar una casa; tarda 5 minutos y aparece una alerta cuando queda lista.
- Rosa, Edith y Rubí ofrecen encargos de cosechas o productos animales. Algunas recompensas son dinero y otras muebles.
- Las vacas y gallinas permanecen dentro del corral junto a la casa. Producen leche y huevos que se pueden recoger y vender en la tienda.
- La tienda queda al costado del rancho.
- El menú ofrece tres espacios de partida. En un espacio vacío pide el nombre del nuevo granjero; cada partida genera un ID que puedes copiar desde Configuración. Puedes recuperar esa partida desde otro equipo pegando el ID en el menú. Las partidas también se guardan localmente en `user://partidas.json`.
- El menú de la bolsa reutiliza el panel gráfico de configuración. Sus celdas y los nuevos elementos de misiones, temporizador de casas y decoración del menú están en escenas como nodos editables.
- La ruta reciente del jugador se registra en `player_route` dentro de cada guardado, junto con posiciones del mapa y marcas de tiempo. Se limita a 2,000 puntos para mantener ligero el guardado.

## Supabase (recuperación por ID)
Cada partida genera un ID aleatorio de 32 caracteres hexadecimales. En Configuración, dentro del juego, puedes copiarlo. En otro equipo, elige Jugar y pega el ID en “Recupera tu partida”. Quien tenga el ID puede cargar y guardar cambios en esa partida. El botón Borrar elimina solo la copia local; para borrar la copia remota, hazlo desde el Dashboard de Supabase.

Para preparar la sincronización, sigue `supabase/README.md`: ejecuta las migraciones SQL y despliega `supabase/functions/game-saves`. La carpeta `database/` contiene una implementación PHP antigua que el proyecto actual no usa.

## Controles táctiles

El juego conserva teclado y gamepad y agrega un joystick virtual, bolsa, interacción y pausa táctiles. El joystick envía las acciones `move_left`, `move_right`, `move_up` y `move_down`; las demás acciones son `abrir_bolsa`, `interactuar` y `pausa`. Mantén presionado el joystick y toca un botón de acción a la vez (multitouch). Los controles aparecen en dispositivos táctiles; en PC se pueden probar activando **Probar controles táctiles en PC** desde Configuración. La opción **Emulate Touch From Mouse** también está habilitada en el proyecto.

Valores de referencia implementados:

| Parámetro | Valor |
| --- | --- |
| Radio del joystick | 96 px (radio efectivo aproximado; base de 192 px) |
| Zona muerta | 20 %, ajustable de 10 a 35 % |
| Tamaño de botones | 100 px, ajustable de 96 a 136 px |
| Opacidad | 55 %, ajustable de 40 a 70 % |
| Vibración | 55 ms al cosechar o recoger leche/huevo; se puede desactivar |
| Pantalla | Horizontal, `canvas_items` y aspecto `expand` |

El joystick y los botones consideran el área segura que reporta el sistema. Las opciones de tamaño, opacidad, zona muerta, vibración y modo de prueba se guardan en `user://settings.cfg`.

Este juego es de granja y no tiene salto, dash/ataque ni daño; por eso esos botones y el coyote time de plataformas no aplican. La interacción táctil reutiliza el buffer de interacción existente (0.22 s). La vibración de daño queda pendiente hasta que exista un evento de daño en el juego.

El dashboard web (`index.html`) sigue siendo una página de navegador conectada a Supabase mediante HTTPS y su CDN; no es una vista nativa dentro del juego. En móvil se consulta desde un navegador con acceso a internet. Este cambio no modifica el esquema ni las funciones de Supabase, el guardado/recorrido, el leaderboard ni el dashboard.

La validación disponible en esta entrega es la carga/parseo headless del proyecto. No se ha probado en un dispositivo físico o emulador ni se han grabado video, capturas o generado APK; esos entregables requieren ejecutar/exportar el proyecto desde un Android con la configuración de exportación correspondiente.
