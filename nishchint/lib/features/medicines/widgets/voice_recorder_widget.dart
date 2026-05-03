import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../data/api_service.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final int? scheduleId;
  final VoidCallback? onSaved;
  final Function(String?)? onRecordingComplete; // For backward compatibility

  const VoiceRecorderWidget({
    super.key, 
    this.scheduleId, 
    this.onSaved,
    this.onRecordingComplete,
  });

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> with TickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  late AudioPlayer _audioPlayer;
  final ApiService _apiService = ApiService();
  
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isUploading = false;
  String? _filePath;
  
  late AnimationController _waveformController;
  final List<double> _waveformHeights = List.filled(15, 5.0);
  final Random _random = Random();
  
  Timer? _timer;
  int _secondsElapsed = 0;

  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initRecorder();
    
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(() {
      if (_isRecording) {
        setState(() {
          for (int i = 0; i < _waveformHeights.length; i++) {
            _waveformHeights[i] = 5.0 + _random.nextDouble() * 25.0;
          }
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _showPermissionDialog();
      return;
    }
    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Permission Needed"),
        content: const Text("Microphone permission is needed to record your voice reminder. Please enable it in settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(ctx);
            },
            child: const Text("Settings"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _audioPlayer.dispose();
    _waveformController.dispose();
    _timer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized) {
      await _initRecorder();
      if (!_isRecorderInitialized) return;
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = 'voice_temp_${widget.scheduleId ?? DateTime.now().millisecondsSinceEpoch}.m4a';
    final path = '${tempDir.path}/$fileName';

    await _recorder.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,
    );

    _waveformController.repeat();
    _startTimer();
    
    setState(() {
      _isRecording = true;
      _filePath = null;
      _secondsElapsed = 0;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stopRecorder();
    _waveformController.stop();
    _timer?.cancel();
    
    setState(() {
      _isRecording = false;
      _filePath = path;
    });

    if (widget.onRecordingComplete != null) {
      widget.onRecordingComplete!(_filePath);
    }
  }

  Future<void> _playPreview() async {
    if (_filePath == null) return;
    if (_isPlaying) {
      await _audioPlayer.stop();
    } else {
      await _audioPlayer.play(DeviceFileSource(_filePath!));
    }
  }

  Future<void> _reRecord() async {
    if (_filePath != null) {
      final file = File(_filePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    setState(() {
      _filePath = null;
      _secondsElapsed = 0;
      _messageController.clear();
    });
    if (widget.onRecordingComplete != null) {
      widget.onRecordingComplete!(null);
    }
  }

  Future<void> _saveAndUpload() async {
    if (_filePath == null || widget.scheduleId == null) return;

    setState(() => _isUploading = true);
    try {
      await _apiService.uploadVoiceReminder(
        widget.scheduleId!,
        _filePath!,
        _messageController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Voice reminder saved!"), backgroundColor: Colors.green),
        );
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _formatDuration(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        children: [
          if (_filePath == null) ...[
            // RECORDING STATE
            Row(
              children: [
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isRecording ? "Recording..." : "Add a voice note",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      if (_isRecording)
                        Row(
                          children: [
                            Text(_formatDuration(_secondsElapsed), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: _waveformHeights.map((h) => Container(
                                  width: 3,
                                  height: h,
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(200),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                )).toList(),
                              ),
                            ),
                          ],
                        )
                      else
                        Text("Tap to record instructions", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // PREVIEW & UPLOAD STATE
            Row(
              children: [
                IconButton(
                  onPressed: _playPreview,
                  icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled),
                  iconSize: 48,
                  color: Theme.of(context).primaryColor,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Recorded Message", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_formatDuration(_secondsElapsed), style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _reRecord,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("Re-record"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Type what you said, e.g. Papa, morning BP tablet lena",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 2,
            ),
            if (widget.scheduleId != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveAndUpload,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Save Voice Reminder"),
                ),
              ),
            ]
          ],
        ],
      ),
    );
  }
}

