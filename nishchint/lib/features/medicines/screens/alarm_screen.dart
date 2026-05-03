import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../../data/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../services/alarm_service.dart';
import '../widgets/voice_recorder_widget.dart';
import '../../../services/voice_cache_service.dart';
import '../../../core/utils/language_helper.dart';
import '../../../core/constants/strings.dart';

class AlarmScreen extends StatefulWidget {
  final int scheduleId;
  final int patientId;
  final String medicineName;
  final String dose;
  final String foodTiming;
  final int isCritical;
  final String voiceUrl;
  final String scheduledTime;
  final String? voicePath;
  final int medicineId;

  const AlarmScreen({
    super.key,
    required this.scheduleId,
    required this.patientId,
    required this.medicineId,
    required this.medicineName,
    required this.dose,
    required this.foodTiming,
    required this.isCritical,
    required this.voiceUrl,
    required this.scheduledTime,
    this.voicePath,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;
  String? _voiceNotePath;
  late AnimationController _pulseController;

  // Escalation timer
  Timer? _escalationTimer;
  int _secondsElapsed = 0;
  bool _escalationTriggered = false;
  static const int _escalationDelaySeconds = 600; // 10 minutes

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _startAlarmAudio();
    _startEscalationTimer();
  }

  Future<void> _startAlarmAudio() async {
    String? localPath = widget.voicePath;
    
    // If no local path but voiceUrl exists, download it
    if ((localPath == null || localPath == 'none') && widget.voiceUrl.isNotEmpty) {
      localPath = await VoiceCacheService.downloadAndCache(widget.voiceUrl);
    }

    try {
      if (localPath != null && localPath != 'none') {
        await _audioPlayer.play(DeviceFileSource(localPath), volume: 1.0);
      } else {
        // Play gentle chime
        await _audioPlayer.play(AssetSource('sounds/gentle_chime.mp3'), volume: 0.8);
      }
    } catch (e) {
      debugPrint("Error playing alarm audio: $e");
    }
  }

  void _startEscalationTimer() {
    _escalationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsElapsed++);
        if (_secondsElapsed >= _escalationDelaySeconds && !_escalationTriggered) {
          _triggerEscalation();
        }
      }
    });
  }

  Future<void> _triggerEscalation() async {
    _escalationTriggered = true;
    try {
      await _apiService.post(ApiConstants.familyNotifyTaken, {
        'patient_id': widget.patientId,
        'medicine_name': widget.medicineName,
        'message': '⚠️ MISSED: ${widget.medicineName} has not been taken for over 10 minutes! Please call and remind.',
      });
    } catch (e) {
      debugPrint('Escalation error: $e');
    }
  }

  Future<void> _startVoiceNote() async {
    // This is replaced by _startAlarmAudio
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pulseController.dispose();
    _escalationTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateStatus(String status, {String? reason}) async {
    setState(() => _isSubmitting = true);
    try {
      await _apiService.post(ApiConstants.logUpdate, {
        'schedule_id': widget.scheduleId,
        'patient_id': widget.patientId,
        'status': status,
        'scheduled_datetime': widget.scheduledTime,
        'skip_reason': reason,
      });

      // Auto-decrement stock on taken
      if (status == 'taken') {
        try {
          await _apiService.post(ApiConstants.medicineDecrementStock, {
            'medicine_id': widget.medicineId,
          });
        } catch (e) {
          debugPrint('Stock decrement error: $e');
        }
      }

      _escalationTimer?.cancel();
      _audioPlayer.stop();

      if (mounted) {
        if (status == 'taken') {
          _showSendVoiceNoteDialog();
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snooze() async {
    await _audioPlayer.stop();
    _escalationTimer?.cancel();
    
    final snoozeTime = DateTime.now().add(const Duration(minutes: 10));
    await AlarmService.scheduleMedicineAlarm(
      widget.scheduleId, 
      widget.patientId, 
      widget.medicineId,
      snoozeTime, 
      widget.medicineName, 
      widget.voicePath
    );
    
    if (mounted) Navigator.of(context).pop();
  }

  void _showSendVoiceNoteDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Medicine Taken! 🎉',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a voice note to your family letting them know?',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            VoiceRecorderWidget(
              scheduleId: widget.scheduleId,
              onSaved: () {
                _notifyFamily(null); // Just notify family, recording is already uploaded by widget
                Navigator.pop(ctx);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Notify family without voice note
                      _notifyFamily(null);
                      Navigator.pop(ctx);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _notifyFamily(_voiceNotePath);
                      Navigator.pop(ctx);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Send & Close'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _notifyFamily(String? voicePath) async {
    try {
      await _apiService.post(ApiConstants.familyNotifyTaken, {
        'patient_id': widget.patientId,
        'medicine_name': widget.medicineName,
        'message': '✅ ${widget.medicineName} has been taken!',
      });

      // If voice note was recorded, upload it
      if (voicePath != null) {
        await _apiService.multipartPost(
          ApiConstants.voiceUpload,
          voicePath,
          {'schedule_id': widget.scheduleId.toString()},
        );
      }
    } catch (e) {
      debugPrint('Notify family error: $e');
    }
  }

  void _showSkipDialog() {
    final List<String> reasons = [
      'Sleeping',
      'Not at home',
      'Feeling better',
      'Side effects',
      'Refused',
      'Other'
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Reason for skipping?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...reasons.map((reason) => ListTile(
                title: Text(reason),
                onTap: () {
                  Navigator.pop(context);
                  _updateStatus('skipped', reason: reason);
                },
              )),
            ],
          ),
        );
      },
    );
  }


  String _formatCountdown() {
    final remaining = _escalationDelaySeconds - _secondsElapsed;
    if (remaining <= 0) return 'Family has been alerted';
    final min = remaining ~/ 60;
    final sec = remaining % 60;
    return 'Family alert in ${min}m ${sec.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isCritical == 1 ? Colors.red.shade900 : Colors.blue.shade900,
      body: SafeArea(
        child: Column(
          children: [
            // Critical Banner
            if (widget.isCritical == 1)
              Container(
                width: double.infinity,
                color: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.warning, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      t(AppStrings.criticalMedicineEn, AppStrings.criticalMedicineHi),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Escalation countdown
            _buildEscalationInfo(),

            const SizedBox(height: 20),

            ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.1).animate(_pulseController),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication, size: 80, color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              t(AppStrings.timeForMedicineEn, AppStrings.timeForMedicineHi).toUpperCase(),
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 16,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    widget.medicineName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.dose,
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  if (widget.foodTiming.isNotEmpty)
                    Chip(
                      label: Text(
                        AppStrings.getFoodTiming(widget.foodTiming),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      backgroundColor: Colors.white,
                    ),
                ],
              ),
            ),
            const Spacer(),
            if (_isSubmitting)
              const CircularProgressIndicator(color: Colors.white)
            else
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildActionButton(
                      label: t(AppStrings.takenEn, AppStrings.takenHi),
                      color: Colors.green,
                      icon: Icons.check_circle,
                      onPressed: () => _updateStatus('taken'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: t(AppStrings.snoozeEn, AppStrings.snoozeHi),
                            color: Colors.orange,
                            icon: Icons.snooze,
                            isSmall: true,
                            onPressed: _snooze,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            label: t(AppStrings.skipEn, AppStrings.skipHi),
                            color: Colors.transparent,
                            icon: Icons.close,
                            isSmall: true,
                            isOutline: true,
                            onPressed: _showSkipDialog,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEscalationInfo() {
    if (_escalationTriggered) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              '⚠️ Family has been notified!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: Colors.orangeAccent, size: 16),
          const SizedBox(width: 8),
          Text(
            _formatCountdown(),
            style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
    bool isSmall = false,
    bool isOutline = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: isSmall ? 20 : 28),
      label: Text(
        label,
        style: TextStyle(
          fontSize: isSmall ? 16 : 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutline ? Colors.transparent : color,
        foregroundColor: Colors.white,
        side: isOutline ? const BorderSide(color: Colors.red, width: 2) : null,
        minimumSize: Size(double.infinity, isSmall ? 60 : 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isOutline ? 0 : 8,
      ),
    );
  }
}
