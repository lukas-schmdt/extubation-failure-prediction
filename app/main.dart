import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prediction App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Prediction Input'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Debouncer to delay API requests
  Timer? _debounce;

  // Input variables
  Map<String, double> inputValues = {
    'demo_age': 28.0,
    'demo_bmi': 24.0,
    'demo_icu_los_min': 4.0,
    'vital_heart_rate': 85.0,
    'vital_bp_mean': 75.0,
    'vital_pulse_press': 40.0,
    'score_rass': 0.0,
    'vent_total_duration': 1.0,
    'vent_resp_rate_spont': 20.0,
    'vent_minute_volume': 6.5,
    'vent_p_mean': 10.0,
    'vent_spont_duration': 600.0,
    'vent_mandatory_duration': 600.0,
    'labs_plt': 200.0,
    'labs_glucose': 150.0,
    'labs_ptt': 35.0,
    'labs_bun': 20.0,
    'med_norepinephrine_dose': 0.0,
    'clin_flbalance': 10.0,
    'clin_fl_input_per_d': 2000.0,
    'clin_fl_output_per_d': 1800.0,
  };

  // Slider attributes (min, max, divisions, etc.) for each feature
  Map<String, Map<String, dynamic>> featureAttributes = {
    'demo_age': {
      'label': 'Age',
      'min': 18,
      'max': 100,
      'divisions': 82,
      'unit': 'years',
    },
    'demo_icu_los_min': {
      'label': 'ICU LOS',
      'min': 1,
      'max': 30,
      'divisions': 29,
      'unit': 'd',
    },
    'vital_heart_rate': {
      'label': 'Heart Rate',
      'min': 30,
      'max': 180,
      'divisions': 150,
      'unit': '/min',
    },
    'vital_bp_mean': {
      'label': 'Blood Pressure Mean',
      'min': 50,
      'max': 150,
      'divisions': 100,
      'unit': 'mmHg',
    },
    'score_rass': {
      'label': 'RASS Score',
      'min': -5,
      'max': 4,
      'divisions': 9,
      'unit': 'points'
    },
    'vent_total_duration': {
      'label': 'Ventilation Total Duration',
      'min': 0,
      'max': 30,
      'divisions': 30,
      'unit': 'd',
    },
    'vent_resp_rate_spont': {
      'label': 'Spont Resp. Rate',
      'min': 0,
      'max': 40,
      'divisions': 40,
      'unit': '/min',
    },
    'vent_minute_volume': {
      'label': 'Minute Volume',
      'min': 0,
      'max': 20,
      'divisions': 100,
      'unit': 'L',
    },
    'vent_p_mean': {
      'label': 'Mean Airway Pressure',
      'min': 0,
      'max': 30,
      'divisions': 100,
      'unit': 'cmH2O',
    },
    'vent_spont_duration': {
      'label': 'Spontaneous Duration',
      'min': 0,
      'max': 3000,
      'divisions': 100,
      'unit': 'min',
    },
    'vent_mandatory_duration': {
      'label': 'Mandatory Duration',
      'min': 0,
      'max': 3000,
      'divisions': 100,
      'unit': 'min',
    },
    'labs_plt': {
      'label': 'Platelet Count',
      'min': 0,
      'max': 500,
      'divisions': 100,
      'unit': 'x10^9/L'
    },
    'labs_glucose': {
      'label': 'Glucose',
      'min': 50,
      'max': 400,
      'divisions': 100,
      'unit': 'mg/dL'
    },
    'labs_ptt': {
      'label': 'PTT',
      'min': 10,
      'max': 100,
      'divisions': 100,
      'unit': 's'
    },
    'labs_bun': {
      'label': 'BUN',
      'min': 5,
      'max': 60,
      'divisions': 100,
      'unit': 'mg/dL'
    },
    'med_norepinephrine_dose': {
      'label': 'Norepinephrine',
      'min': 0,
      'max': 1,
      'divisions': 100,
      'unit': 'ug/kg/min'
    },
    'clin_flbalance': {
      'label': 'Fluid Balance',
      'min': -5000,
      'max': 5000,
      'divisions': 100,
      'unit': 'mL/d'
    },
    'demo_bmi': {
      'label': 'BMI',
      'min': 10,
      'max': 50,
      'divisions': 100,
      'unit': 'kg/m²'
    },
    'clin_fl_input_per_d': {
      'label': 'Fluid Input per Day',
      'min': 0,
      'max': 10000,
      'divisions': 100,
      'unit': 'mL/d'
    },
    'clin_fl_output_per_d': {
      'label': 'Fluid Output per Day',
      'min': 0,
      'max': 10000,
      'divisions': 100,
      'unit': 'mL/d'
    },
    'vital_pulse_press': {
      'label': 'Pulse Pressure',
      'min': 0,
      'max': 100,
      'divisions': 100,
      'unit': 'mmHg'
    },
  };

// Prediction result
  String _predictedClass = '';
  List<double> _probabilities = [];

