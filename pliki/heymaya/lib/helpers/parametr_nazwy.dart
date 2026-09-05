import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Nazwa parametru do POKAZANIA użytkownikowi.
///
/// Kolumna `info.parametr` trzyma dla leczenia KLUCZE TECHNICZNE - `apivarol`
/// i `biovar` - i te klucze zostają w bazie na zawsze: zależy od nich logika
/// w kilkunastu miejscach (liczniki „ostatnie leczenie w roku"
/// w `infos_screen`, gałęzie formularza w `infos_edit_screen`, zapis głosowy),
/// a import z chmury i tak przywlecze stare wiersze z tymi wartościami.
///
/// Zmienia się WYŁĄCZNIE to, co widać. Do 05.09.2026 wartość kolumny szła na
/// ekran surowa (`info_item.dart`), więc pszczelarz czytał w historii nazwy
/// preparatów - „apivarol" i „biovar" - choć gramatyka głosowa mówi od czasu
/// migracji na Vosk „chemia" i „paski". Ta funkcja jest jedynym miejscem,
/// w którym klucz zamienia się w nazwę, więc ręczne wpisy i głosowe pokazują
/// się identycznie.
///
/// Klucz nieznany wraca BEZ ZMIAN, razem z ewentualną spacją na początku:
/// część zapisów trzyma ją celowo (patrz `" excluder -"` w painterze ramek),
/// a dopasowanie i tak idzie po [String.trim].
String nazwaParametru(BuildContext context, String parametr) {
  final l = AppLocalizations.of(context)!;
  switch (parametr.trim()) {
    case 'apivarol':
      return l.apivarolChemistry;
    case 'biovar':
      return l.treatmentStrips;
    default:
      return parametr;
  }
}
