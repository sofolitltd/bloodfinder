import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminWidget extends StatelessWidget {
  final Widget child;

  const AdminWidget({super.key, required this.child});

  Stream<bool> _adminStatusStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value(false);
    }

    return FirebaseFirestore.instance
        .collection('admin')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _adminStatusStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final isAdmin = snapshot.data ?? false;
        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        return child;
      },
    );
  }
}
