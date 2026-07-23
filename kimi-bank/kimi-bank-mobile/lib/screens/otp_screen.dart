import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'set_mpin_screen.dart';

/// Verifies a 6-digit OTP. For SIGNUP, completes account creation on success
/// and routes to MPIN setup. [devOtp] is only populated when the backend
/// is running in dev mode and is shown purely to speed up local testing.
class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String purpose;
  final String? fullName;
  final String? devOtp;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.purpose,
    this.fullName,
    this.devOtp,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _authService = AuthService();
  String _otp = '';
  bool _loading = false;

  Future<void> _verify() async {
    if (_otp.length != 6) return;
    setState(() => _loading = true);
    try {
      if (widget.purpose == 'SIGNUP') {
        await _authService.signup(
          fullName: widget.fullName!,
          phoneNumber: widget.phoneNumber,
          otp: _otp,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SetMpinScreen()),
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Enter the 6-digit code sent to +91 ${widget.phoneNumber}',
                style: Theme.of(context).textTheme.bodyMedium),
            if (widget.devOtp != null) ...[
              const SizedBox(height: 8),
              Text('Dev mode OTP: ${widget.devOtp}',
                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 24),
            PinCodeTextField(
              appContext: context,
              length: 6,
              onChanged: (value) => _otp = value,
              onCompleted: (value) {
                _otp = value;
                _verify();
              },
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
