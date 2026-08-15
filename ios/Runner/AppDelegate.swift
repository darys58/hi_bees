import UIKit
import Flutter
import AudioToolbox

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
        guard call.method == "beep" else {
          result(FlutterMethodNotImplemented)
          return
        }
        //Odpowiadamy OPISEM zaczynającym się od „ok" - tak samo jak Android
        //(MainActivity.zagrajSygnal). Dla strony Dartowej „ok" znaczy „zagrało,
        //nie sięgaj po zapasowy plik" (patrz SoundHelper.beep), a przy okazji
        //ustawienia głosu mogą pokazać, czym właściwie zagrał sygnał.
        //`AudioServicesPlaySystemSound` nie zwraca statusu - jeśli nic nie
        //słychać, dźwięk został wyciszony przez system, nie przez nas.
        let identyfikator = self?.idDzwiekuPotwierdzenia ?? 1116
        AudioServicesPlaySystemSound(identyfikator)
        result("ok: dźwięk systemowy iOS \(identyfikator)")
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
