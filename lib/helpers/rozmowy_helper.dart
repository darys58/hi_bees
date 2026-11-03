// Stan rozmowy telefonicznej na iPhonie (03.11.2026) - do nakładki
// "Polecenia dla Siri" na ekranie sterowania głosem.
//
// Strona natywna: AppDelegate.swift, CXCallObserver (CallKit) na kanale
// [_kanal]. Obserwator widzi też rozmowy komórkowe - nie odbiera ich, tylko
// zgłasza zmiany. Wysyła 'dzwoni' (przychodząca, jeszcze nie odebrana),
// 'trwa' (połączona) albo '' (brak rozmowy).
//
// Tylko iOS: na Androidzie ekran rozmowy i tak zasłania aplikację, a Siri nie
// ma. Drzewo heymaya (Android) nie ma tego kanału w AppDelegate - stąd
// warunek Platform.isIOS i ciche łapanie MissingPluginException.

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RozmowyHelper {
  static const MethodChannel _kanal = MethodChannel('hej_maja/rozmowy');

  /// 'dzwoni' / 'trwa' / null (brak rozmowy).
  static final ValueNotifier<String?> stan = ValueNotifier<String?>(null);

  static bool _uruchomiony = false;

  /// Podłącza nasłuch zmian i pobiera bieżący stan - na wypadek, gdyby ekran
  /// głosu otwarto w trakcie rozmowy. Kolejne wywołania tylko odświeżają stan.
  static Future<void> start() async {
    if (!Platform.isIOS) return;
    if (!_uruchomiony) {
      _uruchomiony = true;
      _kanal.setMethodCallHandler((call) async {
        if (call.method == 'rozmowa') stan.value = _norm(call.arguments);
      });
    }
    try {
      stan.value = _norm(await _kanal.invokeMethod<String>('stan'));
    } catch (e) {
      debugPrint('ROZMOWY: brak stanu rozmowy: $e');
    }
  }

  static String? _norm(Object? s) =>
      (s == 'dzwoni' || s == 'trwa') ? s as String : null;
}
