import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget{
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();

}

class _SplashScreenState extends State<SplashScreen> {
  bool _isTextCentered = false;
  bool _isScalTheCircle = false;

  @override
  void initState() {
    super.initState();
    // Start animation automatically for 3 seconds total
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isTextCentered = true;
        });
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (mounted) {
            setState(() {
              _isScalTheCircle = true;
            });
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/auth');
              }
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B1633), Color(0xFF6E4AA6), Color(0xFFCEB9E0)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        height: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children:[
            AnimatedPositioned(
              duration: Duration(milliseconds: 1000),
              curve: Curves.easeOut,
              top: _isTextCentered ? (MediaQuery.of(context).size.height / 2) - 120 : -120,
              left: MediaQuery.of(context).size.width / 2 - 150, // Center horizontally
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Puzzle Quest",
                    style: TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Slide to Solve Puzzles",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Center(
              child: AnimatedScale(
                duration: Duration(milliseconds: 600),
                curve: Cubic(0.58, -0.30, 0.365, 1),
                scale: _isScalTheCircle ? 10 : 0,

                child: CircleAvatar(
                  radius: 48,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
