import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedMethod = "Google Pay";

  Widget paymentTile({
    required String label,
    required String value,
    required Widget leading,
    String? subtitle,
    bool secured = false,
    bool showButton = false,
    String? buttonLabel,
    VoidCallback? onButtonPressed,
  }) {
    bool isSelected = selectedMethod == value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.grey.shade300)],
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedMethod,
        onChanged: (val) => setState(() => selectedMethod = val!),
        activeColor: Colors.deepPurple,
        title: Row(
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
            if (secured)
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield, size: 14, color: Colors.purple),
                      SizedBox(width: 2),
                      Text("Secured", style: TextStyle(fontSize: 12, color: Colors.purple)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle != null)
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            if (isSelected && showButton)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: onButtonPressed,
                  child: Text(buttonLabel ?? "Pay Now", style: TextStyle(color: Colors.white),),
                ),
              ),
          ],
        ),
        secondary: leading,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text("Payments", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: BackButton(),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Amount
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text("Total Amount", style: TextStyle(fontSize: 16)),
                    Spacer(),
                    Text("₹ 200", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              SizedBox(height: 20),

              Text("Preferred Mode", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),

              // Google Pay
              paymentTile(
                label: "Google Pay",
                value: "Google Pay",
                leading: Image.asset("assets/gpay.png", height: 30, width: 30),
                showButton: true,
                buttonLabel: "Pay using Google Pay",
                
                onButtonPressed: () => print("Google Pay Pressed"),
              ),

              // Paytm
              paymentTile(
                label: "Paytm",
                value: "Paytm",
                leading: Image.asset("assets/paytm.png", height: 30, width: 30),
                subtitle: "₹200",
              ),

              // Mastercard
              paymentTile(
                label: "•••• 9999",
                value: "Card",
                leading: Image.asset("assets/mastercard.png", height: 30, width: 30),
                secured: true,
              ),

              SizedBox(height: 20),
              Text("UPI", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),

              // PhonePe UPI
              paymentTile(
                label: "PhonePe UPI",
                value: "PhonePe",
                leading: Image.asset("assets/phonepe.png", height: 30, width: 30),
                subtitle: "Low success rate currently",
              ),

              // Mobikwik
              paymentTile(
                label: "Mobikwik",
                value: "Mobikwik",
                leading: Image.asset("assets/mobikwik.png", height: 30, width: 30),
              ),

              // CRED Pay
              paymentTile(
                label: "CRED pay",
                value: "CRED",
                leading: Image.asset("assets/cred.png", height: 30, width: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
