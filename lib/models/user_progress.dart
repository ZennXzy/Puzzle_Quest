class PuzzleState {
  final int level;
  final List<int> piecePositions; // List of current positions for each piece
  final int timeElapsed; // Time spent on this puzzle in seconds
  final bool isCompleted;

  const PuzzleState({
    required this.level,
    required this.piecePositions,
    required this.timeElapsed,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'piecePositions': piecePositions,
      'timeElapsed': timeElapsed,
      'isCompleted': isCompleted,
    };
  }

  factory PuzzleState.fromJson(Map<String, dynamic> json) {
    return PuzzleState(
      level: json['level'] as int,
      piecePositions: List<int>.from(json['piecePositions'] as List),
      timeElapsed: json['timeElapsed'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  PuzzleState copyWith({
    int? level,
    List<int>? piecePositions,
    int? timeElapsed,
    bool? isCompleted,
  }) {
    return PuzzleState(
      level: level ?? this.level,
      piecePositions: piecePositions ?? this.piecePositions,
      timeElapsed: timeElapsed ?? this.timeElapsed,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class UserProgress {
  final String email;
  final int currentLevel;
  final List<String> completedImageIds; // List of completed image IDs
  final Map<int, PuzzleState> savedStates; // Level -> PuzzleState
  final Map<int, int> bestTimes; // Level -> Best completion time in seconds

  const UserProgress({
    required this.email,
    this.currentLevel = 1,
    this.completedImageIds = const [],
    this.savedStates = const {},
    this.bestTimes = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'currentLevel': currentLevel,
      'completedImageIds': completedImageIds,
      'savedStates': savedStates.map((k, v) => MapEntry(k.toString(), v.toJson())),
      'bestTimes': bestTimes.map((k, v) => MapEntry(k.toString(), v)),
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      email: json['email'] as String,
      currentLevel: json['currentLevel'] as int? ?? 1,
      completedImageIds: List<String>.from(json['completedImageIds'] as List? ?? []),
      savedStates: (json['savedStates'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(int.parse(k), PuzzleState.fromJson(v as Map<String, dynamic>)),
      ),
      bestTimes: (json['bestTimes'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(int.parse(k), v as int),
      ),
    );
  }

  UserProgress copyWith({
    String? email,
    int? currentLevel,
    List<String>? completedImageIds,
    Map<int, PuzzleState>? savedStates,
    Map<int, int>? bestTimes,
  }) {
    return UserProgress(
      email: email ?? this.email,
      currentLevel: currentLevel ?? this.currentLevel,
      completedImageIds: completedImageIds ?? this.completedImageIds,
      savedStates: savedStates ?? this.savedStates,
      bestTimes: bestTimes ?? this.bestTimes,
    );
  }

  // Helper methods
  bool isImageCompleted(String imageId) => completedImageIds.contains(imageId);

  bool isLevelCompleted(int level) => isImageCompleted('sdg#$level.jpg');

  List<int> get completedLevels => completedImageIds
      .where((id) => id.startsWith('sdg#'))
      .map((id) => int.tryParse(id.replaceFirst('sdg#', '').replaceFirst('.jpg', '')) ?? 0)
      .where((level) => level > 0)
      .toList();

  int getBestTime(int level) => bestTimes[level] ?? 0;

  PuzzleState? getSavedState(int level) => savedStates[level];
}
