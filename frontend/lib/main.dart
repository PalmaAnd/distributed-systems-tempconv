import 'package:flutter/material.dart';
import 'package:grpc/grpc_web.dart';

import 'generated/tempconv/v1/tempconv.pb.dart';
import 'generated/tempconv/v1/tempconv.pbgrpc.dart';

void main() {
  runApp(const TempConvApp());
}

class TempConvApp extends StatelessWidget {
  const TempConvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TempConv',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ConverterPage(),
    );
  }
}

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _inputController = TextEditingController();
  String _result = '';
  String? _error;
  bool _celsiusToFahrenheit = true;
  bool _loading = false;

  GrpcWebClientChannel _channel() {
    final base = Uri.base;
    final host = base.host.isEmpty ? 'localhost' : base.host;
    final port = base.hasPort ? base.port : (base.scheme == 'https' ? 443 : 80);
    final scheme = base.scheme == 'https' ? 'https' : 'http';
    return GrpcWebClientChannel.xhr(Uri(scheme: scheme, host: host, port: port));
  }

  Future<void> _convert() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _error = 'Enter a value';
        _result = '';
      });
      return;
    }
    final value = double.tryParse(input);
    if (value == null) {
      setState(() {
        _error = 'Invalid number';
        _result = '';
      });
      return;
    }
    setState(() {
      _error = null;
      _result = '';
      _loading = true;
    });
    try {
      final client = TempConvClient(_channel());
      final request = Value()..value = value;
      final response = _celsiusToFahrenheit
          ? await client.celsiusToFahrenheit(request)
          : await client.fahrenheitToCelsius(request);
      setState(() {
        _result = response.value.toStringAsFixed(2);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _result = '';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TempConv'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('°C → °F')),
                    ButtonSegment(value: false, label: Text('°F → °C')),
                  ],
                  selected: {_celsiusToFahrenheit},
                  onSelectionChanged: (s) {
                    setState(() {
                      _celsiusToFahrenheit = s.first;
                      _result = '';
                      _error = null;
                    });
                  },
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _inputController,
                  decoration: InputDecoration(
                    labelText: _celsiusToFahrenheit ? 'Celsius' : 'Fahrenheit',
                    border: const OutlineInputBorder(),
                    suffixText: _celsiusToFahrenheit ? '°C' : '°F',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _convert(),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loading ? null : _convert,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.swap_horiz),
                  label: Text(_loading ? 'Converting...' : 'Convert'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                if (_result.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Result: $_result ${_celsiusToFahrenheit ? '°F' : '°C'}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
