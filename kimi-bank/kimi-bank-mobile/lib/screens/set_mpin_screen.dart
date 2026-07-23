import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';

class SetMpinScreen extends StatefulWidget {
  const SetMpinScreen({super.key});

  @override
  State<SetMpinScreen> createState() => _SetMpinScreenState();
}

class _SetMpinScreenState extends State<SetMpinScreen> {
  final _authService = AuthService();
  String _mpin = '';
  String? _confirmMpin;
  bool _confirming = false;
  bool _loading = false;
  String? _error;

  void _onCompleted(String value) {
    if (!_confirming) {
      setState(() {
        _mpin = value;
        _confirming = true;
        _error = null;
      });
    } else {
      _confirmMpin = value;
      if (_confirmMpin != _mpin) {
        setState(() {
          _error = "MPINs don't match. Try again.";
          _confirming = false;
          _mpin = '';
        });
      } else {
        _submit();
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _authService.setMpin(_mpin);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set your MPIN')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _confirming ? 'Confirm your 6-digit MPIN' : 'Choose a 6-digit MPIN',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              "You'll use this to log in and approve payments.",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            PinCodeTextField(
              key: ValueKey(_confirming),
              appContext: context,
              length: 6,
              obscureText: true,
              onChanged: (_) {},
              onCompleted: _onCompleted,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(12),
                fieldHeight: 52,
                fieldWidth: 44,
                activeColor: AppColors.primary,
                selectedColor: AppColors.accent,
                inactiveColor: AppColors.border,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
            if (_loading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ],
        ),
      ),
    );
  }
}
