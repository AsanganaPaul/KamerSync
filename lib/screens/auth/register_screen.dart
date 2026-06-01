import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/custom_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();

  UserRole _selectedRole = UserRole.citizen;
  String? _selectedRegion;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    for (final c in [
      _emailCtrl, _passwordCtrl, _confirmCtrl, _firstNameCtrl,
      _lastNameCtrl, _phoneCtrl, _nationalIdCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authStateProvider.notifier).register(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            firstName: _firstNameCtrl.text.trim(),
            lastName: _lastNameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            role: _selectedRole,
            nationalId: _nationalIdCtrl.text.trim().isEmpty
                ? null
                : _nationalIdCtrl.text.trim(),
            region: _selectedRegion,
          );

      if (!mounted) return;

      final user = ref.read(currentUserProvider);
      if (user != null) {
        if (user.role == UserRole.citizen) {
          context.go(AppRoutes.citizenDashboard);
        } else {
          context.go(AppRoutes.officerDashboard);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.25,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxWidth: isTablet ? 560 : double.infinity),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Back + title
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.go(AppRoutes.login),
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 48),
                          child: Text(
                            'Join the national land registry',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form card
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppColors.elevatedShadow,
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Role selector
                                _buildSectionTitle('Select Your Role'),
                                const SizedBox(height: 12),
                                _RoleSelector(
                                  selectedRole: _selectedRole,
                                  onChanged: (r) =>
                                      setState(() => _selectedRole = r),
                                ),
                                const SizedBox(height: 24),

                                _buildSectionTitle('Personal Information'),
                                const SizedBox(height: 12),

                                // Name row
                                Row(
                                  children: [
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _firstNameCtrl,
                                        label: 'First Name',
                                        hint: 'Jean',
                                        prefixIcon: Icons.person_outline,
                                        validator: (v) =>
                                            v!.isEmpty ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: CustomTextField(
                                        controller: _lastNameCtrl,
                                        label: 'Last Name',
                                        hint: 'Mbeki',
                                        prefixIcon: Icons.person_outline,
                                        validator: (v) =>
                                            v!.isEmpty ? 'Required' : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                CustomTextField(
                                  controller: _phoneCtrl,
                                  label: 'Phone Number',
                                  hint: '+237 6XX XXX XXX',
                                  prefixIcon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) =>
                                      v!.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 12),

                                CustomTextField(
                                  controller: _nationalIdCtrl,
                                  label: 'National ID (optional)',
                                  hint: 'ID card number',
                                  prefixIcon: Icons.badge_outlined,
                                ),
                                const SizedBox(height: 12),

                                // Region
                                DropdownButtonFormField<String>(
                                  value: _selectedRegion,
                                  decoration: InputDecoration(
                                    labelText: 'Region',
                                    prefixIcon: const Icon(Icons.map_outlined),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: AppColors.surfaceVariant,
                                  ),
                                  items: CameroonRegions.regions
                                      .map((r) => DropdownMenuItem(
                                          value: r, child: Text(r)))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _selectedRegion = v),
                                ),
                                const SizedBox(height: 24),

                                _buildSectionTitle('Account Credentials'),
                                const SizedBox(height: 12),

                                CustomTextField(
                                  controller: _emailCtrl,
                                  label: 'Email Address',
                                  hint: 'your@email.cm',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v!.isEmpty) return 'Required';
                                    if (!v.contains('@'))
                                      return 'Invalid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                CustomTextField(
                                  controller: _passwordCtrl,
                                  label: 'Password',
                                  hint: 'Min 8 characters',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscurePass,
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePass
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                    onPressed: () => setState(
                                        () => _obscurePass = !_obscurePass),
                                  ),
                                  validator: (v) {
                                    if (v!.isEmpty) return 'Required';
                                    if (v.length < 8)
                                      return 'Min 8 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                CustomTextField(
                                  controller: _confirmCtrl,
                                  label: 'Confirm Password',
                                  hint: 'Re-enter password',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscureConfirm,
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirm
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                    onPressed: () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm),
                                  ),
                                  validator: (v) {
                                    if (v != _passwordCtrl.text)
                                      return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 28),

                                GradientButton(
                                  label: 'Create Account',
                                  icon: Icons.how_to_reg,
                                  isLoading: _isLoading,
                                  onPressed: _register,
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Already have an account? ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          context.go(AppRoutes.login),
                                      child: const Text('Sign In'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  const _RoleSelector({
    required this.selectedRole,
    required this.onChanged,
  });

  static final _roles = [
    (UserRole.citizen, Icons.person, 'Citizen'),
    (UserRole.mindcafOfficer, Icons.account_balance, 'MINDCAF Officer'),
    (UserRole.surveyor, Icons.straighten, 'Surveyor'),
    (UserRole.notary, Icons.gavel, 'Notary'),
    (UserRole.bank, Icons.account_balance_wallet, 'Bank'),
    (UserRole.localCouncil, Icons.location_city, 'Local Council'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _roles.map(((UserRole, IconData, String) r) {
        final isSelected = selectedRole == r.$1;
        return InkWell(
          onTap: () => onChanged(r.$1),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  r.$2,
                  size: 16,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  r.$3,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
