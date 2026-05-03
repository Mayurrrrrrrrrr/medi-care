import 'package:flutter/material.dart';
import '../../data/api_service.dart';
import '../../core/constants/api_constants.dart';

class EditMedicineScreen extends StatefulWidget {
  final Map<String, dynamic> medicine;
  const EditMedicineScreen({super.key, required this.medicine});

  @override
  State<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends State<EditMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _doseController;
  late TextEditingController _stockController;
  late TextEditingController _stockAlertController;
  late String _selectedForm;
  late String _selectedFoodTiming;
  late bool _isCritical;
  bool _isLoading = false;

  final List<String> _formOptions = ['tablet', 'capsule', 'syrup', 'injection', 'drops', 'inhaler', 'cream'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.medicine['name'] ?? '');
    _doseController = TextEditingController(text: _extractDoseNumber(widget.medicine['dose'] ?? ''));
    _stockController = TextEditingController(text: widget.medicine['stock_count']?.toString() ?? '0');
    _stockAlertController = TextEditingController(text: widget.medicine['stock_alert_at']?.toString() ?? '10');
    _selectedForm = widget.medicine['form'] ?? 'tablet';
    _selectedFoodTiming = widget.medicine['food_timing'] ?? 'after_food';
    _isCritical = widget.medicine['is_critical'] == 1 || widget.medicine['is_critical'] == '1';
  }

  String _extractDoseNumber(String dose) {
    return dose.replaceAll(RegExp(r'[^0-9.]'), '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final medicineId = int.parse(widget.medicine['id'].toString());
      final unit = _selectedForm == 'syrup' ? 'ml' : 'mg';

      await ApiService().put(ApiConstants.medicineUpdate(medicineId), {
        'name': _nameController.text.trim(),
        'form': _selectedForm,
        'dose': _doseController.text.trim() + unit,
        'food_timing': _selectedFoodTiming,
        'is_critical': _isCritical ? 1 : 0,
        'stock_count': int.tryParse(_stockController.text) ?? 0,
        'stock_alert_at': int.tryParse(_stockAlertController.text) ?? 10,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medicine updated successfully')),
        );
        Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Medicine')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Medicine Name'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v!.isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _formOptions.contains(_selectedForm) ? _selectedForm : 'tablet',
                          decoration: const InputDecoration(labelText: 'Form'),
                          items: _formOptions.map((f) => DropdownMenuItem(
                            value: f,
                            child: Text(f[0].toUpperCase() + f.substring(1)),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedForm = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _doseController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Dose',
                            suffixText: _selectedForm == 'syrup' ? 'ml' : 'mg',
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Text("Food Instructions", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Before Food'),
                          selected: _selectedFoodTiming == 'before_food',
                          onSelected: (v) { if (v) setState(() => _selectedFoodTiming = 'before_food'); },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('After Food'),
                          selected: _selectedFoodTiming == 'after_food',
                          onSelected: (v) { if (v) setState(() => _selectedFoodTiming = 'after_food'); },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Life-Saving / Critical', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Triggers aggressive escalation if missed.'),
                    value: _isCritical,
                    activeTrackColor: Colors.red.shade200,
                    activeColor: Colors.red,
                    onChanged: (v) => setState(() => _isCritical = v),
                  ),
                  const SizedBox(height: 32),

                  // Stock Section
                  Text("Stock Management", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Current Stock',
                            suffixText: 'pills',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stockAlertController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Alert When Below',
                            suffixText: 'pills',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Changes'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
