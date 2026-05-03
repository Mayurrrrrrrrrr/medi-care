import 'package:flutter/material.dart';
import '../../../data/api_service.dart';
import '../../../core/constants/api_constants.dart';

class WeeklyChartWidget extends StatefulWidget {
  final int patientId;
  const WeeklyChartWidget({super.key, required this.patientId});

  @override
  State<WeeklyChartWidget> createState() => _WeeklyChartWidgetState();
}

class _WeeklyChartWidgetState extends State<WeeklyChartWidget> {
  List<_DayData> _weekData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = ApiService();
      final response = await api.get(
        '${ApiConstants.logsHistory(widget.patientId)}&days=7',
      );
      if (response['status'] == 'success') {
        final logs = List<Map<String, dynamic>>.from(response['data']);
        _processData(logs);
      }
    } catch (e) {
      debugPrint('Chart error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processData(List<Map<String, dynamic>> logs) {
    final now = DateTime.now();
    final dayData = <String, _DayData>{};

    // Initialize 7 days
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      dayData[key] = _DayData(
        label: dayNames[date.weekday - 1],
        total: 0,
        taken: 0,
        date: key,
      );
    }

    // Count from logs
    for (var log in logs) {
      final date = log['scheduled_date']?.toString() ?? '';
      if (dayData.containsKey(date)) {
        dayData[date]!.total++;
        if (log['status'] == 'taken') {
          dayData[date]!.taken++;
        }
      }
    }

    setState(() {
      _weekData = dayData.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_weekData.isEmpty) return const SizedBox.shrink();

    final maxTotal = _weekData.fold<int>(0, (max, d) => d.total > max ? d.total : max);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '7-Day Adherence',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildLegend(),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _weekData.map((day) {
                  final percentage = day.total > 0 ? day.taken / day.total : 0.0;
                  final barHeight = maxTotal > 0 ? (day.total / maxTotal) * 90 : 10.0;
                  final filledHeight = barHeight * percentage;
                  final color = percentage >= 0.8
                      ? Colors.green
                      : percentage >= 0.5
                          ? Colors.orange
                          : day.total > 0
                              ? Colors.red
                              : Colors.grey.shade300;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (day.total > 0)
                            Text(
                              '${(percentage * 100).round()}%',
                              style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: filledHeight,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            day.label,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _legendDot(Colors.green, '≥80%'),
        const SizedBox(width: 8),
        _legendDot(Colors.orange, '≥50%'),
        const SizedBox(width: 8),
        _legendDot(Colors.red, '<50%'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _DayData {
  final String label;
  int total;
  int taken;
  final String date;

  _DayData({required this.label, required this.total, required this.taken, required this.date});
}
