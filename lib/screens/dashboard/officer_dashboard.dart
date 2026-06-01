import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/land_parcel.dart';
import '../../providers/auth_provider.dart';
import '../../services/land_service.dart';
import '../../providers/land_provider.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/land/land_card.dart';
import '../../models/user_model.dart';
import '../../widgets/dashboard/stat_card.dart';

class OfficerDashboard extends ConsumerStatefulWidget {
  const OfficerDashboard({super.key});

  @override
  ConsumerState<OfficerDashboard> createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends ConsumerState<OfficerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  LandStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final allParcelsAsync = ref.watch(allLandParcelsProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Builder(
              builder: (ctx) => IconButton(
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                icon: const Icon(Icons.menu, color: Colors.white),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => context.push(AppRoutes.auditLog),
                icon: const Icon(Icons.history, color: Colors.white),
                tooltip: 'Audit Log',
              ),
              IconButton(
                onPressed: () => context.push(AppRoutes.search),
                icon: const Icon(Icons.search, color: Colors.white),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance,
                                  color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${user?.firstName ?? 'Officer'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    user?.role.displayName ?? 'MINDCAF Officer',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Stats summary
                        statsAsync.when(
                          data: (stats) => Row(
                            children: [
                              _miniStat('Total', '${stats['total']}'),
                              _divider(),
                              _miniStat('Pending', '${stats['pending']}',
                                  color: AppColors.accentLight),
                              _divider(),
                              _miniStat('Approved', '${stats['approved']}',
                                  color: Colors.greenAccent),
                              _divider(),
                              _miniStat('Rejected', '${stats['rejected']}',
                                  color: Colors.redAccent.shade100),
                            ],
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Pending'),
                Tab(text: 'Review'),
                Tab(text: 'Approved'),
              ],
            ),
          ),
        ],
        body: allParcelsAsync.when(
          data: (parcels) => TabBarView(
            controller: _tabController,
            children: [
              _buildParcelList(parcels, null, context),
              _buildParcelList(
                  parcels.where((p) => p.status == LandStatus.pending).toList(),
                  null,
                  context),
              _buildParcelList(
                  parcels
                      .where((p) => p.status == LandStatus.underReview)
                      .toList(),
                  null,
                  context),
              _buildParcelList(
                  parcels
                      .where((p) => p.status == LandStatus.approved)
                      .toList(),
                  null,
                  context),
            ],
          ),
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),

      // Stat cards in a second scrollable area
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'chat',
            onPressed: () => context.push(AppRoutes.chatbot),
            backgroundColor: const Color(0xFF7B61FF),
            child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'map',
            onPressed: () => context.push(AppRoutes.gisMap),
            icon: const Icon(Icons.map_outlined),
            label: const Text('View Map'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildParcelList(
      List<LandParcel> parcels, LandStatus? filter, BuildContext context) {
    final filtered =
        filter != null ? parcels.where((p) => p.status == filter).toList() : parcels;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('No applications',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        final parcel = filtered[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LandCard(
            parcel: parcel,
            showActions: true,
            onTap: () => context.push('/land/detail/${parcel.id}'),
            onApprove: parcel.status == LandStatus.pending ||
                    parcel.status == LandStatus.underReview
                ? () => _showApprovalDialog(context, parcel)
                : null,
            onReject: parcel.status == LandStatus.pending ||
                    parcel.status == LandStatus.underReview
                ? () => _showRejectionDialog(context, parcel)
                : null,
          ),
        );
      },
    );
  }

  Widget _miniStat(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Future<void> _showApprovalDialog(
      BuildContext context, LandParcel parcel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Application'),
        content: Text(
            'Approve land registration for ${parcel.ownerName} at ${parcel.address}?\n\nA unique Land ID will be generated and a blockchain record created.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final officer = ref.read(currentUserProvider)!;
      final service = ref.read(landServiceProvider);
      await service.updateParcelStatus(
        parcelId: parcel.id,
        newStatus: LandStatus.approved,
        actorId: officer.id,
        actorName: officer.fullName,
      );
      ref.invalidate(allLandParcelsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application approved! Land ID generated.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _showRejectionDialog(
      BuildContext context, LandParcel parcel) async {
    final reasonCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rejecting application for ${parcel.ownerName}.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonCtrl.text),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final officer = ref.read(currentUserProvider)!;
      final service = ref.read(landServiceProvider);
      await service.updateParcelStatus(
        parcelId: parcel.id,
        newStatus: LandStatus.rejected,
        actorId: officer.id,
        actorName: officer.fullName,
        rejectionReason: result,
      );
      ref.invalidate(allLandParcelsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application rejected.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
