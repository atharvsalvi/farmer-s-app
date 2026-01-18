import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmer/providers/language_provider.dart';
import 'package:farmer/services/translation_service.dart';

class AutoTranslatedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final bool filled;
  final Color? fillColor;
  final InputBorder? border;

  const AutoTranslatedTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.filled = false,
    this.fillColor,
    this.border,
  });

  @override
  State<AutoTranslatedTextField> createState() =>
      _AutoTranslatedTextFieldState();
}

class _AutoTranslatedTextFieldState extends State<AutoTranslatedTextField> {
  String? _translatedHintText;
  String? _translatedLabelText;
  String? _currentLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTranslations();
  }

  Future<void> _updateTranslations() async {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final targetLang = languageProvider.locale.languageCode;

    if (_currentLanguageCode == targetLang) return;

    if (targetLang == 'en') {
      if (mounted) {
        setState(() {
          _translatedHintText = widget.hintText;
          _translatedLabelText = widget.labelText;
          _currentLanguageCode = targetLang;
        });
      }
      return;
    }

    final service = TranslationService();
    String? newHint;
    String? newLabel;

    if (widget.hintText != null) {
      newHint = await service.translate(widget.hintText!, targetLang);
    }
    if (widget.labelText != null) {
      newLabel = await service.translate(widget.labelText!, targetLang);
    }

    if (mounted) {
      setState(() {
        _translatedHintText = newHint ?? widget.hintText;
        _translatedLabelText = newLabel ?? widget.labelText;
        _currentLanguageCode = targetLang;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: _translatedHintText ?? widget.hintText,
        labelText: _translatedLabelText ?? widget.labelText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        filled: widget.filled,
        fillColor: widget.fillColor,
        border: widget.border,
      ),
    );
  }
}
