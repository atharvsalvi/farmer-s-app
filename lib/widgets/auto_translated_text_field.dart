import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:farmer/providers/language_provider.dart';
import 'package:farmer/services/translation_service.dart';

class AutoTranslatedTextField extends StatefulWidget {
  final String? hintText;
  final String? labelText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final InputDecoration? decoration;
  final Widget? prefixIcon;
  final bool filled;
  final Color? fillColor;
  final InputBorder? border;

  const AutoTranslatedTextField({
    super.key,
    this.hintText,
    this.labelText,
    this.controller,
    this.onChanged,
    this.decoration,
    this.prefixIcon,
    this.filled = false,
    this.fillColor,
    this.border,
  });

  @override
  State<AutoTranslatedTextField> createState() => _AutoTranslatedTextFieldState();
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

  @override
  void didUpdateWidget(AutoTranslatedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hintText != widget.hintText || oldWidget.labelText != widget.labelText) {
      _updateTranslations();
    }
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
      onChanged: widget.onChanged,
      decoration: (widget.decoration ?? const InputDecoration()).copyWith(
        hintText: _translatedHintText ?? widget.hintText,
        labelText: _translatedLabelText ?? widget.labelText,
        prefixIcon: widget.prefixIcon,
        filled: widget.filled,
        fillColor: widget.fillColor,
        border: widget.border,
      ),
    );
  }
}
