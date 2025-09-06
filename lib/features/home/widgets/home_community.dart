import 'package:flutter/material.dart';

import '../../community/community.dart';

class HomeCommunitySection extends StatelessWidget {
  const HomeCommunitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CommunityScreen()),
        );
      },
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withValues(alpha: 0.05),
              spreadRadius: 5,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'JOIN YOUR COMMUNITY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Find and join your community of local blood bank, School, College or University.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.handshake_outlined, size: 48, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
