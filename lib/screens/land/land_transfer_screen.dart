import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/land_provider.dart';
import '../../services/land_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/gradient_button.dart';

class LandTransferScreen extends ConsumerStatefulWidget {
  final String landId;
  const LandTransferScreen({super.key, required this.landId});

  @override
  ConsumerState<LandTransferScreen> createState() => _LandTransferScreenState();
}

class _LandTransferScreenState extends ConsumerState<LandTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isTransferring = false;
  bool _confirmed = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _transfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm the transfer'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isTransferring = true);

    try {
      final officer = ref.read(currentUserProvider)!;
      final service = ref.read(landServiceProvider);
      await service.transferOwnership(
        parcelId: widget.landId,
        newOwnerName: _nameCtrl.text.trim(),
        newOwnerEmail: _emailCtrl.text.trim(),
        newOwnerPhone: _phoneCtrl.text.trim(),
        newOwnerId: 'transfer-${DateTime.now().millisecondsSinceEpoch}',
        actorId: officer.id,
        actorName: officer.fullName,
      );

      if (mounted) {
        ref.invalidate(userLandParcelsProvider);
        ref.invalidate(allLandParcelsProvider);
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.swap_horiz,
                color: AppColors.success, size: 48),
            title: const Text('Transfer Successful!'),
            content: const Text(
              'Land ownership has been successfully transferred. '
              'A blockchain record has been created for this transaction.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.citizenDashboard);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transfer Ownership'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: AppColors.warning, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Irreversible Action',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning)),
                        const SizedBox(height: 4),
                        Text(
                          'This action will permanently transfer land ownership and cannot be undone.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('New Owner Details',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Enter information for the new land owner',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),

            // Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      hint: 'New owner full name',
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          v!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _emailCtrl,
                      label: 'Email Address',
                      hint: 'newowner@email.cm',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v!.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      hint: '+237 6XX XXX XXX',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v!.isEmpty ? 'Phone is required' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Confirmation checkbox
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: CheckboxListTile(
                value: _confirmed,
                onChanged: (v) => setState(() => _confirmed = v ?? false),
                title: const Text(
                  'I confirm this ownership transfer is legally authorized and all parties have consented.',
                  style: TextStyle(fontSize: 13),
                ),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 20),

            GradientButton(
              label: 'Transfer Ownership',
              icon: Icons.swap_horiz,
              isLoading: _isTransferring,
              onPressed: _transfer,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
