import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddDonationPage extends StatefulWidget {
  const AddDonationPage({super.key});

  @override
  State<AddDonationPage> createState() => _AddDonationPageState();
}

class _AddDonationPageState extends State<AddDonationPage> {
  DateTime? _selectedDate;
  final TextEditingController _recipientNameController =
      TextEditingController();
  final TextEditingController _recipientMobileController =
      TextEditingController();
  bool _isLoading = false;

  Future<void> _pickDonationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveDonation() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a donation date.')),
      );
      return;
    }

    if (_recipientNameController.text.trim().isEmpty ||
        _recipientMobileController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter recipient name and mobile.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final donationRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('donation');

        await donationRef.add({
          'donationDate': _selectedDate,
          'recipientName': _recipientNameController.text.trim(),
          'recipientMobile': _recipientMobileController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation added successfully!')),
        );

        Navigator.pop(context, true); // Refresh donation history
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No user logged in.')));
      }
    } catch (e) {
      print('Error adding donation: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add donation.')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientMobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String selectedDateText = _selectedDate == null
        ? 'Select Date'
        : DateFormat('dd MMMM, yyyy').format(_selectedDate!);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Donation'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey, width: 1),
              ),
              child: ListTile(
                visualDensity: const VisualDensity(vertical: -2),
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  selectedDateText,
                  style: const TextStyle(fontSize: 16),
                ),
                onTap: _pickDonationDate,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _recipientNameController,
              decoration: const InputDecoration(
                labelText: 'Recipient Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _recipientMobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Recipient Mobile',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isLoading ? null : _saveDonation,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Add Donation',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
