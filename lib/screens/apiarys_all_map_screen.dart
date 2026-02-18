import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/weathers.dart';
import '../models/weather.dart';
import '../models/apiarys.dart';

class ApiarysAllMapScreen extends StatefulWidget {
  static const routeName = '/apiarys_all_map';

  @override
  State<ApiarysAllMapScreen> createState() => _ApiarysAllMapScreenState();
}

class _ApiarysAllMapScreenState extends State<ApiarysAllMapScreen> {
  final MapController _mapController = MapController();
  List<_ApiaryLocation> _locations = [];
  bool _isInit = true;
  bool _showCircles = false;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _isInit = false;
      _loadLocations();
    }
    super.didChangeDependencies();
  }

  void _loadLocations() {
    final weatherData = Provider.of<Weathers>(context, listen: false);
    final apiaryData = Provider.of<Apiarys>(context, listen: false);
    final weathers = weatherData.items;
    final apiaries = apiaryData.items;

    final List<_ApiaryLocation> locs = [];
    for (final w in weathers) {
      final lat = double.tryParse(w.latitude);
      final lng = double.tryParse(w.longitude);
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        // Znajdź numer pasieki po id
        String label = w.id;
        String miasto = w.miasto;
        for (final a in apiaries) {
          if (a.id == w.id) {
            label = a.pasiekaNr.toString();
            break;
          }
        }
        locs.add(_ApiaryLocation(
          point: LatLng(lat, lng),
          label: label,
          miasto: miasto,
        ));
      }
    }
    setState(() {
      _locations = locs;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Domyślne centrum: Polska
    final defaultCenter = LatLng(52.0, 19.0);
    LatLng initialCenter = defaultCenter;
    double initialZoom = 6.0;

    if (_locations.length == 1) {
      initialCenter = _locations[0].point;
      initialZoom = 12.0;
    } else if (_locations.length > 1) {
      // Oblicz środek wszystkich lokalizacji
      double sumLat = 0, sumLng = 0;
      for (final loc in _locations) {
        sumLat += loc.point.latitude;
        sumLng += loc.point.longitude;
      }
      initialCenter = LatLng(sumLat / _locations.length, sumLng / _locations.length);
      initialZoom = 8.0;
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
          AppLocalizations.of(context)!.apiaryLocations,
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.circle_outlined,
              color: _locations.isNotEmpty
                  ? (_showCircles ? Color.fromARGB(255, 255, 140, 0) : Colors.black)
                  : Colors.grey,
            ),
            tooltip: AppLocalizations.of(context)!.beeFlightRange,
            onPressed: _locations.isNotEmpty
                ? () {
                    setState(() {
                      _showCircles = !_showCircles;
                    });
                  }
                : null,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: _locations.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.of(context)!.noApiaryLocations,
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: initialZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.darys.hi_bees',
                ),
                if (_showCircles)
                  CircleLayer(
                    circles: _locations.map((loc) {
                      return CircleMarker(
                        point: loc.point,
                        radius: 2500,
                        useRadiusInMeter: true,
                        color: Color.fromARGB(40, 255, 183, 75),
                        borderColor: Color.fromARGB(180, 255, 140, 0),
                        borderStrokeWidth: 2,
                      );
                    }).toList(),
                  ),
                MarkerLayer(
                  markers: _locations.map((loc) {
                    return Marker(
                      point: loc.point,
                      width: 120,
                      height: 55,
                      child: GestureDetector(
                        onTap: () {
                          _showApiaryInfo(context, loc);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Color.fromARGB(255, 255, 140, 0), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                loc.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.location_pin,
                              color: Color.fromARGB(255, 255, 140, 0),
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }

  void _showApiaryInfo(BuildContext context, _ApiaryLocation loc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${AppLocalizations.of(context)!.aPiary} ${loc.label}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loc.miasto.isNotEmpty)
              Text('${AppLocalizations.of(context)!.city}: ${loc.miasto}'),
            SizedBox(height: 4),
            Text('${AppLocalizations.of(context)!.latitude}: ${loc.point.latitude.toStringAsFixed(6)}'),
            Text('${AppLocalizations.of(context)!.longitude}: ${loc.point.longitude.toStringAsFixed(6)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
    );
  }
}

class _ApiaryLocation {
  final LatLng point;
  final String label;
  final String miasto;

  _ApiaryLocation({
    required this.point,
    required this.label,
    required this.miasto,
  });
}
