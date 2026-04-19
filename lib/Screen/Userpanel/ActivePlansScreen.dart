import 'package:flutter/material.dart';

import '../../Constants/GlobalVariables.dart';
import '../../Constants/app_colors.dart';
import '../../Utils/ApiService.dart';
import '../../Utils/SharedPrefUtils.dart';
import '../AdminPanel/AdminDashboard/HomePage.dart';
import '../DrawerScreen.dart';
import 'Customappbar.dart';
import 'UserDashboard/UserHome.dart';
import 'SpecialPlansScreen.dart';
import '../../Utils/RefreshService.dart';
import 'package:get/get.dart';

class ActivePlansScreen extends StatefulWidget {
  const ActivePlansScreen({super.key});

  @override
  State<ActivePlansScreen> createState() => _ActivePlansScreenState();
}

class _ActivePlansScreenState extends State<ActivePlansScreen> {
  bool isLoading = true;
  Map<String, dynamic>? subscriptionData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionDetails();
    
    // Listen for global refresh triggers
    ever(RefreshService.to.refreshTrigger, (_) {
      if (mounted) {
        print('🔄 ActivePlansScreen: Refresh triggered, reloading details...');
        _loadSubscriptionDetails();
      }
    });
  }

  Future<void> _loadSubscriptionDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get user ID from SharedPreferences
      await SharedPrefUtils.init();
      String? userIdStr = SharedPrefUtils.getString('user_id');
      
      if (userIdStr == null || userIdStr.isEmpty) {
        setState(() {
          errorMessage = "User not authenticated. Please login again.";
          isLoading = false;
        });
        return;
      }
      
      int? userId = int.tryParse(userIdStr);
      if (userId == null || userId <= 0) {
        setState(() {
          errorMessage = "Invalid user ID. Please login again.";
          isLoading = false;
        });
        return;
      }

      // Fetch subscription details
      Map<String, dynamic> result = await ApiService.getSubscriptionDetails(userId);

      if (result['success'] == true) {
        setState(() {
          subscriptionData = result['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['error'] ?? "Failed to load subscription details";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "An error occurred: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  String _getPlanDisplayName(String plan) {
    switch (plan.toLowerCase()) {
      case '1m':
        return '1 Month Plan';
      case '3m':
        return '3 Months Plan';
      case '6m':
        return '6 Months Plan';
      case '1y':
        return '1 Year Plan';
      case '1offer':
        return 'Extra Ad Plan';
      case 'trial':
        return 'Trial Plan';
      default:
        return plan.toUpperCase();
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'green';
      case 'expired':
        return 'red';
      case 'pending':
        return 'orange';
      default:
        return 'grey';
    }
  }

  Color _getStatusColorValue(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate directly to home page instead of following history
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => globalUser.value == true ? HomePage() : HomePage(),
          ),
          (route) => false, // Remove all previous routes
        );
        return false; // Prevent default back behavior
      },
        child:Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBarWithDrawer(),
      drawer: const DrawerScreen(),
      body: SafeArea(
        bottom: true,
        child: Column(
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
                           icon: const Icon(Icons.arrow_back, color: Colors.black),
                           onPressed: () {
                             // Navigate directly to home page instead of following history
                             Navigator.pushAndRemoveUntil(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => globalUser.value == true ? HomePage() : HomePage(),
                               ),
                               (route) => false, // Remove all previous routes
                             );
                           },
                         ),
                        const SizedBox(width: 8),
                        const Text(
                          "Active Plans",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
  
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(50.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryRed,
                          ),
                        ),
                      )
                    else if (errorMessage != null)
                      _buildErrorWidget()
                    else if (subscriptionData != null)
                      _buildSubscriptionDetails()
                    else
                      _buildNoSubscriptionWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        )  );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadSubscriptionDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Retry",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.subscriptions_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            "No Active Subscription",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "You don't have an active subscription plan. Subscribe to a plan to start posting ads.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SpecialPlansScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "View Plans",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    final plan = subscriptionData!['plan'] ?? '';
    final status = subscriptionData!['status'] ?? '';
    final endsAt = subscriptionData!['endsAt'] ?? '';
    final remainingDays = subscriptionData!['remainingDays'] ?? 0;
    final adsUsed = subscriptionData!['adsUsed'] ?? 0;
    final adsLimit = subscriptionData!['adsLimit'] ?? 0;
    final isTrialPlan = plan.toLowerCase() == 'trial';
    final isExpired = plan == null || plan.isEmpty || remainingDays <= 0;

    return Column(
      children: [
        // Expired Plan Warning (if applicable)
        if (isExpired)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: Colors.red.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Plan Expired",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Your subscription plan has expired. Please upgrade to continue posting ads.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red.shade600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        
        // Trial Plan Warning (if applicable)
        if (isTrialPlan && !isExpired)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Trial Plan Active",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "You're currently on a trial plan. Subscribe to a paid plan to continue posting ads after the trial expires.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        
        // Plan Status Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isExpired
                  ? Colors.red.withOpacity(0.1)
                  : isTrialPlan 
                    ? Colors.orange.withOpacity(0.1)
                    : AppColors.primaryRed.withOpacity(0.1),
                isExpired
                  ? Colors.red.withOpacity(0.05)
                  : isTrialPlan 
                    ? Colors.orange.withOpacity(0.05)
                    : AppColors.primaryRed.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpired
                ? Colors.red.withOpacity(0.3)
                : isTrialPlan 
                  ? Colors.orange.withOpacity(0.3)
                  : AppColors.primaryRed.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isExpired ? 'No Active Plan' : _getPlanDisplayName(plan),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isExpired 
                        ? Colors.red 
                        : isTrialPlan 
                          ? Colors.orange 
                          : _getStatusColorValue(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isExpired 
                        ? 'EXPIRED' 
                        : isTrialPlan 
                          ? 'TRIAL' 
                          : status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      isExpired ? "Days Overdue" : "Remaining Days",
                      isExpired ? "0 days" : "$remainingDays days",
                      Icons.calendar_today,
                      isExpired ? Colors.red : Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      isExpired ? "Expired On" : "Expires On",
                      isExpired ? "Plan Expired" : _formatDate(endsAt),
                      Icons.event,
                      isExpired ? Colors.red : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Ads Usage Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Ads Usage",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Used: $adsUsed",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    "Limit: $adsLimit",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: adsLimit > 0 ? adsUsed / adsLimit : 0,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  adsUsed >= adsLimit ? Color(0xFF00C853) : Color(0xFF00C853),
                ),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                "${adsLimit > 0 ? ((adsUsed / adsLimit) * 100).toStringAsFixed(1) : '0.0'}% used",
                style: TextStyle(
                  fontSize: 12,
                  color: adsUsed >= adsLimit ? Colors.red : Colors.grey.shade600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Action Buttons
        if (isExpired)
          // For expired plans, show a prominent upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SpecialPlansScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:  Color(0xFF00C853),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: const Text(
                "Upgrade Now",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          )
        else if (isTrialPlan)
          // For trial plans, show a prominent upgrade button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SpecialPlansScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: const Text(
                "Subscribe to Continue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          )
        else
          // For regular plans, show the original layout
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SpecialPlansScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF00C853),),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Upgrade Plan",
                    style: TextStyle(
                      color: Color(0xFF00C853),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _loadSubscriptionDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00C853),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Refresh",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateString;
    }
  }
}
