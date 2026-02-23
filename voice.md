# Voice Screen - Analiza i zmiany

## Plik roboczy: `lib/screens/voice_screen2.dart`
## Plik produkcyjny: `lib/screens/voice_screen.dart`

---

## Data rozpoczęcia: 2026-02-22

---

## ZIDENTYFIKOWANE PROBLEMY

### Problem 1: Brak metody `dispose()` (KRYTYCZNY)
- **Objaw:** Komunikat o zwalnianiu zasobów, wycieki pamięci
- **Przyczyna:** Klasa `_VoiceScreenState` nie ma metody `dispose()`. Przy wyjściu z ekranu:
  - `_picovoiceManager` nigdy nie jest zatrzymywany — mikrofon i silnik Picovoice działają w tle
  - `WakelockPlus` jest wyłączany tylko przez przycisk "back" w AppBar (linia ~7800), nie przy wyjściu systemowym
  - Callbacki (`wakeWordCallback`, `inferenceCallback`) próbują wywoływać `setState()` na zniszczonym widgecie
- **Status:** NAPRAWIONE w voice_screen2.dart

### Problem 2: Wyścig timerów — `Future.delayed` bez anulowania (KRYTYCZNY)
- **Objaw:** Przy szybkim wydawaniu poleceń zaburzona kolejność komend
- **Przyczyna:** `Future.delayed(1500ms)` w `inferenceCallback` (linia ~449 oryginału) nie jest anulowalny. Przy szybkich komendach:
  - Komenda 1 uruchamia `Future.delayed(1500ms)`
  - Komenda 2 przychodzi po 500ms, uruchamia kolejny `Future.delayed(1500ms)`
  - Po 1000ms timer komendy 1 wykonuje się i nadpisuje stan komendy 2
  - Wiele timerów modyfikuje jednocześnie `rhinoText`, `wakeWordDetected`
- **Status:** NAPRAWIONE w voice_screen2.dart — zamieniono na `Timer?` z `.cancel()` przy każdej nowej komendzie

### Problem 3: Brak ochrony współdzielonego stanu (POWAŻNY)
- **Objaw:** Niespójne dane przy szybkich komendach
- **Przyczyna:** `prettyPrintInference()` jest wywoływana wewnątrz `setState()`, ale:
  - Modyfikuje dziesiątki zmiennych stanu (readyApiary, nrXXOfHive, zapisZas itd.)
  - Wywołuje `zapisDoBazy()` który uruchamia łańcuchy `.then()` (async)
  - Nowa komenda może zmienić np. `nrXXOfHive` zanim stary `.then()` zdąży go użyć
- **Status:** DO NAPRAWY — wymaga kolejki komend lub async/await

### Problem 4: Łańcuchy `.then()` bez `await` (POWAŻNY)
- **Objaw:** Operacje bazodanowe wykonują się w nieprzewidywalnej kolejności
- **Przyczyna:** W `zapisDoBazy()` jest 5 poziomów zagnieżdżonych `.then()`:
  ```
  Provider.fetchAndSetHives().then(() →
    Hives.insertHive().then(() →
      Provider.fetchAndSetHives().then(() →
        Apiarys.insertApiary().then(() →
          Provider.fetchAndSetApiarys().then(...)
  ```
  Nic nie jest await-owane. Nowa komenda wchodzi w ten sam kod zanim poprzedni łańcuch się skończy.
- **Status:** DO NAPRAWY — wymaga konwersji na async/await

### Problem 5: `mounted` check niewystarczający (DROBNY)
- **Objaw:** Sporadyczne crashe
- **Przyczyna:** `if (this.mounted)` chroni tylko przed `setState` na zniszczonym widgecie. Nie chroni przed wyścigiem timerów ani niespójnością danych.
- **Status:** NAPRAWIONE w voice_screen2.dart — konsekwentne `if (!mounted) return;` na początku callbacków

---

## WPROWADZONE ZMIANY (voice_screen2.dart)

### Zmiana 1: Dodanie `dispose()` (2026-02-22)
- **Lokalizacja:** po `initState()`, przed `didChangeDependencies()`
- **Co robi:**
  - `_inferenceTimer?.cancel()` — anuluje timer
  - `_picovoiceManager?.stop()` — zatrzymuje nasłuchiwanie
  - `_picovoiceManager?.delete()` — zwalnia zasoby natywne Picovoice
  - `WakelockPlus.disable()` — odblokowanie wygaszania ekranu

