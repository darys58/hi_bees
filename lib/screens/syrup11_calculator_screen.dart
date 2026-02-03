import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Syrup11CalculatorScreen extends StatefulWidget {
  static const routeName = '/syrup-calculator-11';

  @override
  State<Syrup11CalculatorScreen> createState() =>
      _Syrup11CalculatorScreenState();
}

class _Syrup11CalculatorScreenState extends State<Syrup11CalculatorScreen> {
  final TextEditingController _sugarController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  final TextEditingController _litersController = TextEditingController();
  final TextEditingController _kgController = TextEditingController();

  // Proporcja 1:1 → 1 kg cukru na 1 L wody
  // Gęstość syropu ~50% ≈ 1.23 kg/L
  static const double _density = 1.23;
  static const double _maxLiters = 50.0;
  static const double _maxKg = 61.5; // ~50 * 1.23

  double _resultLiters = 0.0;
  double _resultKg = 0.0;

  bool _isUpdating = false;

  @override
  void dispose() {
    _sugarController.dispose();
    _waterController.dispose();
    _litersController.dispose();
    _kgController.dispose();
    super.dispose();
  }

  void _updateFromSugar(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final s = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final w = s;
    final mass = s + w;
    final volume = mass / _density;

    setState(() {
      _resultKg = mass;
      _resultLiters = volume;
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
      _litersController.text = volume > 0 ? volume.toStringAsFixed(2) : '';
      _kgController.text = mass > 0 ? mass.toStringAsFixed(2) : '';
    });

    _isUpdating = false;
  }

  void _updateFromWater(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final w = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final s = w;
    final mass = s + w;
    final volume = mass / _density;

    setState(() {
      _resultKg = mass;
      _resultLiters = volume;
      _sugarController.text = s > 0 ? s.toStringAsFixed(2) : '';
      _litersController.text = volume > 0 ? volume.toStringAsFixed(2) : '';
      _kgController.text = mass > 0 ? mass.toStringAsFixed(2) : '';
    });

    _isUpdating = false;
  }

  void _updateFromLitersSlider(double liters) {
    if (_isUpdating) return;
    _isUpdating = true;

    final mass = liters * _density;
    final s = mass / 2;
    final w = mass / 2;

    setState(() {
      _resultKg = mass;
      _resultLiters = liters;
      _sugarController.text = s > 0 ? s.toStringAsFixed(2) : '';
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
      _litersController.text = liters > 0 ? liters.toStringAsFixed(2) : '';
      _kgController.text = mass > 0 ? mass.toStringAsFixed(2) : '';
    });

    _isUpdating = false;
  }

  void _updateFromKgSlider(double kg) {
    if (_isUpdating) return;
    _isUpdating = true;

    final volume = kg / _density;
    final s = kg / 2;
    final w = kg / 2;

    setState(() {
      _resultKg = kg;
      _resultLiters = volume;
      _sugarController.text = s > 0 ? s.toStringAsFixed(2) : '';
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
      _litersController.text = volume > 0 ? volume.toStringAsFixed(2) : '';
      _kgController.text = kg > 0 ? kg.toStringAsFixed(2) : '';
    });

    _isUpdating = false;
  }

  void _updateFromLitersInput(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final liters = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final mass = liters * _density;
    final s = mass / 2;
    final w = mass / 2;

    setState(() {
      _resultKg = mass;
      _resultLiters = liters;
      _sugarController.text = s > 0 ? s.toStringAsFixed(2) : '';
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
      _kgController.text = mass > 0 ? mass.toStringAsFixed(2) : '';
    });

    _isUpdating = false;
  }

  void _updateFromKgInput(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final kg = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final volume = kg / _density;
    final s = kg / 2;
    final w = kg / 2;

    setState(() {
      _resultKg = kg;
      _resultLiters = volume;
      _sugarController.text = s > 0 ? s.toStringAsFixed(2) : '';
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
      _litersController.text = volume > 0 ? volume.toStringAsFixed(2) : '';
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
          '${loc.syrupCalculator} 1:1',
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
            SizedBox(height: 20),
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
                      labelText: '${loc.water} (l)',
                      prefixIcon: Icon(Icons.water_drop, color: Colors.blue),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _updateFromWater,
                  ),
                ),
              ],
            ),

            SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${loc.syrupLiters}:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _litersController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      suffixText: 'l',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    onChanged: _updateFromLitersInput,
                  ),
                ),
              ],
            ),
            Slider(
              value: _resultLiters.clamp(0.0, _maxLiters),
              min: 0,
              max: _maxLiters,
              divisions: 500,
              label: '${_resultLiters.toStringAsFixed(1)} l',
              onChanged: _updateFromLitersSlider,
            ),

            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${loc.syrupKilograms}:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _kgController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      suffixText: 'kg',
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    onChanged: _updateFromKgInput,
                  ),
                ),
              ],
            ),
            Slider(
              value: _resultKg.clamp(0.0, _maxKg),
              min: 0,
              max: _maxKg,
              divisions: 615,
              label: '${_resultKg.toStringAsFixed(1)} kg',
              onChanged: _updateFromKgSlider,
            ),
          ],
        ),
      ),
    );
  }
}
