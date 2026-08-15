
import Flutter
import UIKit
import AVFoundation

// vosk_api.h is exposed via the pod's public headers AND the module map.
//
// ============================================================================
// KOPIA ZWENDOROWANA (hi_bees, 29.07.2026) — vosk_flutter_service 0.1.2
// ----------------------------------------------------------------------------
// Powód: oryginał psuł RÓWNOLEGŁE nagrywanie na iOS. Pomiar (analiza nagrań
// próbka po próbce, katalog pliki/): przy karmieniu recognizera w tle nagranie
// z AVAudioRecorder miało 74,3 % cyfrowej ciszy i 60 dziur po ~185 ms;
// to samo nagrywanie bez karmienia — 1,7 % zer i ZERO dziur.
//
// Znalezione dwie przyczyny (obie usunięte niżej):
//
// 1. `configureAudioSession()` był wołany przy KAŻDYM wywołaniu `recognizer.*`
//    — czyli przy naszym strumieniu 5 razy na sekundę — i za każdym razem robił
//    `setCategory(...)` + `setActive(true)`. Przestawianie aktywnej sesji audio
//    w trakcie nagrywania przerywa wejście; AVAudioRecorder pisze dalej po osi
//    czasu, więc przerwa ląduje w pliku jako cyfrowa cisza. To tłumaczy wzór
//    „~23 ms sygnału na ~171 ms" (1 cykl I/O na 7) i to, że pozycje dziur są
//    powtarzalne co do bajtu. Recognizer nie dotyka mikrofonu, więc dla
//    `recognizer.*` sesja nie jest konfigurowana W OGÓLE; dla `speechService.*`
//    (wbudowana ścieżka audio wtyczki) konfiguracja jest jednorazowa.
//
// 2. Dekodowanie szło na GŁÓWNYM WĄTKU — `vosk_recognizer_accept_waveform`,
//    `_result`, `_partial_result` i `_final_result` wykonywały się wprost
//    w handlerze `FlutterMethodCall`. Pełny model PL (244 k słów) kosztuje
//    tyle, że główny wątek stoi prawie bez przerwy → zacinający się UI.
//    Teraz cała praca recognizera idzie na własną kolejkę SZEREGOWĄ
//    `voskQueue`, a na main wraca tylko gotowy wynik (`result(...)`).
//    Szeregowa, bo vosk_recognizer_* nie jest bezpieczny wielowątkowo dla
//    jednego recognizera; przy okazji zastępuje flagę `_feeding` po stronie
//    Dart (kanał nie znosił nakładania wywołań).
//
// 3. Z gorącej ścieżki wycięty `NSLog` + skan bajt po bajcie przy każdej
//    porcji (przy dziurawym sygnale to była pętla dodatniego sprzężenia:
//    im więcej zer, tym więcej logowania). Logi zostają pod flagą
//    `voskVerboseLogging`, domyślnie wyłączoną.
//
// Nietknięte co do zasady: `SpeechService` (wbudowany tap AVAudioEngine) — MA
// ZNANY BŁĄD (tap w formacie sprzętowym 48 kHz float podawany wprost do Vosk,
// bez AVAudioConverter; skala i częstotliwość się nie zgadzają → szum). Nie
// używamy go — audio zbiera pakiet `record`, a my karmimy
// `acceptWaveformBytes`. Zeszło z niego tylko dekodowanie z wątku audio na
// `voskQueue`; poprawna konwersja formatu wciąż do napisania, gdyby był
// potrzebny.
//
// Aktualizacja pakietu z pub.dev = nadpisanie tego pliku, więc te zmiany
// trzeba nanieść ponownie. Dlatego kopia jest w repo (packages/), a nie
// łatka na .pub-cache.
//
// Android: `VoskFlutterPlugin.java` miał tę samą wadę (accept/result wołane
// wprost w `onMethodCall`, czyli na wątku UI). Naprawione 13.08.2026 tym samym
// sposobem — kolejka szeregowa `voskQueue`, opis w HI_BEES_PATCH.md.
// ============================================================================

/// Szczegółowe logi wtyczki. Domyślnie WYŁĄCZONE — logowanie przy każdej
/// porcji audio (5/s) samo w sobie obciąża główny wątek.
private let voskVerboseLogging = false

