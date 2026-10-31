alter table public.game_saves
    add column if not exists player_name text
    generated always as (
        coalesce(nullif(btrim(state ->> 'name'), ''), 'Sin nombre')
    ) stored;

comment on column public.game_saves.player_name is
    'Display name copied from state.name for easier identification in the Supabase table editor.';
