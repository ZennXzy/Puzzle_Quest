import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/puzzle_widget.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  int currentLevel = 1;
  int timeElapsed = 0; // Starting time in seconds
  Timer? _timer;
  Key puzzleKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  void _onPuzzleComplete(bool completed) {
    if (completed) {
      _timer?.cancel();
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
