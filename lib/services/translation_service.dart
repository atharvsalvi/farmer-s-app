import 'package:translator/translator.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final GoogleTranslator _translator = GoogleTranslator();
  final Map<String, String> _cache = {};

  Future<String> translate(String text, String targetLanguage) async {
    if (targetLanguage == 'en') return text; // No translation needed for English

    final cacheKey = '$text|$targetLanguage';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final translation = await _translator.translate(text, to: targetLanguage);
      final result = translation.text;
      _cache[cacheKey] = result;
      return result;
    } catch (e) {
      print('Translation Error: $e');
      return text; // Fallback to original text on error
    }
  }
}
