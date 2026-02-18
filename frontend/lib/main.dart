import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TempConvApp());
}

class TempConvApp extends StatelessWidget {
  const TempConvApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF8CB9E2),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF5E8FB9),
      onPrimary: Colors.white,
      secondary: const Color(0xFFA7C7E3),
      surface: const Color(0xFFF6FAFF),
      surfaceContainerHigh: const Color(0xFFEAF3FC),
      surfaceContainerHighest: const Color(0xFFE2EEFA),
      outline: const Color(0xFFB6C7D9),
    );

    return MaterialApp(
      title: 'TempConv',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF2F8FF),
        fontFamily: 'Georgia',
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF2C4258),
              displayColor: const Color(0xFF2C4258),
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.72),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.45)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.45)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
      home: const TempConvPage(),
    );
  }
}

class TempConvPage extends StatefulWidget {
  const TempConvPage({super.key});

  @override
  State<TempConvPage> createState() => _TempConvPageState();
}

class _TempConvPageState extends State<TempConvPage> {
  bool _celsiusToFahrenheit = true;
  final _inputController = TextEditingController();
  String _result = '';
  bool _loading = false;
  String? _error;

  static String get _backendUrl {
    const url = String.fromEnvironment(
      'GRPC_BACKEND_URL',
      defaultValue: 'http://localhost:8080',
    );
    return url;
  }

  Future<void> _convert() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _error = 'Please enter a value';
        _result = '';
      });
      return;
    }

    final value = double.tryParse(input);
    if (value == null) {
      setState(() {
        _error = 'Please enter a valid number';
        _result = '';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = '';
    });

    try {
      final endpoint = _celsiusToFahrenheit ? '/v1/c2f' : '/v1/f2c';
      final resp = await http.post(
        Uri.parse('$_backendUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'value': value}),
      );

      if (resp.statusCode != 200) {
        throw Exception(resp.body);
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final result = (data['value'] as num).toDouble();
      setState(() {
        _result = result.toStringAsFixed(2);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Conversion failed: $e';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF4F9FF), Color(0xFFE6F1FC), Color(0xFFD9EAF9)],
              ),
            ),
          ),
          const _BackgroundOrb(
            size: 260,
            top: -70,
            left: -80,
            color: Color(0x55B8D2EA),
          ),
          const _BackgroundOrb(
            size: 220,
            bottom: -40,
            right: -70,
            color: Color(0x66A8C7E6),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.95, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, scale, child) {
                      return Opacity(
                        opacity: scale,
                        child: Transform.scale(scale: scale, child: child),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.68),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7A9CBF).withOpacity(0.13),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'TempConv',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                              letterSpacing: -0.8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Convert values quickly in a calm, clean workspace.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFF4D6883),
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          _buildModeToggle(theme),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _inputController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: _celsiusToFahrenheit
                                  ? 'Celsius (°C)'
                                  : 'Fahrenheit (°F)',
                              hintText: 'Enter temperature value',
                            ),
                            onSubmitted: (_) => _convert(),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _loading ? null : _convert,
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 17),
                              textStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                : const Text('Convert Now'),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _result.isNotEmpty
                                ? Padding(
                                    key: const ValueKey('result'),
                                    padding: const EdgeInsets.only(top: 20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceContainerHigh
                                            .withOpacity(0.95),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: colorScheme.secondary
                                              .withOpacity(0.55),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _celsiusToFahrenheit
                                                ? 'Result (°F)'
                                                : 'Result (°C)',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              color: const Color(0xFF4D6883),
                                            ),
                                          ),
                                          Text(
                                            _result,
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() {
                _celsiusToFahrenheit = true;
                _result = '';
                _error = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _celsiusToFahrenheit
                      ? colorScheme.primary.withOpacity(0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Celsius to Fahrenheit',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _celsiusToFahrenheit
                        ? colorScheme.primary
                        : const Color(0xFF5E7893),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() {
                _celsiusToFahrenheit = false;
                _result = '';
                _error = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_celsiusToFahrenheit
                      ? colorScheme.primary.withOpacity(0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Fahrenheit to Celsius',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: !_celsiusToFahrenheit
                        ? colorScheme.primary
                        : const Color(0xFF5E7893),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  const _BackgroundOrb({
    required this.size,
    required this.color,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final double size;
  final Color color;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}