private func voskLog(_ message: @autoclosure () -> String) {
    if voskVerboseLogging {
        NSLog("VOSK: %@", message())
    }
}

public class VoskFlutterPlugin: NSObject, FlutterPlugin {
    var channel: FlutterMethodChannel?

    // Maps to store pointers to C objects
    // Key: Path (String) -> Value: OpaquePointer (VoskModel*)
    private var modelsMap = [String: OpaquePointer]()
    private var speakerModelsMap = [String: OpaquePointer]()
    // Key: ID (Int) -> Value: OpaquePointer (VoskRecognizer*)
    // UWAGA: ta mapa jest własnością `voskQueue` — czytamy i piszemy ją
    // WYŁĄCZNIE z tej kolejki. Mapy modeli zostają przy głównym wątku.
    private var recognizersMap = [Int: OpaquePointer]()

    /// Kolejka szeregowa dla całej pracy recognizera. Szeregowa, bo jeden
    /// recognizer nie może być używany z dwóch wątków naraz.
    private let voskQueue = DispatchQueue(label: "org.vosk.recognizer", qos: .userInitiated)

    /// Sesja audio konfigurowana jednorazowo i tylko dla wbudowanej ścieżki
    /// `speechService.*`.
    private var audioSessionConfigured = false

    // Audio service
    private var speechService: SpeechService?

