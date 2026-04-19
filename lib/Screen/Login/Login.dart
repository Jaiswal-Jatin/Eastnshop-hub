
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../Constants/app_colors.dart';
import '../../Controllers/LoginController.dart';
import '../Userpanel/ForgotPassword.dart';
import '../../Routes/App_Pages.dart';
import 'TermsAndConditions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController loginController = Get.find();
  bool _obscurePassword = true; // Add this line to control password visibility
  final _formKey = GlobalKey<FormState>();
  String? _mobileError;
  String? _passwordError;
  String? _serverError;
  bool _isLoading = false;
  
  // Clear all form fields
  void _clearForm() {
    setState(() {
      loginController.eMailController.clear();
      loginController.confirmPassController.clear();
      _obscurePassword = true;
      _mobileError = null;
      _passwordError = null;
      _serverError = null;
    });
  }

  // Validate mobile number
  String? _validateMobile(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter mobile number';
    }
    if (value.length != 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  // Validate password
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Handle login with validation
  Future<void> _handleLogin() async {
    setState(() {
      _mobileError = null;
      _passwordError = null;
      _serverError = null;
    });

    // Validate mobile number
    String? mobileError = _validateMobile(loginController.eMailController.text);
    if (mobileError != null) {
      setState(() {
        _mobileError = mobileError;
      });
      return;
    }

    // Validate password
    String? passwordError = _validatePassword(loginController.confirmPassController.text);
    if (passwordError != null) {
      setState(() {
        _passwordError = passwordError;
      });
      return;
    }

    // If validation passes, call the login method
    bool loginSuccess = await loginController.loginUser();
    
    // Handle server errors
    if (!loginSuccess) {
      setState(() {
        _serverError = "Invalid mobile number or password. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 50),
            Center(
              child: Image.asset(
                'assets/Shopkeeper_logo.png',
                height: 150,
                width: 150,
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.only(left: 30, right: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ' Log in to your account',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, ),
                  ),
                  const SizedBox(height: 20),
                  customTextFieldWidget(
                    controller: loginController.eMailController,
                    hintText: "Mobile Number",
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 20),
                  customTextFieldWidget(
                    controller: loginController.confirmPassController,
                    hintText: "Password",
                    keyboardType: TextInputType.visiblePassword,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                const SizedBox(height: 5),
                 Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ForgotPassword(),
                            ),
                          ),
                      child: Text(' Forgot Password' , style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryBlue,
                      )),
                    ),
                  
                  ],
                ),
                   // Error message display below Sign In button
                   if (_mobileError != null || _passwordError != null || _serverError != null) ...[
                     const SizedBox(height: 15),
                     Container(
                       width: double.infinity,
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Colors.red.shade50,
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: Colors.red.shade200),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           if (_mobileError != null) ...[
                             Text(
                               _mobileError!,
                               style: TextStyle(
                                 color: Colors.red.shade700,
                                 fontSize: 14,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                             if (_passwordError != null || _serverError != null) const SizedBox(height: 8),
                           ],
                           if (_passwordError != null) ...[
                             Text(
                               _passwordError!,
                               style: TextStyle(
                                 color: Colors.red.shade700,
                                 fontSize: 14,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                             if (_serverError != null) const SizedBox(height: 8),
                           ],
                           if (_serverError != null)
                             Text(
                               _serverError!,
                               style: TextStyle(
                                 color: Colors.red.shade700,
                                 fontSize: 14,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                         ],
                       ),
                     ),
                   ],
                const SizedBox(height: 20),
                InkWell(
                    onTap: _isLoading ? null : () async { 
                      setState(() {
                        _isLoading = true;
                      });
                      await _handleLogin();
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },

                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: _isLoading ? Colors.grey : Color(0xFF00C853),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Sign In',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Divider(color: Colors.grey),
                Row(
                  children: [
                    Text(
                      'Create an account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    InkWell(
                      onTap: () {
                        _clearForm(); // Clear form before navigating to signup
                        Get.offNamedUntil(AppRoutes.login, (route) => route.settings.name == AppRoutes.appStart);
                        Get.toNamed(AppRoutes.signUp);
                      },

                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                  const SizedBox(height: 20),
                Center(
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsAndConditionsPage()),
                    ),
                    child: Text(
                      'Terms and Conditions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  customTextFieldWidget({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return SizedBox(
      height: 45,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey),
          counterText: maxLength != null ? "" : null, // Hide counter for mobile number
          suffixIcon: suffixIcon,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.grey,
              width: 1.0,
            ),
          ),
          contentPadding: EdgeInsets.only(top:12,bottom: 10,left: 10),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.grey,
              width: 1.0,
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
    );
  }
}
