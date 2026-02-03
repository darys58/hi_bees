import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CakeCalculatorScreen extends StatefulWidget {
  static const routeName = '/cake-calculator';

  @override
  State<CakeCalculatorScreen> createState() => _CakeCalculatorScreenState();
}

class _CakeCalculatorScreenState extends State<CakeCalculatorScreen> {
  final TextEditingController _honeyController = TextEditingController();
  final TextEditingController _powderedSugarController =
      TextEditingController();
  final TextEditingController _kgController = TextEditingController();

  // Proporcja 1:3 → 1 część miodu na 3 części cukru pudru
  static const double _maxKg = 50.0;

  double _resultKg = 0.0;

  bool _isUpdating = false;

  @override
  void dispose() {
    _honeyController.dispose();
    _powderedSugarController.dispose();
    _kgController.dispose();
    super.dispose();
  }

  void _updateFromHoney(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final h = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final ps = h * 3;
    final mass = h + ps;

    setState(() {
      _resultKg = mass;
      _powderedSugarController.text = ps > 0 ? ps.toStringAsFixed(2) : '';
      _kgController.text = mass > 0 ? mass.toStringAsFixed(2) : '';
    });

    _isUpdating = false;
  }

  void _updateFromPowderedSugar(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final ps = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final h = ps / 3;
    final mass = h + ps;

    setState(() {
      _resultKg = mass;
      _honeyController.text = h > 0 ? h.toStringAsFixed(2) : '';
      _kgController.text = mass > 0 ? mass.toStringAsFixed(2) : '';
    });

    _isUpdating = false;
  }

  void _updateFromKgSlider(double kg) {
    if (_isUpdating) return;
    _isUpdating = true;

    final h = kg / 4;
    final ps = kg * 3 / 4;

    setState(() {
      _resultKg = kg;
      _honeyController.text = h > 0 ? h.toStringAsFixed(2) : '';
      _powderedSugarController.text = ps > 0 ? ps.toStringAsFixed(2) : '';
      _kgController.text = kg > 0 ? kg.toStringAsFixed(2) : '';
    });

    _isUpdating = false;
  }

  void _updateFromKgInput(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final kg = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final h = kg / 4;
    final ps = kg * 3 / 4;

    setState(() {
      _resultKg = kg;
      _honeyController.text = h > 0 ? h.toStringAsFixed(2) : '';
      _powderedSugarController.text = ps > 0 ? ps.toStringAsFixed(2) : '';
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
          loc.honeySugarCake,
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
                    controller: _honeyController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${loc.honey[0].toUpperCase()}${loc.honey.substring(1)} (kg)',
                      prefixIcon:
                          Icon(Icons.hexagon, color: Colors.amber[700]),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _updateFromHoney,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _powderedSugarController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${loc.powderedSugar} (kg)',
                      prefixIcon: Icon(Icons.square, color: Colors.grey[300]),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _updateFromPowderedSugar,
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
                    '${loc.cakeKilograms}:',
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
              divisions: 500,
              label: '${_resultKg.toStringAsFixed(1)} kg',
              onChanged: _updateFromKgSlider,
            ),
          ],
        ),
      ),
    );
  }
}
