import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class VoiceRecorderWidget extends StatefulWidget {
  final Function(String?) onRecordingComplete;

  const VoiceRecorderWidget({super.key, required this.onRecordingComplete});

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  bool _isRecording = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (!_isRecorderInitialized) return;

    if (_isRecording) {
      // STOP recording
      final path = await _recorder.stopRecorder();
      setState(() {
        _isRecording = false;
        _filePath = path;
      });
      widget.onRecordingComplete(_filePath);
    } else {
      // START recording
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/medicine_note_${DateTime.now().millisecondsSinceEpoch}.aac';
      
      await _recorder.startRecorder(
        toFile: targetPath,
        codec: Codec.aacADTS,
      );
      
      setState(() {
        _isRecording = true;
        _filePath = null; // Clear previous while new one records
      });
      widget.onRecordingComplete(null);
    }
  }

  Future<void> _clearRecording() async {
    if (_filePath != null) {
      final file = File(_filePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    setState(() => _filePath = null);
    widget.onRecordingComplete(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isRecording ? Colors.red.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isRecording ? Colors.red.shade200 : Colors.blue.shade200,
          width: 2
        )
      ),
      child: Row(
        children: [
          GestureDetector(
             onTap: _toggleRecording,
             child: CircleAvatar(
               radius: 30,
               backgroundColor: _isRecording ? Colors.red : Theme.of(context).primaryColor,
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
                  _isRecording 
                      ? "Recording... (Max 30s)" 
                      : (_filePath != null ? "Voice Note Saved!" : "Add a caring Voice Note"),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isRecording ? Colors.red : Colors.black87
                  ),
                ),
                Text(
                  _filePath != null 
                    ? "This will play when the alarm rings."
                    : "Tap mic to record a loving message.",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
          if (_filePath != null && !_isRecording)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _clearRecording,
            )
        ],
      ),
    );
  }
}
