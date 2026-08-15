# Reguły R8 dla wersji release.
#
# UWAGA: w tym projekcie `isMinifyEnabled = false`, więc R8 dziś NIC nie robi
# i ten plik jest bezczynny. Jest tu po to, żeby włączenie zmniejszania kodu
# (np. dla zejścia z rozmiarem APK - cztery ABI po ~10 MB libvosk.so) nie
# wywaliło aplikacji po cichu. Test podpisanej wersji release jest JEDYNYM
# testem, który wykrywa złe reguły - w debugu R8 w ogóle nie działa.

# Powiadomienia zaplanowane są zapisywane jako JSON i odtwarzane po restarcie
# telefonu; Gson mapuje je po nazwach pól, więc przemianowane klasy = ciche
# zniknięcie przypomnień.
-keep class com.dexterous.** { *; }

# Silnik i wtyczki Fluttera - wołane z kodu natywnego i przez rejestrator.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Reguł dla Voska i JNA TU NIE MA i nie ma ich tu dopisywać - jadą z wtyczki
# przez consumerProguardFiles (packages/vosk_flutter_service/android/
# consumer-rules.pro), żeby aplikacja nie musiała o nich pamiętać.