    public static func register(with registrar: FlutterPluginRegistrar) {
        voskLog("Registering VoskFlutterPlugin")
        let channel = FlutterMethodChannel(name: "vosk_flutter", binaryMessenger: registrar.messenger())
        let instance = VoskFlutterPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    /// Wykonuje pracę recognizera na `voskQueue` i oddaje wynik na głównym
    /// wątku. Zwrócona wartość idzie wprost do `result(...)`, więc może to być
    /// zarówno wynik, jak i `FlutterError`.
    private func onVoskQueue(_ result: @escaping FlutterResult, _ work: @escaping () -> Any?) {
        voskQueue.async {
            let value = work()
            DispatchQueue.main.async { result(value) }
        }
    }

    /// To samo co `onVoskQueue`, tylko z odszukaniem recognizera po
    /// `recognizerId`. Mapa jest czytana już na `voskQueue` — nigdzie indziej
    /// się jej nie dotyka.
    private func withRecognizer(
        _ args: Any?,
        _ result: @escaping FlutterResult,
        _ work: @escaping (OpaquePointer) -> Any?
    ) {
        voskQueue.async {
            let value: Any?
            if let args = args as? [String: Any], let recognizerId = args["recognizerId"] as? Int {
                if let recognizer = self.recognizersMap[recognizerId] {
                    value = work(recognizer)
                } else {
                    value = FlutterError(code: "NO_RECOGNIZER", message: "Recognizer not found", details: nil)
                }
            } else {
                value = FlutterError(code: "WRONG_ARGS", message: "Missing arguments", details: nil)
            }
            DispatchQueue.main.async { result(value) }
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        voskLog("Handling method \(call.method)")

        // Sesję audio konfiguruje tylko wbudowany SpeechService. Recognizer nie
        // dotyka mikrofonu, a przestawianie sesji w trakcie cudzego nagrywania
        // wycina dziury w nagraniu (patrz nagłówek pliku).
        if call.method.starts(with: "speechService.") {
            configureAudioSessionOnce()
        }

        switch call.method {
        case "model.create":
            guard let modelPath = call.arguments as? String else {
                result(FlutterError(code: "WRONG_ARGS", message: "Model path missing", details: nil))
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                // Ensure usage of C API
                // vosk_model_new takes const char *
                if let model = vosk_model_new(modelPath) {
                    DispatchQueue.main.async {
                        self.modelsMap[modelPath] = model
                        self.channel?.invokeMethod("model.created", arguments: modelPath)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.channel?.invokeMethod("model.error", arguments: ["modelPath": modelPath, "error": "Failed to load model"])
                    }
                }
            }
            result(nil)

        case "speakerModel.create":
             guard let modelPath = call.arguments as? String else {
                result(FlutterError(code: "WRONG_ARGS", message: "Speaker model path missing", details: nil))
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                if let model = vosk_spk_model_new(modelPath) {
                    DispatchQueue.main.async {
                        self.speakerModelsMap[modelPath] = model
                        self.channel?.invokeMethod("speakerModel.created", arguments: modelPath)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.channel?.invokeMethod("speakerModel.error", arguments: ["modelPath": modelPath, "error": "Failed to load speaker model"])
                    }
                }
            }
            result(nil)

        case "recognizer.create":
            guard let args = call.arguments as? [String: Any],
                  let sampleRate = args["sampleRate"] as? NSNumber, // Float passing might be NSNumber
                  let modelPath = args["modelPath"] as? String else {
                result(FlutterError(code: "WRONG_ARGS", message: "Missing required arguments", details: nil))
                return
            }

            // modelsMap należy do głównego wątku — czytamy ją tutaj, a na
            // kolejkę przekazujemy już sam wskaźnik.
            guard let model = modelsMap[modelPath] else {
                result(FlutterError(code: "NO_MODEL", message: "Model not found: \(modelPath)", details: nil))
                return
            }

            let rate = sampleRate.floatValue
            let grammar = args["grammar"] as? String

            // Budowa recognizera z gramatyką potrafi trwać sekundy — też na
            // kolejkę, żeby nie blokować UI.
            onVoskQueue(result) {
                let recognizerId = (self.recognizersMap.keys.max() ?? 0) + 1

                var recognizer: OpaquePointer?
                if let grammar = grammar {
                    recognizer = vosk_recognizer_new_grm(model, rate, grammar)
                } else {
                    recognizer = vosk_recognizer_new(model, rate)
                }

                if let rec = recognizer {
                    self.recognizersMap[recognizerId] = rec
                    return recognizerId
                }
                return FlutterError(code: "CREATION_ERROR", message: "Failed to create recognizer", details: nil)
            }

        case "recognizer.setMaxAlternatives":
            guard let args = call.arguments as? [String: Any],
                  let maxAlternatives = args["maxAlternatives"] as? Int else {
                result(FlutterError(code: "WRONG_ARGS", message: "Missing arguments", details: nil))
                return
            }
            withRecognizer(call.arguments, result) { recognizer in
                vosk_recognizer_set_max_alternatives(recognizer, Int32(maxAlternatives))
                return nil
            }

        case "recognizer.setWords":
            guard let args = call.arguments as? [String: Any],
                  let words = args["words"] as? Bool else {
                result(FlutterError(code: "WRONG_ARGS", message: "Missing arguments", details: nil))
                return
            }
            withRecognizer(call.arguments, result) { recognizer in
                vosk_recognizer_set_words(recognizer, words ? 1 : 0)
                return nil
            }

        case "recognizer.setPartialWords":
             // API might not support partial words config explicitly in same way, or it's implied?
             // Checking vosk_api.h: vosk_recognizer_set_words exists. set_partial_words does NOT appear in standard header usually.
             // It might be confused with Words. Or maybe I missed it.
             // For now acting as no-op or mapping to words if appropriate, but safest is no-op if not in C API.
            result(nil)

        case "recognizer.acceptWaveform", "recognizer.acceptWaveForm":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "WRONG_ARGS", message: "Missing arguments", details: nil))
                return
            }

            guard let bytes = args["bytes"] as? FlutterStandardTypedData else {
                if args["floats"] is [Float] {
                    result(FlutterError(code: "WRONG_ARGS", message: "Floats not implemented in swift bridge yet", details: nil))
                } else {
                    result(FlutterError(code: "WRONG_ARGS", message: "Data missing", details: nil))
                }
                return
            }

            // Najgorętsza ścieżka: 5 wywołań na sekundę, każde to pełne
            // dekodowanie porcji 0,2 s. Zero logowania, zero skanowania danych.
            withRecognizer(call.arguments, result) { recognizer in
                let data = bytes.data
                let length = Int32(data.count)
                let res = data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> Int32 in
                    if let baseAddress = buffer.baseAddress {
                        // vosk_recognizer_accept_waveform expects const char *
                        let charPtr = baseAddress.assumingMemoryBound(to: CChar.self)
                        return vosk_recognizer_accept_waveform(recognizer, charPtr, length)
                    }
                    return -1
                }

                // Result: 1 if silence occurred, 0 if decoding continues, -1 exception
                return res == 1
            }

        case "recognizer.getResult":
            withRecognizer(call.arguments, result) { recognizer in
                if let res = vosk_recognizer_result(recognizer) {
                    return String(cString: res)
                }
                return "{}"
            }

