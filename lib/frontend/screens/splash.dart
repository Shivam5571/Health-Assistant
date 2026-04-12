import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'home.dart';
import 'auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final List<String> greetings = [
    "Hello",
    "नमस्ते",
    "Bonjour",
    "Hola",
    "Ciao",
    "こんにちは",
    "안녕하세요"
  ];

  int _textIndex = 0;
  
  // Animation States
  bool _showLogo = false;
  bool _showGradient = false;
  bool _showText = false;

  late AnimationController _textRevealController;
  Timer? _textTimer;

  @override
  void initState() {
    super.initState();

    // Controller for the "Left to Right" text reveal
    _textRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Speed of writing
    );

    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Phase 1: Solid Color -> Show Logo
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _showLogo = true);

    // Stay on Logo for 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    
    // Phase 2: Hide Logo & Switch to Blur Gradient
    if (!mounted) return;
    setState(() {
      _showLogo = false;
      _showGradient = true; 
    });

    // Wait for gradient transition to settle
    await Future.delayed(const Duration(milliseconds: 800));

    // Phase 3: Start Text Loop
    if (!mounted) return;
    setState(() => _showText = true);
    _cycleGreetings();

    // Final: Navigate to Home after total duration (e.g., 8 seconds total)
    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted) return;
      Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const AuthScreen()),
);



    });
  }

  void _cycleGreetings() {
    if (!mounted) return;
    
    // 1. Play reveal animation (Write)
    _textRevealController.forward(from: 0.0);

    // 2. Schedule next word
    _textTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _textIndex = (_textIndex + 1) % greetings.length;
      });
      // Loop continues
      _cycleGreetings();
    });
  }

  @override
  void dispose() {
    _textRevealController.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // LAYER 1: Animated Background (Solid -> Gradient)
          AnimatedContainer(
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: _showGradient
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE0C3FC), // Light Purple (Blurry feel)
                        Color(0xFF8EC5FC), // Light Blue (Blurry feel)
                      ],
                    )
                  : const LinearGradient(
                      // Initial Solid Color (using gradient with same colors simulates solid)
                      colors: [Colors.black, Colors.black],
                    ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),

          // LAYER 2: Logo (Fade In / Fade Out)
          Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _showLogo ? 1.0 : 0.0,
              child: const Icon(
                Icons.apple, // Using Apple icon as placeholder for logo
                size: 100,
                color: Colors.white,
              ),
            ),
          ),

          // LAYER 3: Handwriting/Typewriter Text (Only visible in Phase 3)
          if (_showText)
            Center(
              child: RevealingText(
                text: greetings[_textIndex],
                controller: _textRevealController,
              ),
            ),
        ],
      ),
    );
  }
}

// Custom Widget for "Character by Character" Typewriter Effect
class RevealingText extends StatelessWidget {
  final String text;
  final AnimationController controller;

  const RevealingText({
    super.key,
    required this.text,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Define style once to ensure perfect overlap
    const textStyle = TextStyle(
      fontFamily: 'serif', // Elegant font
      fontSize: 56,
      fontWeight: FontWeight.w600,
      color: Colors.black87, // Dark text on light gradient
      letterSpacing: 1.2,
    );

    // Using a Stack ensures the layout size is fixed to the full word width,
    // preventing the text from jumping/shifting left-right while typing.
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // 1. Invisible placeholder to keep the text centered on screen
        Text(
          text,
          style: textStyle.copyWith(color: Colors.transparent),
        ),
        // 2. Actual animated text that types out
        AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            // Calculate how many characters to show based on animation progress
            int count = (text.length * controller.value).toInt();
            
            // Safety check
            if (count > text.length) count = text.length;
            
            return Text(
              text.substring(0, count),
              style: textStyle,
            );
          },
        ),
      ],
    );
  }
}