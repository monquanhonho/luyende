<?php
require_once __DIR__ . '/config/db.php';

header('Content-Type: application/json; charset=utf-8');

if (!isLoggedIn()) {
    http_response_code(401);
    echo json_encode(['ok' => false, 'error' => 'Unauthorized']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['ok' => false, 'error' => 'Method not allowed']);
    exit;
}

$raw = file_get_contents('php://input');
$data = json_decode($raw, true);
if (!is_array($data)) {
    $data = $_POST;
}

$sessionId = (int)($data['session_id'] ?? 0);
$elapsedSeconds = max(0, (int)($data['elapsed_seconds'] ?? 0));
$answeredCount = max(0, (int)($data['answered_count'] ?? 0));
$tabSwitchCount = max(0, (int)($data['tab_switch_count'] ?? 0));

if ($sessionId > 0) {
    $stmt = $pdo->prepare("
        UPDATE exam_sessions
        SET last_heartbeat = NOW(),
            elapsed_seconds = GREATEST(elapsed_seconds, ?),
            answered_count = ?,
            tab_switch_count = GREATEST(tab_switch_count, ?)
        WHERE id = ? AND user_id = ? AND status = 'in_progress'
    ");
    $stmt->execute([
        $elapsedSeconds,
        $answeredCount,
        $tabSwitchCount,
        $sessionId,
        currentUser()['id']
    ]);
}

echo json_encode(['ok' => true]);
