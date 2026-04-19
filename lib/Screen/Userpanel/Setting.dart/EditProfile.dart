
import 'package:flutter/material.dart';

import '../../DrawerScreen.dart';
import '../Customappbar.dart';
 
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final displayNameCtl = TextEditingController(text: 'user007');
  final locationCtl    = TextEditingController();
  final aboutCtl       = TextEditingController();

  // quick “selected interests” demo state
  final Set<String> selectedInterests = {'Fashion', 'Platonic'};

  @override
  void dispose() {
    displayNameCtl.dispose();
    locationCtl.dispose();
    aboutCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final red  = const Color(0xFFEA0212);
    final grey = Colors.grey.shade300;

    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: const CustomAppBarWithDrawer(),
      drawer: const DrawerScreen(), // Your drawer widget
      body: SingleChildScrollView(
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              Padding(
    padding: const EdgeInsets.only(left :8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        const Text(
           'Edit Profile',
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
                    /// ─── Avatar & “Change Photo” ────────────────────────────────
              Container(
                height: 80,
                width: 80,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade600, width: 1.5),
                  shape: BoxShape.circle,
                  color: grey,
                ),
                child: Image.asset('assets/profile-man.png'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // TODO: pick image
                },
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text(
                  'Change Photo',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 24),
    
              /// ─── Form Fields ────────────────────────────────────────────
              _LabeledField(
                title: 'Display Name',
                controller: displayNameCtl,
                hint: 'user007',
              ),
              const SizedBox(height: 16),
              _LabeledField(
                title: 'Location',
                controller: locationCtl,
                hint: '',
              ),
              const SizedBox(height: 16),
              _LabeledField(
                title: 'About me',
                controller: aboutCtl,
                hint: '',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
    
              /// ─── Interests ──────────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Interested in',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withOpacity(.8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _InterestGrid(
                interests: const [
                  'Fashion','Beauty','Gadgets',
                  'Food & Health','Furniture','Mobile',
                  'Platonic','Electronic','Application'
                ],
                selected: selectedInterests,
                onTap: (label) {
                  setState(() {
                    selectedInterests.contains(label)
                        ? selectedInterests.remove(label)
                        : selectedInterests.add(label);
                  });
                },
              ),
              const SizedBox(height: 40),
    
              /// ─── Buttons  ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _pillButton(
                    label: 'Discard',
                    color: Colors.black,
                    onTap: () => Navigator.pop(context),
                  ),
                  _pillButton(
                    label: 'Save',
                    color: red,
                    onTap: () {
                      // TODO: save profile changes
                    },
                  ),
                ],
              ),
    
      ],
    ),
  )
      ],
        ),
      ),
    );
  }

  /// pill‑style button
  Widget _pillButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 120,
        height: 42,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// Helper: text field with a label above
/// ─────────────────────────────────────────────────────────────
class _LabeledField extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _LabeledField({
    required this.title,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// Helper: Grid of selectable interest chips
/// ─────────────────────────────────────────────────────────────
class _InterestGrid extends StatelessWidget {
  final List<String> interests;
  final Set<String> selected;
  final void Function(String) onTap;

  const _InterestGrid({
    required this.interests,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.map((label) {
        final bool isActive = selected.contains(label);
        return GestureDetector(
          onTap: () => onTap(label),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFEA0212) : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