        case "recognizer.getPartialResult":
            withRecognizer(call.arguments, result) { recognizer in
                if let res = vosk_recognizer_partial_result(recognizer) {
                    return String(cString: res)
                }
                return "{\"partial\": \"\"}"
            }

        case "recognizer.getFinalResult":
            withRecognizer(call.arguments, result) { recognizer in
                if let res = vosk_recognizer_final_result(recognizer) {
                    return String(cString: res)
                }
                return "{\"text\": \"\"}"
            }

        case "recognizer.reset":
            withRecognizer(call.arguments, result) { recognizer in
                vosk_recognizer_reset(recognizer)
                return nil
            }

        case "recognizer.close":
            guard let args = call.arguments as? [String: Any],
                  let recognizerId = args["recognizerId"] as? Int else {
                result(nil)
                return
            }
            // Zwolnienie musi poczekać na porcje już zakolejkowane — kolejka
            // jest szeregowa, więc dzieje się to samo z siebie.
            onVoskQueue(result) {
                if let recognizer = self.recognizersMap[recognizerId] {
                    vosk_recognizer_free(recognizer)
                    self.recognizersMap.removeValue(forKey: recognizerId)
                }
                return nil
            }

        case "speechService.init":
            guard let args = call.arguments as? [String: Any],
                  let recognizerId = args["recognizerId"] as? Int,
                  let sampleRate = args["sampleRate"] as? NSNumber else {
                result(FlutterError(code: "WRONG_ARGS", message: "Missing arguments", details: nil))
                return
            }

            if speechService != nil {
                result(FlutterError(code: "INITIALIZE_FAIL", message: "SpeechService already initialized", details: nil))
                return
            }

            guard let channel = channel else {
                result(FlutterError(code: "INITIALIZE_FAIL", message: "Method channel missing", details: nil))
                return
            }

            // Mapa recognizerów należy do voskQueue — stąd odczyt przez nią.
            voskQueue.async {
                let recognizer = self.recognizersMap[recognizerId]
                DispatchQueue.main.async {
                    guard let recognizer = recognizer else {
                        result(FlutterError(code: "NO_RECOGNIZER", message: "Recognizer not found", details: nil))
                        return
                    }
                    self.speechService = SpeechService(
                        recognizer: recognizer,
                        sampleRate: sampleRate.doubleValue,
                        channel: channel,
                        queue: self.voskQueue
                    )
                    result(nil)
                }
            }

        case "speechService.start":
            guard let service = speechService else {
                 result(FlutterError(code: "NO_SPEECH_SERVICE", message: "SpeechService not created", details: nil))
                 return
            }
            do {
                try service.start()
                result(true)
            } catch {
                 result(FlutterError(code: "START_ERROR", message: error.localizedDescription, details: nil))
            }

        case "speechService.stop":
            guard let service = speechService else {
                 result(FlutterError(code: "NO_SPEECH_SERVICE", message: "SpeechService not created", details: nil))
                 return
            }
            service.stop()
            result(true)

        case "speechService.cancel":
             guard let service = speechService else {
                 result(FlutterError(code: "NO_SPEECH_SERVICE", message: "SpeechService not created", details: nil))
                 return
            }
            service.stop()
            result(true)

        case "speechService.destroy":
            speechService?.stop()
            speechService = nil
            result(nil)

        case "speechService.setPause":
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    deinit {
        // Clean up models
        for model in modelsMap.values {
            vosk_model_free(model)
        }
        for model in speakerModelsMap.values {
            vosk_spk_model_free(model)
        }
    }

    /// Konfiguracja sesji audio dla wbudowanego SpeechService — RAZ.
    /// Oryginał wołał to przy każdym `recognizer.*`, czyli 5 razy na sekundę
    /// przy strumieniu; `setActive(true)` przerywało wtedy cudze nagrywanie.
    private func configureAudioSessionOnce() {
        guard !audioSessionConfigured else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            // Options to allow bluetooth and mix with others if needed, but primary is playAndRecord
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            audioSessionConfigured = true
            voskLog("AVAudioSession configured and active")
        } catch {
            NSLog("VOSK: Failed to configure AVAudioSession: \(error)")
        }
    }
}

