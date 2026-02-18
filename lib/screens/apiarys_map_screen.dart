import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ApiaryMapScreen extends StatefulWidget {
  static const routeName = '/apiary_map';

  @override
  State<ApiaryMapScreen> createState() => _ApiaryMapScreenState();
}

class _ApiaryMapScreenState extends State<ApiaryMapScreen> {
  LatLng? _selectedLocation;
  bool _showCircle = false;
  final MapController _mapController = MapController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _selectedLocation == null) {
      final lat = double.tryParse(args['latitude']?.toString() ?? '');
      final lng = double.tryParse(args['longitude']?.toString() ?? '');
      if (lat != null && lng != null && lat != 0 && lng != 0) {
        _selectedLocation = LatLng(lat, lng);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Domyslne centrum: Polska
    final defaultCenter = LatLng(52.0, 19.0);
    final initialCenter = _selectedLocation ?? defaultCenter;
    final initialZoom = _selectedLocation != null ? 12.0 : 6.0;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
          AppLocalizations.of(context)!.selectLocationOnMap,
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
        actions: [
          // Przycisk kola 2,5 km
          IconButton(
            icon: Icon(
              Icons.circle_outlined,
              color: _selectedLocation != null
                  ? (_showCircle ? Color.fromARGB(255, 255, 140, 0) : Colors.black)
                  : Colors.grey,
            ),
            tooltip: AppLocalizations.of(context)!.beeFlightRange,
            onPressed: _selectedLocation != null
                ? () {
                    setState(() {
                      _showCircle = !_showCircle;
                    });
                  }
                : null,
          ),
          // Przycisk potwierdzenia
          IconButton(
            icon: Icon(
              Icons.check,
              color: _selectedLocation != null ? Colors.black : Colors.grey,
            ),
            onPressed: _selectedLocation != null
                ? () {
                    Navigator.of(context).pop({
                      'latitude': _selectedLocation!.latitude.toStringAsFixed(6),
                      'longitude': _selectedLocation!.longitude.toStringAsFixed(6),
                    });
                  }
                : null,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          onTap: (tapPosition, point) {
            setState(() {
              _selectedLocation = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.darys.hi_bees',
          ),
          if (_showCircle && _selectedLocation != null)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _selectedLocation!,
                  radius: 2500,
                  useRadiusInMeter: true,
                  color: Color.fromARGB(40, 255, 183, 75),
                  borderColor: Color.fromARGB(180, 255, 140, 0),
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          if (_selectedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _selectedLocation!,
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
