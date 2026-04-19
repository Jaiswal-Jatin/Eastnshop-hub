//// yes/no selected ks smjnar
/// i agree kshya sathi ahe and select/unselect verti action ky ahe??
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../Constants/app_colors.dart';
import '../../Controllers/LoginController.dart';
import '../../Routes/App_Pages.dart';
import '../../Services/OtpService.dart';
import 'TermsAndConditions.dart';

const Color _brandBlue = Color(0xFF0066CC);
const Color _brandOrange = Color(0xFFFF9900);
const Color _textDark = Color(0xFF212121);

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final LoginController loginController = Get.find();
  Timer? _phoneCheckDebounce;
  bool isChecked = false; // <-- Add this line
  bool isOtpButtonPressed = false; // Track OTP button state
  bool _obscureCreatePassword =
      true; // Add this line for create password visibility
  bool _obscureConfirmPassword =
      true; // Add this line for confirm password visibility
  Timer? timer;
  int _seconds = 60; // 01:45
  bool _isOtpSent = false; // Track if OTP has been sent
  String _errorMessage = ''; // Add this line for error messages
  String _successMessage = '';
  bool _isCheckingPhone = false;
  bool _isPhoneAvailable = false;
  bool _isPhoneCheckUnavailable = false;
  bool _isOtpVerified = false; // Track if OTP is verified
  bool _isVerifyingOtp = false; // Track if OTP verification is in progress
  bool _isCreatingAccount = false; // Track if account creation is in progress
  
  @override
  void initState() {
    loginController.userrole.text = "shopkeeper";
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    _phoneCheckDebounce?.cancel();
    super.dispose();
  }

  Future<void> _checkPhoneAvailability(String value) async {
    final phone = value.trim();

    if (phone.length != 10) {
      setState(() {
        _isCheckingPhone = false;
        _isPhoneAvailable = false;
      });
      return;
    }

    setState(() {
      _isCheckingPhone = true;
      _isPhoneAvailable = false;
      _errorMessage = '';
    });

    final result = await loginController.checkSignupPhoneAvailability(phone);
    if (!mounted) return;

    final exists = result['exists'] == true;
    final success = result['success'] == true;
    final checkUnavailable = result['checkUnavailable'] == true;

    final message = (result['message'] ?? '').toString();
    final isDifferentRole = message.toLowerCase().contains('different role');

    setState(() {
      _isCheckingPhone = false;
      _isPhoneCheckUnavailable = checkUnavailable;
      _isPhoneAvailable = (success && !exists) || isDifferentRole;

      if (exists && !isDifferentRole) {
        _errorMessage =
            'This phone number is already registered. Please login.';
        _successMessage = '';
        _isOtpSent = false;
      } else if (!success && message.isNotEmpty && !isDifferentRole) {
        _errorMessage = message;
        _successMessage = '';
      } else {
        _errorMessage = '';
      }
    });
  }

  // Clear all form fields
  void _clearForm() {
    setState(() {
      loginController.uNameController.clear();
      loginController.eMailController.clear();
      loginController.phoneController.clear();
      loginController.otpController.clear();
      loginController.createPassController.clear();
      loginController.confirmPassController.clear();
      loginController.userrole.text = "shopkeeper"; // Always set to shopkeeper
      isChecked = false;
      isOtpButtonPressed = false;
      _isOtpSent = false;
      _seconds = 60;
      _obscureCreatePassword = true;
      _obscureConfirmPassword = true;
      _errorMessage = '';
      _successMessage = '';
      _isCheckingPhone = false;
      _isPhoneAvailable = false;
      _isPhoneCheckUnavailable = false;
      _isOtpVerified = false;
      _isVerifyingOtp = false;
    });
    timer?.cancel();
    // Clear OTP ticket when form is cleared
    OtpService.clearSignupOtpTicket();
  }

  String get _timerText {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startTimer() {
    timer?.cancel(); // Cancel existing timer if any
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
        setState(() {
          // Don't reset _isOtpSent here - keep button disabled
          // _isOtpSent = false; // Reset OTP sent state when timer ends
        });
      } else {
        setState(() => _seconds--);
      }
    });
  }

  // Password validation function
  bool _validatePassword() {
    final password = loginController.createPassController.text;
    final confirmPassword = loginController.confirmPassController.text;

    if (password.length < 8) {
      setState(() {
        _errorMessage = "Password must be at least 8 characters long";
      });
      return false;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = "Passwords do not match";
      });
      return false;
    }

    return true;
  }

  // Automatic OTP verification when 6 digits are entered
  Future<void> _verifyOtpAutomatically() async {
    if (loginController.otpController.text.length == 6 &&
        !_isVerifyingOtp &&
        !_isOtpVerified) {
      setState(() {
        _isVerifyingOtp = true;
        _errorMessage = ''; // Clear any previous error
      });

      try {
        final result = await loginController.verifyOtp();

        if (result['success']) {
          setState(() {
            _isOtpVerified = true;
            _isVerifyingOtp = false;
            _errorMessage = ''; // Clear error on success
          });
          // Show success message
          print('✅ OTP verified successfully');
        } else {
          setState(() {
            _isOtpVerified = false;
            _isVerifyingOtp = false;
            _errorMessage = result['message'] ?? 'Please enter correct OTP';
          });
          // Clear the OTP field
          loginController.otpController.clear();
          print('❌ OTP verification failed: ${result['message']}');
        }
      } catch (e) {
        setState(() {
          _isOtpVerified = false;
          _isVerifyingOtp = false;
          _errorMessage = 'Failed to verify OTP. Please try again.';
        });
        // Clear the OTP field
        loginController.otpController.clear();
        print('❌ OTP error: $e');
      }
    }
  }

  void _showShopkeeperDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Are You A Shop Owner?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          loginController.userrole.text = "shopkeeper";
                          print("User selected: shopkeeper");
                          Navigator.pop(context);
                        },
                        label: const Text(
                          "Yes",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          loginController.userrole.text = "user";
                          print("User selected: user");
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "No",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromRGBO(0, 0, 0, 1),
              const Color.fromARGB(255, 85, 4, 102),
            ], // Replace with your two colors
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Obx(
          () => Stack(
            children: [
              ListView(
                children: [
                  AppBar(
                    title: Text(
                      'SIGN UP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    centerTitle: true,
                    backgroundColor: Colors.black,
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Color(0xFFF5F7FA),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(height: 10),
                        customTxtFieldWithName(
                          title: "Username",
                          hintText: "Enter Username",
                          controller: loginController.uNameController,
                        ),
                        customTxtFieldWithName(
                          title: "Email (Optional)",
                          hintText: "Enter Email Address",
                          controller: loginController.eMailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Phone",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                  color: _textDark,
                                ),
                              ),
                              SizedBox(
                                height: 50,
                                child: TextField(
                                  controller: loginController.phoneController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 10,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _errorMessage = '';
                                      _successMessage = '';
                                      _isCheckingPhone = false;
                                      _isPhoneAvailable = false;
                                      _isPhoneCheckUnavailable = false;
                                      // Reset OTP sent state when phone number changes
                                      if (_isOtpSent) {
                                        _isOtpSent = false;
                                        _seconds = 60; // Reset timer
                                        timer
                                            ?.cancel(); // Cancel existing timer
                                      }
                                      // Reset OTP verification status when phone changes
                                      _isOtpVerified = false;
                                      _isVerifyingOtp = false;
                                      loginController.otpController
                                          .clear(); // Clear OTP field
                                    }); // Trigger rebuild to update button state

                                    _phoneCheckDebounce?.cancel();
                                    if (value.trim().length == 10) {
                                      _phoneCheckDebounce = Timer(
                                        const Duration(milliseconds: 500),
                                        () => _checkPhoneAvailability(value),
                                      );
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Phone Number",
                                    hintStyle: const TextStyle(
                                      color: Colors.black26, // light grey hint
                                      fontSize: 16,
                                    ),
                                    counterText: "", // hides the counter below
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 11,
                                      horizontal: 10,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors
                                            .black26, // light grey border when not focused
                                        width: 1.0,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color:
                                            _brandBlue, // slightly darker grey when focused
                                        width: 1.5,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors
                                            .black26, // default light grey
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),



                        SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: SizedBox(
                            height: 35, // Adjust height if needed
                            child: ElevatedButton(
                              onPressed:
                                  (loginController
                                              .phoneController
                                              .text
                                              .length ==
                                          10 &&
                                      !_isOtpSent &&
                                      !_isCheckingPhone &&
                                      (_isPhoneAvailable ||
                                          _isPhoneCheckUnavailable))
                                  ? () async {
                                      if (!_isPhoneAvailable &&
                                          !_isPhoneCheckUnavailable) {
                                        setState(() {
                                          _errorMessage =
                                              'Please enter a valid new phone number for signup.';
                                        });
                                        return;
                                      }

                                      setState(() {
                                        isOtpButtonPressed = true;
                                        _errorMessage = '';
                                        _successMessage = '';
                                      });

                                      // Call the OTP API
                                      final result = await loginController
                                          .sendOtp();

                                      if (result['success']) {
                                        setState(() {
                                          _isOtpSent = true;
                                          _seconds =
                                              60; // Reset timer to 5 seconds
                                          _successMessage =
                                              (result['message'] ??
                                                      'OTP sent successfully')
                                                  .toString();
                                          _errorMessage = '';
                                        });
                                        // Auto-hide success message after 3 seconds
                                        Future.delayed(const Duration(seconds: 3), () {
                                          if (mounted) {
                                            setState(() {
                                              _successMessage = '';
                                            });
                                          }
                                        });
                                        // Start timer when Send OTP is clicked
                                        _startTimer();
                                        // Show success message
                                        // CommonWidgets.CustomeSnackBar(
                                        //   title: 'Success',
                                        //   message: result['message'] ?? 'OTP sent successfully',
                                        //   backgroundColor: Colors.green,
                                        // );
                                      } else {
                                        // Show error message
                                        final apiMessage =
                                            (result['message'] ?? '')
                                                .toString();
                                        final normalizedMessage = apiMessage
                                            .toLowerCase();
                                        final isAlreadyRegistered =
                                            normalizedMessage.contains(
                                              'already',
                                            ) ||
                                            normalizedMessage.contains(
                                              'exist',
                                            ) ||
                                            normalizedMessage.contains(
                                              'registered',
                                            );

                                        setState(() {
                                          _successMessage = '';
                                          _errorMessage = isAlreadyRegistered
                                              ? 'This phone number is already registered. Please login.'
                                              : (apiMessage.isNotEmpty
                                                    ? apiMessage
                                                    : 'Failed to send OTP');
                                        });
                                      }

                                      // Reset button state after 2 seconds
                                      Future.delayed(Duration(seconds: 2), () {
                                        setState(() {
                                          isOtpButtonPressed = false;
                                        });
                                      });
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    (loginController
                                                .phoneController
                                                .text
                                                .length ==
                                            10 &&
                                        !_isOtpSent &&
                                        !_isCheckingPhone &&
                                        (_isPhoneAvailable ||
                                            _isPhoneCheckUnavailable))
                                    ? (isOtpButtonPressed
                                          ? Colors.grey
                                          : Colors.green)
                                    : Colors
                                          .grey, // Gray when disabled, red when enabled
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    30,
                                  ), // Rounded edges
                                ),
                              ),
                              child: Text(
                                _isCheckingPhone
                                    ? "Checking..."
                                    : (_isOtpSent ? "OTP Sent" : "Send OTP"),
                                style: TextStyle(
                                  color: Colors.white, // Text color
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Enter OTP",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                  color: _textDark,
                                ),
                              ),
                              SizedBox(
                                height: 45,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  controller: loginController.otpController,
                                  onChanged: (value) {
                                    // Trigger automatic verification when 6 digits are entered
                                    if (value.length == 6) {
                                      _verifyOtpAutomatically();
                                    } else {
                                      // Reset verification status if user is still typing
                                      setState(() {
                                        _isOtpVerified = false;
                                        _errorMessage = '';
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Enter OTP",
                                    hintStyle: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 17,
                                      color: Colors.black26,
                                    ),
                                    counterText: "",
                                    contentPadding: EdgeInsets.only(
                                      top: 12,
                                      bottom: 10,
                                      left: 10,
                                    ),
                                    suffixIcon: _isVerifyingOtp
                                        ? Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(_brandBlue),
                                              ),
                                            ),
                                          )
                                        : _isOtpVerified
                                        ? Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
                                          )
                                        : null,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                        width: 1.0,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: _brandBlue,
                                        width: 1.5,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Show timer and resend option only after OTP is sent
                        if (_isOtpSent) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20.0,
                              top: 2.0,
                              right: 20.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer,
                                      size: 16,
                                      color: _brandBlue,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _timerText,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: _brandBlue, // #2C8DFE
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: _seconds == 0
                                      ? () async {
                                          // Call the resend OTP API
                                          final result = await loginController
                                              .resendOtp();

                                          if (result['success']) {
                                            setState(() {
                                              _seconds = 60;
                                              _isOtpSent =
                                                  true; // Keep OTP sent state true to disable button
                                              _successMessage =
                                                  (result['message'] ??
                                                          'OTP resent successfully')
                                                      .toString();
                                              _errorMessage = '';
                                            });
                                            // Auto-hide success message after 3 seconds
                                            Future.delayed(const Duration(seconds: 3), () {
                                              if (mounted) {
                                                setState(() {
                                                  _successMessage = '';
                                                });
                                              }
                                            });
                                            _startTimer();
                                            // Show success message
                                            // CommonWidgets.CustomeSnackBar(
                                            //   title: 'Success',
                                            //   message: result['message'] ?? 'OTP resent successfully',
                                            //   backgroundColor: Colors.green,
                                            // );
                                          } else {
                                            // Show error message
                                            setState(() {
                                              _successMessage = '';
                                              _errorMessage =
                                                  result['message'] ??
                                                  'Failed to resend OTP';
                                            });
                                          }
                                        }
                                      : null,
                                  child: Text(
                                    'Resend OTP',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                      color: _seconds == 0
                                          ? _brandBlue
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        customTxtFieldWithName(
                          title: "Create Password",
                          hintText: "Enter new password ",
                          controller: loginController.createPassController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: _obscureCreatePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCreatePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCreatePassword =
                                    !_obscureCreatePassword;
                              });
                            },
                          ),
                        ),
                        customTxtFieldWithName(
                          title: "Confirm Password",
                          hintText: "Confirm Password",
                          controller: loginController.confirmPassController,
                          keyboardType: TextInputType.visiblePassword,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Row(
                            children: [
                              Checkbox(
                                activeColor: _brandBlue,
                                value: isChecked,
                                onChanged: (value) {
                                  setState(() {
                                    isChecked = value!;
                                  });
                                },
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const TermsAndConditionsPage(),
                                    ),
                                  );

                                  if (result == true) {
                                    setState(() {
                                      isChecked = true;
                                    });
                                  }
                                },
                                child: Text(
                                  'Terms and Conditions',
                                  style: TextStyle(color: _brandBlue),
                                ),
                              ),
                              Spacer(),
                            ],
                          ),
                        ),
                        if (_successMessage.isNotEmpty)
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green[700],
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _successMessage,
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_errorMessage.isNotEmpty)
                          Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red[600],
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            bottom: 15,
                          ),
                          child: InkWell(
                            onTap: () async {
                              // Clear any previous error message
                              setState(() {
                                _errorMessage = '';
                                _successMessage = '';
                              });

                              // Check for empty required fields
                              if (loginController.uNameController.text.isEmpty ||
                                  loginController.phoneController.text.isEmpty ||
                                  loginController.otpController.text.isEmpty ||
                                  loginController.createPassController.text.isEmpty ||
                                  loginController.confirmPassController.text.isEmpty) {
                                setState(() {
                                  _errorMessage = "Please fill all required fields";
                                });
                                return;
                              }

                              // Validate password before proceeding
                              if (!_validatePassword()) {
                                return;
                              }

                              // Check if Terms and Conditions are agreed
                              if (!isChecked) {
                                setState(() {
                                  _errorMessage =
                                      "Please agree to the Terms and Conditions";
                                });
                                return;
                              }

                              // Check if OTP has been verified
                              if (!_isOtpVerified) {
                                setState(() {
                                  _errorMessage =
                                      "Please verify OTP first by entering the 6-digit code";
                                });
                                return;
                              }

                              setState(() {
                                _isCreatingAccount = true;
                              });
                              // Call registerNewUser and handle response
                              final result =
                                  await loginController.registerNewUser();
                              if (result['success']) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Account created successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              } else {
                                setState(() {
                                  _errorMessage = result['message'];
                                });
                              }
                              if (mounted) {
                                setState(() {
                                  _isCreatingAccount = false;
                                });
                              }
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: _isCreatingAccount
                                    ? Colors.grey
                                    : Color(0xFF00C853),
                              ),
                              child: Center(
                                child: _isCreatingAccount
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Create Account Now',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        // Error message display
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Back to login?',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 17,
                                color: _textDark,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                _clearForm(); // Clear form before navigating to login
                                Get.offNamedUntil(AppRoutes.signUp, (route) => route.settings.name == AppRoutes.appStart);
                                Get.toNamed(AppRoutes.login);
                              },
                              child: Text(
                                '   Login',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                  color: _brandBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  // const SizedBox(height: 20),

                  // const SizedBox(height: 30),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Text(
                  //       "By signing up, you agree to our ",
                  //       style: TextStyle(fontSize: 12, color: Colors.white),
                  //     ),
                  //     InkWell(
                  //       onTap: () => Navigator.push(
                  //         context,
                  //         MaterialPageRoute(builder: (context) => const TermsAndConditionsPage()),
                  //       ),
                  //       child: Text(
                  //         "Terms and Conditions.",
                  //         style: TextStyle(
                  //           fontSize: 12,
                  //           color: Colors.white,
                  //           decoration: TextDecoration.underline,
                  //           decorationColor: Colors.white,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // SizedBox(height: 20),
                ],
              ),
              if (loginController.isUploadingData.value)
                Positioned(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [CircularProgressIndicator()],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

customTxtFieldWithName({
  required String title,
  required String hintText,
  required TextEditingController controller,
  TextInputType? keyboardType,
  int? maxLength,
  List<TextInputFormatter>? inputFormatters,
  bool obscureText = false,
  Widget? suffixIcon,
}) {
  return Padding(
    padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: _textDark,
          ),
        ),
        SizedBox(
          height: 45,
          child: TextField(
            keyboardType: keyboardType,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 17,
                color: Colors.black26, // lighter grey
              ),
              suffixIcon: suffixIcon,
              counterText: "", // hide maxLength counter
              contentPadding: EdgeInsets.only(top: 12, bottom: 10, left: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _brandBlue, width: 1.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
