# Reguły R8 doklejane do KAŻDEJ aplikacji używającej tej wtyczki (hi_bees:
# `minifyEnabled true` w buildzie release).
#
# Po co: vosk-android nie ma wygenerowanego JNI. Woła bibliotekę natywną przez
# JNA w trybie bezpośrednim (`Native.register(LibVosk.class, "vosk")`), która
# wiąże metody po NAZWACH w czasie działania. Dla R8 te metody wyglądają na
# nieużywane albo nadają się do przemianowania - po skurczeniu kodu sterowanie
# głosem wywala się w release'ie na `UnsatisfiedLinkError`, a w debugu działa.
# Nie da się tego zauważyć inaczej niż testem podpisanej wersji.

# Cały Vosk: klasy natywne (LibVosk) i opakowania wskaźników JNA
# (Model, Recognizer, SpeakerModel dziedziczą po com.sun.jna.PointerType).
-keep class org.vosk.** { *; }

# JNA: wiązanie po nazwach + własne wyjątki i struktury.
-keep class com.sun.jna.** { *; }
-keepclassmembers class * extends com.sun.jna.** { public *; }

# Metody natywne w ogóle - JNA szuka ich po sygnaturze.
-keepclasseswithmembernames class * {
    native <methods>;
}

# JNA jest budowana także dla desktopu i odwołuje się do klas AWT, których na
# Androidzie nie ma. Bez tego R8 zatrzymuje build na brakujących referencjach.
-dontwarn java.awt.**
-dontwarn com.sun.jna.**
