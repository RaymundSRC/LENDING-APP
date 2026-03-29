import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SimpleAuthScreen extends StatefulWidget {
  final VoidCallback? onAuthenticated;

  const SimpleAuthScreen({super.key, this.onAuthenticated});

  @override
  State<SimpleAuthScreen> createState() => _SimpleAuthScreenState();
}

class _SimpleAuthScreenState extends State<SimpleAuthScreen> {
  String _enteredPin = '';
  String _errorMessage = '';
  List<bool> _pinDots = List.filled(4, false);

  static const String _defaultPin = '1234';

  void _onNumberPressed(String number) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += number;
        _pinDots[_enteredPin.length - 1] = true;
        _errorMessage = '';
      });

      HapticFeedback.lightImpact();

      if (_enteredPin.length == 4) {
        _handlePinSubmit();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _pinDots[_enteredPin.length - 1] = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
      HapticFeedback.lightImpact();
    }
  }

  void _handlePinSubmit() {
    if (_enteredPin == _defaultPin) {
      widget.onAuthenticated?.call();
    } else {
      setState(() {
        _errorMessage = 'Invalid PIN. Use 1234 for first time.';
        _enteredPin = '';
        _pinDots = List.filled(4, false);
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF263238),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo/Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF546E7A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    const Text(
                      'Enter your PIN to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // PIN Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _pinDots[index]
                                  ? const Color(0xFF546E7A)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        );
                      }),
                    ),

                    // Error Message
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Number Pad
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Number Rows
                  for (final row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ]) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row.map((number) {
                        return _NumberButton(
                          number: number,
                          onPressed: () => _onNumberPressed(number),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Last Row (0, Delete)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 80),
                      _NumberButton(
                        number: '0',
                        onPressed: () => _onNumberPressed('0'),
                      ),
                      const SizedBox(width: 80),
                      _DeleteButton(
                        onPressed: _onDeletePressed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final String number;
  final VoidCallback onPressed;

  const _NumberButton({
    required this.number,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DeleteButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Icon(
            Icons.backspace,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
