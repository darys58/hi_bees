import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OxalicCalculatorScreen extends StatefulWidget {
  static const routeName = '/oxalic-calculator';

  @override
  State<OxalicCalculatorScreen> createState() => _OxalicCalculatorScreenState();
}

class _OxalicCalculatorScreenState extends State<OxalicCalculatorScreen> {
  final TextEditingController _acidController = TextEditingController();
  final TextEditingController _sugarController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  final TextEditingController _solutionController = TextEditingController();
  final TextEditingController _coloniesController = TextEditingController();

  // Przepis bazowy: 45g kwasu + 0.625kg cukru + 0.625L wody = 1L roztworu 3.2%
  // Syrop cukrowy 1:1 (waga): 1L wody + 1kg cukru = ~1.6L syropu
  // 45g kwasu szczawiowego na 1L gotowego syropu = stężenie 3.2%
  static const double _acidPerLiterSolution = 45.0; // g kwasu na 1L roztworu
  static const double _waterPerLiterSolution = 0.625; // L wody na 1L roztworu
  static const double _sugarPerLiterSolution = 0.625; // kg cukru na 1L roztworu
  static const double _mlPerColony = 50.0; // ml roztworu na rodzinę
  static const double _maxSolution = 2.5; // max L roztworu na suwaku
  static const double _maxColonies = 50.0; // max rodzin na suwaku

  double _resultSolution = 0.0;
  double _resultColonies = 0.0;

  bool _isUpdating = false;

  @override
  void dispose() {
    _acidController.dispose();
    _sugarController.dispose();
    _waterController.dispose();
    _solutionController.dispose();
    _coloniesController.dispose();
    super.dispose();
  }

  void _updateFromWater(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final w = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final solution = w / _waterPerLiterSolution;
    final acid = solution * _acidPerLiterSolution;
    final sugar = solution * _sugarPerLiterSolution;
    final colonies = solution * 1000 / _mlPerColony;

    setState(() {
      _resultSolution = solution;
      _resultColonies = colonies;
      _acidController.text = acid > 0 ? acid.toStringAsFixed(1) : '';
      _sugarController.text = sugar > 0 ? sugar.toStringAsFixed(2) : '';
      _solutionController.text =
          solution > 0 ? solution.toStringAsFixed(2) : '';
      _coloniesController.text =
          colonies > 0 ? colonies.toStringAsFixed(0) : '';
    });

    _isUpdating = false;
  }

  void _updateFromAcid(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final acid = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final solution = acid / _acidPerLiterSolution;
    final w = solution * _waterPerLiterSolution;
    final sugar = solution * _sugarPerLiterSolution;
    final colonies = solution * 1000 / _mlPerColony;

    setState(() {
      _resultSolution = solution;
      _resultColonies = colonies;
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
      _sugarController.text = sugar > 0 ? sugar.toStringAsFixed(2) : '';
      _solutionController.text =
          solution > 0 ? solution.toStringAsFixed(2) : '';
      _coloniesController.text =
          colonies > 0 ? colonies.toStringAsFixed(0) : '';
    });

    _isUpdating = false;
  }

  void _updateFromSugar(String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    final sugar = double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    final solution = sugar / _sugarPerLiterSolution;
    final acid = solution * _acidPerLiterSolution;
    final w = solution * _waterPerLiterSolution;
    final colonies = solution * 1000 / _mlPerColony;

    setState(() {
      _resultSolution = solution;
      _resultColonies = colonies;
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
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
    final w = solution * _waterPerLiterSolution;
    final sugar = solution * _sugarPerLiterSolution;
    final colonies = solution * 1000 / _mlPerColony;

    setState(() {
      _resultSolution = solution;
      _resultColonies = colonies;
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
      _acidController.text = acid > 0 ? acid.toStringAsFixed(1) : '';
      _sugarController.text = sugar > 0 ? sugar.toStringAsFixed(2) : '';
      _coloniesController.text =
          colonies > 0 ? colonies.toStringAsFixed(0) : '';
    });

    _isUpdating = false;
  }

  void _updateFromSolutionSlider(double solution) {
    if (_isUpdating) return;
    _isUpdating = true;

    final acid = solution * _acidPerLiterSolution;
    final w = solution * _waterPerLiterSolution;
    final sugar = solution * _sugarPerLiterSolution;
    final colonies = solution * 1000 / _mlPerColony;

    setState(() {
      _resultSolution = solution;
      _resultColonies = colonies;
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
      _acidController.text = acid > 0 ? acid.toStringAsFixed(1) : '';
      _sugarController.text = sugar > 0 ? sugar.toStringAsFixed(2) : '';
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
    final w = solution * _waterPerLiterSolution;
    final sugar = solution * _sugarPerLiterSolution;

    setState(() {
      _resultSolution = solution;
      _resultColonies = colonies;
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
      _acidController.text = acid > 0 ? acid.toStringAsFixed(1) : '';
      _sugarController.text = sugar > 0 ? sugar.toStringAsFixed(2) : '';
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
    final w = solution * _waterPerLiterSolution;
    final sugar = solution * _sugarPerLiterSolution;

    setState(() {
      _resultSolution = solution;
      _resultColonies = colonies;
      _waterController.text = w > 0 ? w.toStringAsFixed(2) : '';
      _acidController.text = acid > 0 ? acid.toStringAsFixed(1) : '';
      _sugarController.text = sugar > 0 ? sugar.toStringAsFixed(2) : '';
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
          loc.oxalicAcidSolution,
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
              loc.oxalicAcidRecipe,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            SizedBox(height: 16),
// Kwas szczawiowy - pełna szerokość
            TextField(
              controller: _acidController,
              keyboardType:
                  TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '${loc.oxalicAcid} (g)',
                prefixIcon:
                    Icon(Icons.science, color: Colors.orange[700]),
                border: OutlineInputBorder(),
              ),
              onChanged: _updateFromAcid,
            ),
            SizedBox(height: 16),
// Cukier i Woda w rzędzie
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sugarController,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '${loc.sugar} (kg)',
                      prefixIcon:
                          Icon(Icons.square, color: Colors.brown[300]),
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
                      prefixIcon:
                          Icon(Icons.water_drop, color: Colors.blue),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _updateFromWater,
                  ),
                ),
              ],
            ),

            SizedBox(height: 32),

  // Roztwór w litrach
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${loc.oxalicSolutionLiters}:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    '${loc.oxalicColonies} (${_mlPerColony.toStringAsFixed(0)} ml):',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
