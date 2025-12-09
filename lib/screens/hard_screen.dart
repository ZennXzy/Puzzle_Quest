import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/puzzle_widget_4x4.dart';
import '../widgets/puzzle_preview_widget.dart';
import '../widgets/level_completion_overlay.dart';
import '../models/user_progress.dart';
import '../services/progress_service.dart';

class HardScreen extends StatefulWidget {
  const HardScreen({super.key});

  @override
  State<HardScreen> createState() => _HardScreenState();
}

class _HardScreenState extends State<HardScreen> {
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
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (currentUser != null) {
      _currentUser = currentUser;

      // First try to load from Firebase
      try {
        final progressService = ProgressService();
        final userProgress = await progressService.loadProgress();
        if (userProgress != null) {
          setState(() {
            _userProgress = userProgress;
            currentLevel = userProgress.currentLevel;
            _isLoadingProgress = false;
          });
          return;
        }
      } catch (e) {
        print('Error loading from Firebase: $e');
      }

      // Fallback to local storage
      final localKey = user != null ? 'user_progress_${user.uid}' : 'user_progress_$currentUser';
      final progressJson = prefs.getString(localKey);
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
                gridSize: 4,
              ),
              const SizedBox(height: 16),
              const Text('This is a HARD puzzle! Slide the pieces to arrange them in the correct order and complete the image.'),
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
          achievements: {},
        );
      }
    }

    // Update user progress with calculated achievements
    final updatedProgress = _userProgress!.copyWith(
      currentLevel: currentLevel + 1,
      completedImageIds: List.from(_userProgress!.completedImageIds)..add(_getImagePath()),
      bestTimes: Map.from(_userProgress!.bestTimes)
        ..[currentLevel] = (_userProgress!.bestTimes[currentLevel] ?? 0) == 0
            ? timeElapsed
            : (timeElapsed < (_userProgress!.bestTimes[currentLevel] ?? 0)
                ? timeElapsed
                : (_userProgress!.bestTimes[currentLevel] ?? 0)),
      achievements: _userProgress!.getCalculatedAchievements(),
    );

    // Save to Firebase
    try {
      final progressService = ProgressService();
      await progressService.saveProgress(updatedProgress);
    } catch (e) {
      print('Error saving to Firebase: $e');
    }

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

  // Local SDG trivia data (matching the database structure)
  final Map<int, List<String>> _sdgTrivia = {
    1: [
      'SDG 1 aims to eradicate extreme poverty for all people everywhere, currently measured as people living on less than \$1.25 a day.',
      'By 2030, SDG 1 targets to reduce at least by half the proportion of men, women and children of all ages living in poverty.',
      'Social protection systems are crucial for SDG 1, helping to reduce poverty and inequality.',
      'In 2015, about 736 million people lived in extreme poverty, down from 1.9 billion in 1990.',
      'SDG 1 includes targets for equal rights to economic resources and access to basic services for the poor.',
    ],
    2: [
      'SDG 2 aims to end hunger, achieve food security and improved nutrition, and promote sustainable agriculture.',
      'By 2030, SDG 2 targets to end all forms of malnutrition and address the nutritional needs of adolescent girls.',
      'Sustainable agriculture is key to SDG 2, doubling the productivity and incomes of small-scale food producers.',
      'About 821 million people were undernourished in 2017, representing 10.9% of the world population.',
      'SDG 2 includes maintaining genetic diversity of seeds and cultivated plants for food security.',
    ],
    3: [
      'SDG 3 aims to ensure healthy lives and promote well-being for all at all ages.',
      'By 2030, SDG 3 targets to reduce the global maternal mortality ratio to less than 70 per 100,000 live births.',
      'Universal health coverage is a key target of SDG 3, ensuring access to quality health services.',
      'In 2016, the world lost 15 million lives due to non-communicable diseases before age 70.',
      'SDG 3 includes ending the epidemics of AIDS, tuberculosis, malaria, and neglected tropical diseases.',
    ],
    4: [
      'SDG 4 aims to ensure inclusive and equitable quality education and promote lifelong learning opportunities.',
      'By 2030, SDG 4 targets to ensure all girls and boys complete free, equitable and quality primary and secondary education.',
      'Technical and vocational skills are emphasized in SDG 4 for employment and decent work.',
      'In 2017, 617 million children and adolescents worldwide were not achieving minimum proficiency levels in reading and mathematics.',
      'SDG 4 includes increasing the supply of qualified teachers in developing countries.',
    ],
    5: [
      'SDG 5 aims to achieve gender equality and empower all women and girls.',
      'By 2030, SDG 5 targets to eliminate all forms of violence against all women and girls in public and private spheres.',
      'Women\'s participation in decision-making is crucial for SDG 5, aiming for equal opportunities.',
      'Women spend about three times as many hours in unpaid domestic and care work as men.',
      'SDG 5 includes universal access to sexual and reproductive health and reproductive rights.',
    ],
    6: [
      'SDG 6 aims to ensure availability and sustainable management of water and sanitation for all.',
      'By 2030, SDG 6 targets to achieve universal and equitable access to safe and affordable drinking water.',
      'Water quality is addressed in SDG 6, including reducing pollution and increasing recycling.',
      'In 2015, 2.1 billion people lacked safely managed drinking water services.',
      'SDG 6 includes protecting and restoring water-related ecosystems.',
    ],
    7: [
      'SDG 7 aims to ensure access to affordable, reliable, sustainable and modern energy for all.',
      'By 2030, SDG 7 targets to increase substantially the share of renewable energy in the global energy mix.',
      'Energy efficiency is key to SDG 7, doubling the global rate of improvement in energy efficiency.',
      'In 2016, about 840 million people still lacked access to electricity.',
      'SDG 7 includes international cooperation to facilitate access to clean energy research and technology.',
    ],
    8: [
      'SDG 8 aims to promote sustained, inclusive and sustainable economic growth, full and productive employment.',
      'By 2030, SDG 8 targets to achieve full and productive employment and decent work for all women and men.',
      'Youth unemployment is addressed in SDG 8, promoting entrepreneurship and job creation.',
      'In 2017, about 172 million people worldwide were unemployed.',
      'SDG 8 includes protecting labor rights and promoting safe working environments.',
    ],
    9: [
      'SDG 9 aims to build resilient infrastructure, promote inclusive and sustainable industrialization.',
      'By 2030, SDG 9 targets to develop quality, reliable, sustainable and resilient infrastructure.',
      'Innovation is central to SDG 9, increasing the number of research and development workers per million people.',
      'Infrastructure investment needs are estimated at \$3.7 trillion per year globally.',
      'SDG 9 includes supporting domestic technology development and industrial diversification.',
    ],
    10: [
      'SDG 10 aims to reduce inequality within and among countries.',
      'By 2030, SDG 10 targets to progressively achieve and sustain income growth of the bottom 40% of the population.',
      'Social protection systems are emphasized in SDG 10 to reduce inequality.',
      'The richest 1% of the population owns more wealth than the bottom 50% combined.',
      'SDG 10 includes facilitating orderly, safe, regular and responsible migration.',
    ],
    11: [
      'SDG 11 aims to make cities and human settlements inclusive, safe, resilient and sustainable.',
      'By 2030, SDG 11 targets to ensure access for all to adequate, safe and affordable housing.',
      'Urban planning is key to SDG 11, reducing the adverse per capita environmental impact of cities.',
      'By 2050, 68% of the world population is projected to live in urban areas.',
      'SDG 11 includes protecting and safeguarding cultural and natural heritage.',
    ],
    12: [
      'SDG 12 aims to ensure sustainable consumption and production patterns.',
      'By 2030, SDG 12 targets to achieve the sustainable management and efficient use of natural resources.',
      'Food waste reduction is addressed in SDG 12, halving per capita global food waste.',
      'Each year, an estimated one-third of all food produced for human consumption is lost or wasted.',
      'SDG 12 includes environmentally sound management of chemicals and wastes.',
    ],
    13: [
      'SDG 13 aims to take urgent action to combat climate change and its impacts.',
      'The Paris Agreement is central to SDG 13, strengthening resilience to climate-related hazards.',
      'By 2030, SDG 13 targets to integrate climate change measures into national policies.',
      'Climate change is causing long-term shifts in weather patterns and increasing extreme weather events.',
      'SDG 13 includes improving education and awareness-raising on climate change.',
    ],
    14: [
      'SDG 14 aims to conserve and sustainably use the oceans, seas and marine resources.',
      'By 2030, SDG 14 targets to prevent and significantly reduce marine pollution of all kinds.',
      'Ocean acidification is addressed in SDG 14, minimizing its impacts.',
      'Over 3 billion people depend on marine and coastal biodiversity for their livelihoods.',
      'SDG 14 includes regulating harvesting and ending overfishing.',
    ],
    15: [
      'SDG 15 aims to protect, restore and promote sustainable use of terrestrial ecosystems.',
      'By 2030, SDG 15 targets to ensure the conservation of mountain ecosystems.',
      'Biodiversity loss is tackled in SDG 15, halting deforestation and restoring degraded forests.',
      'Forests cover about 31% of the world\'s land surface and provide vital ecosystem services.',
      'SDG 15 includes combating desertification and halting land degradation.',
    ],
    16: [
      'SDG 16 aims to promote peaceful and inclusive societies for sustainable development.',
      'By 2030, SDG 16 targets to significantly reduce all forms of violence and related death rates.',
      'Rule of law is emphasized in SDG 16, ensuring equal access to justice for all.',
      'In 2017, about 1.1 billion people lived in countries affected by conflict or violence.',
      'SDG 16 includes reducing illicit financial flows and arms flows.',
    ],
    17: [
      'SDG 17 aims to strengthen the means of implementation and revitalize the global partnership for sustainable development.',
      'By 2030, SDG 17 targets to mobilize additional financial resources for developing countries.',
      'Technology transfer is key to SDG 17, promoting development and diffusion of technologies.',
      'Official development assistance reached \$146.6 billion in 2017.',
      'SDG 17 includes enhancing global macroeconomic stability through policy coordination.',
    ],
  };

  Future<void> _fetchTrivia() async {
    // Get trivia for current level, or fallback to default
    final levelTrivia = _sdgTrivia[currentLevel];
    if (levelTrivia != null && levelTrivia.isNotEmpty) {
      // Select random fact from the level's trivia
      final randomFact = (levelTrivia..shuffle()).first;
      setState(() {
        _triviaFact = randomFact;
      });
    } else {
      // Fallback for levels beyond 17 or if no trivia available
      setState(() {
        _triviaFact = 'Did you know? Hard puzzles improve cognitive skills even more!';
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
                          color: Colors.red.shade700,
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
                              'Hard Level $currentLevel',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                color: Colors.white,
                                fontSize: 28,
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
                      child: PuzzleWidget4x4(
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
