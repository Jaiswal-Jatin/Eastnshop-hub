import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';

import '../../../Services/OtpService.dart';
import '../../DrawerScreen.dart';
import '../Customappbar.dart';

class ChangeMobileScreen extends StatefulWidget {
  const ChangeMobileScreen({super.key});

  @override
  State<ChangeMobileScreen> createState() => _ChangeMobileScreenState();
}

class _ChangeMobileScreenState extends State<ChangeMobileScreen> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController confirmMobileController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool otpSent = false;
  int secondsRemaining = 120;
  Timer? countdownTimer;
  bool isLoading = false;
  bool isVerifying = false;

  void _startTimer() {
    setState(() {
      secondsRemaining = 120;
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

  Future<void> _sendOtp() async {
    if (mobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid current mobile number')),
      );
      return;
    }

    if (confirmMobileController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid new mobile number')),
      );
      return;
    }

    if (mobileController.text == confirmMobileController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'New mobile number cannot be same as current mobile number',
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await OtpService.sendOtp(
        phone: confirmMobileController.text,
        purpose: 'signup',
      );

      if (result['success']) {
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'OTP sent successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to send OTP')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Network error')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    if (secondsRemaining == 0) {
      setState(() {
        isLoading = true;
      });

      try {
        final result = await OtpService.resendOtp(
          phone: confirmMobileController.text,
          purpose: 'signup',
          channel: 'sms',
        );

        if (result['success']) {
          _startTimer();
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Network error')));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: const Text("Mobile Number Updated Successfully"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNumber() async {
    if (otpController.text.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter valid OTP')));
      return;
    }

    setState(() {
      isVerifying = true;
    });

    try {
      final result = await OtpService.verifyOtp(
        phone: confirmMobileController.text,
        otp: otpController.text,
        purpose: 'signup',
      );

      if (result['success']) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Invalid OTP')),
        );
      }
    } finally {
      setState(() {
        isVerifying = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    mobileController.addListener(() => setState(() {}));
    confirmMobileController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    mobileController.dispose();
    confirmMobileController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool sameNumber =
        mobileController.text.isNotEmpty &&
        confirmMobileController.text.isNotEmpty &&
        mobileController.text == confirmMobileController.text;

    bool enableSendOtp =
        mobileController.text.length == 10 &&
        confirmMobileController.text.length == 10 &&
        !sameNumber &&
        !otpSent &&
        !isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBarWithDrawer(),
      drawer: const DrawerScreen(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Change mobile number',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            _roundedTextField(
              controller: mobileController,
              hintText: 'Current Mobile Number',
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 10),

            _roundedTextField(
              controller: confirmMobileController,
              hintText: 'New Mobile Number',
              keyboardType: TextInputType.phone,
            ),

            if (sameNumber)
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  "New mobile number cannot be same as current mobile number",
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),

            const SizedBox(height: 15),

            SizedBox(
              height: 35,
              width: 120,
              child: GestureDetector(
                onTap: enableSendOtp ? _sendOtp : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: enableSendOtp
                        ? const Color(0xFF00C853)
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: isLoading
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          )
                        : const Text(
                            "Send OTP",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            if (otpSent)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatTime(secondsRemaining)),
                  GestureDetector(
                    onTap: secondsRemaining == 0 ? _resendOtp : null,
                    child: const Text(
                      "Resend OTP",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            _roundedTextField(
              controller: otpController,
              hintText: 'Enter OTP',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isVerifying ? null : _saveNumber,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isVerifying
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundedTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: hintText.contains("Mobile") ? 10 : 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        counterText: "",
        hintText: hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }
}
