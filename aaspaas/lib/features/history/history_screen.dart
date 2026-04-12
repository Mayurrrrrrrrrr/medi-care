import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/patient_provider.dart';
import '../../data/api_service.dart';
import '../../core/constants/api_constants.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;
  int _selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final patient = context.read<PatientProvider>().selectedPatient;
    if (patient == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = ApiService();
      final response = await api.get(
        '${ApiConstants.logsHistory(patient.id)}&days=$_selectedDays',
      );
      if (response['status'] == 'success') {
        setState(() {
          _logs = List<Map<String, dynamic>>.from(response['data']);
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

  Map<String, List<Map<String, dynamic>>> _groupByDate() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var log in _logs) {
      final date = log['scheduled_date'] ?? 'Unknown';
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(log);
    }
    return grouped;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'taken':
        return Colors.green;
      case 'skipped':
        return Colors.red;
      case 'snoozed':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'taken':
        return Icons.check_circle;
      case 'skipped':
        return Icons.cancel;
      case 'snoozed':
        return Icons.snooze;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final targetDate = DateTime(date.year, date.month, date.day);

      if (targetDate == today) return 'Today';
      if (targetDate == yesterday) return 'Yesterday';

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();
    final dates = grouped.keys.toList();

    // Calculate summary stats
    final totalTaken = _logs.where((l) => l['status'] == 'taken').length;
    final totalSkipped = _logs.where((l) => l['status'] == 'skipped').length;
    final totalCount = _logs.length;
    final adherenceRate = totalCount > 0 ? (totalTaken / totalCount * 100).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        elevation: 0,
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
                      Text('Failed to load history', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _loadHistory, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Period selector
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [3, 7, 14, 30].map((days) {
                              final isSelected = _selectedDays == days;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('$days days'),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedDays = days;
                                    });
                                    _loadHistory();
                                  },
                                  selectedColor: Theme.of(context).primaryColor.withAlpha(50),
                                  labelStyle: TextStyle(
                                    color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Summary card
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Text(
                                  'Adherence Summary',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _summaryItem('$adherenceRate%', 'Adherence', Colors.blue),
                                    _summaryItem('$totalTaken', 'Taken', Colors.green),
                                    _summaryItem('$totalSkipped', 'Skipped', Colors.red),
                                    _summaryItem('$totalCount', 'Total', Colors.blueGrey),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Progress bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: totalCount > 0 ? totalTaken / totalCount : 0,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      adherenceRate >= 80 ? Colors.green : adherenceRate >= 50 ? Colors.orange : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_logs.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(Icons.history, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No history yet',
                                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Medication logs will appear here once you start tracking.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...dates.map((date) {
                            final dayLogs = grouped[date]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8, top: 8),
                                  child: Text(
                                    _formatDate(date),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                ...dayLogs.map((log) => _buildLogCard(log)),
                                const Divider(height: 24),
                              ],
                            );
                          }),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _summaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final status = log['status'] ?? 'pending';
    final color = _statusColor(status);
    final icon = _statusIcon(status);
    final time = (log['time_slot'] ?? '').toString();
    final displayTime = time.length >= 5 ? time.substring(0, 5) : time;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          log['medicine_name'] ?? 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$displayTime • ${log['dose'] ?? ''} • ${(log['food_timing'] ?? '').toString().replaceAll('_', ' ')}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
