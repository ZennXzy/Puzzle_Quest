import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_progress.dart';
import '../models/hard_user_progress.dart';
import '../services/hard_progress_service.dart';
import '../widgets/achievements_widget.dart';
import 'login_screen.dart';
import '../services/progress_service.dart';
import '../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  UserProgress? _userProgress;
  HardUserProgress? _hardProgress;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final user = authService.currentUser;
    if (user != null) {
      // Try to load username from Firestore
      try {
        final userData = await authService.getUserData(user.uid);
        if (userData != null && userData['name'] != null) {
          _username = userData['name'];
          print('Username loaded from Firestore: $_username');
        }
      } catch (e) {
        print('Error loading username from Firestore: $e');
      }

      // Fallback to SharedPreferences if not loaded from Firestore
      if (_username == null) {
        final prefs = await SharedPreferences.getInstance();
        final currentUser = prefs.getString('current_user');
        if (currentUser != null) {
          _username = currentUser;
          print('Username fallback to SharedPreferences: $_username');
        }
      }

      // Update UI for username
      setState(() {});

      // Load progress
      try {
        final progressService = ProgressService();
        final userProgress = await progressService.loadProgress();
        if (userProgress != null) {
          setState(() {
            _userProgress = userProgress;
          });
        }
      } catch (e) {
        print('Error loading progress from Firebase: $e');
      }

      // Load hard progress
      try {
        final hardService = HardProgressService();
        final hardProgress = await hardService.loadProgress();
        if (hardProgress != null) {
          setState(() {
            _hardProgress = hardProgress;
          });
        }
      } catch (e) {
        print('Error loading hard progress from Firebase: $e');
      }

      // Fallback to local storage for progress
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('user_progress_${user.uid}');
      if (progressJson != null && _userProgress == null) {
        final progressData = jsonDecode(progressJson) as Map<String, dynamic>;
        setState(() {
          _userProgress = UserProgress.fromJson(progressData);
        });
      }
      // Fallback for hard progress local copy
      final hardProgressJson = prefs.getString('hard_user_progress_${user.uid}');
      if (hardProgressJson != null && _hardProgress == null) {
        final hardData = jsonDecode(hardProgressJson) as Map<String, dynamic>;
        setState(() {
          _hardProgress = HardUserProgress.fromJson(hardData);
        });
      }
    } else {
      print('No authenticated user found');
    }
  }

  Future<void> _loadProgress() async {
    final authService = AuthService();
    final user = authService.currentUser;
    if (user != null) {
      // Load progress
      try {
        final progressService = ProgressService();
        final userProgress = await progressService.loadProgress();
        if (userProgress != null) {
          setState(() {
            _userProgress = userProgress;
          });
          return;
        }
      } catch (e) {
        print('Error loading progress from Firebase: $e');
      }

      // Fallback to local storage for progress
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('user_progress_${user.uid}');
      if (progressJson != null) {
        final progressData = jsonDecode(progressJson) as Map<String, dynamic>;
        setState(() {
          _userProgress = UserProgress.fromJson(progressData);
        });
      }

      // Also load Hard progress when refreshing
      try {
        final hardService = HardProgressService();
        final hardProgress = await hardService.loadProgress();
        if (hardProgress != null) {
          setState(() {
            _hardProgress = hardProgress;
          });
        } else {
          // fallback to local prefs
          final hardProgressJson = prefs.getString('hard_user_progress_${user.uid}');
          if (hardProgressJson != null) {
            final hardData = jsonDecode(hardProgressJson) as Map<String, dynamic>;
            setState(() {
              _hardProgress = HardUserProgress.fromJson(hardData);
            });
          }
        }
      } catch (e) {
        print('Error loading hard progress during refresh: $e');
      }
    } else {
      print('No authenticated user found');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
          child: RefreshIndicator(
            onRefresh: _loadProgress,
            color: Colors.white,
            backgroundColor: Colors.purple,
            child: ListView(
              children: [
                // AppBar with back button
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
                        // Back button
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

                        // Title
                        Expanded(
                          child: Text(
                            'Account',
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

                        // Spacer for balance
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Account card
                Center(
                  child: Container(
                    width: width > 520 ? 460 : width * 0.92,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.06),
                          Colors.white.withOpacity(0.03)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(6, 8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Username
                          Text(
                            _username ?? 'Loading...',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Username',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Current Level (Classic / Hard)
                          Text(
                            'Current Level',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'Classic',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_userProgress?.currentLevel ?? 1}',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white.withOpacity(0.95),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      'Hard',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_hardProgress?.currentLevel ?? 1}',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Colors.white.withOpacity(0.95),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Achievements Widget
                          AchievementsWidget(userProgress: _userProgress, hardUserProgress: _hardProgress),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Logout button
                Center(
                  child: Container(
                    width: width > 520 ? 460 : width * 0.92,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.red.shade300.withOpacity(0.9), Colors.red.shade200.withOpacity(0.7)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          offset: const Offset(4, 6),
                          blurRadius: 10,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.18),
                          offset: const Offset(-2, -2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _logout,
                        child: const Center(
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20), // Extra space for refresh indicator
              ],
            ),
          ),
        ),
      ),
    );
  }
}