/// UWAGA: ta klasa MA ZNANY BŁĄD i nie jest używana w hi_bees — tap jest
/// instalowany w formacie sprzętowym (iPhone: 48 kHz float ±1.0) i podawany
/// wprost do Vosk, który oczekuje skali int16 i częstotliwości zadanej przy
/// tworzeniu recognizera. Brakuje AVAudioConverter (autor zostawił o tym
/// komentarz niżej). Audio zbieramy pakietem `record` i karmimy
/// `recognizer.acceptWaveform`. Zmiana względem oryginału: dekodowanie zeszło
/// z wątku audio na wspólną kolejkę `voskQueue` — blokowanie wątku renderowania
/// audio gubi bufory.
class SpeechService {
    let recognizer: OpaquePointer // C pointer
    let engine = AVAudioEngine()
    let inputNode: AVAudioInputNode
    let bus = 0
    let sampleRate: Double
    let channel: FlutterMethodChannel
    let queue: DispatchQueue

    init(recognizer: OpaquePointer, sampleRate: Double, channel: FlutterMethodChannel, queue: DispatchQueue) {
        self.recognizer = recognizer
        self.sampleRate = sampleRate
        self.channel = channel
        self.queue = queue
        self.inputNode = engine.inputNode
    }

    func start() throws {
        let format = inputNode.outputFormat(forBus: bus)

        inputNode.installTap(onBus: bus, bufferSize: 4096, format: format) { (buffer, time) in
             // Convert to 16kHz Int16 mono if needed.
             // Vosk robustly handles sample rate mismatches ONLY if configured, but best to feed it what it expects.
             // We will assume for now we just dump the buffer bytes.
             // Ideally we should use AVAudioConverter here.

             // Simplification: Direct mapping if possible.
             if let channelData = buffer.int16ChannelData {
                let dataLen = Int32(buffer.frameLength) * 2
                // Kopia, bo bufor tapu żyje tylko do końca tego wywołania,
                // a dekodowanie schodzi na inną kolejkę.
                let data = Data(bytes: channelData[0], count: Int(dataLen))
                self.queue.async {
                    let accepted = data.withUnsafeBytes { (raw: UnsafeRawBufferPointer) -> Int32 in
                        guard let base = raw.baseAddress else { return -1 }
                        return vosk_recognizer_accept_waveform(
                            self.recognizer,
                            base.assumingMemoryBound(to: CChar.self),
                            dataLen
                        )
                    }
                    self.emit(accepted: accepted)
                }
             } else if let floatChannelData = buffer.floatChannelData {
                 // Convert float to int16 or use vosk_recognizer_accept_waveform_f ??
                 // vosk_recognizer_accept_waveform_f is available!
                 let dataLen = Int32(buffer.frameLength)
                 let floats = Array(UnsafeBufferPointer(start: floatChannelData[0], count: Int(dataLen)))

                 self.queue.async {
                     // However, vosk_recognizer_accept_waveform_f takes float *.
                     let accepted = floats.withUnsafeBufferPointer { ptr -> Int32 in
                         guard let base = ptr.baseAddress else { return -1 }
                         return vosk_recognizer_accept_waveform_f(self.recognizer, base, dataLen)
                     }
                     self.emit(accepted: accepted)
                 }
             }
        }

        try engine.start()
    }

    /// Wołane z `queue`.
    private func emit(accepted: Int32) {
        if accepted == 1 {
            if let res = vosk_recognizer_result(self.recognizer) {
                self.reportResult(String(cString: res))
            }
        } else {
            if let res = vosk_recognizer_partial_result(self.recognizer) {
                self.reportPartial(String(cString: res))
            }
        }
    }

    func stop() {
        engine.stop()
        inputNode.removeTap(onBus: bus)
        // Po kolejce, żeby domknąć porcje już zakolejkowane przez tap.
        queue.async {
            if let res = vosk_recognizer_final_result(self.recognizer) {
                self.reportFinal(String(cString: res))
            }
        }
    }

    func reportResult(_ result: String) {
        DispatchQueue.main.async {
            self.channel.invokeMethod("speechService.onResult", arguments: result)
        }
    }

    func reportPartial(_ result: String) {
        DispatchQueue.main.async {
             self.channel.invokeMethod("speechService.onPartial", arguments: result)
        }
    }

    func reportFinal(_ result: String) {
        DispatchQueue.main.async {
             self.channel.invokeMethod("speechService.onFinalResult", arguments: result)
        }
    }
}
