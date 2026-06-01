import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/land_service.dart';
import '../../providers/land_provider.dart';
import '../../models/land_parcel.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final parcelsAsync = ref.watch(userLandParcelsProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.heroGradient),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 3),
                        ),
                        child: Center(
                          child: Text(
                            '${user.firstName[0]}${user.lastName[0]}'.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role.displayName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Edit Profile',
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats row for citizens
                parcelsAsync.when(
                  data: (parcels) {
                    final approved = parcels
                        .where((p) =>
                            p.status == LandStatus.approved)
                        .length;
                    final pending = parcels
                        .where((p) => p.status == LandStatus.pending ||
                          p.status == LandStatus.underReview)
                        .length;

                    return Row(
                      children: [
                        _statTile('Total Parcels', '${parcels.length}'),
                        _statTile('Approved', '$approved',
                            color: AppColors.success),
                        _statTile('Pending', '$pending',
                            color: AppColors.warning),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),

                // Profile info
                _infoCard(context, [
                  _infoItem(Icons.email_outlined, 'Email', user.email),
                  _infoItem(Icons.phone_outlined, 'Phone', user.phone),
                  if (user.region != null)
                    _infoItem(Icons.location_on_outlined, 'Region', user.region!),
                  if (user.nationalId != null)
                    _infoItem(Icons.badge_outlined, 'National ID', user.nationalId!),
                  _infoItem(Icons.calendar_today_outlined, 'Member Since',
                      DateFormat('MMMM yyyy').format(user.createdAt)),
                ]),
                const SizedBox(height: 16),

                // Menu
                _menuCard(context, ref, user),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, {Color? color}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: (color ?? AppColors.primary).withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.primary,
              ),
            ),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(children: items),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textHint, fontSize: 11)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext context, WidgetRef ref, UserModel user) {
    final items = [
      _MenuItem(Icons.notifications_outlined, 'Notifications',
          () => context.push(AppRoutes.notifications)),
      _MenuItem(Icons.security_outlined, 'Security & Privacy', () {}),
      _MenuItem(Icons.language_outlined, 'Language', () {}),
      _MenuItem(Icons.help_outline, 'Help & Support', () {}),
      _MenuItem(Icons.info_outline, 'About KamerSync', () {}),
    ];

    if (user.role == UserRole.mindcafOfficer ||
        user.role == UserRole.admin) {
      items.insert(
          0,
          _MenuItem(Icons.history, 'Audit Log',
              () => context.push(AppRoutes.auditLog)));
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          ...items.map((item) => ListTile(
                leading: Icon(item.icon,
                    size: 22, color: AppColors.textSecondary),
                title: Text(item.label),
                trailing: const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textHint),
                onTap: item.onTap,
                dense: true,
              )),
          const Divider(height: 1),
          ListTile(
            leading:
                const Icon(Icons.logout, size: 22, color: AppColors.error),
            title: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).logout();
              context.go(AppRoutes.login);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.onTap);
}
