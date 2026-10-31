<?php
declare(strict_types=1);

// Configura GRANJA_PG_DSN, GRANJA_PG_USER y GRANJA_PG_PASSWORD en el servidor.
// Mantén PostgreSQL detrás del API; nunca pongas credenciales de la base en el juego.
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$playerId = $_GET['player_id'] ?? '';
if (!preg_match('/^[0-9a-f]{32}$/', $playerId)) {
    http_response_code(400);
    echo json_encode(['error' => 'player_id inválido']);
    exit;
}

try {
    $pdo = new PDO(
        getenv('GRANJA_PG_DSN') ?: '',
        getenv('GRANJA_PG_USER') ?: '',
        getenv('GRANJA_PG_PASSWORD') ?: '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    if ($_SERVER['REQUEST_METHOD'] === 'GET' && ($_GET['action'] ?? '') === 'load') {
        $query = $pdo->prepare('SELECT slot, state FROM granja_partidas WHERE player_id = :player_id ORDER BY slot');
        $query->execute(['player_id' => $playerId]);
        $slots = array_fill(0, 3, (object)[]);
        foreach ($query->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $slots[(int)$row['slot']] = json_decode($row['state']);
        }
        echo json_encode($slots, JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST' && ($_GET['action'] ?? '') === 'save') {
        $payload = json_decode(file_get_contents('php://input'), true, 512, JSON_THROW_ON_ERROR);
        $slot = filter_var($payload['slot'] ?? null, FILTER_VALIDATE_INT);
        $state = $payload['state'] ?? null;
        if ($slot === false || $slot < 0 || $slot > 2 || !is_array($state)) {
            http_response_code(400);
            echo json_encode(['error' => 'slot o state inválido']);
            exit;
        }
        $name = mb_substr((string)($state['name'] ?? 'Granjero'), 0, 24);
        $updatedAt = (int)($state['updated_at'] ?? time());
        $statement = $pdo->prepare(
            'INSERT INTO granja_partidas (player_id, slot, player_name, state, updated_at)
             VALUES (:player_id, :slot, :player_name, CAST(:state AS JSONB), :updated_at)
             ON CONFLICT (player_id, slot) DO UPDATE SET
                player_name = EXCLUDED.player_name,
                state = EXCLUDED.state,
                updated_at = EXCLUDED.updated_at'
        );
        $statement->execute([
            'player_id' => $playerId,
            'slot' => $slot,
            'player_name' => $name,
            'state' => json_encode($state, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR),
            'updated_at' => $updatedAt,
        ]);
        echo json_encode(['saved' => true, 'slot' => $slot]);
        exit;
    }

    http_response_code(404);
    echo json_encode(['error' => 'acción no encontrada']);
} catch (Throwable $error) {
    http_response_code(500);
    echo json_encode(['error' => 'error interno del servicio']);
}
