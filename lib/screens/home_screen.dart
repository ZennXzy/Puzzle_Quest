import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'account_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showOverlay = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final buttonWidth = width * 0.78;
    final buttonHeight = 86.0;

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
              const SizedBox(height: 36),
              // Title
              Text(
                'Puzzle Quest',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 56,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 80),

              // Buttons column
              Center(
                child: Column(
                  children: [
                    // Play (filled)
                    _MenuButton(
                      width: buttonWidth,
                      height: buttonHeight,
                      label: 'Play',
                      filled: true,
                      onTap: () {
                        Navigator.pushNamed(context, '/play');
                      },
                    ),

                    const SizedBox(height: 24),

                    // Account (outlined)
                    _MenuButton(
                      width: buttonWidth * 0.84,
                      height: 64,
                      label: 'Account',
                      filled: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AccountScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Exit (outlined)
                    _MenuButton(
                      width: buttonWidth * 0.84,
                      height: 64,
                      label: 'Exit',
                      filled: false,
                      onTap: () {
                        SystemNavigator.pop();
                      },
                    ),

                    const SizedBox(height: 20),

                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!_showOverlay)
                          Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Greetings',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Welcome to Puzzle Quest!',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // flexible space for background art
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _MenuButton({
    required this.width,
    required this.height,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: Colors.white.withOpacity(0.9), width: 2.4);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: border,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 12,
                offset: const Offset(6, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.14),
                blurRadius: 6,
                offset: const Offset(-2, -2),
              ),
            ],
            gradient: filled
                ? LinearGradient(colors: [Colors.purple.shade300.withOpacity(0.95), Colors.purple.shade200.withOpacity(0.8)])
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: filled ? 28 : 22,
                letterSpacing: 6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
