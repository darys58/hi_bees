import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';

//FILMY ULA (28.10.2026) - wspólne dla przeglądu (infos_screen) i Aktualności ula
//(summary_screen). Film leży obok zdjęć i ma wpis w tabeli zdjecia, rozpoznaje go
//PhotoHelper.jestFilm.

//Miniatura = pierwszy kadr filmu (fc_native_video_thumbnail: AVAssetImageGenerator na iOS,
//MediaMetadataRetriever na Androidzie - bez bibliotek .so, więc bez ryzyka 16 KB).
//Liczona RAZ przy pierwszym wyświetleniu i trzymana w katalogu cache (<tmp>/miniatury_filmow);
//system może ją wyczyścić - wtedy powstanie od nowa. Dzięki temu usuwanie filmu, ula
//i synchronizacja usunięć nie muszą wiedzieć o miniaturach. Gdy się nie uda - czarny
//kafelek z ikoną odtwarzania jak dotąd.
class MiniaturaFilmu extends StatefulWidget {
  final String sciezka;
  final double rozmiar;
  const MiniaturaFilmu({super.key, required this.sciezka, this.rozmiar = 80});

  //jedna generacja na plik, także gdy ten sam film jest na dwóch ekranach naraz
  static final Map<String, Future<String?>> _wToku = {};

  static Future<String?> _miniatura(String sciezka) {
    return _wToku.putIfAbsent(sciezka, () async {
      try {
        final tmp = await getTemporaryDirectory();
        final katalog = Directory('${tmp.path}/miniatury_filmow');
        if (!await katalog.exists()) await katalog.create(recursive: true);
        final cel = '${katalog.path}/${sciezka.split('/').last}.jpg';
        if (await File(cel).exists()) return cel;
        final ok = await FcNativeVideoThumbnail().saveThumbnailToFile(
          srcFile: sciezka,
          destFile: cel,
          width: 240,
          height: 240,
          format: 'jpeg',
          quality: 80,
        );
        return ok && await File(cel).exists() ? cel : null;
      } catch (e) {
        debugPrint('FILM: brak miniatury $sciezka: $e');
        return null;
      } finally {
        //po zakończeniu zapominamy - przy następnym wyświetleniu sprawdzi się plik w cache
        Future.microtask(() => _wToku.remove(sciezka));
      }
    });
  }

  @override
  State<MiniaturaFilmu> createState() => _MiniaturaFilmuState();
}

class _MiniaturaFilmuState extends State<MiniaturaFilmu> {
  late Future<String?> _plik;

  @override
  void initState() {
    super.initState();
    _plik = MiniaturaFilmu._miniatura(widget.sciezka);
  }

  @override
  void didUpdateWidget(MiniaturaFilmu old) {
    super.didUpdateWidget(old);
    if (old.sciezka != widget.sciezka) _plik = MiniaturaFilmu._miniatura(widget.sciezka);
  }

  @override
  Widget build(BuildContext context) {
    final double r = widget.rozmiar;
    final Widget czarny = Container(width: r, height: r, color: Colors.black87);
    return FutureBuilder<String?>(
      future: _plik,
      builder: (ctx, snap) {
        final String? plik = snap.data;
        return Stack(
          alignment: Alignment.center,
          children: [
            plik == null
                ? czarny
                : Image.file(
                    File(plik),
                    width: r,
                    height: r,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => czarny,
                  ),
            //znak, że to film, a nie zdjęcie
            Icon(Icons.play_circle_outline,
                color: Colors.white, size: r / 2,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 6)]),
          ],
        );
      },
    );
  }
}

//odtwarzacz na pełnym ekranie (w podglądzie zamiast InteractiveViewer ze zdjęciem);
//start od razu, dotknięcie = pauza/wznowienie, po końcu dotknięcie odtwarza od początku
class OdtwarzaczFilmu extends StatefulWidget {
  final String sciezka;
  const OdtwarzaczFilmu({super.key, required this.sciezka});

  @override
  State<OdtwarzaczFilmu> createState() => _OdtwarzaczFilmuState();
}

class _OdtwarzaczFilmuState extends State<OdtwarzaczFilmu> {
  late final VideoPlayerController _film;
  bool _gotowy = false;
  bool _blad = false;

  @override
  void initState() {
    super.initState();
    _film = VideoPlayerController.file(File(widget.sciezka));
    _film.addListener(_odswiez);
    _film.initialize().then((_) {
      if (!mounted) return;
      setState(() => _gotowy = true);
      _film.play();
    }).catchError((e) {
      debugPrint('FILM: nie da się odtworzyć ${widget.sciezka}: $e');
      if (mounted) setState(() => _blad = true);
    });
  }

  void _odswiez() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _film.removeListener(_odswiez);
    _film.dispose();
    super.dispose();
  }

  bool get _koniec =>
      _film.value.duration > Duration.zero && _film.value.position >= _film.value.duration;

  void _przelacz() {
    if (!_gotowy) return;
    if (_film.value.isPlaying) {
      _film.pause();
    } else {
      if (_koniec) _film.seekTo(Duration.zero);
      _film.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_blad) {
      return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 64));
    }
    if (!_gotowy) {
      return const Center(child: CircularProgressIndicator());
    }
    //cały ekran podglądu - pasek postępu liczony od dołu ekranu, nie od dołu filmu
    return GestureDetector(
      onTap: _przelacz,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _film.value.aspectRatio,
              child: VideoPlayer(_film),
            ),
          ),
          if (!_film.value.isPlaying)
            const Center(child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 80)),
          Positioned(
            left: 16,
            right: 16,
            bottom: 100, //nad przyciskami podglądu (udostępnij/zamknij/usuń)
            child: VideoProgressIndicator(_film, allowScrubbing: true),
          ),
        ],
      ),
    );
  }
}
