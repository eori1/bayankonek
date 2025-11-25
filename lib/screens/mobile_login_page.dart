import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/page_header.dart';
import '../widgets/primary_gradient_button.dart';
import 'verify_code_page.dart';

class MobileLoginPage extends StatefulWidget {
  const MobileLoginPage({super.key});

  @override
  State<MobileLoginPage> createState() => _MobileLoginPageState();
}

class _MobileLoginPageState extends State<MobileLoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final PhoneNumberFormatter _phoneFormatter = PhoneNumberFormatter();
  bool _isSending = false;
  String? _errorMessage;

  String get _enteredDigits =>
      _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleAutoSignIn(PhoneAuthCredential credential) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage =
            'We couldn’t verify automatically. Please use the code.';
      });
    }
  }

  Future<void> _submitPhone() async {
    FocusScope.of(context).unfocus();
    final digits = _enteredDigits;

    if (digits.length != 10) {
      setState(() {
        _errorMessage = 'Please enter your complete 10-digit mobile number.';
      });
      return;
    }

    final phoneNumber = '+63$digits';

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await _handleAutoSignIn(credential);
        },
        verificationFailed: (exception) {
          if (!mounted) return;
          setState(() {
            _isSending = false;
            _errorMessage =
                exception.message ?? 'Failed to send verification code.';
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _isSending = false;
          });
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VerifyCodePage(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {
          if (!mounted) return;
          setState(() {
            _isSending = false;
          });
        },
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = e.message ?? 'Failed to send verification code.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PageHeader(
                  title: 'Login with Mobile',
                  onBack: () => Navigator.pop(context),
                ),
                const SizedBox(height: 8),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F1C3D).withValues(alpha: 0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2DA7F8),
                                    Color(0xFF1C64D9),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 20,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.smartphone_outlined,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Enter your Mobile Number',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F1F1F),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We’ll send you a verification code',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Cellphone Number',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF102A43),
                                ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FBFF),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFE4E8F3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF667699)
                                      .withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 18,
                                  ),
                                  child: Text(
                                    '+63',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E2C4D),
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: const Color(0xFFE0E5F0),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                      _phoneFormatter,
                                    ],
                                    onChanged: (_) {
                                      if (_errorMessage != null) {
                                        setState(() {
                                          _errorMessage = null;
                                        });
                                      } else {
                                        setState(() {});
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: '9XX XXX XXXX',
                                      hintStyle: TextStyle(
                                        letterSpacing: 1,
                                        color: Color(0xFF9AA3B9),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Insert 10-digit Number',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          _PreviewNumber(digits: _enteredDigits),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Color(0xFFE74C3C),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          PrimaryGradientButton(
                            label: 'Send Code',
                            isLoading: _isSending,
                            enabled: !_isSending,
                            onPressed: _submitPhone,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Prefer another option later? You’ll soon be able to link your number inside your profile.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Secure and safe access',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDigits(String digits) {
  final clean = digits.replaceAll(RegExp(r'[^0-9]'), '');
  final buffer = StringBuffer();
  for (var i = 0; i < clean.length && i < 10; i++) {
    if (i == 3 || i == 6) buffer.write(' ');
    buffer.write(clean[i]);
  }
  return buffer.toString();
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 10 ? digits.substring(0, 10) : digits;
    final formatted = _formatDigits(limited);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _PreviewNumber extends StatelessWidget {
  const _PreviewNumber({required this.digits});

  final String digits;

  @override
  Widget build(BuildContext context) {
    final formatted = _formatDigits(digits);
    final display = digits.isEmpty ? '+63 9XX XXX XXXX' : '+63 $formatted';

    return Text(
      display.trim(),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: digits.isEmpty ? Colors.grey.shade400 : const Color(0xFF0F60CC),
      ),
    );
  }
}
