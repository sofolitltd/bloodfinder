import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/data/db/app_data.dart';
import '/data/models/community.dart';
import '/features/community/search_page.dart';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _facebookController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  String? _selectedDistrict;
  String? _selectedSubDistrict;
  String? _communityCode;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _facebookController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<String> _generateCommunityCode() async {
    final CollectionReference communities = FirebaseFirestore.instance
        .collection('communities');
    try {
      QuerySnapshot lastCommunitySnapshot = await communities
          .orderBy('code', descending: true)
          .limit(1)
          .get();
      int nextNumber = 1;
      if (lastCommunitySnapshot.docs.isNotEmpty) {
        String lastCode = lastCommunitySnapshot.docs.first['code'] as String;
        RegExp regExp = RegExp(r'\d+');
        String? numberString = regExp.stringMatch(lastCode);
        if (numberString != null) {
          nextNumber = int.parse(numberString) + 1;
        }
      }
      return 'BF$nextNumber';
    } catch (e) {
      log('Error generating community code: $e');
      return 'BF1';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Community'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          spacing: 8,
          children: [
            //
            ExpandableInfoCard(),

            //
            Card(
              margin: EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //
                      Text(
                        'Community Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Community Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Community name',
                          hintText: 'Enter community name',
                        ),
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a community name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Mobile Number
                      TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(
                          labelText: 'Admin Mobile',
                          hintText: 'Enter mobile number',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a mobile number';
                          }
                          if (value.length < 10) {
                            return 'Mobile number too short';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          hintText: 'Enter community address',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      //
                      // District Dropdown
                      _buildDistrictDropdown(),

                      const SizedBox(height: 16),

                      // Sub-District Dropdown
                      _buildSubDistrictDropdown(),

                      const SizedBox(height: 16),

                      // Facebook Link (Optional)
                      TextFormField(
                        controller: _facebookController,
                        decoration: const InputDecoration(
                          labelText: 'Facebook Link (Optional)',
                          hintText: 'Enter Facebook page URL',
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),

                      // WhatsApp Link (Optional)
                      TextFormField(
                        controller: _whatsappController,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp Link (Optional)',
                          hintText: 'Enter WhatsApp group invite link',
                        ),
                        keyboardType: TextInputType.url,
                      ),

                      const SizedBox(height: 32),

                      // Create Community Button
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            if (_selectedDistrict == null ||
                                _selectedSubDistrict == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select District and Subdistrict',
                                  ),
                                ),
                              );
                              return;
                            }

                            // Generate a new code on form submission
                            await _generateCommunityCode().then((code) {
                              _communityCode = code;
                            });

                            // current uid
                            final uid = FirebaseAuth.instance.currentUser!.uid;

                            final docRef = FirebaseFirestore.instance
                                .collection('communities')
                                .doc();

                            final generatedId = docRef.id;

                            //
                            Community newCommunity = Community(
                              id: generatedId.toString(),
                              code: _communityCode.toString(),
                              name: _nameController.text.trim(),
                              mobile: _mobileController.text.trim(),
                              district: _selectedDistrict!,
                              subDistrict: _selectedSubDistrict!,
                              address: _addressController.text.trim(),
                              admin: [uid],
                              images: [],
                              createdAt: Timestamp.now(),
                              memberCount: 1,
                              facebook:
                                  _facebookController.text.trim().isNotEmpty
                                  ? _facebookController.text.trim()
                                  : '',
                              whatsapp:
                                  _whatsappController.text.trim().isNotEmpty
                                  ? _whatsappController.text.trim()
                                  : '',
                            );

                            log('New Community JSON: ${newCommunity.toJson()}');

                            //
                            try {
                              await docRef.set(newCommunity.toJson());

                              await FirebaseFirestore.instance
                                  .collection('communities')
                                  .doc(generatedId)
                                  .collection('members')
                                  .doc(uid)
                                  .set({
                                    'uid': uid,
                                    'member': true,
                                    'createdAt': Timestamp.now(),
                                  });

                              // notification
                              await FirebaseMessaging.instance.subscribeToTopic(
                                generatedId,
                              );

                              //
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Community created successfully!',
                                  ),
                                ),
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              log('Error creating community: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to create community: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Create Community',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //
  Widget _buildDistrictDropdown() {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        // labelText: 'District',
        hintText: _selectedDistrict ?? 'Select District',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: _selectedDistrict != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedDistrict = null;
                    _selectedSubDistrict = null;
                  });
                },
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        final selectedValue = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchPage(
              title: 'District',
              items: (AppData.districts.map((d) => d.name).toList()..sort()),
            ),
          ),
        );
        if (selectedValue != null) {
          setState(() {
            _selectedDistrict = selectedValue;
            _selectedSubDistrict = null;
          });
        }
      },
      validator: (value) {
        if (_selectedDistrict == null) {
          return 'Please select a district';
        }
        return null;
      },
    );
  }

  //
  Widget _buildSubDistrictDropdown() {
    final subDistricts = _selectedDistrict != null
        ? AppData.districts
              .firstWhere((d) => d.name == _selectedDistrict)
              .subDistricts
        : <String>[];
    return TextFormField(
      readOnly: true,
      enabled: _selectedDistrict != null,
      decoration: InputDecoration(
        // labelText: 'Subdistrict',
        hintText: _selectedSubDistrict ?? 'Select Subdistrict',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: _selectedSubDistrict != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedSubDistrict = null;
                  });
                },
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        if (_selectedDistrict == null) return;
        final selectedValue = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SearchPage(title: 'Subdistrict', items: subDistricts),
          ),
        );
        if (selectedValue != null) {
          setState(() {
            _selectedSubDistrict = selectedValue;
          });
        }
      },
      validator: (value) {
        if (_selectedSubDistrict == null) {
          return 'Please select a subdistrict';
        }
        return null;
      },
    );
  }
}

//
class ExpandableInfoCard extends StatefulWidget {
  const ExpandableInfoCard({super.key});

  @override
  State<ExpandableInfoCard> createState() => _ExpandableInfoCardState();
}

class _ExpandableInfoCardState extends State<ExpandableInfoCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                //
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 24,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create a community for your school, college, university, or family. Stay connected. Tap to view/hide community guidelines.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            // Animated expansion
                            AnimatedCrossFade(
                              alignment: Alignment.centerLeft,
                              firstChild: const SizedBox.shrink(),
                              secondChild: const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  "- Add at least 10 members within 1 month.\n"
                                  "- Communities not meeting this may be removed.\n"
                                  "- You’ll be notified before any removal.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              crossFadeState: _expanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Optional: Icon to show expand/collapse state
                Positioned(
                  right: 8,
                  bottom: 4,
                  child: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.red,
                    size: 28,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
