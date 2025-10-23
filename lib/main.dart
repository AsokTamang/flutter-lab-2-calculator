import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CalculatorHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorHome extends StatefulWidget {
  @override
  _CalculatorHomeState createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> {
  String display = '';
  String inputFormula = '';

  @override
  void initState() {
    super.initState();
    _loadLastValue();
  }

  // Load last value from SharedPreferences
  void _loadLastValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      display = prefs.getString('last_value') ?? '';
      inputFormula = display; // start with last result
    });
  }

  // Save last value to SharedPreferences
  void _saveLastValue(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_value', value);
  }

  void press(String value) {
    setState(() {
      if (value == 'C') {
        display = '';
        inputFormula = '';
      } else if (value == 'CE') {
        display = '';
      } else if (value == '=') {
        try {
          String finalInput = inputFormula.replaceAll('x', '*');
          Parser p = Parser();
          Expression exp = p.parse(finalInput);
          ContextModel cm = ContextModel();
          double eval = exp.evaluate(EvaluationType.REAL, cm);

          if (eval.isNaN) {
            display = 'ERROR';
          } else if (eval.abs() > 99999999) {
            display = 'OVERFLOW';
          } else {
            display = eval.toStringAsFixed(2);
          }

          inputFormula = display; // keep result for next calculation
          _saveLastValue(display);
        } catch (e) {
          display = 'ERROR';
          inputFormula = '';
        }
      } else {
        inputFormula += value;
        display = inputFormula.length <= 8 ? inputFormula : display;
      }
    });
  }

  bool isOperator(String x) {
    return '+-x*/'.contains(x);
  }

  Widget buildButton(String label, {Color? color, Color? textColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey[200],
            foregroundColor: textColor ?? Colors.black,
            padding: EdgeInsets.all(20),
          ),
          onPressed: () => press(label),
          child: Text(label, style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<List<String>> buttons = [
      ['C', 'CE', '%', '/'],
      ['7', '8', '9', 'x'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '=']
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Calculator')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            alignment: Alignment.bottomRight,
            padding: EdgeInsets.all(24),
            child: Text(display, style: TextStyle(fontSize: 48)),
          ),
          ...buttons.map((row) {
            return Row(
              children: row.map((label) {
                Color? bgColor;
                Color? txtColor = Colors.black;

                if (label == 'C' || label == 'CE') bgColor = Colors.redAccent;
                if (isOperator(label)) bgColor = Colors.blueAccent;
                if (label == '=') bgColor = Colors.orangeAccent;

                txtColor = (bgColor != null) ? Colors.white : Colors.black;

                return buildButton(label, color: bgColor, textColor: txtColor);
              }).toList(),
            );
          }).toList(),
        ],
      ),
    );
  }
}
