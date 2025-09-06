import 'dart:async';
import 'dart:developer';

import 'package:bloodfinder/data/db/app_data.dart';
import 'package:bloodfinder/features/blood_bank/widgets/blood_bank_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddBloodBank extends StatefulWidget {
  const AddBloodBank({super.key});

  @override
  State<AddBloodBank> createState() => _AddBloodBankState();
}

class _AddBloodBankState extends State<AddBloodBank> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mobile1Controller = TextEditingController();
  final TextEditingController _mobile2Controller = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  String _selectedDistrict = '';
  List<String> _selectedSubDistrictList = [];
  String _selectedSubDistrict = '';

  Timer? _debounce;

  bool? _slugIsUnique;
  bool _checkingSlug = false;

  @override
  void initState() {
    super.initState();

    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _slugController.dispose();
    _addressController.dispose();
    _mobile1Controller.dispose();
    _websiteController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onNameChanged() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _slugController.text = '';
        _slugIsUnique = null;
      });
      return;
    }

    // Debounce slug generation + check uniqueness after user stops typing for 800ms
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final slug = _generateSlug(name);
      _slugController.text = slug;
      await _checkSlugUnique(slug);
    });
  }

  String _generateSlug(String text) {
    // simple slug generation: lowercase, replace space with dash, remove invalid chars
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }

  Future<void> _checkSlugUnique(String slug) async {
    setState(() {
      _checkingSlug = true;
      _slugIsUnique = null;
    });

    final querySnapshot = await FirebaseFirestore.instance
        .collection('blood_bank')
        .where('slug', isEqualTo: slug)
        .get();

    setState(() {
      _checkingSlug = false;
      _slugIsUnique = querySnapshot.docs.isEmpty;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDistrict == null || _selectedSubDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both District and Thana')),
      );
      return;
    }
    if (_slugIsUnique == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slug already exists. Please change the name.'),
        ),
      );
      return;
    }
    if (_slugIsUnique == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slug validation in progress. Please wait.'),
        ),
      );
      return;
    }

    final bloodBank = BloodBank(
      name: _nameController.text.trim(),
      slug: _slugController.text.trim(),
      address: _addressController.text.trim(),
      district: _selectedDistrict,
      thana: _selectedSubDistrict,
      mobile1: _mobile1Controller.text.trim(),
      mobile2: _mobile2Controller.text.trim(),
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
    );

    await FirebaseFirestore.instance
        .collection('blood_bank')
        .add(bloodBank.toJson());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blood Bank created successfully!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Blood Bank'), centerTitle: true),
      body: SingleChildScrollView(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Name'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter blood bank name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Slug (auto-generated)'),
                  TextFormField(
                    controller: _slugController,
                    readOnly: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: const OutlineInputBorder(),
                      suffixIcon: _checkingSlug
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : _slugIsUnique == null
                          ? null
                          : _slugIsUnique == true
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.cancel, color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Address'),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      hintText: 'Enter address',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Enter address'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('District'),

                            Autocomplete<String>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                List<String> allDistrictNames = AppData
                                    .districts
                                    .map((district) => district.name)
                                    .toList(); // Convert to List to sort

                                // Sort the entire list alphabetically
                                allDistrictNames.sort(
                                  (a, b) => a.toLowerCase().compareTo(
                                    b.toLowerCase(),
                                  ),
                                );

                                // If the text field is empty, show all sorted districts
                                if (textEditingValue.text == '') {
                                  return allDistrictNames;
                                }

                                // Otherwise, filter based on the typed text from the sorted list
                                return allDistrictNames.where(
                                  (districtName) =>
                                      districtName.toLowerCase().contains(
                                        textEditingValue.text.toLowerCase(),
                                      ),
                                ); // No need to map again, it's already a list of names
                              },
                              onSelected: (String selectedDistrict) {
                                setState(() {
                                  this._selectedDistrict = selectedDistrict;
                                  _selectedSubDistrictList = AppData.districts
                                      .firstWhere(
                                        (district) =>
                                            district.name == selectedDistrict,
                                      )
                                      .subDistricts;
                                  _selectedSubDistrict =
                                      ''; // Reset thana when district is changed
                                });
                              },
                              fieldViewBuilder:
                                  (
                                    BuildContext context,
                                    TextEditingController textEditingController,
                                    FocusNode focusNode,
                                    VoidCallback onFieldSubmitted,
                                  ) {
                                    return TextField(
                                      controller: textEditingController,
                                      focusNode: focusNode,
                                      decoration: const InputDecoration(
                                        labelText: 'Select District',
                                      ),
                                    );
                                  },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Thana'),
                            Autocomplete<String>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                // If no district is selected or no thanas are available for the selected district,
                                // or if the text field is empty, handle accordingly.
                                if (_selectedSubDistrictList.isEmpty) {
                                  return const Iterable<
                                    String
                                  >.empty(); // No thanas to show if the list is empty
                                }

                                // Convert to List to sort
                                List<String> sortedThanas =
                                    _selectedSubDistrictList.toList();
                                // Sort the entire list alphabetically
                                sortedThanas.sort(
                                  (a, b) => a.toLowerCase().compareTo(
                                    b.toLowerCase(),
                                  ),
                                );

                                // If the text field is empty, show all sorted thanas
                                if (textEditingValue.text == '') {
                                  return sortedThanas;
                                }

                                // Otherwise, filter based on the typed text from the sorted list
                                return sortedThanas.where(
                                  (thana) => thana.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase(),
                                  ),
                                );
                              },
                              onSelected: (String selectedThana) {
                                setState(() {
                                  this._selectedSubDistrict = selectedThana;
                                });
                              },

                              fieldViewBuilder:
                                  (
                                    BuildContext context,
                                    TextEditingController textEditingController,
                                    FocusNode focusNode,
                                    VoidCallback onFieldSubmitted,
                                  ) {
                                    return TextField(
                                      controller: textEditingController,
                                      focusNode: focusNode,

                                      decoration: InputDecoration(
                                        labelText: _selectedDistrict.isEmpty
                                            ? 'Select District first'
                                            : 'Select Thana',
                                      ),
                                      enabled: _selectedDistrict
                                          .isNotEmpty, // Disable until district is selected
                                    );
                                  },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Mobile'),
                  Row(
                    spacing: 16,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mobile1Controller,
                          decoration: const InputDecoration(
                            hintText: 'Enter mobile1',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Enter mobile No';
                            }
                            if (val.trim().length < 10) return 'Too short';
                            return null;
                          },
                        ),
                      ),
                      //
                      Expanded(
                        child: TextFormField(
                          controller: _mobile2Controller,
                          decoration: const InputDecoration(
                            hintText: 'Enter mobile2',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          // validator: (val) {
                          //   if (val == null || val.trim().isEmpty) return 'Enter mobile1';
                          //   if (val.trim().length < 10) return 'Too short';
                          //   return null;
                          // },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('Website (optional)'),
                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      hintText: 'Enter website URL',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (val) {
                      if (val != null && val.isNotEmpty) {
                        final urlPattern =
                            r'^(https?:\/\/)?([\w\-]+)+([\w\-\.]+)+[\w\-\/]*$';
                        final regex = RegExp(urlPattern);
                        if (!regex.hasMatch(val)) return 'Invalid URL';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  //
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // onPressed: _checkingSlug ? null : _submit,
                      onPressed: () async {
                        final firestore = FirebaseFirestore.instance;

                        for (final bloodBank in bloodBanks) {
                          final slug = bloodBank['slug'];

                          // Check if slug already exists to avoid duplicates
                          final query = await firestore
                              .collection('blood_bank')
                              .where('slug', isEqualTo: slug)
                              .limit(1)
                              .get();

                          if (query.docs.isEmpty) {
                            // Add new blood bank document
                            await firestore
                                .collection('blood_bank')
                                .add(bloodBank);
                            log('Added: ${bloodBank['name']}');
                          } else {
                            log(
                              'Skipped (already exists): ${bloodBank['name']}',
                            );
                          }
                        }

                        log('Upload completed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Add Blood Bank',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),

                      //
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
  );
}

final List<Map<String, dynamic>> bloodBanks = [
  {
    "name": "Quantum Blood Bank (Segunbagicha, Kakrail)",
    "slug": "quantum-blood-bank-segunbagicha-kakrail",
    "mobile1": "+8801714010869",
    "mobile2": "",
    "website": "http://quantummethod.org/blood-donation",
    "district": "Dhaka",
    "thana": "",
    "address":
        "1/1 Pioneer Road (Ground Floor), Segunbagicha, Kakrail, Dhaka‑1000",
    "imageUrl":
        "https://bdrcs.org/wp-content/uploads/2021/04/Quantum-Blood-Bank.jpg",
  },
  {
    "name": "Quantum Blood Bank (Shantinagar Branch)",
    "slug": "quantum-blood-bank-shantinagar",
    "mobile1": "+8801714010869",
    "mobile2": "",
    "website": "http://quantummethod.org",
    "district": "Dhaka",
    "thana": "",
    "address": "31/V Shilpacharya Zainul Abedin Sarak, Shantinagar, Dhaka‑1217",
    "imageUrl":
        "https://bdrcs.org/wp-content/uploads/2021/04/Quantum-Blood-Bank.jpg",
  },
  {
    "name": "Bangladesh Red Crescent Blood Bank",
    "slug": "bangladesh-red-crescent-blood-bank-mohammadpur",
    "mobile1": "+8801811458537",
    "mobile2": "+880248121182",
    "website": "https://bdrcs.org/",
    "district": "Dhaka",
    "thana": "",
    "address": "7/5 Aurangzeb Road, Mohammadpur, Dhaka‑1207",
    "imageUrl":
        "https://www.shutterstock.com/image-photo/people-donate-blood-red-crescent-260nw-2239455323.jpg",
  },
  {
    "name": "Badhan Blood Bank",
    "slug": "badhan-blood-bank-du-tsc",
    "mobile1": "+8801534982674",
    "mobile2": "+8801311477933",
    "website": "https://badhan.org/",
    "district": "Dhaka",
    "thana": "",
    "address":
        "Central Office, T.S.C (Ground Floor), University of Dhaka, Dhaka‑1000",
    "imageUrl":
        "https://badhanfoundation.org/assets/frontend/images/badhan_logo.png",
  },
  {
    "name": "Sandhani Central (BSMMU)",
    "slug": "sandhani-central-bsmmu-shahbag",
    "mobile1": "+8801794565654",
    "mobile2": "",
    "website": "https://www.sandhani.org",
    "district": "Dhaka",
    "thana": "",
    "address":
        "Sandhani Bhaban, 33/2 Nilkhet (Babupura Rd), Shahbag, Dhaka‑1000",
    "imageUrl":
        "https://www.sandhani.org/wp-content/uploads/2021/05/sandhani-logo.png",
  },
  {
    "name": "Islami Bank Hospital Blood Bank",
    "slug": "islami-bank-hospital-blood-bank-kakrail",
    "mobile1": "+88028321495",
    "mobile2": "",
    "website": "https://islamibankhospital.com/",
    "district": "Dhaka",
    "thana": "",
    "address": "Plot 30, VIP Road, Kakrail, Dhaka‑1000",
    "imageUrl":
        "https://islamibankhospital.com/uploads/logo/1628169974_Islamibankhospital_logo_01.png",
  },
  {
    "name": "Alif Blood Bank & Transfusion Center",
    "slug": "alif-blood-bank-transfusion-center-panthapath",
    "mobile1": "+8801712392923",
    "mobile2": "+8801913059375",
    "website": "",
    "district": "Dhaka",
    "thana": "",
    "address":
        "44/11 West Panthapath (2nd Floor), Opposite Shamrita Hospital, Dhaka‑1215",
    "imageUrl":
        "https://bdtradeinfo.com/assets/uploads/company/alif-blood-bank-transfusion-center-558237.jpg",
  },
  {
    "name": "Thalassemia Blood Bank",
    "slug": "thalassemia-blood-bank-chamelibag",
    "mobile1": "+8801755587479",
    "mobile2": "",
    "website": "http://www.thals.org",
    "district": "Dhaka",
    "thana": "",
    "address": "30 Chamelibag, 1st Lane, Dhaka‑1217",
    "imageUrl": "http://www.thals.org/wp-content/uploads/2020/03/logo.png",
  },
  {
    "name": "Police Blood Bank (Central Police Hospital)",
    "slug": "police-blood-bank-cph-rajarbag",
    "mobile1": "+8801713398386",
    "mobile2": "",
    "website": "http://www.policebloodbank.gov.bd",
    "district": "Dhaka",
    "thana": "",
    "address": "Central Police Hospital, Rajarbag, Dhaka‑1000",
    "imageUrl": "http://www.policebloodbank.gov.bd/images/logo.png",
  },
  {
    "name": "Mukti Blood Bank & Pathology Lab",
    "slug": "mukti-blood-bank-pathology-free-school",
    "mobile1": "+88028624249",
    "mobile2": "",
    "website": "",
    "district": "Dhaka",
    "thana": "",
    "address":
        "54 (1st Floor), Bir‑Uttam A.M. Shafiullah Road, Free School Street, Dhaka‑1207",
    "imageUrl": "https://i.ibb.co/L5Q82mP/Mukti-Blood-Bank.png",
  },
  {
    "name": "Oriental Blood Bank",
    "slug": "oriental-blood-bank-dhanmondi",
    "mobile1": "+8801812700053",
    "mobile2": "",
    "website": "",
    "district": "Dhaka",
    "thana": "",
    "address": "Green Center, 2B/30 Green Road, Dhanmondi, Dhaka‑1205",
    "imageUrl": "https://i.ibb.co/y4p131M/Oriental-Blood-Bank.jpg",
  },
  {
    "name": "Ideal Blood Bank",
    "slug": "ideal-blood-bank-naya-paltan",
    "mobile1": "+8801819143760",
    "mobile2": "+88029346594",
    "website": "http://www.idealbloodbank.com.bd",
    "district": "Dhaka",
    "thana": "",
    "address": "53 DIT Extension Road (1st floor), Naya Paltan, Dhaka‑1000",
    "imageUrl": "https://www.istockphoto.com/illustrations/blood-bank",
  },
  {
    "name": "Labaid Limited Blood Bank",
    "slug": "labaid-limited-blood-bank-mirpur",
    "mobile1": "+8801766662888",
    "mobile2": "",
    "website": "https://www.labaidgroup.com/hospital",
    "district": "Dhaka",
    "thana": "",
    "address": "Holding No 9/B, Mirpur Road Section‑1, Mirpur, Dhaka",
    "imageUrl":
        "https://www.labaidgroup.com/hospital/assets/images/labaid-logo.png",
  },
  {
    "name": "Bangladesh Blood Bank & Transfusion Center (Mirpur)",
    "slug": "bangladesh-blood-bank-transfusion-mohammadpur-mirpur",
    "mobile1": "+8801850077185",
    "mobile2": "+8801776291633",
    "website": "",
    "district": "Dhaka",
    "thana": "",
    "address":
        "Holding No 22/12 (1st Floor), Mirpur Road (Babar Road), Mohammadpur, Dhaka‑1207",
    "imageUrl": "https://bdspecializedhospital.com/assets/images/logo.png",
  },
  {
    "name": "Retina Blood Bank",
    "slug": "retina-blood-bank-pg-hospital",
    "mobile1": "+8801614606411",
    "mobile2": "",
    "website": "",
    "district": "Dhaka",
    "thana": "",
    "address": "2 KA 5, Nowab Habibullah Road (Behind PG Hospital), Dhaka",
    "imageUrl": "https://i.ibb.co/h7g40Xn/Retina-Blood-Bank.png",
  },
  {
    "name": "Sir Salimullah College Blood Bank",
    "slug": "sir-salimullah-college-blood-bank-mitford",
    "mobile1": "+88027319123",
    "mobile2": "",
    "website": "http://www.ssmc.edu.bd/",
    "district": "Dhaka",
    "thana": "",
    "address": "Sir Salimullah College Hospital, 217 Mitford Road, Dhaka‑1100",
    "imageUrl": "http://www.ssmc.edu.bd/assets/img/logo.png",
  },
  {
    "name": "Holy Family Red Crescent Medical College Blood Center",
    "slug": "holy-family-red-crescent-blood-center-eskaton",
    "mobile1": "+88029353031",
    "mobile2": "+8801716346930",
    "website": "https://www.hfrcmc.edu.bd/",
    "district": "Dhaka",
    "thana": "",
    "address": "Eskaton Garden Road near Moghbazar, Dhaka‑1217",
    "imageUrl": "http://hfrcmc.edu.bd/images/hfrcmc_logo.png",
  },
  {
    "name": "Chittagong Red Crescent Blood Centre",
    "slug": "chittagong-red-crescent-blood-centre",
    "mobile1": "+8801819353445",
    "mobile2": "+88031620926",
    "website": "https://bdrcs.org/",
    "district": "Chattogram",
    "thana": "",
    "address": "Anderkilla, Chattogram",
    "imageUrl":
        "https://www.shutterstock.com/image-photo/people-donate-blood-red-crescent-260nw-2239455323.jpg",
  },
  {
    "name": "Sandhani (CMC, Chattogram)",
    "slug": "sandhani-cmc-chattogram",
    "mobile1": "+88031616625",
    "mobile2": "",
    "website": "https://www.sandhani.org",
    "district": "Chattogram",
    "thana": "",
    "address": "Chittagong Medical College campus, Agrabad, Chattogram",
    "imageUrl":
        "https://www.sandhani.org/wp-content/uploads/2021/05/sandhani-logo.png",
  },
  {
    "name": "Ahad Red Crescent Blood Centre",
    "slug": "ahad-red-crescent-blood-centre-jashore",
    "mobile1": "+88042168882",
    "mobile2": "+8801939109722",
    "website": "https://bdrcs.org/",
    "district": "Jashore",
    "thana": "",
    "address": "Jashore Sadar, Jashore",
    "imageUrl":
        "https://www.shutterstock.com/image-photo/people-donate-blood-red-crescent-260nw-2239455323.jpg",
  },
  {
    "name": "Begum Tayeeba Mojumder Red Crescent Blood Centre",
    "slug": "begum-tayeeba-mojumder-red-crescent-blood-centre-dinajpur",
    "mobile1": "+8801765311450",
    "mobile2": "+8801944354776",
    "website": "https://bdrcs.org/",
    "district": "Dinajpur",
    "thana": "",
    "address": "Dinajpur Sadar, Dinajpur",
    "imageUrl":
        "https://www.shutterstock.com/image-photo/people-donate-blood-red-crescent-260nw-2239455323.jpg",
  },
  {
    "name": "Mujib Jahan Red Crescent Blood Centre",
    "slug": "mujib-jahan-red-crescent-blood-centre-sylhet",
    "mobile1": "+8801611300900",
    "mobile2": "+880821724098",
    "website": "https://bdrcs.org/",
    "district": "Sylhet",
    "thana": "",
    "address": "Chowhatta area, Sylhet Sadar, Sylhet",
    "imageUrl":
        "https://www.shutterstock.com/image-photo/people-donate-blood-red-crescent-260nw-2239455323.jpg",
  },
  {
    "name": "Rajshahi Red Crescent Blood Centre",
    "slug": "rajshahi-red-crescent-blood-centre",
    "mobile1": "+8801865055075",
    "mobile2": "+8801556333821",
    "website": "https://bdrcs.org/",
    "district": "Rajshahi",
    "thana": "",
    "address": "Rajshahi Sadar, Rajshahi",
    "imageUrl":
        "https://www.shutterstock.com/image-photo/people-donate-blood-red-crescent-260nw-2239455323.jpg",
  },
  {
    "name": "Natore Red Crescent Blood Centre",
    "slug": "natore-red-crescent-blood-centre",
    "mobile1": "+8801792774841",
    "mobile2": "+8801725097292",
    "website": "https://bdrcs.org/",
    "district": "Natore",
    "thana": "",
    "address": "Natore Sadar, Natore",
    "imageUrl":
        "https://www.shutterstock.com/image-photo/people-donate-blood-red-crescent-260nw-2239455323.jpg",
  },
  {
    "name": "Magura Red Crescent Blood Centre",
    "slug": "magura-red-crescent-blood-centre",
    "mobile1": "+8801913137366",
    "mobile2": "",
    "website": "https://bdrcs.org/",
    "district": "Magura",
    "thana": "",
    "address": "Magura Sadar, Magura",
    "imageUrl":
        "https://www.shutterstock.com/image-photo/people-donate-blood-red-crescent-260nw-2239455323.jpg",
  },
];
