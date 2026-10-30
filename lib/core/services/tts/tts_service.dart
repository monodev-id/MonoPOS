import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/result.dart';
import '../../constants/constants.dart';
import '../../utilities/console_logger.dart';
import '../../utilities/number_to_words_id.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  final SharedPreferences _sharedPreferences;

  TtsService(this._sharedPreferences);

  void setLocale(String languageCode) {
    final locale = languageCode == 'id' ? 'id-ID' : 'en-US';
    _tts.setLanguage(locale);
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  bool get isEnabled {
    final dana = _sharedPreferences.getBool(Constants.danaTtsEnabled);
    if (dana != null) return dana;
    return _sharedPreferences.getBool(Constants.klikQrisTtsEnabled) ?? true;
  }

  Future<Result<void>> playCashRegister() async {
    try {
      cl('[TTS] playing cash register sound');
      await _player.play(AssetSource('audio/cashmasuk.mp3'));
      return Result.success(data: null);
    } catch (e) {
      cl('[TTS] play sound error: $e');
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> speakAmount(int amount) async {
    if (!isEnabled) {
      cl('[TTS] disabled, skip speaking');
      return Result.success(data: null);
    }

    try {
      final text = 'diterima ${terbilang(amount)} rupiah';
      cl('[TTS] speaking: $text');
      await _tts.speak(text);
      return Result.success(data: null);
    } catch (e) {
      cl('[TTS] speak error: $e');
      return Result.failure(error: e.toString());
    }
  }
}
