import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../data/api_service.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String phoneNumber;
  final String? firebaseToken;

  const RegisterScreen({super.key, required this.phoneNumber, this.firebaseToken});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      final response = await apiService.post(ApiConstants.register, {
        'name': name,
        'phone': widget.phoneNumber,
        'firebase_token': widget.firebaseToken,
      });

      if (response['status'] == 'success') {
        // Registration saves a JWT
        await apiService.saveToken(response['data']['token']);
        
        // Refresh AuthProvider State
        if (!mounted) return;
        final authProvider = context.read<AuthProvider>();
        await authProvider.checkExistingAuth();

        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registering: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                "Welcome to the Family",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Your number (+91 ${widget.phoneNumber}) is verified. What should we call you?",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(
                  labelText: "Your Full Name",
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registerUser,
                      child: const Text("Finish Setup"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
