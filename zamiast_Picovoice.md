# Alternatywy dla Picovoice w Hi Bees — analiza (06.04.2026)

## Kontekst

Aplikacja Hi Bees wykorzystuje **Picovoice** (Porcupine + Rhino) do sterowania głosowego
w pliku `lib/screens/voice_screen2.dart` (10 150 linii kodu).

Cel analizy: czy nowe technologie platformowe (Android AppFunctions, iOS App Intents)
mogą w przyszłości zastąpić Picovoice jako silnik rozpoznawania poleceń głosowych.

---

## Obecna architektura głosowa (Picovoice)

### Komponenty
- **Porcupine** — wake word "Hey Maya" (pliki `.ppn`)
- **Rhino** — speech-to-intent, on-device NLU (pliki `.rhn`)
- **Modele językowe** — osobne pliki `.pv` dla PL i EN
- **Pliki assetów:** 12 plików w `assets/contexts/`, `assets/keyword_files/`, `assets/porcupine/`, `assets/rhino/`

### Skala
| Element | Ilość |
|---------|-------|
| Intencji (intents) | 18 |
| Slotów (parametrów) | ~120 |
| Główna funkcja `prettyPrintInference()` | 3 633 linii |
| Łącznie voice_screen2.dart | 10 150 linii |
| Języki | PL + EN |

### 18 intencji
| Intent | Opis | Przybliżony zakres linii |
|--------|------|--------------------------|
| setStore | Zasoby na ramce (trutnie, czerw, jaja, pierzga, miód...) | 502–1000 |
| setFrame | Operacje na ramce (otwórz/zamknij/wstaw, numer, rozmiar) | 1001–1134 |
| setChange | Zmiana pozycji ramki | 1135–1238 |
| setMoveBody | Przenoszenie korpusu do innego ula | 1239–1448 |
| setHive | Wybór ula, stan (otwórz/zamknij), pogoda | 1449–1664 |
| setBody | Korpus — stan, numer, pozycja | 1665–1756 |
| setHalfBody | Półkorpus — stan, numer, pozycja | 1757–1844 |
| setQueen | Matka — dane, znakowanie, jakość, data urodzenia | 1845–1989 |
| setEquipment | Wyposażenie (ilość ramek, krata, dennica, poławiacz) | 1990–2102 |
| setFeeding | Dokarmianie (syropy 1:1, 3:2, candy, inwert) | 2103–2294 |
| setTreatment | Leczenie (apivarol, biovar, kwasy, varroa) | 2295–2541 |
| setColony | Stan rodziny (siła, osyp) | 2542–2709 |
| setHelp | Pomoc kontekstowa (dialogi) | 2710–3499 |
| setDate | Ustawianie daty przeglądu | 3500–3596 |
| setHarvest | Miodobranie (miód/wosk/propolis) | 3597–3838 |
| setFrames | Zakres ramek (od–do) | 3839–3938 |
| setAllHives | Operacje na wszystkich ulach | 3939–4005 |
| setApiary | Wybór pasieki | 4006–4107 |

### Kluczowa cecha: hierarchia stanów sesji
Użytkownik buduje kontekst krok po kroku, a system go pamięta:
```
readyApiary → readyHive → readyBody → readyFrame → readyStory/readyInfo
```
Przykład sesji:
1. "Pasieka jeden" → readyApiary = true
2. "Ul pięć" → readyHive = true
3. "Korpus dwa" → readyBody = true
4. "Ramka trzy" → readyFrame = true
5. "Jaja dwa, czerw trzy" → zapis do bazy

---

## Android AppFunctions (Android 16+)

### Czym jest
- Nowa funkcja platformy Android 16 + biblioteka Jetpack (`androidx.appfunctions`)
- Umożliwia udostępnianie funkcji aplikacji na zewnątrz
- Agent AI (np. Gemini) może odkrywać i wywoływać te funkcje z parametrami
- Lokalny odpowiednik "tool use" / MCP na poziomie systemu operacyjnego

### Jak działa
1. Definiujesz funkcję z adnotacją `@AppFunction` (np. `setFrameResources(hiveNr, frameNr, eggs, brood...)`)
2. System indeksuje te funkcje (XML schema)
3. Agent AI rozumie naturalny język → mapuje na funkcję + parametry → wywołuje

### Zalety dla Hi Bees
- **Eliminacja ~8000 linii switch/case** — AI sam mapuje mowę na parametry
- **Elastyczność języka** — użytkownik może mówić dowolnie, LLM zrozumie
- **Wielojęzyczność z natury** — brak potrzeby osobnych modeli per język
- **Łatwe dodawanie nowych komend** — nowa funkcja z adnotacją, bez edycji 10k linii
- **Brak kosztów licencji Picovoice**

### Ograniczenia
- **Tylko Android 16+** — iOS bez tego
- **Alpha / experimental** — API się zmienia
- **Prawdopodobnie wymaga sieci** — zależy od agenta AI
- **Brak własnego wake word** — systemowy agent (np. "Hey Google")
- **Flutter bridge** — wymaga Platform Channel (natywny Kotlin)
- **Brak stanu sesji** — każde wywołanie jest niezależne (vs. hierarchia stanów Picovoice)

