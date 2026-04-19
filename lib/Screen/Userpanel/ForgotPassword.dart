import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../../Constants/app_colors.dart';
import '../../Controllers/LoginController.dart';
import '../Login/ForgotPasswordOtpVerification.dart';
import '../Login/Login.dart';

import '../../Screen/Login/TermsAndConditions.dart';
import '../AdminPanel/CreateOffer/PrivacyPolicy.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  TextEditingController emailController = TextEditingController();
  final LoginController loginController = Get.find();
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  /// Send OTP for password reset
  Future<void> _sendOtp() async {
    if (emailController.text.length != 10) {
      setState(() {
        errorMessage = 'Please enter a valid 10-digit mobile number';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await loginController.requestPasswordResetOtp(
        emailController.text,
      );

      if (result['success']) {
        // Navigate to OTP verification screen
        Get.to(
          () =>
              ForgotPasswordOtpVerification(phoneNumber: emailController.text),
        );
      } else {
        setState(() {
          errorMessage =
              result['message'] ?? 'Failed to send OTP. Please try again.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                children: [
                  const SizedBox(height: 50),
                  Center(
                    child: Image.asset(
                      'assets/Shopkeeper_logo.png',
                      height: 150,
                      width: 150,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Forgot your password?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Enter your mobile number and we’ll send you an authentication code',
                    style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(height: 20),
                  customTextFieldWidget(
                    controller: emailController,
                    hintText: "Mobile Number",
                    keyboardType: TextInputType.phone,
                    onChanged: (value) {
                      setState(() {
                        errorMessage = null; // Clear error when user types
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

                  // Send OTP Button
                  InkWell(
                    onTap: (emailController.text.length == 10 && !isLoading)
                        ? _sendOtp
                        : null,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: (emailController.text.length == 10 && !isLoading)
                            ? Color(0xFF00C853)
                            : Colors.grey,
                      ),
                      child: Center(
                        child: isLoading
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
                            : Text(
                                'Send OTP',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      ),
                      child: Text(
                        'Return to log in',
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

            // Legal Text at Bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "By continuing, you agree to our",
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Poppins',
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Get.to(() => const TermsAndConditionsPage()),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Terms and Conditions",
                          style: TextStyle(
                            color: AppColors.primaryRed,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryRed,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Text(
                        "&",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                      TextButton(
                        onPressed: () => Get.to(
                          () => const PrivacyPolicyPage(showAppBar: false),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Privacy Policy",
                          style: TextStyle(
                            color: AppColors.primaryRed,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primaryRed,
                            fontFamily: 'Poppins',
                          ),
                        ),
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

customTextFieldWidget({
  required TextEditingController controller,
  required String hintText,
  TextInputType keyboardType = TextInputType.text,
  Function(String)? onChanged,
}) {
  return SizedBox(
    height: 45,
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 10,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.only(top: 12, bottom: 10, left: 10),
        hintText: hintText,
        counterText: "",
        hintStyle: TextStyle(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey, width: 1.0),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey, width: 1.0),
        ),
      ),
    ),
  );
}
