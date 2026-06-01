import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../models/land_parcel.dart';
import '../../providers/land_provider.dart';
import '../../widgets/common/status_badge.dart';

class ApplicationTrackingScreen extends ConsumerWidget {
  const ApplicationTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcelsAsync = ref.watch(userLandParcelsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Application Tracking'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: parcelsAsync.when(
        data: (parcels) {
          if (parcels.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.track_changes,
                      size: 72, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text('No Applications Found'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () =>
                        context.push('/land/register'),
                    child: const Text('Register Land'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: parcels.length,
            itemBuilder: (context, i) {
              return _TrackingCard(parcel: parcels[i]);
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final LandParcel parcel;

  const _TrackingCard({required this.parcel});

  @override
  Widget build(BuildContext context) {
    final steps = parcel.timeline;
    final completedSteps =
        steps.where((s) => s.isCompleted).length;
    final totalSteps = steps.length;
    final progress =
        totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: parcel.status == LandStatus.approved
                  ? LinearGradient(
                      colors: [
                        AppColors.success.withOpacity(0.1),
                        AppColors.success.withOpacity(0.05),
                      ],
                    )
                  : null,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parcel.landId ?? 'Application #${parcel.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        parcel.address,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Applied: ${DateFormat('dd MMM yyyy').format(parcel.applicationDate)}',
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: parcel.status.displayName),
              ],
            ),
          ),

          const Divider(height: 1),

          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$completedSteps / $totalSteps steps',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceVariant,
                    color: _progressColor(parcel.status),
                  ),
                ),
              ],
            ),
          ),

          // Timeline steps
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: steps.asMap().entries.map((entry) {
                final i = entry.key;
                final step = entry.value;
                final isLast = i == steps.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: step.isCompleted
                                ? AppColors.success
                                : step.isActive
                                    ? AppColors.primary
                                    : AppColors.surfaceVariant,
                            border: Border.all(
                              color: step.isCompleted
                                  ? AppColors.success
                                  : step.isActive
                                      ? AppColors.primary
                                      : AppColors.border,
                            ),
                          ),
                          child: Icon(
                            step.isCompleted ? Icons.check : Icons.circle,
                            size: 12,
                            color: step.isCompleted || step.isActive
                                ? Colors.white
                                : AppColors.border,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 28,
                            color: step.isCompleted
                                ? AppColors.success.withOpacity(0.5)
                                : AppColors.border,
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.only(bottom: isLast ? 0 : 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: step.isCompleted
                                    ? AppColors.textPrimary
                                    : step.isActive
                                        ? AppColors.primary
                                        : AppColors.textHint,
                              ),
                            ),
                            if (step.completedAt != null)
                              Text(
                                DateFormat('dd MMM, HH:mm')
                                    .format(step.completedAt!),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          // Rejection reason
          if (parcel.rejectionReason != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: ${parcel.rejectionReason}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _progressColor(LandStatus status) {
    switch (status) {
      case LandStatus.approved:
      case LandStatus.transferred:
        return AppColors.success;
      case LandStatus.rejected:
        return AppColors.error;
      case LandStatus.underReview:
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }
}
