-- PostgreSQL 14+. Cada identificador de jugador puede guardar como máximo 3 slots.
CREATE TABLE IF NOT EXISTS granja_partidas (
    player_id CHAR(32) NOT NULL CHECK (player_id ~ '^[0-9a-f]{32}$'),
    slot SMALLINT NOT NULL CHECK (slot BETWEEN 0 AND 2),
    player_name VARCHAR(24) NOT NULL DEFAULT 'Granjero',
    state JSONB NOT NULL,
    updated_at BIGINT NOT NULL,
    PRIMARY KEY (player_id, slot)
);

CREATE INDEX IF NOT EXISTS granja_partidas_updated_idx
    ON granja_partidas (player_id, updated_at DESC);
