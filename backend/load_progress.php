<?php
// Load progress endpoint
require_once __DIR__ . '/db.php';

$mysqli = include __DIR__ . '/db.php';

$user_id = $_GET['user_id'] ?? null;

if (!$user_id) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'User ID is required']);
    exit;
}

$stmt = $mysqli->prepare('SELECT current_level, completed_levels, saved_states, best_times FROM user_progress WHERE user_id = ? LIMIT 1');
$stmt->bind_param('i', $user_id);
$stmt->execute();
$res = $stmt->get_result();
$progress = $res->fetch_assoc();
$stmt->close();

if ($progress) {
    echo json_encode([
        'success' => true,
        'progress' => [
            'email' => '', // Not needed here, but for compatibility
            'currentLevel' => (int)$progress['current_level'],
            'completedLevels' => json_decode($progress['completed_levels'], true),
            'savedStates' => json_decode($progress['saved_states'], true),
            'bestTimes' => json_decode($progress['best_times'], true),
        ]
    ]);
} else {
    // No progress found, return default
    echo json_encode([
        'success' => true,
        'progress' => [
            'email' => '',
            'currentLevel' => 1,
            'completedLevels' => [],
            'savedStates' => [],
            'bestTimes' => [],
        ]
    ]);
}

$mysqli->close();
?>
