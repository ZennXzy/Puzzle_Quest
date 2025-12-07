<?php
// Load progress endpoint - loads from Firebase Firestore via REST API
require_once __DIR__ . '/db.php';

$mysqli = include __DIR__ . '/db.php';

$user_id = $_GET['user_id'] ?? null;
$id_token = $_GET['id_token'] ?? null; // Firebase ID token for authentication

if (!$user_id || !$id_token) {
    http_response_code(400);
    echo json_encode(['success' => false, 'error' => 'User ID and ID token are required']);
    exit;
}

// Firebase Firestore REST API URL
$url = "https://firestore.googleapis.com/v1/projects/puzzle-quest-c5c7e/databases/(default)/documents/user_progress/$user_id";

// Prepare cURL request
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $id_token
]);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($http_code >= 200 && $http_code < 300) {
    // Parse Firebase response
    $firebase_data = json_decode($response, true);
    if (isset($firebase_data['fields'])) {
        $fields = $firebase_data['fields'];

        // Helper function to extract values from Firebase format
        function extractValue($field) {
            if (isset($field['stringValue'])) return $field['stringValue'];
            if (isset($field['integerValue'])) return (int)$field['integerValue'];
            if (isset($field['booleanValue'])) return $field['booleanValue'];
            if (isset($field['arrayValue']['values'])) {
                return array_map(function($item) {
                    return $item['stringValue'] ?? null;
                }, $field['arrayValue']['values']);
            }
            if (isset($field['mapValue']['fields'])) {
                $map = [];
                foreach ($field['mapValue']['fields'] as $key => $value) {
                    if (isset($value['stringValue'])) {
                        $map[$key] = json_decode($value['stringValue'], true) ?? $value['stringValue'];
                    } elseif (isset($value['integerValue'])) {
                        $map[$key] = (int)$value['integerValue'];
                    } elseif (isset($value['booleanValue'])) {
                        $map[$key] = $value['booleanValue'];
                    }
                }
                return $map;
            }
            return null;
        }

        $progress = [
            'email' => extractValue($fields['email'] ?? []),
            'currentLevel' => extractValue($fields['currentLevel'] ?? ['integerValue' => 1]),
            'completedImageIds' => extractValue($fields['completedImageIds'] ?? ['arrayValue' => ['values' => []]]),
            'savedStates' => extractValue($fields['savedStates'] ?? ['mapValue' => ['fields' => []]]),
            'bestTimes' => extractValue($fields['bestTimes'] ?? ['mapValue' => ['fields' => []]]),
            'achievements' => extractValue($fields['achievements'] ?? ['mapValue' => ['fields' => []]]),
        ];

        echo json_encode(['success' => true, 'progress' => $progress]);
    } else {
        // No document found in Firebase, try local database as fallback
        goto local_fallback;
    }
} else {
    // Firebase request failed, fallback to local database
    local_fallback:
    $stmt = $mysqli->prepare('SELECT current_level, completed_levels, saved_states, best_times, achievements FROM user_progress WHERE user_id = ? LIMIT 1');
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
                'completedImageIds' => json_decode($progress['completed_levels'], true),
                'savedStates' => json_decode($progress['saved_states'], true),
                'bestTimes' => json_decode($progress['best_times'], true),
                'achievements' => json_decode($progress['achievements'], true) ?? [],
            ]
        ]);
    } else {
        // No progress found anywhere, return default
        echo json_encode([
            'success' => true,
            'progress' => [
                'email' => '',
                'currentLevel' => 1,
                'completedImageIds' => [],
                'savedStates' => [],
                'bestTimes' => [],
                'achievements' => [],
            ]
        ]);
    }
}

$mysqli->close();
?>
