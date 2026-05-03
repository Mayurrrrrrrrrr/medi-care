import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';
import '../../shared/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8F5), Color(0xFFFFE8E0)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                size: const Size(120, 120),
                painter: HeartMedicinePainter(),
              ),
              const SizedBox(height: 24),
              Text(
                'Nishchint',
                style: GoogleFonts.nunito(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const Text(
                'निश्चिंत',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFFF7F50),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '“दूर हो, पर चिंता नहीं”',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeartMedicinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF7F50)
      ..style = PaintingStyle.fill;

    final path = Path();
    double width = size.width;
    double height = size.height;

    // Draw Heart
    path.moveTo(width * 0.5, height * 0.25);
    path.cubicTo(width * 0.2, height * 0.1, 0, height * 0.5, width * 0.5, height * 0.9);
    path.cubicTo(width, height * 0.5, width * 0.8, height * 0.1, width * 0.5, height * 0.25);
    canvas.drawPath(path, paint);

    // Draw Pill inside
    final pillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final pillRect = Rect.fromCenter(
      center: Offset(width * 0.5, height * 0.45),
      width: width * 0.35,
      height: height * 0.12,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(8)), pillPaint);
    
    // Pill divider
    final dividerPaint = Paint()
      ..color = const Color(0xFFFF7F50)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(width * 0.5, height * 0.39),
      Offset(width * 0.5, height * 0.51),
      dividerPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
