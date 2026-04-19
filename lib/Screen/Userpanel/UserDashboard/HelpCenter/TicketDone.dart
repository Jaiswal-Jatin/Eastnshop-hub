
import 'package:flutter/material.dart';

import '../../../../Constants/app_colors.dart';
import '../../../DrawerScreen.dart';
import '../../Customappbar.dart';

class TicketCreatedPage extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const TicketCreatedPage({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      // appBar: AppBar(
      //   title: const Text(
      //     'Ticket Created',
      //     style: TextStyle(
      //       fontFamily: 'Poppins',
      //       color: Colors.black,
      //     ),
      //   ),
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   leading: const BackButton(color: Colors.black),
      // ),
      appBar: const CustomAppBarWithDrawer(),
      drawer: const DrawerScreen(), // Your drawer widget
      body: SingleChildScrollView(
         child: Column(
          children: [ 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white, // Outer border color
                border: Border.all(
                  color: Colors.black, // Outer border color
                  width: 2, // Outer border thickness
                ),
                ),
                padding: const EdgeInsets.all(4), // Space between outer and inner border
                child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryRed,
                  border: Border.all(
                  color: AppColors.primaryRed, // Inner border color
                  width: 3, // Inner border thickness
                  ),
                ),
                padding: const EdgeInsets.all(2), // Adjust for desired radius
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                  Image.asset(
                    'assets/ticket_icon.png',
                    height: 100,
                    width: 100,
                    color: Colors.white,
                  ),
                  Container(
                    decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                  ],
                ),
                ),
              ),
              const SizedBox(height: 10),
  
              // 🎉 Title
              Text(
                ticket['message'] ?? 'Ticket Created',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit.\nconsectetur adipiscing elit",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 30),
  
              // 📄 Ticket Details Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Ticket No: ${ticket['ticket_no'] ?? ticket['id'] ?? '—'}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text("Name: ${ticket['full_name'] ?? '—'}", style: const TextStyle(color: Colors.white)),
                    Text("Email: ${ticket['email'] ?? '—'}", style: const TextStyle(color: Colors.white)),
                    Text("Mobile: ${ticket['mobile_number'] ?? '—'}", style: const TextStyle(color: Colors.white)),
                    Text("Category: ${ticket['category'] ?? '—'}", style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 20),
  
                    // 📝 Message Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ticket['description'] ?? '',
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                     SizedBox(height: 10,),
                    // Back Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                           Navigator.pop(context);
                        },
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        label: Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, // Correct way
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                      ),
                    ),

                  ],
                ),
               ),
              const SizedBox(height: 40),
              ],
            ),
          )
 
          ],
        ),
      ),
    );
  }
}
