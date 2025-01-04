import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'home_screen.dart';

// Define the logo colors
const Color logoBlue = Color(0xFF0066CC); // The blue color from your logo

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconScale;
  late Animation<double> _waveOffset;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _backgroundFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Icon and wave animations
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 100.0,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6),
    ));

    _waveOffset = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    // Text animations
    _textSlide = Tween<double>(begin: 20.0, end: 0.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
    ));

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
    ));

    _backgroundFade =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _controller.forward();

    Timer(const Duration(milliseconds: 3500), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SMSReaderPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Animated background with waves
              Positioned.fill(
                child: Opacity(
                  opacity: _backgroundFade.value,
                  child: CustomPaint(
                    painter: WavesPainter(
                      waveOffset: _waveOffset.value,
                      primaryColor: logoBlue,
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated icon with wave effect
                    Transform.translate(
                      offset: Offset(
                          0, math.sin(_controller.value * 2 * math.pi) * 3),
                      child: Transform.scale(
                        scale: _iconScale.value,
                        child: Image.asset(
                          'assets/icon/icon.png',
                          width: 140,
                          height: 140,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Animated text
                    Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: Text(
                          'FlowTrack',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: logoBlue,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class WavesPainter extends CustomPainter {
  final double waveOffset;
  final Color primaryColor;

  WavesPainter({required this.waveOffset, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    // First wave (background)
    final paint1 = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    const amplitude1 = 25.0;
    const frequency1 = 0.012;

    path1.moveTo(0, size.height);

    for (var i = 0; i <= size.width; i++) {
      final x = i.toDouble();
      final wave = math.sin((x + waveOffset) * frequency1) * amplitude1;
      path1.lineTo(x, size.height * 0.65 + wave);
    }

    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Second wave (middle layer)
    final paint2 = Paint()
      ..color = primaryColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    const amplitude2 = 30.0;
    const frequency2 = 0.015;

    path2.moveTo(0, size.height);

    for (var i = 0; i <= size.width; i++) {
      final x = i.toDouble();
      final wave = math.sin((x - waveOffset * 1.2) * frequency2) * amplitude2;
      path2.lineTo(x, size.height * 0.72 + wave);
    }

    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);

    // Third wave (foreground)
    final paint3 = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path3 = Path();
    const amplitude3 = 20.0;
    const frequency3 = 0.02;

    path3.moveTo(0, size.height);

    for (var i = 0; i <= size.width; i++) {
      final x = i.toDouble();
      final wave = math.sin((x + waveOffset * 0.8) * frequency3) * amplitude3;
      path3.lineTo(x, size.height * 0.78 + wave);
    }

    path3.lineTo(size.width, size.height);
    path3.close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(WavesPainter oldDelegate) =>
      oldDelegate.waveOffset != waveOffset ||
      oldDelegate.primaryColor != primaryColor;
}
