import 'package:flutter/material.dart';
import '../../data/api_service.dart';
import '../../core/constants/api_constants.dart';
import 'edit_medicine_screen.dart';

class MedicineDetailScreen extends StatefulWidget {
  final int medicineId;
  final String medicineName;
  final int patientId;

  const MedicineDetailScreen({
    super.key,
    required this.medicineId,
    required this.medicineName,
    required this.patientId,
  });

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _medicine;
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load medicine details
      final medRes = await _api.get(ApiConstants.medicineIndex(widget.patientId));
      if (medRes['status'] == 'success') {
        final meds = medRes['data'] as List;
        _medicine = meds.firstWhere(
          (m) => m['id'].toString() == widget.medicineId.toString(),
          orElse: () => null,
        );
      }

      // Load schedules
      final schedRes = await _api.get(ApiConstants.scheduleIndex(widget.medicineId));
      if (schedRes['status'] == 'success') {
        _schedules = List<Map<String, dynamic>>.from(schedRes['data']);
      }
    } catch (e) {
      debugPrint('Error loading medicine detail: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addSchedule() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    // Show days-of-week picker
    final days = await _showDaysOfWeekPicker();
    if (days == null) return;

    try {
      final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
      await _api.post(ApiConstants.scheduleAdd, {
        'medicine_id': widget.medicineId,
        'time_slot': formattedTime,
        'days_of_week': days,
        'label': 'Dose ${_schedules.length + 1}',
      });
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<String?> _showDaysOfWeekPicker() async {
    final List<String> dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<int> dayValues = [1, 2, 3, 4, 5, 6, 7];
    List<bool> selected = List.filled(7, true); // Default: all selected

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Days'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick select buttons
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
                if (selectedDays.length == 7) {
                  Navigator.pop(ctx, 'Everyday');
                } else {
                  Navigator.pop(ctx, selectedDays.join(','));
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSchedule(int scheduleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text('Remove this time slot?'),
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
      await _api.delete(ApiConstants.scheduleDelete(scheduleId));
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatDaysOfWeek(String? days) {
    if (days == null || days == 'Everyday' || days == '1,2,3,4,5,6,7') return 'Everyday';
    final dayNames = {
      '1': 'Mon', '2': 'Tue', '3': 'Wed', '4': 'Thu',
      '5': 'Fri', '6': 'Sat', '7': 'Sun',
    };
    return days.split(',').map((d) => dayNames[d.trim()] ?? d).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicineName),
        actions: [
          if (_medicine != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditMedicineScreen(medicine: _medicine!),
                  ),
                );
                _loadData();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medicine == null
              ? const Center(child: Text('Medicine not found'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Medicine Info Card
                      _buildInfoCard(),
                      const SizedBox(height: 20),

                      // Stock Card
                      _buildStockCard(),
                      const SizedBox(height: 20),

                      // Schedules Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Schedules (${_schedules.length})',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _addSchedule,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Time'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_schedules.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: Text('No schedules. Add a time slot.')),
                          ),
                        )
                      else
                        ..._schedules.map((s) => _buildScheduleCard(s)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard() {
    final isCritical = _medicine!['is_critical'] == 1 || _medicine!['is_critical'] == '1';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCritical ? Colors.red.shade200 : Colors.transparent,
          width: 2,
        ),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.medication, color: Theme.of(context).primaryColor, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _medicine!['name'] ?? '',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_medicine!['form'] ?? ''} • ${_medicine!['dose'] ?? ''}',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (isCritical)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700, size: 14),
                        const SizedBox(width: 4),
                        Text('Critical', style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            _detailRow(Icons.restaurant, 'Food Timing', (_medicine!['food_timing'] ?? '').replaceAll('_', ' ')),
            _detailRow(Icons.calendar_today, 'Started', _medicine!['start_date'] ?? 'N/A'),
            if (_medicine!['end_date'] != null)
              _detailRow(Icons.event, 'Ends', _medicine!['end_date']),
          ],
        ),
      ),
    );
  }

  Widget _buildStockCard() {
    final stockCount = int.tryParse(_medicine!['stock_count']?.toString() ?? '0') ?? 0;
    final alertAt = int.tryParse(_medicine!['stock_alert_at']?.toString() ?? '10') ?? 10;
    final isLow = stockCount <= alertAt;
    final isEmpty = stockCount <= 0;
    final color = isEmpty ? Colors.red : isLow ? Colors.orange : Colors.green;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.inventory_2, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    isEmpty ? 'Out of stock!' : isLow ? 'Running low — refill soon' : 'Good supply',
                    style: TextStyle(color: color, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$stockCount pills',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final scheduleId = int.tryParse(schedule['id']?.toString() ?? '0') ?? 0;
    final timeSlot = schedule['time_slot']?.toString() ?? '';
    final displayTime = timeSlot.length >= 5 ? timeSlot.substring(0, 5) : timeSlot;
    final daysDisplay = _formatDaysOfWeek(schedule['days_of_week']?.toString());
    final label = schedule['label']?.toString() ?? '';
    final isActive = schedule['is_active'] == 1 || schedule['is_active'] == '1';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.withAlpha(25) : Colors.grey.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.alarm,
            color: isActive ? Colors.blue : Colors.grey,
          ),
        ),
        title: Text(displayTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label.isNotEmpty) Text(label, style: TextStyle(color: Colors.grey.shade600)),
            Text(daysDisplay, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteSchedule(scheduleId),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