### Status (kwiecień 2026)
Jeszcze nie do użycia w produkcji. Kierunek strategiczny Google (AI-first Android).

---

## iOS App Intents (iOS 16+)

### Czym jest
- Framework Apple do udostępniania akcji aplikacji dla Siri i Shortcuts
- Definiujesz `AppIntent` w Swift z parametrami (`@Parameter`)
- Siri wywołuje intencję głosowo, Shortcuts — automatyzacją

### Porównanie z AppFunctions

| Cecha | AppFunctions (Android) | App Intents (iOS) |
|-------|----------------------|-------------------|
| Kto wywołuje | Dowolny autoryzowany agent AI | Tylko Siri / Apple Intelligence |
| Discovery | Agent dynamicznie odkrywa funkcje | Zamknięty katalog |
| Parsowanie mowy | LLM — dowolna forma | Sztywniejsze frazy |
| Cross-app orchestration | Tak (łańcuch wywołań) | Ograniczone |
| Otwarty dla 3rd-party | Tak | Nie |

### Czego App Intents nie ma (vs AppFunctions)
- Otwarty dostęp dla zewnętrznych agentów AI
- Dynamiczne odkrywanie funkcji przez AI
- LLM-driven parameter matching (dowolna forma wypowiedzi)
- Kompozycja wielu funkcji w łańcuch

### Czy App Intents może zastąpić Picovoice na iOS?

**NIE** — z następujących powodów:

| Cecha | Picovoice | App Intents |
|-------|-----------|-------------|
| Wake word "Hey Maya" | Tak | Nie — tylko "Siri" |
| Ciągłe nasłuchiwanie (sesja) | Tak | Nie — jednorazowe wywołanie |
| Hierarchia stanów | Tak | Nie — brak stanu sesji |
| Offline 100% | Tak | Częściowo |
| Polskie słownictwo pszczelarskie | Wytrenowany model | Siri może nie rozpoznać |
| Cross-platform | iOS + Android | Tylko iOS |

### Ale App Intents mógłby UZUPEŁNIĆ Picovoice

Dla prostych operacji wywołanych z poziomu Siri/Shortcuts:

| Operacja | Nadaje się? | Powód |
|----------|------------|-------|
| Dodaj miodobranie | Tak | Mało parametrów |
| Pogoda dla pasieki | Tak | 1 parametr |
| Pokaż notatki | Tak | Nawigacja |
| Ile uli w pasiece? | Tak | Proste zapytanie |
| Dokarmianie | Częściowo | 3–4 parametry |
| Zapis zasobów na ramce | Nie | Za dużo parametrów + sesja |
| Przegląd ramek | Nie | Wymaga ciągłego dialogu |

### Implementacja (koncept)
- Intencje definiowane w natywnym Swift w `ios/Runner/Intents/`
- Komunikacja z Flutterem: wspólna baza SQLite (hibees.db) lub MethodChannel
- Brak oficjalnego pakietu Flutter — wymaga ręcznego bridge'a
- Frazy Siri lokalizowane dla PL/EN

---

## Wnioski i strategia

### Na teraz
**Picovoice zostaje** — jedyne rozwiązanie łączące:
- Własny wake word ("Hey Maya")
- Ciągłą sesję z hierarchią stanów
- 100% offline
- Cross-platform (iOS + Android)
- Wytrenowany model na polskie słownictwo pszczelarskie

### Przygotowanie na przyszłość
**Refaktoryzacja voice_screen2.dart** — wydzielenie logiki biznesowej z 10k-liniowego
pliku do czystych, reużywalnych funkcji Dart:

```dart
// Przykład docelowej struktury:
class VoiceActions {
  Future<void> setFrameResources({required int apiary, required int hive,
      required int body, required int frame, int? eggs, int? brood, ...});
  Future<void> feedHive({required int hive, required String type, required double amount});
  Future<void> setTreatment({required int hive, required String treatment, ...});
  Future<void> recordHarvest({required int apiary, double? honeyKg, ...});
  // ... pozostałe akcje
}
```

Te same funkcje posłużą jako backend dla:
- **Picovoice** (obecne) — wywoływane z switch/case
- **AppFunctions** (Android, przyszłość) — eksponowane przez @AppFunction + Platform Channel
- **App Intents** (iOS, przyszłość) — eksponowane przez Swift AppIntent + MethodChannel/SQLite
- **Dowolny przyszły agent AI**

### Kiedy warto wrócić do tematu
- Gdy **AppFunctions wyjdzie z alpha** i będzie dostępne na Android 16 w produkcji
- Gdy **Apple Intelligence** (iOS 18+) rozszerzy App Intents o lepsze AI discovery
- Gdy pojawi się **pakiet Flutter** dla App Intents lub AppFunctions
- Gdy Google/Apple dodadzą **obsługę sesji stanowych** (hierarchia kontekstu)

---

## Linki i zasoby
- Picovoice Console: https://console.picovoice.ai/
- Android AppFunctions: `androidx.appfunctions` (Jetpack, alpha)
- Apple App Intents: developer.apple.com/documentation/appintents
- Obecny plik: `lib/screens/voice_screen2.dart` (10 150 linii)
- Modele: `assets/contexts/`, `assets/keyword_files/`, `assets/porcupine/`, `assets/rhino/`
