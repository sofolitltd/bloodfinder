import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../models/blood_bank.dart';
import '../pages/blood_bank_detail_page.dart';

class BloodBankCard extends StatelessWidget {
  final BloodBank bloodBank;

  const BloodBankCard({super.key, required this.bloodBank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BloodBankDetailPage(bloodBank: bloodBank),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.red.shade50,
                ),
                clipBehavior: Clip.antiAlias,
                child: bloodBank.imageUrl != null &&
                        bloodBank.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: bloodBank.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const CupertinoActivityIndicator(),
                        errorWidget: (_, _, _) => Icon(
                          Icons.local_hospital,
                          color: Colors.red.shade200,
                          size: 22,
                        ),
                      )
                    : Icon(
                        Icons.local_hospital,
                        color: Colors.red.shade200,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bloodBank.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(PhosphorIcons.hospital,
                            size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            bloodBank.address,
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(PhosphorIcons.mapPin,
                            size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            bloodBank.locationAddress ?? 'Location not set',
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(PhosphorIcons.phoneCall,
                            size: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text(
                          bloodBank.mobile1,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  PhosphorIcons.caretRight,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
