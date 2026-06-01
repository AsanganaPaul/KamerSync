import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/land_parcel.dart';
import '../../services/land_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/status_badge.dart';

class LandVerificationScreen extends ConsumerStatefulWidget {
  const LandVerificationScreen({super.key});

  @override
  ConsumerState<LandVerificationScreen> createState() =>
      _LandVerificationScreenState();
}

class _LandVerificationScreenState
    extends ConsumerState<LandVerificationScreen> {
  final _searchCtrl = TextEditingController();
  LandParcel? _result;
  bool _isSearching = false;
  bool _hasSearched = false;
  String _searchType = 'landId'; // 'landId' | 'ownerName'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _hasSearched = false;
    });

    final service = ref.read(landServiceProvider);
    final results = await service.searchLand(_searchCtrl.text.trim());

    setState(() {
      _isSearching = false;
      _hasSearched = true;
      _result = results.isNotEmpty ? results.first : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Land Ownership'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.verified_outlined,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Real-Time Verification',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Instant land ownership verification',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search type toggle
            Row(
              children: [
                Expanded(
                  child: _toggleButton(
                    'By Land ID',
                    Icons.tag,
                    _searchType == 'landId',
                    () => setState(() => _searchType = 'landId'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _toggleButton(
                    'By Owner Name',
                    Icons.person_search,
                    _searchType == 'ownerName',
                    () => setState(() => _searchType = 'ownerName'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            CustomTextField(
              controller: _searchCtrl,
              label: _searchType == 'landId'
                  ? 'Enter Land ID'
                  : 'Enter Owner Name',
              hint: _searchType == 'landId'
                  ? 'e.g. CM-CTR-2024-0001'
                  : 'e.g. Jean Mbeki',
              prefixIcon: _searchType == 'landId'
                  ? Icons.pin
                  : Icons.person_search,
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 12),

            GradientButton(
              label: 'Verify Now',
              icon: Icons.search,
              isLoading: _isSearching,
              onPressed: _verify,
            ),
            const SizedBox(height: 24),

            // Result
            if (_hasSearched) ...[
              if (_result == null)
                _buildNotFound()
              else
                _buildResultCard(_result!),
            ],

            // Demo hint
            if (!_hasSearched)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: AppColors.accent, size: 18),
                        SizedBox(width: 8),
                        Text('Demo Searches',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _demoChip('CM-CTR-2024-0001'),
                    _demoChip('Jean Mbeki'),
                    _demoChip('Sophie Nkemdirim'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(
      String label, IconData icon, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoChip(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          _searchCtrl.text = value;
          _verify();
        },
        child: Row(
          children: [
            const Icon(Icons.arrow_right, color: AppColors.primary, size: 16),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          const Text('No Land Record Found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error)),
          const SizedBox(height: 6),
          Text(
            'No land parcel found matching "${_searchCtrl.text}".\nPlease verify the Land ID or owner name.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(LandParcel parcel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verified header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              border: Border(
                  bottom:
                      BorderSide(color: AppColors.success.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 24),
                const SizedBox(width: 10),
                const Text('Land Record Verified',
                    style: TextStyle(
                        color: AppColors.success,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                StatusBadge(status: parcel.status.displayName),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (parcel.landId != null)
                  _detailRow('Land ID', parcel.landId!, bold: true),
                _detailRow('Owner', parcel.ownerName),
                _detailRow('Address', parcel.address),
                _detailRow('Region', parcel.region),
                _detailRow('Land Use', parcel.landUse.displayName),
                if (parcel.areaHectares != null)
                  _detailRow('Area',
                      '${parcel.areaHectares!.toStringAsFixed(2)} hectares'),
                if (parcel.approvalDate != null)
                  _detailRow('Approved On',
                      '${parcel.approvalDate!.day}/${parcel.approvalDate!.month}/${parcel.approvalDate!.year}'),
                if (parcel.blockchainHash != null) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.link,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      const Text('Blockchain verified',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontWeight:
                        bold ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
                    color: bold
                        ? AppColors.primary
                        : AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
