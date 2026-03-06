import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LacticCalculatorScreen extends StatefulWidget {
  static const routeName = '/lactic-calculator';

  @override
  State<LacticCalculatorScreen> createState() => _LacticCalculatorScreenState();
}

class _LacticCalculatorScreenState extends State<LacticCalculatorScreen> {
  final TextEditingController _acidController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  final TextEditingController _solutionController = TextEditingController();
  final TextEditingController _coloniesController = TextEditingController();

  // Roztwór 15% z kwasu mlekowego 80%
  // Na 1 L roztworu 15%: 187.5 ml kwasu 80% + 812.5 ml wody
  static const double _concentratedPercent = 80.0;
  static const double _targetPercent = 15.0;
  static const double _acidPerLiterSolution =
      _targetPercent / _concentratedPercent * 1000; // 187.5 ml
  static const double _waterPerLiterSolution =
      1000 - _acidPerLiterSolution; // 812.5 ml
  static const double _mlPerColony = 50.0; // ml roztworu na rodzinę
  static const double _maxSolution = 2.5;
  static const double _maxColonies = 50.0;

  double _resultSolution = 0.0;
  double _resultColonies = 0.0;

  bool _isUpdating = false;

  @override
  void dispose() {
    _acidController.dispose();
    _waterController.dispose();
    _solutionController.dispose();
    _coloniesController.dispose();
    super.dispose();
  }

  void _updateFromAcid(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final acid = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final solution = acid / _acidPerLiterSolution;
    final water = solution * _waterPerLiterSolution;
    final colonies = solution * 1000 / _mlPerColony;

    setState(() {
      _resultSolution = solution;
      _resultColonies = colonies;
      _waterController.text = water > 0 ? water.toStringAsFixed(1) : '';
      _solutionController.text =
          solution > 0 ? solution.toStringAsFixed(2) : '';
      _coloniesController.text =
          colonies > 0 ? colonies.toStringAsFixed(0) : '';
    });

    _isUpdating = false;
  }

  void _updateFromWater(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final water = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final solution = water / _waterPerLiterSolution;
    final acid = solution * _acidPerLiterSolution;
    final colonies = solution * 1000 / _mlPerColony;

    setState(() {
      _resultSolution = solution;
      _resultColonies = colonies;
      _acidController.text = acid > 0 ? acid.toStringAsFixed(1) : '';
      _solutionController.text =
          solution > 0 ? solution.toStringAsFixed(2) : '';
      _coloniesController.text =
          colonies > 0 ? colonies.toStringAsFixed(0) : '';
    });

    _isUpdating = false;
  }

  void _updateFromSolution(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final solution = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final acid = solution * _acidPerLiterSolution;
    final water = solution * _waterPerLiterSolution;
    final colonies = solution * 1000 / _mlPerColony;

    setState(() {
      _resultSolution = solution;
      _resultColonies = colonies;
      _acidController.text = acid > 0 ? acid.toStringAsFixed(1) : '';
      _waterController.text = water > 0 ? water.toStringAsFixed(1) : '';
      _coloniesController.text =
          colonies > 0 ? colonies.toStringAsFixed(0) : '';
    });

    _isUpdating = false;
  }

  void _updateFromSolutionSlider(double solution) {
    if (_isUpdating) return;
    _isUpdating = true;

    final acid = solution * _acidPerLiterSolution;
    final water = solution * _waterPerLiterSolution;
    final colonies = solution * 1000 / _mlPerColony;

    setState(() {
      _resultSolution = solution;
      _resultColonies = colonies;
      _acidController.text = acid > 0 ? acid.toStringAsFixed(1) : '';
      _waterController.text = water > 0 ? water.toStringAsFixed(1) : '';
      _solutionController.text =
          solution > 0 ? solution.toStringAsFixed(2) : '';
      _coloniesController.text =
          colonies > 0 ? colonies.toStringAsFixed(0) : '';
    });

    _isUpdating = false;
  }

  void _updateFromColonies(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final colonies = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final solution = colonies * _mlPerColony / 1000;
    final acid = solution * _acidPerLiterSolution;
    final water = solution * _waterPerLiterSolution;

    setState(() {
      _resultSolution = solution;
      _resultColonies = colonies;
      _acidController.text = acid > 0 ? acid.toStringAsFixed(1) : '';
      _waterController.text = water > 0 ? water.toStringAsFixed(1) : '';
      _solutionController.text =
          solution > 0 ? solution.toStringAsFixed(2) : '';
    });

    _isUpdating = false;
  }

  void _updateFromColoniesSlider(double colonies) {
    if (_isUpdating) return;
    _isUpdating = true;

    final solution = colonies * _mlPerColony / 1000;
    final acid = solution * _acidPerLiterSolution;
    final water = solution * _waterPerLiterSolution;

    setState(() {
      _resultSolution = solution;
      _resultColonies = colonies;
      _acidController.text = acid > 0 ? acid.toStringAsFixed(1) : '';
      _waterController.text = water > 0 ? water.toStringAsFixed(1) : '';
      _solutionController.text =
          solution > 0 ? solution.toStringAsFixed(2) : '';
      _coloniesController.text =
          colonies > 0 ? colonies.toStringAsFixed(0) : '';
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
          loc.lacticAcidSolution,
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
            SizedBox(height: 8),
            Text(
              loc.lacticAcidRecipe,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            SizedBox(height: 16),
            // Kwas mlekowy 80% - pełna szerokość
            TextField(
              controller: _acidController,
              keyboardType:
                  TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '${loc.lacticAcid} 80% (ml)',
                prefixIcon:
                    Icon(Icons.science, color: Colors.green[700]),
                border: OutlineInputBorder(),
              ),
              onChanged: _updateFromAcid,
            ),
            SizedBox(height: 16),
            // Woda - pełna szerokość
            TextField(
              controller: _waterController,
              keyboardType:
                  TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '${loc.water} (ml)',
                prefixIcon: Icon(Icons.water_drop, color: Colors.blue),
                border: OutlineInputBorder(),
              ),
              onChanged: _updateFromWater,
            ),

            SizedBox(height: 32),

            // Roztwór 15% w litrach
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${loc.lacticSolutionLiters}:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _solutionController,
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
                    onChanged: _updateFromSolution,
                  ),
                ),
              ],
            ),
            Slider(
              value: _resultSolution.clamp(0.0, _maxSolution),
              min: 0,
              max: _maxSolution,
              divisions: 200,
              label: '${_resultSolution.toStringAsFixed(1)} l',
              onChanged: _updateFromSolutionSlider,
            ),

            SizedBox(height: 16),

            // Ilość rodzin
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${loc.lacticColonies} (${_mlPerColony.toStringAsFixed(0)} ml):',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _coloniesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    onChanged: _updateFromColonies,
                  ),
                ),
              ],
            ),
            Slider(
              value: _resultColonies.clamp(0.0, _maxColonies),
              min: 0,
              max: _maxColonies,
              divisions: 200,
              label: _resultColonies.toStringAsFixed(0),
              onChanged: _updateFromColoniesSlider,
            ),
          ],
        ),
      ),
    );
  }
}
