
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../../../../Constants/app_colors.dart';
import '../../../../Controllers/ticketController.dart';
import '../../../DrawerScreen.dart';
import '../../Customappbar.dart';
import 'TicketDone.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final TicketController ticketController = Get.put(TicketController());

  /// Clear all fields
  void _clearFields() {

    ticketController.fullNameController.clear();
    ticketController.descriptionController.clear();
    ticketController.selectedCategory.value = '';
    ticketController.selectedFile.value = null;
  }

  /// Handle back button press
  Future<bool> _onWillPop() async {
    _clearFields(); // clear all text fields and selected file
    return true; // allow pop
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: const CustomAppBarWithDrawer(),
        drawer: const DrawerScreen(),
        body: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          _clearFields(); // clear all fields
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Create Ticket",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit.\nconsectetur adipiscing elit',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email
                      TextFormField(
                        controller: ticketController.emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.grey),
                        decoration: _inputDecoration('Email address', required: true),
                        readOnly: true,
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),

                      // Full Name
                      TextFormField(
                        controller: ticketController.fullNameController,
                        style: const TextStyle(color: Colors.grey),
                        decoration: _inputDecoration(
                            'Full Name',
                            hint: 'enter your name.',
                            required: true),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),

                      // Mobile Number
                      TextFormField(
                        controller: ticketController.mobileNumberController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.grey),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: _inputDecoration(
                          'Mobile Number',
                          hint: 'Please enter your active number',
                          required: true,
                        ),
                        readOnly: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Required';
                          } else if (val.length != 10) {
                            return 'Mobile number must be 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Concern Category
                      const Text(
                        "Concern Category *",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Please select the closest possible category among the choices",
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Obx(
                        () => Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField2<String>(
                                alignment: AlignmentGeometry.centerLeft,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 7),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                hint: Text(
                                  'Select a Category',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                iconStyleData: const IconStyleData(
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                                  iconSize: 24,
                                ),
                                buttonStyleData: const ButtonStyleData(
                                  height: 33,
                                  padding: EdgeInsets.only(right: 8),
                                ),
                                dropdownStyleData: DropdownStyleData(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        spreadRadius: 2,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                                items: ticketController.categories
                                    .map((e) => DropdownMenuItem<String>(
                                          value: e,
                                          child: Text(
                                            e,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                                value: ticketController.selectedCategory.value.isEmpty
                                    ? null
                                    : ticketController.selectedCategory.value,
                                onChanged: (val) {
                                  if (val != null) {
                                    ticketController.setCategory(val);
                                  }
                                },
                                onMenuStateChange: (isOpen) {
                                  if (isOpen) {
                                    HapticFeedback.lightImpact();
                                  }
                                },
                                validator: (val) =>
                                    val == null ? 'Please select a category' : null,
                              ),
                            ),

                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        "Explain your concern. Include all the detail related to the concern to help speed up fixing your problem",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: ticketController.descriptionController,
                        maxLines: 5,
                        style: const TextStyle(color: Colors.grey),
                        decoration: _inputDecoration('Write something...', required: true),
                        validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),

                      // File attachment
                      GestureDetector(
                        onTap: () async {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.any,
                            allowMultiple: false,
                          );

                          if (result != null) {
                            ticketController.selectedFile.value = result.files.first;
                            print("File selected: ${ticketController.selectedFile.value?.name}");
                          } else {
                            print("File picking canceled");
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          height: 55,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file_outlined, color: Colors.black54),
                              const SizedBox(width: 10),
                              Obx(() => Flexible(
                                child: Text(
                                  ticketController.selectedFile.value?.name ?? 'Attach a file',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              )),

                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Submit button
                      Obx(
                            () => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: ticketController.isCreatingTicket.value
                                ? null
                                : () async {
                              if (_formKey.currentState!.validate()) {
                                final ticket = await ticketController.createTicket();
                                if (ticket != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TicketCreatedPage(ticket: ticket),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ticketController.isCreatingTicket.value
                                  ? Colors.grey
                                  : AppColors.primaryRed,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: ticketController.isCreatingTicket.value
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Creating Ticket...",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            )
                                : const Text(
                              'Submit the Ticket',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label,
      {bool required = false, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey, width: 1.0),
      ),
      suffixIcon: required
          ? const Icon(Icons.star, color: Colors.red, size: 12)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
