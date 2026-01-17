import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmer/providers/language_provider.dart';
import 'package:farmer/services/translation_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AutoTranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AutoTranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<AutoTranslatedText> createState() => _AutoTranslatedTextState();
}

class _AutoTranslatedTextState extends State<AutoTranslatedText> {
  String? _translatedText;
  String? _currentLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTranslation();
  }

  @override
  void didUpdateWidget(AutoTranslatedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _updateTranslation();
    }
  }

  Future<void> _updateTranslation() async {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final targetLang = languageProvider.locale.languageCode;

    // Avoid re-translating if language hasn't changed and we have a result
    if (_currentLanguageCode == targetLang && _translatedText != null && widget.text == _translatedText) {
       return;
    }

    if (targetLang == 'en') {
      if (mounted) {
        setState(() {
          _translatedText = widget.text;
          _currentLanguageCode = targetLang;
        });
      }
      return;
    }

    final service = TranslationService();
    final result = await service.translate(widget.text, targetLang);

    if (mounted) {
      setState(() {
        _translatedText = result;
        _currentLanguageCode = targetLang;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _translatedText ?? widget.text,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}
