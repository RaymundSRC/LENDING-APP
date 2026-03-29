import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback? onAuthenticated;

  const AuthScreen({super.key, this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  String _enteredPin = '';
  bool _isFirstTime = false;
  bool _isSetupMode = false;
  String? _selectedSecurityQuestion;
  String? _errorMessage;
  List<bool> _pinDots = List.filled(6, false);

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final firstTime = await AuthService.isFirstTime();
    final pinSet = await AuthService.isPinSet();

    setState(() {
      _isFirstTime = firstTime || !pinSet;
      _isSetupMode = _isFirstTime;
    });
  }

  void _onNumberPressed(String number) {
    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += number;
        _pinDots[_enteredPin.length - 1] = true;
        _errorMessage = null;
      });

      HapticFeedback.lightImpact();

      if (_enteredPin.length >= 4) {
        _handlePinSubmit();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _pinDots[_enteredPin.length - 1] = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _handlePinSubmit() async {
    if (_isSetupMode) {
      if (_enteredPin.length < 4) {
        setState(() => _errorMessage = 'PIN must be at least 4 digits');
        return;
      }
      _showSecurityQuestionSetup();
    } else {
      final isValid = await AuthService.validatePin(_enteredPin);

      if (isValid) {
        await AuthService.updateLastActiveTime();
        widget.onAuthenticated?.call();
      } else {
        setState(() {
          _errorMessage = 'Invalid PIN';
          _enteredPin = '';
          _pinDots = List.filled(6, false);
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _showSecurityQuestionSetup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Setup Security Question'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedSecurityQuestion,
                  decoration: const InputDecoration(
                    labelText: 'Select Security Question',
                    border: OutlineInputBorder(),
                  ),
                  items: AuthService.getSecurityQuestions()
                      .map((question) => DropdownMenuItem(
                            value: question,
                            child: Text(question),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => _selectedSecurityQuestion = value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _answerController,
                  decoration: const InputDecoration(
                    labelText: 'Your Answer',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearPin();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_selectedSecurityQuestion != null &&
                  _answerController.text.isNotEmpty) {
                final success = await AuthService.setSecurityQuestion(
                  _selectedSecurityQuestion!,
                  _answerController.text,
                );

                if (success) {
                  final pinSuccess = await AuthService.setPin(_enteredPin);
                  if (pinSuccess) {
                    widget.onAuthenticated?.call();
                  }
                }
              }
            },
            child: const Text('Complete Setup'),
          ),
        ],
      ),
    );
  }

  void _showRecoveryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Recovery'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<String?>(
                  future: AuthService.getSecurityQuestion(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }

                    final question = snapshot.data;
                    if (question == null) {
                      return const Text(
                          'No security question set. Contact support.');
                    }

                    return Column(
                      children: [
                        Text(
                          question,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _answerController,
                          decoration: const InputDecoration(
                            labelText: 'Your Answer',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final isValid = await AuthService.validateSecurityAnswer(
                _answerController.text,
              );

              if (isValid) {
                Navigator.of(context).pop();
                _showPinResetDialog();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Incorrect answer')),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showPinResetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Set New PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newPinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'New PIN (4-6 digits)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_newPinController.text == _confirmPinController.text &&
                  _newPinController.text.length >= 4) {
                final success =
                    await AuthService.resetPin(_newPinController.text);
                if (success && mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN reset successfully')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('PINs do not match or too short')),
                );
              }
            },
            child: const Text('Reset PIN'),
          ),
        ],
      ),
    );
  }

  void _clearPin() {
    setState(() {
      _enteredPin = '';
      _pinDots = List.filled(6, false);
      _errorMessage = null;
    });
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
                    Text(
                      _isSetupMode ? 'Setup Security' : 'Welcome Back',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      _isSetupMode
                          ? 'Create your PIN to secure the app'
                          : 'Enter your PIN to continue',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // PIN Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
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
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
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

                  // Last Row (0, Delete, Recovery)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!_isSetupMode) ...[
                        _RecoveryButton(
                          onPressed: _showRecoveryDialog,
                        ),
                        const SizedBox(width: 80),
                      ] else ...[
                        const SizedBox(width: 80),
                      ],
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

  @override
  void dispose() {
    _pinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _answerController.dispose();
    super.dispose();
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

class _RecoveryButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RecoveryButton({
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
          color: Colors.orange.shade800,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Icon(
            Icons.help_outline,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
