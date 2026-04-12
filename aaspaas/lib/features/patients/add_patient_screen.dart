import 'package:flutter/material.dart';
import '../../data/api_service.dart';
import '../../core/constants/api_constants.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/patient_provider.dart';

class AddPatientScreen extends StatefulWidget {
  final bool isFirstPatient;
  const AddPatientScreen({super.key, this.isFirstPatient = false});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _doctorController = TextEditingController();
  final _emergencyController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final payload = {
        'name': _nameController.text.trim(),
        'conditions': _conditionsController.text.trim(),
        'doctor_name': _doctorController.text.trim(),
        'emergency_contact': _emergencyController.text.trim(),
      };

      await ApiService().post(ApiConstants.patientsCreate, payload);
      
      if (!mounted) return;
      
      // Refresh the root patient state so the Dashboard updates instantly
      await context.read<PatientProvider>().fetchPatients();
      
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstPatient ? 'Welcome! Set Up Profile' : 'Add Family Member'),
        automaticallyImplyLeading: !widget.isFirstPatient,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  if (widget.isFirstPatient) ...[
                    const Icon(Icons.family_restroom, size: 64, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      "Let's set up the first profile for the loved one you are caring for.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 32),
                  ],
                  
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Patient Full Name *'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v!.isEmpty ? 'Name is strictly required' : null,
                  ),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: _conditionsController,
                    decoration: const InputDecoration(
                      labelText: 'Known Conditions (Optional)',
                      hintText: 'e.g., Diabetes, Hypertension',
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _emergencyController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Number (Optional)',
                      hintText: 'e.g., +91 9876543210',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: Text(widget.isFirstPatient ? "Create Profile & Start" : "Save Profile"),
                  ),
                ],
              )
            ),
    );
  }
}
