-- Guardados recuperables mediante un ID secreto de 128 bits generado por el juego.
create table if not exists public.shared_game_saves (
    game_id text primary key check (game_id ~ '^[0-9a-f]{32}$'),
    state jsonb not null check (jsonb_typeof(state) = 'object'),
    created_by uuid references auth.users (id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    player_name text generated always as (
        coalesce(nullif(btrim(state ->> 'name'), ''), 'Sin nombre')
    ) stored
);

comment on table public.shared_game_saves is
    'Partidas compartidas y recuperables por game_id; el ID funciona como credencial de acceso.';
comment on column public.shared_game_saves.game_id is
    'ID aleatorio de 32 caracteres hexadecimales; necesario para recuperar, modificar o borrar la partida.';

alter table public.shared_game_saves enable row level security;
revoke all on public.shared_game_saves from public, anon, authenticated;
grant all on public.shared_game_saves to service_role;