### Zmiana 2: Timer zamiast Future.delayed (2026-02-22)
- **Lokalizacja:** `inferenceCallback()`
- **Co robi:**
  - Dodano zmienną `Timer? _inferenceTimer`
  - Każde nowe wywołanie `inferenceCallback` anuluje poprzedni timer (`_inferenceTimer?.cancel()`)
  - Timer tworzony przez `Timer(Duration(...))` zamiast `Future.delayed`
  - Eliminuje wyścig timerów — tylko ostatni timer się wykonuje

### Zmiana 3: Konsekwentne `mounted` checks (2026-02-22)
- **Lokalizacja:** `wakeWordCallback()`, `errorCallback()`, `_stopProcessing()`
- **Co robi:**
  - `if (!mounted) return;` na początku callbacków zamiast warunkowego `if (this.mounted)` opakowującego setState
  - Anulowanie timera w `wakeWordCallback()` — nowe wybudzenie resetuje cykl
  - Anulowanie timera w `_stopProcessing()` — zatrzymanie czyści timer

### Zmiana 4: Zmiana nazwy klasy (2026-02-22)
- `VoiceScreen` → `VoiceScreen2`, `_VoiceScreenState` → `_VoiceScreen2State`
- Route: `/screen-voice2`
- Pozwala na równoległe istnienie z oryginalnym plikiem

---

## PLAN DALSZYCH ZMIAN

### Etap 2: Konwersja `zapisDoBazy()` na async/await
- Zamienić łańcuchy `.then()` na `await`
- Zapewni sekwencyjne wykonywanie operacji bazodanowych
- **Ryzyko:** średnie — wymaga testowania każdej operacji

### Etap 3: Kolejka komend
- Dodać `List<RhinoInference> _commandQueue` i `bool _isProcessingCommand`
- Nowe komendy trafiają do kolejki zamiast bezpośredniego przetwarzania
- Po zakończeniu przetwarzania bierze następną z kolejki
- **Ryzyko:** duże — zmienia logikę przepływu

### Etap 4: Konwersja `zapisInfoDoBazy()` na async/await
- Analogicznie do etapu 2 ale dla funkcji info
- **Ryzyko:** średnie

---

## TESTOWANIE

### Scenariusze testowe dla zmian z etapu 1:
1. **Wyjście z ekranu głosowego** — czy komunikat o zasobach zniknął?
2. **Szybkie komendy (3-4 pod rząd)** — czy timer się nie nakłada?
3. **Wake word w trakcie przetwarzania** — czy anuluje stary timer?
4. **STOP w trakcie przetwarzania** — czy timer jest anulowany?
5. **Wyjście przyciskiem back systemu** — czy dispose() się wykonuje?
6. **Długa sesja (10+ komend)** — stabilność

---

## JAK PRZEŁĄCZYĆ NA VOICE_SCREEN2 DO TESTÓW

W `lib/main.dart` zmienić dwie rzeczy:

**1. Import (linia 13):**
```dart
// BYŁO:
import './screens/voice_screen.dart';
// ZMIEŃ NA:
import './screens/voice_screen2.dart';
```

**2. Route (linia 246):**
```dart
// BYŁO:
VoiceScreen.routeName: (ctx) => VoiceScreen(),
// ZMIEŃ NA:
VoiceScreen2.routeName: (ctx) => VoiceScreen2(),
```

**3. Miejsce wywołania (szukaj `Navigator.pushNamed` z `'/screen-voice'`):**
Zmień route na `'/screen-voice2'` lub `VoiceScreen2.routeName`.

**Po testach — przywróć oryginalne linie.**

---

## NOTATKI
- Plik voice_screen.dart ma ponad 10 000 linii
- Zmienna `zwloka = 1500` ms — czas opóźnienia między komendami
- Picovoice używa callbacków natywnych (z innego wątku) — dlatego `mounted` check jest kluczowy
- Dodano zmienną `_isInferenceProcessing` na przyszłość (etap 3 - kolejka komend)
- PicovoiceManager v3 API: `create()`, `start()`, `stop()`, `delete()`, `reset()`, `contextInfo`
