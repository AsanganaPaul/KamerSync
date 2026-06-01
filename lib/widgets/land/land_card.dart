import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/land_parcel.dart';
import '../common/status_badge.dart';
class LandCard extends StatelessWidget {
  final LandParcel parcel;
  final VoidCallback? onTap;
  final bool showActions;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const LandCard({super.key, required this.parcel, this.onTap, this.showActions = false, this.onApprove, this.onReject});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.landscape_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(parcel.landId ?? 'Pending ID', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                  StatusBadge(status: parcel.status.displayName),
                ],
              ),
              const SizedBox(height: 8),
              Text(parcel.address, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(parcel.ownerName, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
              if (showActions && (parcel.status == LandStatus.pending || parcel.status == LandStatus.underReview)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onApprove != null) Expanded(child: ElevatedButton(onPressed: onApprove, style: ElevatedButton.styleFrom(backgroundColor: AppColors.success), child: const Text('Approve'))),
                    const SizedBox(width: 8),
                    if (onReject != null) Expanded(child: OutlinedButton(onPressed: onReject, child: const Text('Reject'))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}