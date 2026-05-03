import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/patient_provider.dart';
import '../../data/models/medicine_model.dart';
import '../../data/api_service.dart';
import '../../core/constants/api_constants.dart';
import 'add_medicine_screen.dart';
import 'medicine_detail_screen.dart';

class MedicinesListScreen extends StatefulWidget {
  const MedicinesListScreen({super.key});

  @override
  State<MedicinesListScreen> createState() => _MedicinesListScreenState();
}

class _MedicinesListScreenState extends State<MedicinesListScreen> {
  List<MedicineModel> _medicines = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    final patient = context.read<PatientProvider>().selectedPatient;
    if (patient == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ApiService();
      final response = await api.get(ApiConstants.medicineIndex(patient.id));
      if (response['status'] == 'success') {
        setState(() {
          _medicines = (response['data'] as List)
              .map((item) => MedicineModel.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMedicine(int medicineId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine? This will also delete all its schedules and logs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ApiService();
      await api.delete(ApiConstants.medicineDelete(medicineId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine deleted successfully')),
        );
      }
      _loadMedicines();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  IconData _getFormIcon(String form) {
    switch (form.toLowerCase()) {
      case 'tablet':
        return Icons.medication;
      case 'capsule':
        return Icons.medication_liquid;
      case 'syrup':
      case 'liquid':
        return Icons.local_drink;
      case 'injection':
        return Icons.vaccines;
      case 'drops':
        return Icons.water_drop;
      case 'inhaler':
        return Icons.air;
      case 'cream':
      case 'ointment':
        return Icons.spa;
      default:
        return Icons.medical_services;
    }
  }

  Color _getFormColor(String form) {
    switch (form.toLowerCase()) {
      case 'tablet':
        return Colors.blue;
      case 'capsule':
        return Colors.purple;
      case 'syrup':
      case 'liquid':
        return Colors.teal;
      case 'injection':
        return Colors.red;
      case 'drops':
        return Colors.cyan;
      case 'inhaler':
        return Colors.indigo;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medicines'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
              );
              _loadMedicines();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 12),
                      Text('Failed to load medicines', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _loadMedicines, child: const Text('Retry')),
                    ],
                  ),
                )
              : _medicines.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadMedicines,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _medicines.length,
                        itemBuilder: (context, index) => _buildMedicineCard(_medicines[index]),
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No medicines added yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first medicine',
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
                );
                _loadMedicines();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Medicine'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineCard(MedicineModel medicine) {
    final formColor = _getFormColor(medicine.form);
    final formIcon = _getFormIcon(medicine.form);
    final patient = context.read<PatientProvider>().selectedPatient;

    return InkWell(
      onTap: () async {
        if (patient == null) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineDetailScreen(
              medicineId: medicine.id,
              medicineName: medicine.name,
              patientId: patient.id,
            ),
          ),
        );
        _loadMedicines();
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: medicine.isCritical ? Colors.red.shade200 : Colors.transparent,
          width: 2,
        ),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Medicine icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: formColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(formIcon, color: formColor, size: 28),
            ),
            const SizedBox(width: 16),
            // Medicine details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          medicine.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (medicine.isCritical) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, color: Colors.red.shade700, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                'Critical',
                                style: TextStyle(color: Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _infoChip(Icons.category, medicine.form),
                      const SizedBox(width: 8),
                      _infoChip(Icons.science, medicine.dose),
                      const SizedBox(width: 8),
                      _infoChip(Icons.restaurant, medicine.foodTiming.replaceAll('_', ' ')),
                    ],
                  ),
                  if (medicine.timeSlot != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          medicine.timeSlot!.substring(0, 5),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Delete button
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteMedicine(medicine.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
