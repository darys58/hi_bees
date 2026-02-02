import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SyrupCalculatorScreen extends StatefulWidget {
  static const routeName = '/syrup-calculator';

  @override
  State<SyrupCalculatorScreen> createState() => _SyrupCalculatorScreenState();
}

class _SyrupCalculatorScreenState extends State<SyrupCalculatorScreen> {
  final TextEditingController _sugarController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();

  // Proporcja 3:2 → 3 kg cukru na 2 L wody
  // Gęstość syropu 60% ≈ 1.29 kg/L
  static const double _density = 1.29;
  static const double _maxLiters = 50.0;
  static const double _maxKg = 64.5; // ~50 * 1.29

  double _resultLiters = 0.0;
  double _resultKg = 0.0;
  double _sugar = 0.0;
  double _water = 0.0;

  bool _isUpdating = false;

  @override
  void dispose() {
    _sugarController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  void _updateFromSugar(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final s = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final w = s * 2 / 3;
    final mass = s + w;
    final volume = mass / _density;

    setState(() {
      _sugar = s;
      _water = w;
      _resultKg = mass;
      _resultLiters = volume;
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
    });

    _isUpdating = false;
  }

  void _updateFromWater(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final w = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final s = w * 3 / 2;
    final mass = s + w;
    final volume = mass / _density;

    setState(() {
      _sugar = s;
      _water = w;
      _resultKg = mass;
      _resultLiters = volume;
      _sugarController.text = s > 0 ? s.toStringAsFixed(2) : '';
    });

    _isUpdating = false;
  }

  void _updateFromLitersSlider(double liters) {
    if (_isUpdating) return;
    _isUpdating = true;

    final mass = liters * _density;
    final s = mass * 3 / 5;
    final w = mass * 2 / 5;

    setState(() {
      _sugar = s;
      _water = w;
      _resultKg = mass;
      _resultLiters = liters;
      _sugarController.text = s > 0 ? s.toStringAsFixed(2) : '';
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
    });

    _isUpdating = false;
  }

  void _updateFromKgSlider(double kg) {
    if (_isUpdating) return;
    _isUpdating = true;

    final volume = kg / _density;
    final s = kg * 3 / 5;
    final w = kg * 2 / 5;

    setState(() {
      _sugar = s;
      _water = w;
      _resultKg = kg;
      _resultLiters = volume;
      _sugarController.text = s > 0 ? s.toStringAsFixed(2) : '';
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
    });

    _isUpdating = false;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
          '${loc.syrupCalculator} 3:2',
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[300],
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cukier i Woda - dwa pola obok siebie
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sugarController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${loc.sugar} (kg)',
                      prefixIcon: Icon(Icons.square, color: Colors.brown[300]),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _updateFromSugar,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _waterController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${loc.water} (L)',
                      prefixIcon: Icon(Icons.water_drop, color: Colors.blue),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _updateFromWater,
                  ),
                ),
              ],
            ),

            SizedBox(height: 32),

            // Suwak - Wynik w litrach
            Text(
              '${loc.resultLiters}: ${_resultLiters.toStringAsFixed(2)} L',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Slider(
              value: _resultLiters.clamp(0.0, _maxLiters),
              min: 0,
              max: _maxLiters,
              divisions: 500,
              label: '${_resultLiters.toStringAsFixed(1)} L',
              onChanged: _updateFromLitersSlider,
            ),

            SizedBox(height: 16),

            // Suwak - Wynik w kg
            Text(
              '${loc.resultKilograms}: ${_resultKg.toStringAsFixed(2)} kg',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Slider(
              value: _resultKg.clamp(0.0, _maxKg),
              min: 0,
              max: _maxKg,
              divisions: 645,
              label: '${_resultKg.toStringAsFixed(1)} kg',
              onChanged: _updateFromKgSlider,
            ),

            SizedBox(height: 32),

            // Podsumowanie
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      loc.sugarSyrup32,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.square, color: Colors.brown[300], size: 32),
                            SizedBox(height: 4),
                            Text(loc.sugar),
                            Text(
                              '${_sugar.toStringAsFixed(2)} kg',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.water_drop, color: Colors.blue, size: 32),
                            SizedBox(height: 4),
                            Text(loc.water),
                            Text(
                              '${_water.toStringAsFixed(2)} L',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
