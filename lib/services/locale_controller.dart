import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController {
  LocaleController._();
  static final instance = LocaleController._();
  final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language');
    if (const ['tr', 'en', 'pl'].contains(code)) locale.value = Locale(code!);
  }

  Future<void> setLocale(Locale? value) async {
    locale.value = value;
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('language');
    } else {
      await prefs.setString('language', value.languageCode);
    }
  }
}
