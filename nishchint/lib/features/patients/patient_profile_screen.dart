import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/patient_provider.dart';
import '../../data/api_service.dart';
import '../../core/constants/api_constants.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _conditionsController;
  late TextEditingController _doctorController;
  late TextEditingController _emergencyController;

  @override
  void initState() {
    super.initState();
    final patient = context.read<PatientProvider>().selectedPatient;
    _nameController = TextEditingController(text: patient?.name ?? '');
    _conditionsController = TextEditingController(text: patient?.conditions ?? '');
    _doctorController = TextEditingController(text: patient?.doctorName ?? '');
    _emergencyController = TextEditingController(text: patient?.emergencyContact ?? '');
  }

  Future<void> _saveProfile() async {
    final patient = context.read<PatientProvider>().selectedPatient;
    if (patient == null) return;

    setState(() => _isLoading = true);
    try {
      await ApiService().put(ApiConstants.patientUpdate(patient.id), {
        'name': _nameController.text.trim(),
        'conditions': _conditionsController.text.trim(),
        'doctor_name': _doctorController.text.trim(),
        'emergency_contact': _emergencyController.text.trim(),
      });

      await context.read<PatientProvider>().fetchPatients();

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<PatientProvider>().selectedPatient;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : patient == null
              ? const Center(child: Text('No patient selected'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColor.withAlpha(50),
                        backgroundImage: patient.photoUrl != null ? NetworkImage(patient.photoUrl!) : null,
                        child: patient.photoUrl == null
                            ? Icon(Icons.person, size: 50, color: Theme.of(context).primaryColor)
                            : null,
                      ),
                      const SizedBox(height: 16),

                      if (!_isEditing) ...[
                        Text(
                          patient.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        _infoTile(Icons.medical_information, 'Conditions', patient.conditions ?? 'Not specified'),
                        _infoTile(Icons.local_hospital, 'Doctor', patient.doctorName ?? 'Not specified'),
                        _infoTile(Icons.phone, 'Emergency Contact', patient.emergencyContact ?? 'Not specified'),
                      ] else ...[
                        // Edit Form
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Patient Name'),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _conditionsController,
                          decoration: const InputDecoration(
                            labelText: 'Known Conditions',
                            hintText: 'e.g., Diabetes, Hypertension',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _doctorController,
                          decoration: const InputDecoration(
                            labelText: 'Doctor Name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emergencyController,
                          decoration: const InputDecoration(
                            labelText: 'Emergency Contact',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text('Save Changes'),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ),
    );
  }
}
