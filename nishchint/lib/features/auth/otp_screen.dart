import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyCode() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a 6-digit code")),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    debugPrint("Checking OTP bypass for phone: ${widget.phoneNumber} with code: $code");

    // --- DEVELOPMENT BYPASS ---
    if (widget.phoneNumber.endsWith("9644771118") || widget.phoneNumber.endsWith("9004437501")) {
      if (code == "123456") {
        debugPrint("OTP Bypass TRIGGERED!");
        try {
          final authProvider = context.read<AuthProvider>();
          await authProvider.verifyOtp(widget.phoneNumber);
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
          return;
        } catch (e) {
          debugPrint("Backend check during bypass: $e");
          // If the backend returns 404, it means the phone is "verified" by our bypass
          // but the user needs to register.
          if (mounted) {
            setState(() => _isLoading = false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RegisterScreen(phoneNumber: widget.phoneNumber),
              ),
            );
          }
          return; // Stop here, don't fall through to Firebase
        }
      }
    }

    try {
      // 1. Verify SMS Code with Firebase natively
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: code,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 2. Verified via Firebase! Now exchange phone for PHP Backend JWT
      if (!mounted) return;
      
      final authProvider = context.read<AuthProvider>();
      
      try {
        await authProvider.verifyOtp(widget.phoneNumber);
        // Success! User exists in MySQL. Reroute to Dashboard.
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      } catch (backendError) {
        // Backend returned 404 meaning Firebase liked the phone, but our DB doesn't know them!
        // Route them to Registration flow
        setState(() => _isLoading = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterScreen(phoneNumber: widget.phoneNumber),
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Invalid OTP code')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('System error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Number'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Code Sent!",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "We sent a 6-digit security code to +91 ${widget.phoneNumber}",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, letterSpacing: 8, fontWeight: FontWeight.bold),
                maxLength: 6,
                decoration: const InputDecoration(
                  counterText: "",
                  hintText: "••••••"
                ),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _verifyCode,
                      child: const Text("Verify & Login"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
