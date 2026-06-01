import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/app_models.dart';
import '../../models/land_parcel.dart';
import '../../providers/land_provider.dart';
import '../../services/land_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/status_badge.dart';

class LandRegistrationScreen extends ConsumerStatefulWidget {
  const LandRegistrationScreen({super.key});

  @override
  ConsumerState<LandRegistrationScreen> createState() =>
      _LandRegistrationScreenState();
}

class _LandRegistrationScreenState
    extends ConsumerState<LandRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1 controllers
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _subdivisionCtrl = TextEditingController();

  // Step 2 — boundary drawn on map
  final List<Map<String, double>> _boundaryPoints = [];

  // Step 3 — documents
  final List<String> _docPaths = [];
  final List<String> _docNames = [];

  String? _selectedRegion;
  String? _selectedDivision;
  LandUseType _landUse = LandUseType.residential;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _subdivisionCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra;
      if (extra is List<LatLng>) {
        setState(() {
          for (final point in extra) {
            _boundaryPoints.add({
              'lat': point.latitude,
              'lng': point.longitude,
            });
            ref.read(landRegistrationProvider.notifier)
              .addBoundaryPoint(point.latitude, point.longitude);
          }
        });
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRegion == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a region')));
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await ref.read(landRegistrationProvider.notifier).submit();
    setState(() => _isSubmitting = false);

    if (success && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 56,
          ),
          title: const Text('Application Submitted!'),
          content: const Text(
            'Your land registration has been submitted successfully. '
            'You will receive a notification once reviewed.\n\n'
            'Status: Pending Review',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go(AppRoutes.citizenDashboard);
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Register New Land'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      label: _currentStep == 3
                          ? 'Submit Application'
                          : 'Continue',
                      icon: _currentStep == 3
                          ? Icons.send
                          : Icons.arrow_forward,
                      isLoading: _isSubmitting,
                      onPressed: details.onStepContinue!,
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Land Details'),
              subtitle: const Text('Basic information about the land'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildStep1(),
            ),
            Step(
              title: const Text('Map Boundary'),
              subtitle: const Text('Draw land boundary on map'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _buildStep2(),
            ),
            Step(
              title: const Text('Documents'),
              subtitle: const Text('Upload supporting documents'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: _buildStep3(),
            ),
            Step(
              title: const Text('Review & Submit'),
              subtitle: const Text('Confirm your application'),
              isActive: _currentStep >= 3,
              state: StepState.indexed,
              content: _buildStep4(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Land Use Type
          Text('Land Use Type', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LandUseType.values.map((type) {
              final isSelected = _landUse == type;
              return FilterChip(
                label: Text(type.displayName),
                selected: isSelected,
                onSelected: (_) => setState(() => _landUse = type),
                selectedColor: AppColors.primary.withOpacity(0.15),
                checkmarkColor: AppColors.primary,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          CustomTextField(
            controller: _addressCtrl,
            label: 'Property Address',
            hint: 'Street, Neighbourhood',
            prefixIcon: Icons.location_on_outlined,
            validator: (v) => v!.isEmpty ? 'Address is required' : null,
            onChanged: (v) => ref
                .read(landRegistrationProvider.notifier)
                .updateField('address', v),
          ),
          const SizedBox(height: 12),

          // Region
          DropdownButtonFormField<String>(
            value: _selectedRegion,
            decoration: InputDecoration(
              labelText: 'Region *',
              prefixIcon: const Icon(Icons.map_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            items: CameroonRegions.regions
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) {
              setState(() {
                _selectedRegion = v;
                _selectedDivision = null;
              });
              ref
                  .read(landRegistrationProvider.notifier)
                  .updateField('region', v ?? '');
            },
            validator: (v) => v == null ? 'Select a region' : null,
          ),
          const SizedBox(height: 12),

          // Division
          DropdownButtonFormField<String>(
            value: _selectedDivision,
            decoration: InputDecoration(
              labelText: 'Division',
              prefixIcon: const Icon(Icons.map),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            items:
                (_selectedRegion != null &&
                    CameroonRegions.divisions.containsKey(_selectedRegion))
                ? CameroonRegions.divisions[_selectedRegion]!
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList()
                : [],
            onChanged: (v) {
              setState(() => _selectedDivision = v);
              ref
                  .read(landRegistrationProvider.notifier)
                  .updateField('division', v ?? '');
            },
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _subdivisionCtrl,
            label: 'Subdivision / Locality',
            hint: 'e.g., Bastos, Akwa',
            prefixIcon: Icons.location_city_outlined,
            onChanged: (v) => ref
                .read(landRegistrationProvider.notifier)
                .updateField('subdivision', v),
          ),
          const SizedBox(height: 12),

          CustomTextField(
            controller: _descCtrl,
            label: 'Land Description',
            hint: 'Describe the land parcel, usage, features...',
            prefixIcon: Icons.description_outlined,
            maxLines: 4,
            validator: (v) => v!.isEmpty ? 'Description is required' : null,
            onChanged: (v) => ref
                .read(landRegistrationProvider.notifier)
                .updateField('description', v),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Draw the boundary of your land parcel on the map.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // Map placeholder (tap to navigate to full GIS screen)
        GestureDetector(
          onTap: () => context.push(AppRoutes.gisMap),
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, width: 2),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.05),
                  AppColors.primaryLight.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 56,
                  color: AppColors.primary.withOpacity(0.7),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap to Open GIS Map',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Draw land boundary polygon',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Manual coordinate input
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
              const Text(
                'Boundary Points (optional manual entry)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _boundaryPoints.isEmpty
                          ? 'No points added yet'
                          : '${_boundaryPoints.length} points defined',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _boundaryPoints.clear()),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Demo — add Yaoundé center
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _boundaryPoints.addAll([
                      {'lat': 3.8700, 'lng': 11.5120},
                      {'lat': 3.8710, 'lng': 11.5135},
                      {'lat': 3.8705, 'lng': 11.5150},
                      {'lat': 3.8695, 'lng': 11.5138},
                    ]);
                  });
                },
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Add Demo Boundary'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    final docTypes = [
      ('Title Deed', Icons.article_outlined),
      ('Survey Plan', Icons.straighten),
      ('National ID', Icons.badge_outlined),
      ('Tax Receipt', Icons.receipt_outlined),
      ('Other', Icons.attach_file),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload supporting documents (PDF, JPG, PNG)',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // Upload buttons for each type
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: docTypes.map(((String, IconData) doc) {
            return OutlinedButton.icon(
              onPressed: () => _simulateDocUpload(doc.$1),
              icon: Icon(doc.$2, size: 16),
              label: Text(doc.$1),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Uploaded docs list
        if (_docNames.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Uploaded Documents:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ..._docNames.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.file_present,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.error,
                          ),
                          onPressed: () => setState(() {
                            _docNames.removeAt(entry.key);
                            _docPaths.removeAt(entry.key);
                          }),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.upload_file_outlined,
                  size: 40,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No documents uploaded yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Upload at least one supporting document',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStep4() {
    final regState = ref.read(landRegistrationProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reviewRow('Land Use', _landUse.displayName),
        _reviewRow(
          'Address',
          _addressCtrl.text.isEmpty ? '—' : _addressCtrl.text,
        ),
        _reviewRow('Region', _selectedRegion ?? '—'),
        _reviewRow('Division', _selectedDivision ?? '—'),
        _reviewRow(
          'Subdivision',
          _subdivisionCtrl.text.isEmpty ? '—' : _subdivisionCtrl.text,
        ),
        _reviewRow(
          'Description',
          _descCtrl.text.isEmpty ? '—' : _descCtrl.text,
        ),
        _reviewRow('Boundary Points', '${_boundaryPoints.length} defined'),
        _reviewRow('Documents', '${_docNames.length} uploaded'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'By submitting, you confirm all information is accurate and agree to the terms of the Cameroon Land Registry.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _simulateDocUpload(String docType) {
    setState(() {
    _docNames.add('${docType}_${DateTime.now().millisecondsSinceEpoch}.pdf');      _docPaths.add(
        '/simulated/path/${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    });
    ref.read(landRegistrationProvider.notifier).addDocument(_docPaths.last);
  }
}
