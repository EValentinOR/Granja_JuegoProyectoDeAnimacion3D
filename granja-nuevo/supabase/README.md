# Recuperación de partidas por ID

El juego guarda las ranuras localmente y sincroniza cada partida con Supabase usando un ID aleatorio de 32 caracteres hexadecimales. En otro equipo, la persona escribe ese ID en el menú para recuperar la partida. El ID funciona como llave: quien lo conozca puede cargar y guardar cambios en esa partida. El botón Borrar del juego elimina solo la copia local; para borrar la copia remota hay que hacerlo desde el Dashboard de Supabase.

## Preparar Supabase

1. Activa **Authentication → Sign In / Providers → Anonymous Sign-Ins**.
2. En tu proyecto actual, abre **SQL Editor** y ejecuta el contenido de `migrations/20261023000000_shared_game_saves.sql`. No vuelvas a ejecutar las dos migraciones anteriores si ya instalaste la sincronización vieja. Para configurar un proyecto nuevo desde cero, ejecuta primero las migraciones `20261016000000` y `20261022000000`, y después la `20261023000000`.
3. Despliega la función desde esta carpeta:

   ```powershell
   supabase login
   supabase link --project-ref TU_PROJECT_REF
   supabase functions deploy game-saves
   ```

4. En `scripts/global.gd`, confirma que `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` y `DATABASE_ENDPOINT` corresponden al proyecto. La clave publishable puede estar en el juego; nunca pongas una clave `service_role` o `sb_secret_` en el cliente.

La función requiere un JWT anónimo válido y usa `SUPABASE_SERVICE_ROLE_KEY` únicamente en el servidor. La tabla `shared_game_saves` no permite lecturas directas a `anon` ni `authenticated`; la función valida el ID y realiza las consultas con la clave de servidor.

## Operaciones

- `POST ?action=load_by_id` recibe `{ "game_id": "..." }` y devuelve el estado de esa partida.
- `POST ?action=save` recibe `{ "game_id": "...", "state": { ... } }`. La clave primaria de `game_id` hace que guardar de nuevo actualice esa misma fila.
La función no expone una operación de borrado remoto. Para eliminar una fila remota, usa el Table Editor o SQL Editor del Dashboard de Supabase.

El estado completo, incluido `player_route`, se guarda como JSONB. Los guardados de la versión anterior que estén únicamente en `game_saves` no aparecen automáticamente en el menú nuevo; el juego ya no enumera las partidas remotas y solo recupera una cuando se ingresa su ID.
