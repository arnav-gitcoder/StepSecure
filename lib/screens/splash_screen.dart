// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:stepsecure_app/constants/colors.dart';
import 'package:stepsecure_app/constants/styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The main brand logo block
              Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  color: AppColors.primary, // Solid Teal background for the container
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  size: 60,
                  color: Colors.white, // Pure white shield icon inside
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "StepSecure",
                style: AppStyles.splashTitle,
              ),

              const SizedBox(height: 8),

              const Text(
                "AI-Powered Fall Detection System",
                textAlign: TextAlign.center,
                style: AppStyles.splashSubtitle,
              ),

              const SizedBox(height: 60),

              const SizedBox(
                width: 35,
                height: 35,
                child: CircularProgressIndicator(
                  color: AppColors.primaryLight, // Matching light teal spinner
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}