// Function to make the POST request
 Future<void> _getPrediction() async {
  final url = Uri.parse('http://127.0.0.1:8000/predict');
  var _inputValues = Map.from(inputValues);
  _inputValues['demo_icu_los_min'] = _inputValues['demo_icu_los_min'] * 1440;
  _inputValues['vent_total_duration'] = _inputValues['vent_total_duration'] * 1440;
  _inputValues['med_norepinephrine_dose'] = _inputValues['med_norepinephrine_dose'] * 1440;
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(_inputValues),
  );

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);
    
    // Add print statements for debugging
    print('Predicted class from API: ${decoded['predicted_class']}');
    print('Probabilities from API: ${decoded['probabilities']}');

setState(() {
  _predictedClass = decoded['predicted_class'].toString();
  _probabilities = List<double>.from(decoded['probabilities']);
  // Force a UI refresh
});
  } else {
    // Handle error
    print('Failed to get prediction');
  }
}

  // Debounce API calls
  void _onInputChange() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _getPrediction();
    });
  }

// Function to dynamically build each card for features
  Widget buildWidget(String key, Map<String, dynamic> attributes) {
    return SizedBox(
      width: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(attributes['label']),
                  Text(
                      '${inputValues[key]!.toStringAsFixed(1)} ${attributes['unit']}'),
                ],
              ),
              Slider(
                value: inputValues[key]!,
                min: attributes['min'].toDouble(),
                max: attributes['max'].toDouble(),
                divisions: attributes['divisions'],
                label: inputValues[key].toString(),
                onChanged: (double value) {
                  setState(() {
                    inputValues[key] = value;
                  });
                  _onInputChange();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                  child: Column(children: [
                ListTile(
                  title: Text('Demographics',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Wrap(
                    alignment: WrapAlignment.start,
                    children: featureAttributes.entries
                        .where((e) => e.key.contains('demo_'))
                        .map((entry) => buildWidget(entry.key, entry.value))
                        .toList(),
                  ),
                ),
                ListTile(
                  title: Text('Vital Signs',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Wrap(
                    alignment: WrapAlignment.start,
                    children: featureAttributes.entries
                        .where((e) => e.key.contains('vital_'))
                        .map((entry) => buildWidget(entry.key, entry.value))
                        .toList(),
                  ),
                ),
                ListTile(
                  title: Text('Ventilation',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Wrap(
                    alignment: WrapAlignment.start,
                    children: featureAttributes.entries
                        .where((e) => e.key.contains('vent_'))
                        .map((entry) => buildWidget(entry.key, entry.value))
                        .toList(),
                  ),
                ),
                ListTile(
                  title: Text(
                    'Labs',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Wrap(
                    alignment: WrapAlignment.start,
                    children: featureAttributes.entries
                        .where((e) => e.key.contains('labs_'))
                        .map((entry) => buildWidget(entry.key, entry.value))
                        .toList(),
                  ),
                ),
                ListTile(
                  title: Text('Medication',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Wrap(
                    alignment: WrapAlignment.start,
                    children: featureAttributes.entries
                        .where((e) => e.key.contains('med_'))
                        .map((entry) => buildWidget(entry.key, entry.value))
                        .toList(),
                  ),
                ),
                ListTile(
                  title: Text('Clinical',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Wrap(
                    alignment: WrapAlignment.start,
                    children: featureAttributes.entries
                        .where((e) => e.key.contains('clin_'))
                        .map((entry) => buildWidget(entry.key, entry.value))
                        .toList(),
                  ),
                ),
                ListTile(
                  title: Text('Scores',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Wrap(
                    alignment: WrapAlignment.start,
                    children: featureAttributes.entries
                        .where((e) => e.key.contains('score_'))
                        .map((entry) => buildWidget(entry.key, entry.value))
                        .toList(),
                  ),
                ),
              ])),
            ),
          ),
          MyPredictionWidget(_predictedClass, _probabilities),
        ],
      ),
    );
  }
}

class MyPredictionWidget extends StatelessWidget {
  final String _predictedClass;
  final List<double> _probabilities;

  const MyPredictionWidget(this._predictedClass, this._probabilities,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color _getRiskColor(double probability) {
      // Mapping probability to a color between green and red
      if (probability <= 0.5) {
        // Gradient from green to yellow (low to medium risk)
        return Color.lerp(Colors.green, Colors.yellow, probability * 2)!;
      } else {
        // Gradient from yellow to red (medium to high risk)
        return Color.lerp(Colors.yellow, Colors.red, (probability - 0.5) * 2)!;
      }
    }
    print(_predictedClass.toString() + 'XXXX');
    double riskProbability =
        _probabilities.isNotEmpty ? _probabilities[1] : 0.0;

    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Container(
          decoration: BoxDecoration(
            color: _getRiskColor(
                riskProbability),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_probabilities.isNotEmpty) ...[
                Text(
                    'Success: ${(_probabilities[0] * 100).toStringAsFixed(2)}%',style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(
                    'Failure: ${(_probabilities[1] * 100).toStringAsFixed(2)}%',style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
