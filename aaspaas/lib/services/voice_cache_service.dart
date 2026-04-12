import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class VoiceCacheService {
  /// Aggressively downloads and stores Voice Notes in a hidden system directory
  /// Returns the absolute Local Path for the NotificationService to instantly play offline.
  static Future<String?> downloadAndCache(String? url) async {
    if (url == null || url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);
      final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      
      // Use ApplicationDocumentsDirectory to ensure the OS doesn't purge it randomly
      final directory = await getApplicationDocumentsDirectory();
      final hiddenDir = Directory('${directory.path}/.voice_cache'); // Dot prefix hides it from standard media scanners
      
      if (!await hiddenDir.exists()) {
        await hiddenDir.create(recursive: true);
      }
      
      final file = File('${hiddenDir.path}/$filename');
      
      // Fast Short-Circuit: If we already aggressively cached it previously, return 0ms!
      if (await file.exists()) {
        return file.path;
      }
      
      // Silently download in background
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      // Swallow error to prevent crashing, fallback to generic ringtone logic downstream
    }
    return null;
  }
}
