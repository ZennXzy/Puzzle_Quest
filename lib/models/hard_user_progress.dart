import 'puzzle_piece.dart';

class HardUserProgress {
  final String email;
  final int currentLevel;
  final List<String> completedImageIds; // List of completed image IDs
  final Map<int, PuzzleState> savedStates; // Level -> Saved puzzle state
  final Map<int, int> bestTimes; // Level -> Best completion time in seconds
  final Map<String, bool> achievements; // Achievement name -> unlocked status

  const HardUserProgress({
    required this.email,
    this.currentLevel = 1,
    this.completedImageIds = const [],
    this.savedStates = const {},
    this.bestTimes = const {},
    this.achievements = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'currentLevel': currentLevel,
      'completedImageIds': completedImageIds,
      'savedStates': savedStates.map((k, v) => MapEntry(k.toString(), v.toJson())),
      'bestTimes': bestTimes.map((k, v) => MapEntry(k.toString(), v)),
      'achievements': achievements,
    };
  }

  factory HardUserProgress.fromJson(Map<String, dynamic> json) {
    return HardUserProgress(
      email: json['email'] as String,
      currentLevel: json['currentLevel'] as int? ?? 1,
      completedImageIds: List<String>.from(json['completedImageIds'] as List? ?? []),
      savedStates: (json['savedStates'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(int.parse(k), PuzzleState.fromJson(v as Map<String, dynamic>)),
      ),
      bestTimes: (json['bestTimes'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(int.parse(k), v as int),
      ),
      achievements: (json['achievements'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, v as bool),
      ),
    );
  }

  HardUserProgress copyWith({
    String? email,
    int? currentLevel,
    List<String>? completedImageIds,
    Map<int, PuzzleState>? savedStates,
    Map<int, int>? bestTimes,
    Map<String, bool>? achievements,
  }) {
    return HardUserProgress(
      email: email ?? this.email,
      currentLevel: currentLevel ?? this.currentLevel,
      completedImageIds: completedImageIds ?? this.completedImageIds,
      savedStates: savedStates ?? this.savedStates,
      bestTimes: bestTimes ?? this.bestTimes,
      achievements: achievements ?? this.achievements,
    );
  }

  // Helper methods
  List<int> get completedLevels => completedImageIds
      .where((id) => id.startsWith('sdg#'))
      .map((id) => int.tryParse(id.replaceFirst('sdg#', '').replaceFirst('.jpg', '')) ?? 0)
      .where((level) => level > 0)
      .toList();

  int getBestTime(int level) => bestTimes[level] ?? 0;

  // Achievement calculation methods
  Map<String, bool> getCalculatedAchievements() {
    final Map<String, bool> calculated = {};

    // Fastest Solve
    if (bestTimes.isNotEmpty) {
      final fastestLevel = bestTimes.entries.reduce((a, b) => a.value < b.value ? a : b).key;
      calculated['fastest_solve'] = true; // Always true if any best time exists
    }

    // Completion Milestones
    final completedCount = completedLevels.length;
    if (completedCount >= 5) calculated['complete_5'] = true;
    if (completedCount >= 10) calculated['complete_10'] = true;
    if (completedCount >= 17) calculated['complete_all'] = true;

    // Speed Achievements (harder thresholds for hard mode)
    int under3Min = 0, under2Min = 0, under1Min = 0;
    for (final time in bestTimes.values) {
      if (time < 180) under3Min++;
      if (time < 120) under2Min++;
      if (time < 60) under1Min++;
    }
    if (under3Min > 0) calculated['under_3_min'] = true;
    if (under2Min > 0) calculated['under_2_min'] = true;
    if (under1Min > 0) calculated['under_1_min'] = true;

    return calculated;
  }

  // Get fastest solve details
  MapEntry<int, int>? getFastestSolve() {
    if (bestTimes.isEmpty) return null;
    return bestTimes.entries.reduce((a, b) => a.value < b.value ? a : b);
  }

  // Get average best time
  double getAverageBestTime() {
    if (bestTimes.isEmpty) return 0.0;
    final total = bestTimes.values.reduce((a, b) => a + b);
    return total / bestTimes.length;
  }
}
