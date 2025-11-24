import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/puzzle_widget.dart';
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
    if (currentUserId != null) {
      try {
        const baseUrl = 'http://10.0.2.2:8000'; // For Android emulator, use 10.0.2.2 for localhost
        final response = await http.get(Uri.parse('$baseUrl/backend/load_progress.php?user_id=$currentUserId'));

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['success'] == true) {
            final progressData = responseData['progress'] as Map<String, dynamic>;
            final userProgress = UserProgress.fromJson(progressData);
            setState(() {
              _userProgress = userProgress;
              currentLevel = userProgress.currentLevel;
            });
          } else {
            // No progress found, initialize with default
            setState(() {
              currentLevel = 1;
            });
          }
        } else {
          // Fallback to local storage if backend fails
          final currentUser = prefs.getString('current_user');
          if (currentUser != null) {
            final progressJson = prefs.getString('user_progress_$currentUser');
            if (progressJson != null) {
              final progressData = jsonDecode(progressJson) as Map<String, dynamic>;
              final userProgress = UserProgress.fromJson(progressData);
              setState(() {
                _userProgress = userProgress;
                _currentUser = currentUser;
                currentLevel = userProgress.currentLevel;
              });
            } else {
              setState(() {
                _currentUser = currentUser;
                currentLevel = 1;
              });
            }
          }
        }
      } catch (e) {
        // Fallback to local storage
        final currentUser = prefs.getString('current_user');
        if (currentUser != null) {
          final progressJson = prefs.getString('user_progress_$currentUser');
          if (progressJson != null) {
            final progressData = jsonDecode(progressJson) as Map<String, dynamic>;
            final userProgress = UserProgress.fromJson(progressData);
            setState(() {
              _userProgress = userProgress;
              _currentUser = currentUser;
              currentLevel = userProgress.currentLevel;
            });
          } else {
            setState(() {
              _currentUser = currentUser;
              currentLevel = 1;
            });
          }
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

  void _onPuzzleComplete(bool completed) async {
    print('Puzzle complete callback: completed=$completed, _userProgress=${_userProgress != null}, _currentUser=${_currentUser != null}');
    if (completed) {
      _timer?.cancel();

      // If user progress is not loaded yet, wait for it
      if (_userProgress == null || _currentUser == null) {
        print('Waiting for user progress to load...');
        // Wait a bit and try again, or show a loading state
        await Future.delayed(const Duration(milliseconds: 500));
        if (_userProgress == null || _currentUser == null) {
          // Still not loaded, show error or retry
          print('User progress still not loaded, showing basic completion dialog');
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Congratulations!'),
                content: Text(
                  'You completed the puzzle in ${(timeElapsed ~/ 60).toString().padLeft(2, '0')}:${(timeElapsed % 60).toString().padLeft(2, '0')}!',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _nextLevel();
                    },
                    child: const Text('Next Level'),
                  ),
                ],
              );
            },
          );
          return;
        }
      }

      // Update user progress
      final updatedProgress = _userProgress!.copyWith(
        currentLevel: currentLevel + 1,
        completedLevels: List.from(_userProgress!.completedLevels)..add(currentLevel),
        bestTimes: Map.from(_userProgress!.bestTimes)
          ..[currentLevel] = _userProgress!.bestTimes[currentLevel] == 0
              ? timeElapsed
              : (timeElapsed < _userProgress!.bestTimes[currentLevel]!
                  ? timeElapsed
                  : _userProgress!.bestTimes[currentLevel]!),
      );

      // Save to backend
      final prefs = await SharedPreferences.getInstance();
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

          if (response.statusCode != 200) {
            // Fallback to local storage if backend fails
            await prefs.setString('user_progress_$_currentUser', jsonEncode(updatedProgress.toJson()));
          }
        } catch (e) {
          // Fallback to local storage
          await prefs.setString('user_progress_$_currentUser', jsonEncode(updatedProgress.toJson()));
        }
      } else {
        // Fallback to local storage
        await prefs.setString('user_progress_$_currentUser', jsonEncode(updatedProgress.toJson()));
      }

      setState(() {
        _userProgress = updatedProgress;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Congratulations!'),
            content: Text(
              'You completed the puzzle in ${(timeElapsed ~/ 60).toString().padLeft(2, '0')}:${(timeElapsed % 60).toString().padLeft(2, '0')}!',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _nextLevel();
                },
                child: const Text('Next Level'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: Column(
            children: [
              // AppBar with back button, level, and reset button
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF000728),
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
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white.withOpacity(0.95),
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
