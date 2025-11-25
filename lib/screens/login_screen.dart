import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:puzzle_quest/screens/registration_screen.dart';
import 'package:puzzle_quest/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool remember = false;
  bool _loading = false;

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('local_users') ?? '[]';
      final List<dynamic> users = jsonDecode(usersJson);

      // Find user by email
      final userIndex = users.indexWhere((u) => (u['email'] as String).toLowerCase() == email);
      if (userIndex == -1) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not found')));
        return;
      }

      final user = users[userIndex] as Map<String, dynamic>;
      final storedHash = user['password_hash'] as String;
      final salt = user['salt'] as String;

      // Verify password
      final inputHash = _hashPassword(password, salt);
      if (inputHash != storedHash) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid password')));
        return;
      }

      // Login successful
      await prefs.setString('current_user', user['name']);
      await prefs.setString('current_user_email', user['email']);

      // Optionally store remembered email
      if (remember) {
        await prefs.setString('remember_email', email);
      }

      // Show a modal loading indicator for 3 seconds before entering Home
      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: const Center(
              child: SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(strokeWidth: 4.0, color: Colors.white),
              ),
            ),
          ),
        );

        // keep the dialog up for 3 seconds
        await Future.delayed(const Duration(seconds: 3));

        // close dialog and navigate to HomeScreen
        if (mounted) {
          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode(salt + password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B1633), Color(0xFF6E4AA6), Color(0xFFCEB9E0)],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // soft blurred shapes for depth
          Positioned(
            left: -80,
            top: 120,
            child: Container(
              width: 380,
              height: 240,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(220),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                child: const SizedBox(),
              ),
            ),
          ),

          Positioned(
            right: -140,
            bottom: -40,
            child: Container(
              width: 520,
              height: 380,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(260),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
                child: const SizedBox(),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  // Title
                  Text(
                    'Puzzle Quest',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white.withOpacity(0.95),
                      fontSize: width > 400 ? 64 : 48,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Login card
                  Center(
                    child: Container(
                      width: width > 520 ? 460 : width * 0.92,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 18),

                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Email:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                TextFormField(
                                  controller: emailController,
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: Colors.white70,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white54),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please enter email';
                                    if (!value.contains('@')) return 'Enter a valid email';
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 14),
                                const Text('Password:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: true,
                                  style: const TextStyle(color: Colors.white),
                                  cursorColor: Colors.white70,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white54),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please enter password';
                                    if (value.length < 6) return 'Password too short';
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    Checkbox(
                                      value: remember,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                      activeColor: Colors.purple.shade200,
                                      side: BorderSide(color: Colors.white70),
                                      onChanged: (v) => setState(() => remember = v ?? false),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('Remember me', style: TextStyle(color: Colors.white70)),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Login button (neon-ish)
                                Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(
                                      colors: [Colors.purple.shade300.withOpacity(0.9), Colors.purple.shade200.withOpacity(0.7)],
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
                                      onTap: _loading ? null : _login,
                                      child: Center(
                                        child: _loading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                              )
                                            : const Text('Login', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                                      );
                                    },
                                    child: Text(
                                      'Create new account',
                                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
