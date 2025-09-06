import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/blood_request.dart';

class DonationPage extends StatelessWidget {
  final String requestId;

  const DonationPage({super.key, required this.requestId});

  Stream<DocumentSnapshot<Map<String, dynamic>>> _requestStream() {
    return FirebaseFirestore.instance
        .collection('blood_requests')
        .doc(requestId)
        .snapshots();
  }

  Future<void> _callDonor(String mobile) async {
    if (mobile.isEmpty) return;
    final Uri uri = Uri.parse("tel:$mobile");
    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) debugPrint("❌ Could not launch dialer for $mobile");
    } catch (e) {
      debugPrint("❌ Error launching dialer: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donation', style: TextStyle(color: Colors.white60)),
        centerTitle: false,
        backgroundColor: Colors.red,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _requestStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("❌ Request not found"));
          }

          final data = snapshot.data!.data()!;
          final request = BloodRequest.fromJson(data);

          return Column(
            children: [
              // 🔴 Top Header with Blood Group
              Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  spacing: 12,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Text(
                          request.bloodGroup ?? "N/A",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),

                    //
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Requester",
                          style: TextStyle(
                            // fontWeight: FontWeight.bold,
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          request.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Location
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${request.subdistrict}, ${request.district}",
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // ⚪ Content
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Address
                      Text(
                        "Blood need",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request.bag} bag',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Address
                      Text(
                        "Detail address",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.address ?? "No address provided",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // mobile
                      Text(
                        'Contact Number',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request.mobile ?? "-",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // time
                      Text(
                        'Requested Donation Time',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${request.time}, ${request.date} ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // note
                      if (request.note != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Additional Note',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${request.note},',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              //
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade500,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: (request.mobile.isNotEmpty)
                              ? () => _callDonor(request.mobile)
                              : null,
                          icon: const Icon(Icons.call),
                          label: const Text("Call Donor"),
                        ),
                      ),
                      const SizedBox(width: 12),

                      //
                      Expanded(child: ChatButton(requesterId: request.uid)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ChatButton extends StatefulWidget {
  final String requesterId;
  const ChatButton({super.key, required this.requesterId});

  @override
  State<ChatButton> createState() => _ChatButtonState();
}

class _ChatButtonState extends State<ChatButton> {
  bool isLoading = false;

  Future<void> _startChat() async {
    setState(() => isLoading = true);

    final donorId = FirebaseAuth.instance.currentUser!.uid;
    final chatsCollection = FirebaseFirestore.instance.collection('chats');

    final chatQuery = await chatsCollection
        .where('participants', arrayContains: donorId)
        .get();

    DocumentSnapshot? chatDoc;
    for (var doc in chatQuery.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(widget.requesterId)) {
        chatDoc = doc;
        break;
      }
    }

    if (chatDoc == null) {
      final newChatRef = await chatsCollection.add({
        'participants': [donorId, widget.requesterId],
        'lastMessage': '',
        'lastTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      chatDoc = await newChatRef.get();
    }

    setState(() => isLoading = false);

    GoRouter.of(context).push(
      '/chat/${chatDoc.id}',
      extra: {'donorId': donorId, 'requesterId': widget.requesterId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent.shade200,
        visualDensity: VisualDensity.compact,
      ),
      onPressed: isLoading ? null : _startChat,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chat),
      label: isLoading ? Text('data') : const Text("Chat Now"),
    );
  }
}
