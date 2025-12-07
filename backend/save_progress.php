<?php
// Save progress endpoint - saves to Firebase Firestore via REST API
require_once __DIR__ . '/db.php';

$mysqli = include __DIR__ . '/db.php';

// Get POST data
$input = json_decode(file_get_contents('php://input'), true);

$user_id = $input['user_id'] ?? null;
$progress = $input['progress'] ?? null;
$id_token = $input['id_token'] ?? null; // Firebase ID token for authentication

if (!$user_id || !$progress || !$id_token) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'User ID, progress data, and ID token are required']);
    exit;
}

// Prepare data for Firebase
$firestore_data = [
    'fields' => [
        'email' => ['stringValue' => $progress['email'] ?? ''],
        'currentLevel' => ['integerValue' => $progress['currentLevel'] ?? 1],
        'completedImageIds' => ['arrayValue' => ['values' => array_map(function($id) {
            return ['stringValue' => $id];
        }, $progress['completedImageIds'] ?? [])]],
        'savedStates' => ['mapValue' => ['fields' => array_map(function($k, $v) {
            return [$k => ['stringValue' => json_encode($v)]];
        }, array_keys($progress['savedStates'] ?? []), array_values($progress['savedStates'] ?? []))]],
        'bestTimes' => ['mapValue' => ['fields' => array_map(function($k, $v) {
            return [$k => ['integerValue' => $v]];
        }, array_keys($progress['bestTimes'] ?? []), array_values($progress['bestTimes'] ?? []))]],
        'achievements' => ['mapValue' => ['fields' => array_map(function($k, $v) {
            return [$k => ['booleanValue' => $v]];
        }, array_keys($progress['achievements'] ?? []), array_values($progress['achievements'] ?? []))]],
        'updated_at' => ['timestampValue' => date('c')]
    ]
];

// Firebase Firestore REST API URL
$url = "https://firestore.googleapis.com/v1/projects/puzzle-quest-c5c7e/databases/(default)/documents/user_progress/$user_id";

// Prepare cURL request
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PATCH');
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($firestore_data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Authorization: Bearer ' . $id_token
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($http_code >= 200 && $http_code < 300) {
    // Also save to local database as backup
    $current_level = $progress['currentLevel'] ?? 1;
    $completed_levels = json_encode($progress['completedImageIds'] ?? []);
    $saved_states = json_encode($progress['savedStates'] ?? []);
    $best_times = json_encode($progress['bestTimes'] ?? []);
    $achievements = json_encode($progress['achievements'] ?? []);

    $stmt = $mysqli->prepare('INSERT INTO user_progress (user_id, current_level, completed_levels, saved_states, best_times, achievements) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE current_level = VALUES(current_level), completed_levels = VALUES(completed_levels), saved_states = VALUES(saved_states), best_times = VALUES(best_times), achievements = VALUES(achievements)');
    $stmt->bind_param('iissss', $user_id, $current_level, $completed_levels, $saved_states, $best_times, $achievements);
    $stmt->execute();
    $stmt->close();

    echo json_encode(['success' => true]);
} else {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Failed to save progress to Firebase: ' . $response]);
}

$mysqli->close();
?>
