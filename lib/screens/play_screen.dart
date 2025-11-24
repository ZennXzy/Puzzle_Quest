import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/puzzle_widget.dart';
import '../widgets/level_completion_overlay.dart';
import '../models/user_progress.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  UserProgress? _userProgress;
  String? _currentUser;
  int currentLevel = 1;
  int timeElapsed = 0; // Starting time in seconds
  Timer? _timer;
  Key puzzleKey = UniqueKey();
  bool _showCompletionOverlay = false;
  bool _isSavingProgress = false;

  @override
  void initState() {
    super.initState();
    _loadUserProgress();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt('current_user_id');
    final currentUser = prefs.getString('current_user');

    if (currentUser != null) {
      _currentUser = currentUser;

      // First try to load from local storage
      final progressJson = prefs.getString('user_progress_$currentUser');
      if (progressJson != null) {
        final progressData = jsonDecode(progressJson) as Map<String, dynamic>;
        final userProgress = UserProgress.fromJson(progressData);
        setState(() {
          _userProgress = userProgress;
          currentLevel = _getNextUnsolvedLevel();
        });
      } else {
        // Initialize with default progress
        final defaultProgress = UserProgress(
          email: currentUser,
          currentLevel: 1,
          completedLevels: [],
          savedStates: {},
          bestTimes: {},
        );
        setState(() {
          _userProgress = defaultProgress;
          currentLevel = 1;
        });
      }

      // Then try to sync with backend if user is logged in
      if (currentUserId != null) {
        try {
          const baseUrl = 'http://10.0.2.2:8000'; // For Android emulator, use 10.0.2.2 for localhost
          final response = await http.get(Uri.parse('$baseUrl/backend/load_progress.php?user_id=$currentUserId'));

          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            if (responseData['success'] == true) {
              final progressData = responseData['progress'] as Map<String, dynamic>;
              final userProgress = UserProgress.fromJson(progressData);
              // Update local progress with backend data if it's more advanced
              if (userProgress.currentLevel > (_userProgress?.currentLevel ?? 0) ||
                  userProgress.completedLevels.length > (_userProgress?.completedLevels.length ?? 0)) {
                setState(() {
                  _userProgress = userProgress;
                  currentLevel = _getNextUnsolvedLevel();
                });
                // Save the updated progress locally
                await prefs.setString('user_progress_$currentUser', jsonEncode(userProgress.toJson()));
              }
            }
          }
        } catch (e) {
          // Backend sync failed, but local progress is already loaded
          print('Backend sync failed: $e');
        }
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timeElapsed++;
      });
    });
  }

  void _resetLevel() {
    setState(() {
      // Reset functionality - placeholder for now
      // This will reset the puzzle when implemented
      _timer?.cancel();
      _startTimer();
    });
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help'),
          content: const Text('This is the help dialog for the puzzle game.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _nextLevel() {
    setState(() {
      currentLevel++;
      timeElapsed = 0;
      _timer?.cancel();
      _startTimer();
      puzzleKey = UniqueKey();
    });
  }

  String _getImagePath() {
    return 'assets/sdg_images/sdg#$currentLevel.jpg';
  }

  int _getNextUnsolvedLevel() {
    if (_userProgress == null) return currentLevel;

    // Find the next level that hasn't been completed
    for (int level = 1; level <= 17; level++) { // Assuming 17 SDG images
      if (!_userProgress!.isLevelCompleted(level)) {
        return level;
      }
    }

    // If all levels are completed, return the current level (or wrap around)
    return currentLevel;
  }

  void _onPuzzleComplete(bool completed) async {
    print('Puzzle complete callback: completed=$completed, _userProgress=${_userProgress != null}, _currentUser=${_currentUser != null}');
    if (completed) {
      print('Level $currentLevel completed! Starting save process...');
      _timer?.cancel();

      // Show completion overlay immediately
      setState(() {
        _showCompletionOverlay = true;
        _isSavingProgress = true;
      });

      // Save progress in background
      await _saveProgress();

      setState(() {
        _isSavingProgress = false;
      });
    }
  }

  Future<void> _saveProgress() async {
    print('Starting _saveProgress for level $currentLevel');

    // If user progress is not loaded yet, wait for it
    if (_userProgress == null || _currentUser == null) {
      print('Waiting for user progress to load...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (_userProgress == null || _currentUser == null) {
        print('User progress still not loaded, using default');
        _userProgress = UserProgress(
          email: _currentUser ?? 'guest',
          currentLevel: 1,
          completedLevels: [],
          savedStates: {},
          bestTimes: {},
        );
      }
    }

    // Update user progress
    final updatedProgress = _userProgress!.copyWith(
      currentLevel: currentLevel + 1,
      completedLevels: List.from(_userProgress!.completedLevels)..add(currentLevel),
      bestTimes: Map.from(_userProgress!.bestTimes)
        ..[currentLevel] = _userProgress!.bestTimes[currentLevel] == null || _userProgress!.bestTimes[currentLevel] == 0
            ? timeElapsed
            : (timeElapsed < _userProgress!.bestTimes[currentLevel]!
                ? timeElapsed
                : _userProgress!.bestTimes[currentLevel]!),
    );

    print('Updated progress: currentLevel=${updatedProgress.currentLevel}, completedLevels=${updatedProgress.completedLevels}');

    // Save to local storage first
    final prefs = await SharedPreferences.getInstance();
    final currentUser = prefs.getString('current_user') ?? _currentUser ?? '';
    final progressKey = 'user_progress_$currentUser';
    final success = await prefs.setString(progressKey, jsonEncode(updatedProgress.toJson()));

    if (success) {
      print('Local save successful for key: $progressKey');
    } else {
      print('Local save failed for key: $progressKey');
    }

    // Verify the save by reading it back
    final savedData = prefs.getString(progressKey);
    if (savedData != null) {
      try {
        final verifiedProgress = UserProgress.fromJson(jsonDecode(savedData));
        print('Local save verification successful: currentLevel=${verifiedProgress.currentLevel}');
      } catch (e) {
        print('Local save verification failed: $e');
      }
    } else {
      print('Local save verification failed: data is null');
    }

    // Also try to save to backend
    final currentUserId = prefs.getInt('current_user_id');
    if (currentUserId != null) {
      try {
        const baseUrl = 'http://10.0.2.2:8000'; // For Android emulator, use 10.0.2.2 for localhost
        final response = await http.post(
          Uri.parse('$baseUrl/backend/save_progress.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': currentUserId,
            'progress': updatedProgress.toJson(),
          }),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            print('Progress saved to backend successfully');
          } else {
            print('Backend save failed: ${responseData['error'] ?? 'Unknown error'}');
          }
        } else {
          print('Backend save failed with status: ${response.statusCode}, body: ${response.body}');
        }
      } catch (e) {
        print('Backend save error: $e');
      }
    } else {
      print('No user_id found, skipping backend save');
    }

    setState(() {
      _userProgress = updatedProgress;
    });

    print('_saveProgress completed');
  }

  void _onNextLevel() {
    setState(() {
      _showCompletionOverlay = false;
      currentLevel++;
      timeElapsed = 0;
      _timer?.cancel();
      _startTimer();
      puzzleKey = UniqueKey();
    });
  }

  void _onExitLevel() {
    setState(() {
      _showCompletionOverlay = false;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main game UI
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B1633), Color(0xFF6E4AA6), Color(0xFFCEB9E0)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // AppBar with back button, level, and reset button
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF000728),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white,
                          width: 2.0,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          // Back button (left)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: Colors.white.withOpacity(0.95),
                                  size: 28,
                                ),
                              ),
                            ),
                          ),

                          // Level text (center)
                          Expanded(
                            child: Text(
                              'Level $currentLevel',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          // Reset and Help buttons (right)
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Reset button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _resetLevel,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.refresh,
                                      color: Colors.white.withOpacity(0.95),
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                              // Help button
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _showHelp,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      Icons.help_outline,
                                      color: Colors.white.withOpacity(0.95),
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Timer row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        // Timer (left)
                        Text(
                          '${(timeElapsed ~/ 60).toString().padLeft(2, '0')}:${(timeElapsed % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Puzzle area
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      child: PuzzleWidget(
                        key: puzzleKey,
                        imagePath: _getImagePath(),
                        onPuzzleComplete: _onPuzzleComplete,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Completion overlay
          if (_showCompletionOverlay)
            LevelCompletionOverlay(
              level: currentLevel,
              timeElapsed: timeElapsed,
              isSaving: _isSavingProgress,
              onNextLevel: _onNextLevel,
              onExit: _onExitLevel,
            ),
        ],
      ),
    );
  }
}
