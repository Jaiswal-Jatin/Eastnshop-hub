import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

import '../../Constants/app_colors.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Terms and Conditions",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF00C853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.gavel, color: Colors.white, size: 32),
                  SizedBox(height: 12),
                  Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Last updated: March 2026',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Introduction
            _buildSectionCard(
              title: 'Introduction',
              content:
                  'These Terms and Conditions ("Terms") govern the registration and use of the EastNShop Hub mobile application ("the App") by shopkeepers/merchants ("Shopkeeper," "You," or "Your"). The App is operated by EASTNSHOPTECH LLP ("we," "us," or "our").\n\nBy registering as a Shopkeeper and using the App, you agree to comply with and be legally bound by these Terms. If you do not agree, please do not register or use the App.',
            ),

            _buildSectionCard(
              title: '1. Eligibility & Registration',
              content:
                  '1.1 You must be legally capable of entering into a binding contract under applicable laws.\n\n1.2 You agree to provide accurate, complete, and up-to-date information during registration.\n\n1.3 You are solely responsible for maintaining the confidentiality of your account credentials and for all activities conducted through your account.\n\n1.4 We reserve the right to approve, reject, or suspend any Shopkeeper registration at our sole discretion.',
            ),

            _buildSectionCard(
              title: '2. Nature of the Platform',
              content:
                  '2.1 EastNShop Hub is a digital advertising and listing platform that allows Shopkeepers to promote their products and services.\n\n2.2 We do not:\n• Act as a buyer or seller.\n• Handle payments between Shopkeepers and customers.\n• Provide delivery or logistics services.\n• Guarantee any sales, leads, or customer visits.\n\n2.3 All transactions, pricing, communication, delivery, and after-sales services are solely between the Shopkeeper and the Customer.',
            ),

            _buildSectionCard(
              title: '3. Subscription Fees & Payments',
              content:
                  '3.1 Shopkeepers are required to pay a subscription fee in order to list and promote their products or services on the app.\n\n3.2 Subscription fees:\n• Must be paid in advance.\n• Are non-refundable unless otherwise stated.\n• May be revised at our discretion with prior notice.\n\n3.3 Failure to pay subscription fees on time may result in:\n• Suspension of listings.\n• Temporary or permanent account deactivation.\n\n3.4 We are not responsible for any loss of business due to suspension caused by non-payment.',
            ),

            _buildSectionCard(
              title: '4. Advertisement & Content Guidelines',
              content:
                  '4.1 You are solely responsible for all content uploaded, including:\n• Product descriptions\n• Images\n• Prices\n• Offers\n• Contact details\n\n4.2 You agree that your listings:\n• Must not contain false, misleading, or deceptive information.\n• Must not violate any law, trademark, copyright, or intellectual property rights.\n• Must not promote illegal, prohibited, or restricted products.\n• Must not promote Obscene, explicit, or inappropriate content.\n\n4.3 We reserve the right to:\n• Remove or edit any content that violates our policies.\n• Suspend accounts for repeated violations.',
            ),

            _buildSectionCard(
              title: '5. Pricing & Taxes',
              content:
                  '5.1 Shopkeepers are fully responsible for:\n• Setting product/service prices.\n• Charging and collecting applicable taxes (GST or other taxes).\n• Issuing invoices or receipts where required by law.\n\n5.2 We do not collect, process, or manage any payments from customers.',
            ),

            _buildSectionCard(
              title: '6. Customer Interaction & Liability',
              content:
                  '6.1 You are solely responsible for:\n• Product quality\n• Customer service\n• Delivery arrangements (if offered)\n• Refunds, returns, and warranties\n\n6.2 Any dispute between Shopkeeper and Customer must be resolved directly between them.\n\n6.3 We are not liable for:\n• Customer complaints\n• Fraudulent transactions\n• Non-payment by customers\n• Product defects or damages.',
            ),

            _buildSectionCard(
              title: '7. Compliance with Laws',
              content:
                  '7.1 You agree to comply with all applicable local, state, and national laws.\n\n7.2 If your business requires licenses, registrations, or permits, you are responsible for obtaining and maintaining them.',
            ),

            _buildSectionCard(
              title: '8. Intellectual Property',
              content:
                  '8.1 You grant us a non-exclusive, royalty-free license to use your uploaded content (logos, images, descriptions) for:\n• Displaying listings on the App\n• Marketing and promotional purposes related to the platform\n\n8.2 You confirm that you own or have rights to use all content you upload.',
            ),

            _buildSectionCard(
              title: '9. Limitation of Liability',
              content:
                  'To the fullest extent permitted by law, we shall not be liable for:\n• Loss of profits, business, or revenue.\n• Indirect or consequential damages.\n• Any disputes between Shopkeeper and Customer.\n• Technical errors, downtime, or system failures.\n\nOur total liability shall not exceed the subscription fees you paid under the applicable subscription plan.',
            ),

            _buildSectionCard(
              title: '10. Termination & Suspension',
              content:
                  'We reserve the right to suspend or permanently terminate your account without prior notice if:\n• You violate these Terms.\n• You post misleading or illegal content.\n• You fail to pay subscription fees.\n• Your conduct harms the platform’s reputation.\n\nUpon termination:\n• Active listings may be removed.\n• Subscription fees already paid are non-refundable.',
            ),

            _buildSectionCard(
              title: '11. Modification of Terms',
              content:
                  'We may update these Terms at any time. Continued use of the App after changes means you accept the revised Terms.',
            ),

            _buildSectionCard(
              title: '12. Governing Law',
              content:
                  'These Terms shall be governed by and interpreted in accordance with the laws of India.',
            ),

            _buildSectionCard(
              title: '13. Contact Information',
              content: '', // Empty because we're using customContent
              customContent: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                  children: [
                    TextSpan(
                      text:
                          'For any queries related to these Terms:\n\nCompany Name: EASTNSHOPTECH LLP\nEmail: ',
                      children: [
                        TextSpan(
                          text: 'eastnshoptechsup@gmail.com',
                          style: const TextStyle(
                            color: Color.fromARGB(255, 0, 50, 200),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () =>
                                _launchEmail('eastnshoptechsup@gmail.com'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Accept Button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00C853), Color(0xFF00C853)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'I Understand & Accept',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Query regarding Terms and Conditions'},
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch $emailLaunchUri';
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }

  Widget _buildSectionCard({
    required String title,
    required String content,
    Widget? customContent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00C853),
            ),
          ),
          const SizedBox(height: 12),
          customContent ??
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
        ],
      ),
    );
  }
}
