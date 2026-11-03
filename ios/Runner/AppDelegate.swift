import UIKit
import Flutter
import AudioToolbox
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  //SYGNAŁ POTWIERDZENIA KOMENDY GŁOSOWEJ - dźwięk systemowy iOS.
  //
  //Do 14.08.2026 grał go pakiet `flutter_beep`
  //(`FlutterBeep.playSysSound(iOSSoundIDs.JBL_NoMatch)`). Cały ten pakiet to po
  //stronie iOS jedno wywołanie `AudioServicesPlaySystemSound(soundId)`, a po
  //stronie Androida `ToneGenerator` - i tam nie przechodził już buildu od AGP 8
  //(brak `namespace` w jego `android/build.gradle`), więc na Androidzie trzeba
  //było i tak napisać to samo ręcznie. Zamiast trzymać zależność dla jednej
  //linijki na jednej platformie, obie strony wołają teraz kanał [kanalSygnalu].
  //
  //DŹWIĘK JEST TEN SAM CO DOTĄD: `iOSSoundIDs.JBL_NoMatch` to stała 1116
  //z `flutter_beep`, przekazywana wprost do `AudioServicesPlaySystemSound`.
  private let kanalSygnalu = "hej_maja/sygnal"

  //identyfikator systemowego dźwięku (patrz wyżej - dawne iOSSoundIDs.JBL_NoMatch)
  private let idDzwiekuPotwierdzenia: SystemSoundID = 1116

  //odczyt kodu QR ula (16.10.2026) - krótkie systemowe „tink", inne niż potwierdzenie komendy
  private let idDzwiekuSkanu: SystemSoundID = 1057

  //STAN ROZMOWY TELEFONICZNEJ (03.11.2026) - do nakładki „Polecenia dla Siri"
  //na ekranie sterowania głosem (RozmowyHelper w Dart). CXCallObserver tylko
  //OBSERWUJE rozmowy (także komórkowe) - nie odbiera ich i nie wymaga VoIP.
  //Wysyłamy „dzwoni" / „trwa" / „" metodą „rozmowa"; Dart może też zapytać
  //o bieżący stan metodą „stan".
  private let kanalRozmow = "hej_maja/rozmowy"
  private let obserwatorRozmow = CXCallObserver()
  private var kanalRozmowFlutter: FlutterMethodChannel?

  private func stanRozmowy() -> String {
    let rozmowy = obserwatorRozmow.calls.filter { !$0.hasEnded }
    if rozmowy.contains(where: { $0.hasConnected }) { return "trwa" }
    if rozmowy.contains(where: { !$0.isOutgoing }) { return "dzwoni" }
    return "" //wychodząca jeszcze niepołączona - pomijamy
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Powiadomienia lokalne - delegat dla iOS 10+
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let kanal = FlutterMethodChannel(
        name: kanalSygnalu,
        binaryMessenger: controller.binaryMessenger)
      kanal.setMethodCallHandler { [weak self] call, result in
        guard call.method == "beep" || call.method == "skan" else {
          result(FlutterMethodNotImplemented)
          return
        }
        //Odpowiadamy OPISEM zaczynającym się od „ok" - tak samo jak Android
        //(MainActivity.zagrajSygnal). Dla strony Dartowej „ok" znaczy „zagrało,
        //nie sięgaj po zapasowy plik" (patrz SoundHelper.beep), a przy okazji
        //ustawienia głosu mogą pokazać, czym właściwie zagrał sygnał.
        //`AudioServicesPlaySystemSound` nie zwraca statusu - jeśli nic nie
        //słychać, dźwięk został wyciszony przez system, nie przez nas.
        let identyfikator = call.method == "skan"
          ? (self?.idDzwiekuSkanu ?? 1057)
          : (self?.idDzwiekuPotwierdzenia ?? 1116)
        AudioServicesPlaySystemSound(identyfikator)
        result("ok: dźwięk systemowy iOS \(identyfikator)")
      }
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      let kanal = FlutterMethodChannel(
        name: kanalRozmow,
        binaryMessenger: controller.binaryMessenger)
      kanal.setMethodCallHandler { [weak self] call, result in
        guard call.method == "stan" else {
          result(FlutterMethodNotImplemented)
          return
        }
        result(self?.stanRozmowy() ?? "")
      }
      kanalRozmowFlutter = kanal
      obserwatorRozmow.setDelegate(self, queue: DispatchQueue.main)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

//zmiana stanu dowolnej rozmowy - wysyłamy do Darta stan wypadkowy
extension AppDelegate: CXCallObserverDelegate {
  func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
    kanalRozmowFlutter?.invokeMethod("rozmowa", arguments: stanRozmowy())
  }
}
