
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../Constants/GlobalVariables.dart';
import '../../../../Controllers/ticketListController.dart';
import '../../../AdminPanel/AdminDashboard/HomePage.dart';
import '../../../DrawerScreen.dart';
import '../../Customappbar.dart';
import '../UserHome.dart';
import 'CreatingTicket.dart';
import 'TicketListPage.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  late TicketListController ticketController;

  @override
  void initState() {
    super.initState();
    ticketController = Get.put(TicketListController());
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
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        // appBar: AppBar(
        //   backgroundColor: Colors.transparent,
        //   elevation: 0,
        //   leading: const BackButton(color: Colors.black),
        //   centerTitle: true,
        //   title: const Text(
        //     'Help Center',
        //     style: TextStyle(
        //       fontFamily: 'Poppins',
        //       fontWeight: FontWeight.bold,
        //       fontSize: 18,
        //       color: Colors.black,
        //     ),
        //   ),
        // ),
        appBar: const CustomAppBarWithDrawer(),
        drawer: const DrawerScreen(), // Your drawer widget
        body: SingleChildScrollView( 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Padding(
    padding: const EdgeInsets.only(left :8.0),
    child: Row(
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
          "Help Center",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    ),
  ),
    SizedBox(height: 25),
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16.0),
  child: Column(
    children: [
                  const Center(
                child: Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Chat is currently unavailable. You can still reach out by\nsubmitting a ticket.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 20),
  
              /// --- Submit a Ticket Card ---
              GestureDetector(
                onTap: () {
                    Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateTicketPage()));
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Text & Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Create a Ticket',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. In sollicitudin efficitur ipsum',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Image
                        Image.asset(
                          'assets/help_ticket.png',
                          height: 120,
                          width: 120,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
  
              const SizedBox(height: 10),
  
              /// --- Your Tickets Section ---
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TicketListPage()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Your Tickets',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (ticketController.isLoading.value)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ticketController.tickets.isEmpty 
                          ? 'No Tickets yet'
                          : '${ticketController.tickets.length} ticket${ticketController.tickets.length == 1 ? '' : 's'} available',
                        style: TextStyle(
                          color: ticketController.tickets.isEmpty ? Colors.blueGrey : Colors.green,
                          fontSize: 13,
                          fontWeight: ticketController.tickets.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      if (ticketController.tickets.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildStatusChip('Pending', ticketController.getTicketCountByStatus('pending'), Colors.orange),
                            const SizedBox(width: 8),
                            _buildStatusChip('In Progress', ticketController.getTicketCountByStatus('in_progress'), Colors.blue),
                            const SizedBox(width: 8),
                            _buildStatusChip('Resolved', ticketController.getTicketCountByStatus('resolved'), Colors.green),
                          ],
                        ),
                      ],
                    ],
                  )),
                ),
              ),
  
              const SizedBox(height: 16),
  
              /// --- FAQs Card ---
              GestureDetector(
                onTap: () {
                  // Navigator.push(context,
                  //   MaterialPageRoute(builder: (_) => const FAQPage()));
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Text & Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'FAQs',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. In sollicitudin efficitur ipsum',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Image.asset(
                          'assets/help_faq.png',
                          height: 100,
                          width: 100,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
         
    ],
  ),
)   ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        '$label ($count)',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
