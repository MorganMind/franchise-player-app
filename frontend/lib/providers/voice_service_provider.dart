import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/voice_service.dart';

final voiceServiceProvider = ChangeNotifierProvider<VoiceService>((ref) {
  return VoiceService();
}); 