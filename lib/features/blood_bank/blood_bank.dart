import 'package:bloodfinder/features/blood_bank/widgets/blood_bank_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../shared/admin_widget.dart';
import 'add_blood_bank.dart';

class BloodBankScreen extends StatelessWidget {
  const BloodBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Bank'),
        centerTitle: true, // Center the title
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('blood_bank')
                      .snapshots(),
                  builder: (context, asyncSnapshot) {
                    if (asyncSnapshot.hasError) {
                      return Text('Error: ${asyncSnapshot.error}');
                    }
                    if (asyncSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: const Text('Loading...'));
                    }
                    final bloodBanks = asyncSnapshot.data!.docs;

                    if (bloodBanks.isEmpty) {
                      return Center(
                        child: const Text('No blood banks found...'),
                      );
                    }

                    //
                    return ListView.separated(
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemCount: bloodBanks.length,
                      itemBuilder: (context, index) {
                        //
                        final BloodBank bloodBank = BloodBank.fromJson(
                          bloodBanks[index].data(),
                        );

                        //
                        return BloodBankCard(bloodBank: bloodBank);
                      },
                    );
                  },
                ),
              ),
            ),
          ),

          //todo: only for admin
          AdminWidget(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => (
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddBloodBank()),
                    ),
                  ),
                  child: const Text(
                    'Add Blood Bank',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
