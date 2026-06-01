import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/land_parcel.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/land_provider.dart';
import '../../services/land_service.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/land/land_card.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../widgets/dashboard/quick_action_card.dart';
import '../../widgets/common/status_badge.dart';

class CitizenDashboard extends ConsumerStatefulWidget {
  const CitizenDashboard({super.key});

  @override
  ConsumerState<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends ConsumerState<CitizenDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final parcelsAsync = ref.watch(userLandParcelsProvider);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          // Hero App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
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
                              child: Center(
                                child: Text(
                                  user?.firstName.isNotEmpty == true
                                      ? user!.firstName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Good ${_greeting()}, ${user?.firstName ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    user?.role.displayName ?? 'Citizen',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Notifications
                            notificationsAsync.when(
                              data: (notifs) {
                                final unread =
                                    notifs.where((n) => !n.isRead).length;
                                return Stack(
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          context.push(AppRoutes.notifications),
                                      icon: const Icon(Icons.notifications_outlined,
                                          color: Colors.white),
                                    ),
                                    if (unread > 0)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          width: 16,
                                          height: 16,
                                          decoration: const BoxDecoration(
                                            color: AppColors.accent,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$unread',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: Builder(
              builder: (ctx) => IconButton(
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                icon: const Icon(Icons.menu, color: Colors.white),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => context.push(AppRoutes.search),
                icon: const Icon(Icons.search, color: Colors.white),
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row
                parcelsAsync.when(
                  data: (parcels) => _buildStatsRow(parcels),
                  loading: () => _buildStatsShimmer(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                _buildSectionHeader(context, 'Quick Actions', null),
                const SizedBox(height: 12),
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // My Land Parcels
                _buildSectionHeader(
                  context,
                  'My Land Parcels',
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All'),
                  ),
                ),
                const SizedBox(height: 12),
                parcelsAsync.when(
                  data: (parcels) => parcels.isEmpty
                      ? _buildEmptyParcels(context)
                      : Column(
                          children: parcels
                              .take(5)
                              .map((p) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: LandCard(
                                      parcel: p,
                                      onTap: () => context.push(
                                          '/land/detail/${p.id}'),
                                    ),
                                  ))
                              .toList(),
                        ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.landRegistration),
        icon: const Icon(Icons.add),
        label: const Text('Register Land'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildStatsRow(List<LandParcel> parcels) {
    final approved = parcels.where((p) => p.status == LandStatus.approved).length;
    final pending = parcels.where((p) => p.status == LandStatus.pending).length;
    final underReview = parcels.where((p) => p.status == LandStatus.underReview).length;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.landscape_rounded,
            label: 'Total Parcels',
            value: '${parcels.length}',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.check_circle_outline,
            label: 'Approved',
            value: '$approved',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.hourglass_empty,
            label: 'Pending',
            value: '${pending + underReview}',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsShimmer() {
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        QuickActionCard(
          icon: Icons.add_location_alt_outlined,
          label: 'Register Land',
          color: AppColors.primary,
          onTap: () => context.push(AppRoutes.landRegistration),
        ),
        QuickActionCard(
          icon: Icons.verified_outlined,
          label: 'Verify Land',
          color: AppColors.info,
          onTap: () => context.push(AppRoutes.landVerification),
        ),
        QuickActionCard(
          icon: Icons.map_outlined,
          label: 'GIS Map',
          color: AppColors.primaryLight,
          onTap: () => context.push(AppRoutes.gisMap),
        ),
        QuickActionCard(
          icon: Icons.track_changes,
          label: 'Track Status',
          color: AppColors.accent,
          onTap: () => context.push(AppRoutes.applicationTracking),
        ),
        QuickActionCard(
          icon: Icons.smart_toy_outlined,
          label: 'AI Assistant',
          color: const Color(0xFF7B61FF),
          onTap: () => context.push(AppRoutes.chatbot),
        ),
        QuickActionCard(
          icon: Icons.upload_file_outlined,
          label: 'Upload Docs',
          color: AppColors.textSecondary,
          onTap: () => context.push('/documents/upload/new'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Widget? action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (action != null) action,
      ],
    );
  }

  Widget _buildEmptyParcels(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.landscape_outlined,
              size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            'No Land Parcels Yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Start by registering your first land parcel.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.landRegistration),
            icon: const Icon(Icons.add),
            label: const Text('Register Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) {
        setState(() => _selectedIndex = i);
        switch (i) {
          case 0:
            break; // Already on dashboard
          case 1:
            context.push(AppRoutes.gisMap);
            break;
          case 2:
            context.push(AppRoutes.applicationTracking);
            break;
          case 3:
            context.push(AppRoutes.profile);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'Map',
        ),
        NavigationDestination(
          icon: Icon(Icons.track_changes_outlined),
          selectedIcon: Icon(Icons.track_changes),
          label: 'Tracking',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
