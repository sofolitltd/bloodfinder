import 'package:bloodfinder/features/emergency_donor/emergency_donor_page.dart';
import 'package:flutter/material.dart';

import '../../blood_bank/blood_bank.dart';
import '../../blood_request/post_blood_request.dart';
import 'home_community.dart';

class HomeActionButtonsSection extends StatelessWidget {
  const HomeActionButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          spacing: 20,
          children: [
            //
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .9,
              children: [
                _buildActionButton(
                  context,
                  icon: Icons.scatter_plot,
                  text: 'Post Blood\nRequest',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PostBloodRequestPage(),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.bloodtype,
                  text: 'Blood\nBank',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BloodBankScreen(),
                      ),
                    );
                  },
                ),
                _buildActionButton(
                  context,
                  icon: Icons.local_hospital,
                  text: 'Emergency\nDonors',
                  onTap: () {
                    //
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencyDonorPage(),
                      ),
                    );
                  },
                ),
              ],
            ),

            //
            HomeCommunitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.fromLTRB(8, 6, 8, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.red, size: 60),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
