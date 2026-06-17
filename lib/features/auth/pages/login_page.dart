import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;

  Future<void> signIn() async {
    setState(() {
      isLoading = true;
    });

    try {
      await AuthService().signInWithGoogle();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.dark2,
          content: Text(
            'Login error: $e',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Image.asset(
                    'assets/images/big-logo.png',
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 42),

                const Text(
                  'Plant Journal',

                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,

                    color: AppColors.heading,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'Track your plants,\nwatering and growth',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,

                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 54),

                SizedBox(
                  width: double.infinity,
                  height: 58,

                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : signIn,

                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,

                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.dark1,
                            ),
                          )
                        : const Icon(Icons.login),

                    label: Text(
                      isLoading ? 'Signing in...' : 'Continue with Google',

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldAccent,
                      foregroundColor: AppColors.dark1,

                      elevation: 0,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'Your data is securely stored in Firebase',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 0.3,

                    color: AppColors.warmGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
