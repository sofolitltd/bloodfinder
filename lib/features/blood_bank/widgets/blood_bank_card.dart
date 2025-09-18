import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class BloodBank {
  final String name;
  final String slug;
  final String address;
  final String district;
  final String mobile1;
  final String? thana;
  final String? mobile2;
  final String? imageUrl;
  final String? website; // Nullable

  BloodBank({
    required this.name,
    required this.slug,
    required this.address,
    required this.district,
    required this.mobile1,
    this.thana,
    this.mobile2,
    this.imageUrl,
    this.website,
  });

  // Factory constructor to create a BloodBank from a Map
  factory BloodBank.fromJson(Map<String, dynamic> json) {
    return BloodBank(
      name: json['name'] as String,
      slug: json['slug'] as String,
      address: json['address'] as String,
      district: json['district'] as String,
      mobile1: json['mobile1'] as String,
      thana: json['thana'] as String?,
      mobile2: json['mobile2'] as String?,
      imageUrl: json['imageUrl'] as String?,
      website: json['website'] as String?,
    );
  }

  //
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'address': address,
      'district': district,
      'mobile1': mobile1,
      'thana': thana,
      'mobile2': mobile2,
      'imageUrl': imageUrl,
      'website': website,
    };
  }
}

class BloodBankCard extends StatelessWidget {
  final BloodBank bloodBank;

  const BloodBankCard({super.key, required this.bloodBank});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///

                //
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //
                      Text(
                        bloodBank.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      //
                      Text(
                        'Address: ${bloodBank.address}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // todo:  add image feature later
                // Container(
                //   width: 56,
                //   height: 56,
                //   decoration: BoxDecoration(
                //     borderRadius: BorderRadius.circular(8),
                //     border: Border.all(color: Colors.black12, width: 1),
                //     color: Colors.red.shade200,
                //   ),
                // ),
                //   image:
                //       bloodBank.imageUrl != null &&
                //           bloodBank.imageUrl!.isNotEmpty
                //       ? DecorationImage(
                //           image: NetworkImage(bloodBank.imageUrl!),
                //           fit: BoxFit.cover,
                //         )
                //       : null, // No image if imageUrl is empty or null
                // ),
                // child:
                //     bloodBank.imageUrl == null || bloodBank.imageUrl!.isEmpty
                //     ? const Icon(
                //         Icons.local_hospital,
                //         color: Colors.white,
                //         size: 40,
                //       )
                //     : null,
                // ),
              ],
            ),

            //
            const SizedBox(height: 4),
            // Buttons Row
            Row(
              children: [
                if (bloodBank.mobile1.isNotEmpty)
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.call, color: Colors.green),
                        Positioned(top: -3, right: 2, child: Text('1')),
                      ],
                    ),
                    onPressed: () async {
                      final uri = Uri.parse('tel:${bloodBank.mobile1}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch call'),
                          ),
                        );
                      }
                    },
                  ),
                if (bloodBank.mobile2 != null && bloodBank.mobile2!.isNotEmpty)
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.call, color: Colors.green),
                        Positioned(top: -3, right: 2, child: Text('2')),
                      ],
                    ),
                    onPressed: () async {
                      final uri = Uri.parse('tel:${bloodBank.mobile2}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch call'),
                          ),
                        );
                      }
                    },
                  ),
                if (bloodBank.website != null && bloodBank.website!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.language, color: Colors.blue),
                    onPressed: () async {
                      final uri = Uri.parse(bloodBank.website!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not launch website'),
                          ),
                        );
                      }
                    },
                  ),

                //
                Spacer(),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.grey),
                  onPressed: () {
                    // Implement share functionality here
                    // For example, using the share_plus package
                    SharePlus.instance.share(
                      ShareParams(
                        text:
                            '${bloodBank.name} at ${bloodBank.address}.\nContact: ${bloodBank.mobile1}\n${bloodBank.mobile2}\n${bloodBank.website}',
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
