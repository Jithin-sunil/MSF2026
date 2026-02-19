import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shop_app/homepage.dart';
import 'package:shop_app/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // Navigation after 5 seconds
    Timer(const Duration(seconds: 5), () {
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    User? user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color brandColor = Color(0xFF009ADE);

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // 1. MAIN CENTER CONTENT (Event Branding)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- MSF2026 MAIN LOGO ---
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Image.asset(
                      'assets/msf2026logo.png',
                      height: 120,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.event_available, size: 100, color: brandColor),
                    ),
                  ),
                  
                  Text(
                    "MSF2026",
                    style: GoogleFonts.exo2(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: brandColor,
                      letterSpacing: -2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "പ്ലാറ്റിനം ജൂബിലി വ്യാപാര മേള",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.hindVadodara(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 40),

                  Text(
                    "ORGANIZED BY",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: brandColor.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/logo.png', 
                      height: 80,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.store, size: 60, color: brandColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "The Merchants' Association",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    "Muvattupuzha",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: brandColor,
                    ),
                  ),
                ],
              ),
            ),

            // 2. BOTTOM FOOTER SECTION (Developer Branding)
            Positioned(
              bottom: 30, // Adjusted for logo placement
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: brandColor,
                    ),
                  ),
                  const SizedBox(height: 25),
                  
                  Text(
                    "BUILD BY",
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // --- DEVELOPER COMPANY LOGO ---
                  Image.asset(
                    'assets/psst.png', // Ensure this matches your file name in assets
                    height: 45, // Size adjusted for a footer look
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      "Progressive Software Solutions",
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}