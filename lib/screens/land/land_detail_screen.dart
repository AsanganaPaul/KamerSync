import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/land_parcel.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/land_provider.dart';
import '../../services/land_service.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/land/boundary_map_widget.dart';

class LandDetailScreen extends ConsumerWidget {
  final String landId;

  const LandDetailScreen({super.key, required this.landId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parcelAsync = ref.watch(landParcelByIdProvider(landId));
    final currentRole = ref.watch(currentRoleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: parcelAsync.when(
        data: (parcel) {
          if (parcel == null) {
            return const Center(child: Text('Land parcel not found'));
          }
          return _LandDetailContent(
              parcel: parcel, currentRole: currentRole, ref: ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _LandDetailContent extends StatelessWidget {
  final LandParcel parcel;
  final UserRole? currentRole;
  final WidgetRef ref;

  const _LandDetailContent({
    required this.parcel,
    required this.currentRole,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Hero app bar
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: AppColors.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Map preview
                parcel.boundary != null
                    ? BoundaryMapWidget(
                        boundary: parcel.boundary!,
                        interactive: false,
                      )
                    : Container(
                        decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient),
                        child: const Center(
                          child: Icon(Icons.landscape,
                              color: Colors.white, size: 80),
                        ),
                      ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                // Land ID badge
                if (parcel.landId != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(status: parcel.status.displayName),
                        const SizedBox(height: 6),
                        Text(
                          parcel.landId!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: parcel.landId ?? parcel.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Land ID copied!')),
                );
              },
              icon: const Icon(Icons.copy, color: Colors.white),
            ),
          ],
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Owner info card
                _sectionCard(
                  context,
                  title: 'Owner Information',
                  icon: Icons.person_outline,
                  children: [
                    _infoRow('Name', parcel.ownerName),
                    _infoRow('Email', parcel.ownerEmail),
                    _infoRow('Phone', parcel.ownerPhone),
                  ],
                ),
                const SizedBox(height: 16),

                // Land details card
                _sectionCard(
                  context,
                  title: 'Land Details',
                  icon: Icons.landscape_outlined,
                  children: [
                    _infoRow('Land Use', parcel.landUse.displayName),
                    _infoRow('Address', parcel.address),
                    _infoRow('Region', parcel.region),
                    _infoRow('Division', parcel.division),
                    _infoRow('Subdivision', parcel.subdivision),
                    if (parcel.areaHectares != null)
                      _infoRow('Area', '${parcel.areaHectares!.toStringAsFixed(2)} ha'),
                    _infoRow('Application Date',
                        DateFormat('dd MMM yyyy').format(parcel.applicationDate)),
                    if (parcel.approvalDate != null)
                      _infoRow('Approval Date',
                          DateFormat('dd MMM yyyy').format(parcel.approvalDate!)),
                    _infoRow('Description', parcel.description),
                  ],
                ),
                const SizedBox(height: 16),

                // Application Timeline
                _sectionCard(
                  context,
                  title: 'Application Timeline',
                  icon: Icons.timeline,
                  children: [
                    _buildTimeline(context, parcel.timeline),
                  ],
                ),
                const SizedBox(height: 16),

                // Blockchain verification
                if (parcel.blockchainHash != null)
                  _sectionCard(
                    context,
                    title: 'Blockchain Verification',
                    icon: Icons.verified_outlined,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          const Text('Transaction Verified',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                parcel.blockchainHash!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 16),
                              onPressed: () => Clipboard.setData(
                                  ClipboardData(
                                      text: parcel.blockchainHash!)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                if (parcel.blockchainHash != null) const SizedBox(height: 16),

                // QR Code for approved parcels
                if (parcel.status == LandStatus.approved &&
                    parcel.landId != null)
                  _sectionCard(
                    context,
                    title: 'Digital Certificate',
                    icon: Icons.qr_code_2,
                    children: [
                      Center(
                        child: QrImageView(
                          data:
                              'KAMERSYNC|${parcel.landId}|${parcel.ownerName}|${parcel.region}',
                          version: QrVersions.auto,
                          size: 160,
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'Scan to verify land ownership',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Action buttons
                if (parcel.status == LandStatus.approved)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/land/transfer/${parcel.id}'),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Transfer Ownership'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                      ),
                    ),
                  ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                )),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<ApplicationStep> steps) {
    if (steps.isEmpty) return const Text('No timeline data');

    return Column(
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
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isCompleted
                        ? AppColors.success
                        : step.isActive
                            ? AppColors.primary
                            : AppColors.border,
                  ),
                  child: Icon(
                    step.isCompleted ? Icons.check : Icons.circle,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: step.isCompleted
                        ? AppColors.success
                        : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: step.isCompleted || step.isActive
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (step.description != null)
                      Text(
                        step.description!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    if (step.completedAt != null)
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm')
                            .format(step.completedAt!),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textHint),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
