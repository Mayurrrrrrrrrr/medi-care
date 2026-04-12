import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../data/api_service.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/patient_provider.dart';
import 'package:intl/intl.dart';
import 'widgets/voice_recorder_widget.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _stockController = TextEditingController(text: '30');
  final _stockAlertController = TextEditingController(text: '10');
  
  // States
  String _selectedForm = 'tablet';
  String _selectedFoodTiming = 'after_food';
  bool _isCritical = false;
  String? _recordedVoicePath;
  bool _isLoading = false;

  // Multiple schedules
  final List<_ScheduleSlot> _scheduleSlots = [];

  final List<String> _formOptions = ['tablet', 'capsule', 'syrup', 'injection', 'drops', 'inhaler'];

  void _addTimeSlot() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;

    // Show days-of-week picker
    final days = await _showDaysOfWeekPicker();
    if (days == null) return;

    setState(() {
      _scheduleSlots.add(_ScheduleSlot(time: picked, daysOfWeek: days));
    });
  }

  Future<String?> _showDaysOfWeekPicker() async {
    final List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<int> dayValues = [1, 2, 3, 4, 5, 6, 7];
    List<bool> selected = List.filled(7, true);

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Days'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: () => setDialogState(() => selected = List.filled(7, true)),
                    child: const Text('Everyday'),
                  ),
                  TextButton(
                    onPressed: () => setDialogState(() {
                      selected = [true, true, true, true, true, false, false];
                    }),
                    child: const Text('Weekdays'),
                  ),
                ],
              ),
              const Divider(),
              Wrap(
                spacing: 8,
                children: List.generate(7, (i) {
                  return FilterChip(
                    label: Text(dayNames[i]),
                    selected: selected[i],
                    onSelected: (val) => setDialogState(() => selected[i] = val),
                    selectedColor: Theme.of(context).primaryColor.withAlpha(50),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final selectedDays = <String>[];
                for (int i = 0; i < 7; i++) {
                  if (selected[i]) selectedDays.add(dayValues[i].toString());
                }
                if (selectedDays.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select at least one day')),
                  );
                  return;
                }
                Navigator.pop(ctx, selectedDays.length == 7 ? 'Everyday' : selectedDays.join(','));
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeTimeSlot(int index) {
    setState(() => _scheduleSlots.removeAt(index));
  }

  String _formatDaysOfWeek(String days) {
    if (days == 'Everyday' || days == '1,2,3,4,5,6,7') return 'Everyday';
    final dayNames = {'1': 'Mon', '2': 'Tue', '3': 'Wed', '4': 'Thu', '5': 'Fri', '6': 'Sat', '7': 'Sun'};
    return days.split(',').map((d) => dayNames[d.trim()] ?? d).join(', ');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduleSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one daily time slot')),
      );
      return;
    }

    final patientProvider = context.read<PatientProvider>();
    final activePatient = patientProvider.selectedPatient;
    
    if (activePatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No patient selected')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();
      
      // 1. Save Medicine Data
      final unit = _selectedForm == 'syrup' ? 'ml' : 'mg';
      final medicinePayload = {
        'patient_id': activePatient.id,
        'name': _nameController.text.trim(),
        'form': _selectedForm,
        'dose': _doseController.text.trim() + unit,
        'food_timing': _selectedFoodTiming,
        'is_critical': _isCritical ? 1 : 0,
        'stock_count': int.tryParse(_stockController.text) ?? 30,
        'stock_alert_at': int.tryParse(_stockAlertController.text) ?? 10,
        'start_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      };

      final medicineRes = await apiService.post(ApiConstants.medicineAdd, medicinePayload);
      final medicineId = medicineRes['data']['id'];

      // 2. Save ALL Schedule Slots
      for (int i = 0; i < _scheduleSlots.length; i++) {
        final slot = _scheduleSlots[i];
        final formattedTime = '${slot.time.hour.toString().padLeft(2, '0')}:${slot.time.minute.toString().padLeft(2, '0')}:00';
        
        final schedulePayload = {
          'medicine_id': medicineId,
          'time_slot': formattedTime,
          'days_of_week': slot.daysOfWeek,
          'label': 'Dose ${i + 1}',
        };

        final scheduleRes = await apiService.post(ApiConstants.scheduleAdd, schedulePayload);
        
        // 3. Upload Voice Note to the first schedule only
        if (i == 0 && _recordedVoicePath != null) {
          final scheduleId = scheduleRes['data']['id'];
          await apiService.multipartPost(
            ApiConstants.voiceUpload,
            _recordedVoicePath!,
            {'schedule_id': scheduleId.toString()},
          );
        }
      }

      // 4. Refresh Dashboard State
      await patientProvider.fetchTodayMedicines(activePatient.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_scheduleSlots.length} schedule(s) created successfully!')),
      );
      Navigator.pop(context);

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failure: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medicine'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                // Medicine Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    hintText: 'e.g. Paracetamol',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v!.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 24),

                // Form & Dose Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _selectedForm,
                        decoration: const InputDecoration(labelText: 'Form'),
                        items: _formOptions.map((f) => DropdownMenuItem(value: f, child: Text(f[0].toUpperCase() + f.substring(1)))).toList(),
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
                          hintText: 'e.g. 500',
                          suffixText: _selectedForm == 'syrup' ? 'ml' : 'mg',
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Schedule Time Slots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Daily Schedule", style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(
                      onPressed: _addTimeSlot,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Add Time"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_scheduleSlots.isEmpty)
                  InkWell(
                    onTap: _addTimeSlot,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.alarm_add, size: 32, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text("Tap to add alarm time", style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ..._scheduleSlots.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final slot = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.alarm, color: Theme.of(context).primaryColor),
                        ),
                        title: Text(
                          slot.time.format(context),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text(
                          _formatDaysOfWeek(slot.daysOfWeek),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeTimeSlot(idx),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 32),

                // Food Timing Segment
                Text("Food Instructions", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Before Food'),
                        selected: _selectedFoodTiming == 'before_food',
                        onSelected: (bool selected) {
                          if (selected) setState(() => _selectedFoodTiming = 'before_food');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('After Food'),
                        selected: _selectedFoodTiming == 'after_food',
                        onSelected: (bool selected) {
                          if (selected) setState(() => _selectedFoodTiming = 'after_food');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Criticality Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Life-Saving / Critical Medicine', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Will trigger aggressive alarm escalations if missed.'),
                  value: _isCritical,
                  activeTrackColor: Colors.red.shade200,
                  activeColor: Colors.red,
                  onChanged: (bool value) => setState(() => _isCritical = value),
                ),
                const SizedBox(height: 32),

                // Stock Management
                Text("Stock Management", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock Count',
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
                          labelText: 'Alert Below',
                          suffixText: 'pills',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Voice Recorder Widget
                Text("Personal Voice Note", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                VoiceRecorderWidget(
                  onRecordingComplete: (path) => setState(() => _recordedVoicePath = path),
                ),
                const SizedBox(height: 48),

                // Submit
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _isCritical ? Colors.red.shade600 : Theme.of(context).primaryColor,
                  ),
                  child: Text('Save Medicine (${_scheduleSlots.length} schedule${_scheduleSlots.length != 1 ? 's' : ''})'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }
}

class _ScheduleSlot {
  final TimeOfDay time;
  final String daysOfWeek;

  _ScheduleSlot({required this.time, required this.daysOfWeek});
}
