import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../Constants/GlobalVariables.dart';
import '../../Constants/app_colors.dart';
import '../../Utils/ApiService.dart';
import '../../Utils/RefreshService.dart';
import '../../Utils/SharedPrefUtils.dart';
import 'dart:developer';
import '../AdminPanel/AdminDashboard/HomePage.dart';
import '../DrawerScreen.dart';
import 'Customappbar.dart';
import 'UserDashboard/UserHome.dart';

class SpecialPlansScreen extends StatefulWidget {
  const SpecialPlansScreen({super.key});

  @override
  State<SpecialPlansScreen> createState() => _SpecialPlansScreenState();
}

class _SpecialPlansScreenState extends State<SpecialPlansScreen> {
  static const String _configuredRazorpayKey = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
  );
  static const String _testRazorpayKey = 'rzp_test_SNvb24HNx40RgV';
  static const bool _forceDirectTestCheckout = false;

  int selectedPlanIndex = -1;
  bool _isApiLoading = false; // drives the loading dialog
  bool isFetchingPlans = true; // drives the screen-level loader
  bool hasActiveSubscription = false;
  Map<String, dynamic>? subscriptionData;
  List<SubscriptionPlan> dynamicRegularPlans = [];
  List<SubscriptionPlan> dynamicActiveSubscriberPlans = [];

  // Razorpay instance
  late Razorpay _razorpay;

  // Holds state needed by Razorpay callbacks
  SubscriptionPlan? _pendingPlan;
  int? _pendingUserId;
  String? _pendingOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _checkSubscriptionStatus(); // This will trigger _fetchPlans internally
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      // Get user ID from SharedPreferences
      await SharedPrefUtils.init();
      String? userIdStr = SharedPrefUtils.getString('user_id');

      if (userIdStr == null || userIdStr.isEmpty) {
        _selectMostPopularPlan();
        return;
      }

      int? userId = int.tryParse(userIdStr);
      if (userId == null || userId <= 0) {
        _selectMostPopularPlan();
        return;
      }

      // Fetch subscription details
      Map<String, dynamic> result = await ApiService.getSubscriptionDetails(
        userId,
      );

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          subscriptionData = result['data'];
          String planType =
              subscriptionData?['plan']?.toString().toLowerCase() ?? '';
          String status =
              subscriptionData?['status']?.toString().toLowerCase() ?? '';

          // Check if it's a trial plan or active subscription (but not trial)
          hasActiveSubscription = status == 'active' && planType != 'trial';
        });
      } else {
        // Show error if 402 Payment Required
        if (result['statusCode'] == 402) {
          _showError(
            'Payment required. Please subscribe to a plan to continue.',
          );
        }
        setState(() {
          hasActiveSubscription = false;
        });
      }
    } catch (e) {
      setState(() {
        hasActiveSubscription = false;
      });
    } finally {
      // Always fetch plans after checking subscription status
      _fetchPlans();
    }
  }

  void _selectMostPopularPlan() {
    final currentPlans = plans;
    for (int i = 0; i < currentPlans.length; i++) {
      if (currentPlans[i].isPopular && !currentPlans[i].isCurrentlyActive) {
        setState(() {
          selectedPlanIndex = i;
        });
        return;
      }
    }
    // Fallback: pick first non-active plan
    for (int i = 0; i < currentPlans.length; i++) {
      if (!currentPlans[i].isCurrentlyActive) {
        setState(() {
          selectedPlanIndex = i;
        });
        return;
      }
    }
    if (currentPlans.isNotEmpty) {
      setState(() {
        selectedPlanIndex = 0;
      });
    }
  }

  Future<void> _fetchPlans() async {
    try {
      setState(() {
        isFetchingPlans = true;
      });

      List<SubscriptionPlan> fetchedPlans = [];
      String activePlanName = subscriptionData?['plan']?.toString().toLowerCase() ?? '';

      // Helper function to map API data
      void addPlansFromApiResult(dynamic result) {
        if (result['success'] == true && result['data'] != null) {
          final List<dynamic> apiData = result['data'];
          for (var item in apiData) {
            final String name = item['name']?.toString() ?? 'Unknown';
            final double price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
            final int days = int.tryParse(item['days']?.toString() ?? '0') ?? 0;
            final int adsLimit = int.tryParse(item['ads_limit']?.toString() ?? '0') ?? 0;
            
            // Determine duration display dynamically
            String duration = "";
            if (name.toLowerCase().contains('offer') || adsLimit == 1) {
              duration = "Individual Ad";
            } else if (days == 30) {
              duration = "1 Month";
            } else if (days == 90) {
              duration = "3 Months";
            } else if (days == 180) {
              duration = "6 Months";
            } else if (days == 365) {
              duration = "1 Year";
            } else {
              duration = "$days Days";
            }

            // Determine Savings and Popularity based on tiers
            String? savings;
            bool isPopular = false;

            if (adsLimit > 1) {
              if (days == 90) savings = "Save 25%";
              if (days == 180) {
                savings = "Save 40%";
                isPopular = true; // Mark 6 months as popular
              }
              if (days == 365) savings = "Save 50%";
            } else {
              if (!hasActiveSubscription) {
                isPopular = true; // Mark individual ad as popular if no active sub
              }
            }

            bool isCurrentlyActive = hasActiveSubscription && name.toLowerCase() == activePlanName;

            SubscriptionPlan plan = SubscriptionPlan(
              duration: duration,
              adsCount: "$adsLimit offers",
              price: "₹${price.toStringAsFixed(0)}",
              isPopular: isPopular && !isCurrentlyActive,
              savings: savings,
              borderColor: isPopular && !isCurrentlyActive ? AppColors.primaryRed : Colors.grey.shade300,
              apiPlan: name,
              isCurrentlyActive: isCurrentlyActive,
            );

            fetchedPlans.add(plan);
          }
        }
      }

      // Always fetch regular plans
      final regularResult = await ApiService.getPlans();
      addPlansFromApiResult(regularResult);

      // If active subscription, ALSO fetch additional plans
      if (hasActiveSubscription) {
        final additionalResult = await ApiService.getAdditionalPlans();
        addPlansFromApiResult(additionalResult);
      }

      setState(() {
        dynamicRegularPlans = fetchedPlans;
        dynamicActiveSubscriberPlans = [];
        isFetchingPlans = false;
      });
      
      _selectMostPopularPlan();

    } catch (e) {
      log('❌ Error fetching plans: $e');
      setState(() {
        isFetchingPlans = false;
      });
    }
  }

  // Get the appropriate plans list based on subscription status
  List<SubscriptionPlan> get plans {
    // Return all plans fetched for the current subscription state
    return dynamicRegularPlans;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Simply navigate back to previous screen
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBarWithDrawer(),
        drawer: const DrawerScreen(),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Special Plans",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    _buildHeader(),
                    if (isFetchingPlans)
                      const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00C853),
                          ),
                        ),
                      )
                    else ...[
                      const SizedBox(height: 8),
                      _buildPlansList(),
                      const SizedBox(height: 20),
                      _buildSubscribeButton(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Special Plans",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String planType = subscriptionData?['plan']?.toString().toLowerCase() ?? '';
    String status = subscriptionData?['status']?.toString().toLowerCase() ?? '';
    bool isTrialPlan = planType == 'trial' && status == 'active';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        hasActiveSubscription
            ? "You have an active subscription! Upgrade your plan below."
            : isTrialPlan
            ? "You're on a trial plan. Choose a subscription plan to continue."
            : "Choose the right plan for you.",
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildPlansList() {
    return Column(
      children: plans.asMap().entries.map((entry) {
        int index = entry.key;
        SubscriptionPlan plan = entry.value;
        return _buildPlanCard(plan, index);
      }).toList(),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, int index) {
    return GestureDetector(
      onTap: () {
        if (plan.isCurrentlyActive) return;
        _showSubscriptionDialog(plan, index);
      },
      child: Column(
        children: [
          if (plan.isPopular && selectedPlanIndex == index)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF00C853),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: const Text(
                "Most Popular",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          // Main Plan Card
          Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: selectedPlanIndex == index
                    ? Color(0xFF00C853)
                    : Colors.grey.shade300,
                width: selectedPlanIndex == index ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: selectedPlanIndex == index
                  ? AppColors.primaryRed.withValues(alpha: 0.05)
                  : Colors.white,
            ),
            child: Stack(
              children: [
                // Main content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.duration,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plan.adsCount,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              plan.price,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            if (plan.isCurrentlyActive) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Already Active',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Savings Badge
                if (plan.savings != null)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: plan.savings!.contains("25%")
                            ? Colors.orange
                            : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        plan.savings!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    final SubscriptionPlan? currentSelectedPlan = selectedPlanIndex >= 0 && selectedPlanIndex < plans.length ? plans[selectedPlanIndex] : null;
    final bool disabled = selectedPlanIndex < 0 || (currentSelectedPlan?.isCurrentlyActive ?? false);
    
    String buttonText = 'Select a Plan First';
    if (currentSelectedPlan != null) {
      if (currentSelectedPlan.isCurrentlyActive) {
        buttonText = 'Already Active';
      } else {
        buttonText = hasActiveSubscription ? 'Proceed To Pay' : 'Activate Plan';
      }
    }

    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        onPressed: disabled
            ? null
            : () => _handleSubscriptionConfirmation(plans[selectedPlanIndex]),
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? Colors.grey : const Color(0xFF00C853),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  void _showSubscriptionDialog(SubscriptionPlan plan, int index) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plan.price,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.duration,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.adsCount,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Select this plan
                      setState(() {
                        selectedPlanIndex = index;
                      });
                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(
                      //     content: Text('${plan.duration} plan selected!'),
                      //     backgroundColor: Colors.green,
                      //     duration: const Duration(seconds: 2),
                      //   ),
                      // );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00C853),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      hasActiveSubscription
                          ? "Add To Offer"
                          : "Select This Plan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubscriptionConfirmation(SubscriptionPlan plan) async {
    _showLoadingDialog('Preparing payment...');
    try {
      // Step 1 – validate plan and get price/days/adsLimit
      log('🔄 Subscribing to plan: ${plan.apiPlan}');
      print('DEBUG: Attempting to subscribe to plan: ${plan.apiPlan}');
      print(
        'DEBUG: Plan details: duration=${plan.duration}, price=${plan.price}, adsCount=${plan.adsCount}',
      );

      final subscribeResult = await ApiService.subscribeToPlan(plan.apiPlan);

      print('DEBUG: Subscribe result: $subscribeResult');

      if (subscribeResult['success'] != true) {
        _hideLoadingDialog();
        final String errorMsg =
            subscribeResult['error'] ?? 'Subscription request failed';
        final int? statusCode = subscribeResult['statusCode'] as int?;

        log('❌ Subscription failed: $errorMsg (Status: $statusCode)');
        print(
          'DEBUG: ERROR - Subscription failed: $errorMsg, Status: $statusCode',
        );

        // Show detailed error message
        String userMessage = errorMsg;
        if (statusCode == 400) {
          userMessage = 'Invalid plan selected. Please try again.';
        } else if (statusCode == 402) {
          userMessage = 'Payment required. Please check your payment method.';
        } else if (statusCode == 403) {
          userMessage = 'Access denied. Please contact support.';
        } else if (statusCode == 500) {
          userMessage = 'Server error. Please try again later.';
        }

        _showError(userMessage);
        return;
      }

      final int priceInRupees = (subscribeResult['price'] ?? 0) as int;

      // Step 2 – create a Razorpay order
      log('🔄 Creating payment order for plan: ${plan.apiPlan}');
      print('DEBUG: Creating Razorpay order for plan: ${plan.apiPlan}');

      final orderResult = await ApiService.createPaymentOrder(plan.apiPlan);

      print('DEBUG: Razorpay order result: $orderResult');

      if (orderResult['success'] != true) {
        _hideLoadingDialog();
        final String errorMsg =
            orderResult['error'] ?? 'Failed to create payment order';
        final int? statusCode = orderResult['statusCode'] as int?;

        log('❌ Payment order failed: $errorMsg (Status: $statusCode)');
        print(
          'DEBUG: ERROR - Payment order failed: $errorMsg, Status: $statusCode',
        );

        // Show detailed error message
        String userMessage = errorMsg;
        if (statusCode == 400) {
          userMessage = 'Invalid payment request. Please try again.';
        } else if (statusCode == 402) {
          userMessage = 'Payment configuration error. Please contact support.';
        } else if (statusCode == 403) {
          userMessage = 'Payment access denied. Please contact support.';
        } else if (statusCode == 500) {
          userMessage = 'Payment server error. Please try again later.';
        }

        _showError(userMessage);
        return;
      }

      final String orderId = orderResult['orderId'] ?? '';
      final int amountInPaise =
          (orderResult['amount'] ?? priceInRupees * 100) as int;
      final String razorpayKey = _configuredRazorpayKey.isNotEmpty
          ? _configuredRazorpayKey
          : (orderResult['keyId']?.toString().trim().isNotEmpty == true
                ? orderResult['keyId'].toString().trim()
                : _testRazorpayKey);

      if (orderId.isEmpty && !_forceDirectTestCheckout) {
        _hideLoadingDialog();
        _showError('Payment order ID is missing. Please try again.');
        return;
      }
      if (amountInPaise <= 0) {
        _hideLoadingDialog();
        _showError('Invalid payment amount. Please try again.');
        return;
      }
      if (razorpayKey.isEmpty) {
        _hideLoadingDialog();
        _showError('Payment config missing: Razorpay key not found.');
        return;
      }

      await SharedPrefUtils.init();
      _pendingUserId = int.tryParse(SharedPrefUtils.getString('user_id') ?? '');
      _pendingPlan = plan;
      _pendingOrderId = orderId;

      final String contact = (SharedPrefUtils.getString('user_phone') ?? '')
          .trim();
      final String email = (SharedPrefUtils.getString('user_email') ?? '')
          .trim();

      final Map<String, dynamic> options = {
        'key': razorpayKey,
        'amount': amountInPaise,
        'name': 'EastnShop Hub',
        'description': '${plan.duration} Subscription',
        'external': {
          'wallets': ['paytm'],
        },
        'retry': {'enabled': true, 'max_count': 1},
      };

      options['order_id'] = orderId;

      final Map<String, String> prefill = {};
      if (contact.isNotEmpty && RegExp(r'^\d{10,15}$').hasMatch(contact)) {
        prefill['contact'] = contact;
      }
      if (email.isNotEmpty && email.contains('@')) {
        prefill['email'] = email;
      }
      if (prefill.isNotEmpty) {
        options['prefill'] = prefill;
      }

      log(
        '🧾 Razorpay open payload => key: $razorpayKey, orderId: $orderId, amount: $amountInPaise, prefill: $prefill',
      );

      // Dismiss loading BEFORE handing control to Razorpay
      _hideLoadingDialog();

      // Step 3 – open Razorpay checkout
      _razorpay.open(options);
    } catch (e) {
      _hideLoadingDialog();
      _showError('An error occurred: ${e.toString()}');
    }
  }

  // ── Loading dialog helpers ────────────────────────────────────────────────

  void _showLoadingDialog(String message) {
    if (!mounted || _isApiLoading) return;
    setState(() => _isApiLoading = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF00C853),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (!mounted || !_isApiLoading) return;
    setState(() => _isApiLoading = false);
    Navigator.of(context, rootNavigator: true).pop();
  }

  // ── Razorpay callbacks ────────────────────────────────────────────────────

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _showLoadingDialog('Verifying payment...');
    try {
      if (_pendingPlan == null || _pendingUserId == null) {
        _hideLoadingDialog();
        _showError('Payment context lost. Please contact support.');
        return;
      }

      final String orderIdForVerify = (response.orderId ?? '').isNotEmpty
          ? (response.orderId ?? '')
          : (_pendingOrderId ?? '');
      if (orderIdForVerify.isEmpty ||
          (response.paymentId ?? '').isEmpty ||
          (response.signature ?? '').isEmpty) {
        _hideLoadingDialog();
        _showError('Payment data missing for verification. Please try again.');
        return;
      }

      final verifyResult = await ApiService.verifyPayment(
        razorpayOrderId: orderIdForVerify,
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
        userId: _pendingUserId!,
        plan: _pendingPlan!.apiPlan,
      );

      _hideLoadingDialog();

      if (verifyResult['success'] == true) {
        await _checkSubscriptionStatus();
        // Trigger global refresh for other pages to update plan status
        RefreshService.to.triggerPlanRefresh();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                hasActiveSubscription
                    ? 'Ad purchased successfully!'
                    : '${_pendingPlan!.duration} subscription activated successfully!',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context);
          });
        }
      } else {
        final int? statusCode = verifyResult['statusCode'] as int?;
        // Even on a 500, the backend may have activated the plan before crashing.
        // Refresh subscription status so the user isn't left with a broken UI.
        if (statusCode == 500) {
          await _checkSubscriptionStatus();
          if (hasActiveSubscription) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription activated successfully!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) Navigator.pop(context);
              });
            }
            return;
          }
        }
        final String errorMessage =
            verifyResult['error'] ?? 'Payment verification failed';
        if (statusCode != null) {
          _showError('Verify failed ($statusCode): $errorMessage');
        } else {
          _showError(errorMessage);
        }
      }
    } catch (e) {
      _hideLoadingDialog();
      _showError('Payment verification error: ${e.toString()}');
    } finally {
      _pendingPlan = null;
      _pendingUserId = null;
      _pendingOrderId = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _pendingPlan = null;
    _pendingUserId = null;
    _pendingOrderId = null;
    final String message =
        'Payment failed (code ${response.code ?? 'N/A'}): ${response.message ?? 'Unknown error'}';
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet selected: ${response.walletName}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

class SubscriptionPlan {
  final String duration;
  final String adsCount;
  final String price;
  final bool isPopular;
  final String? savings;
  final Color borderColor;
  final String apiPlan;
  final bool isCurrentlyActive;

  SubscriptionPlan({
    required this.duration,
    required this.adsCount,
    required this.price,
    required this.isPopular,
    this.savings,
    required this.borderColor,
    required this.apiPlan,
    this.isCurrentlyActive = false,
  });
}
