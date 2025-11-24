<?php
// Save progress endpoint
require_once __DIR__ . '/db.php';

$mysqli = include __DIR__ . '/db.php';

// Get POST data
$input = json_decode(file_get_contents('php://input'), true);

$user_id = $input['user_id'] ?? null;
$progress = $input['progress'] ?? null;

if (!$user_id || !$progress) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'User ID and progress data are required']);
    exit;
}

// Prepare data for database
$current_level = $progress['currentLevel'] ?? 1;
$completed_levels = json_encode($progress['completedLevels'] ?? []);
$saved_states = json_encode($progress['savedStates'] ?? []);
$best_times = json_encode($progress['bestTimes'] ?? []);

// Insert or update progress
$stmt = $mysqli->prepare('INSERT INTO user_progress (user_id, current_level, completed_levels, saved_states, best_times) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE current_level = VALUES(current_level), completed_levels = VALUES(completed_levels), saved_states = VALUES(saved_states), best_times = VALUES(best_times)');
$stmt->bind_param('iisss', $user_id, $current_level, $completed_levels, $saved_states, $best_times);

if ($stmt->execute()) {
    echo json_encode(['success' => true]);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Failed to save progress']);
}

$stmt->close();
$mysqli->close();
?>
