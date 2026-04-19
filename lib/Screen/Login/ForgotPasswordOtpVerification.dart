import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../../Constants/app_colors.dart';
import '../../Controllers/LoginController.dart';
import 'Login.dart';
import 'ResetPassword.dart';

class ForgotPasswordOtpVerification extends StatefulWidget {
  final String phoneNumber;

  const ForgotPasswordOtpVerification({super.key, required this.phoneNumber});

  @override
  State<ForgotPasswordOtpVerification> createState() =>
      _ForgotPasswordOtpVerificationState();
}

class _ForgotPasswordOtpVerificationState
    extends State<ForgotPasswordOtpVerification> {
  final LoginController loginController = Get.find();
  final TextEditingController otpController = TextEditingController();

  bool otpSent = true;
  int secondsRemaining = 120;
  Timer? countdownTimer;
  bool isLoading = false;
  bool isVerifying = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  /// Start countdown timer
  void _startTimer() {
    setState(() {
      secondsRemaining = 120; // 2 minutes
      otpSent = true;
    });

    countdownTimer?.cancel();

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          secondsRemaining--;
        });
      }
    });
  }

  /// Verify OTP
  Future<void> _verifyOtp() async {
    if (otpController.text.isEmpty || otpController.text.length != 6) {
      setState(() {
        errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      isVerifying = true;
      errorMessage = null;
    });

    try {
      final result = await loginController.verifyForgotPasswordOtp(
        widget.phoneNumber,
        otpController.text,
      );

      if (result['success']) {
        // Navigate to reset password screen
        Get.to(() => ResetPasswordScreen(phoneNumber: widget.phoneNumber));
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Invalid OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error. Please try again.';
      });
    } finally {
      setState(() {
        isVerifying = false;
      });
    }
  }

  /// Resend OTP
  Future<void> _resendOtp() async {
    if (secondsRemaining == 0) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        final result = await loginController.resendForgotPasswordOtp(
          widget.phoneNumber,
        );

        if (result['success']) {
          _startTimer();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'OTP resent successfully!'),
              ),
            );
          }
        } else {
          setState(() {
            errorMessage = result['message'] ?? 'Failed to resend OTP';
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = 'Network error. Please try again.';
        });
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// Format seconds to MM:SS
  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/Shopkeeper_logo.png',
                    height: 120,
                    width: 120,
                  ),
                ),
                const SizedBox(height: 30),

                Text(
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  'We have sent a 6-digit verification code to',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 5),

                Text(
                  '+91 ${widget.phoneNumber}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: Color(0xFF00C853),
                  ),
                ),
                const SizedBox(height: 30),

                // OTP Input Field
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 24,
                      letterSpacing: 8,
                    ),
                    counterText: "",
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF00C853),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00C853)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF00C853),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      errorMessage = null;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Error Message
                if (errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Timer and Resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(secondsRemaining),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: secondsRemaining > 0 ? Colors.blue : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: secondsRemaining == 0 && !isLoading
                          ? _resendOtp
                          : null,
                      child: Text(
                        'Resend OTP',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          color: (secondsRemaining == 0 && !isLoading)
                              ? Color(0xFF00C853)
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                          decoration: (secondsRemaining == 0 && !isLoading)
                              ? TextDecoration.underline
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isVerifying ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isVerifying
                          ? Colors.grey
                          : Color(0xFF00C853),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 18,
                              fontFamily: 'Poppins',
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Back to Login
                Center(
                  child: InkWell(
                    onTap: () => Get.offAll(() => const LoginScreen()),
                    child: Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
