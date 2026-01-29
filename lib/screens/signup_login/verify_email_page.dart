import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trashtrack/services/auth_service.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({Key? key}) : super(key: key);

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _auth = AuthService();
  Timer? _timer;
  int _cooldown = 0;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Start polling every 5 seconds to detect verification.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerified());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final verified = await _auth.isEmailVerified();
      if (verified && mounted) {
        _timer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email verified. You can now log in.')));
        Navigator.of(context).pop();
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    try {
      await _auth.resendVerificationEmail();
      setState(() => _cooldown = 30);
      // start cooldown timer
      Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        if (_cooldown <= 1) {
          t.cancel();
          setState(() => _cooldown = 0);
        } else {
          setState(() => _cooldown -= 1);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification email resent')));
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to resend: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A verification email has been sent. Please check your inbox and follow the link to verify your account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cooldown == 0 ? _resend : null,
                child: Text(_cooldown == 0 ? 'Resend verification email' : 'Resend available in $_cooldown s'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _checkVerified,
                child: _checking ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('I have verified, check now'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
