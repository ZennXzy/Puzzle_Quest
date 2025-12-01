import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../widgets/puzzle_widget.dart';
import '../widgets/puzzle_preview_widget.dart';
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
  bool _isLoadingProgress = true;
  String? _triviaFact;

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
    final currentUser = prefs.getString('current_user');

    if (currentUser != null) {
      _currentUser = currentUser;

      // First try to load from backend
      try {
        final response = await http.post(
          Uri.parse('http://localhost/puzzle_quest/backend/load_progress.php'),
          body: {'email': currentUser},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            final userProgress = UserProgress.fromJson(data['progress']);
            setState(() {
              _userProgress = userProgress;
              currentLevel = userProgress.currentLevel;
              _isLoadingProgress = false;
            });
            return;
          }
        }
      } catch (e) {
        print('Error loading from backend: $e');
      }

      // Fallback to local storage
      final progressJson = prefs.getString('user_progress_$currentUser');
      if (progressJson != null) {
        final progressData = jsonDecode(progressJson) as Map<String, dynamic>;
        final userProgress = UserProgress.fromJson(progressData);
        setState(() {
          _userProgress = userProgress;
          currentLevel = userProgress.currentLevel;
          _isLoadingProgress = false;
        });
      } else {
        // Initialize with default progress
        final defaultProgress = UserProgress(
          email: currentUser,
          currentLevel: 1,
          completedImageIds: [],
          bestTimes: {},
        );
        setState(() {
          _userProgress = defaultProgress;
          currentLevel = 1;
          _isLoadingProgress = false;
        });
      }
    } else {
      setState(() {
        _isLoadingProgress = false;
      });
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
      timeElapsed = 0;
      _timer?.cancel();
      _startTimer();
      puzzleKey = UniqueKey();
    });
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PuzzlePreviewWidget(
                imagePath: _getImagePath(),
                gridSize: 3,
              ),
              const SizedBox(height: 16),
              const Text('Slide the puzzle pieces to arrange them in the correct order and complete the image.'),
            ],
          ),
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



  String _getImagePath() {
    return 'assets/sdg_images/sdg#$currentLevel.jpg';
  }

  void _onPuzzleComplete(bool completed) async {
    print('Puzzle complete callback: completed=$completed, _userProgress=${_userProgress != null}, _currentUser=${_currentUser != null}');
    if (completed) {
      print('Level $currentLevel completed! Starting save process...');
      _timer?.cancel();

      // Fetch trivia
      await _fetchTrivia();

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
    // If user progress is not loaded yet, wait for it
    if (_userProgress == null || _currentUser == null) {
      print('Waiting for user progress to load...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (_userProgress == null || _currentUser == null) {
        print('User progress still not loaded, using default');
        _userProgress = UserProgress(
          email: _currentUser ?? 'guest',
          currentLevel: 1,
          completedImageIds: [],
          savedStates: {},
          bestTimes: {},
        );
      }
    }

    // Update user progress
    final updatedProgress = _userProgress!.copyWith(
      currentLevel: currentLevel + 1,
      completedImageIds: List.from(_userProgress!.completedImageIds)..add(_getImagePath()),
      bestTimes: Map.from(_userProgress!.bestTimes)
        ..[currentLevel] = (_userProgress!.bestTimes[currentLevel] ?? 0) == 0
            ? timeElapsed
            : (timeElapsed < (_userProgress!.bestTimes[currentLevel] ?? 0)
                ? timeElapsed
                : (_userProgress!.bestTimes[currentLevel] ?? 0)),
    );

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    final currentUser = prefs.getString('current_user') ?? _currentUser ?? '';
    await prefs.setString('user_progress_$currentUser', jsonEncode(updatedProgress.toJson()));

    setState(() {
      _userProgress = updatedProgress;
    });
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

  Future<void> _fetchTrivia() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost/puzzle_quest/backend/sdg_trivia.php'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _triviaFact = data['fact'];
          });
        } else {
          setState(() {
            _triviaFact = 'Did you know? Puzzles improve cognitive skills!';
          });
        }
      } else {
        setState(() {
          _triviaFact = 'Did you know? Puzzles improve cognitive skills!';
        });
      }
    } catch (e) {
      setState(() {
        _triviaFact = 'Did you know? Puzzles improve cognitive skills!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProgress) {
      return Scaffold(
        body: Container(
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
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

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

                          // Reset button (right)
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
                        ],
                      ),
                    ),
                  ),

                  // Timer row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        // Help button (right)
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
              triviaFact: _triviaFact,
              onNextLevel: _onNextLevel,
              onExit: _onExitLevel,
            ),
        ],
      ),
    );
  }
}
