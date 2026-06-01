import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String landId;
  const DocumentUploadScreen({super.key, required this.landId});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final List<Map<String, String>> _uploadedDocs = [];
  bool _isUploading = false;

  final _docTypes = [
    'Title Deed',
    'Survey Plan',
    'National ID',
    'Tax Receipt',
    'Witness Statement',
    'Previous Title',
    'Other',
  ];

  String _selectedType = 'Title Deed';

  Future<void> _simulateUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _isUploading = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final file = result.files.first;
    final sizeKb = '${(file.size / 1024).toStringAsFixed(1)} KB';

    setState(() {
      _uploadedDocs.add({
        'name': file.name,
        'type': _selectedType,
        'size': sizeKb,
        'status': 'uploaded',
        'path': file.path ?? '',
      });
      _isUploading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${file.name} uploaded successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload Documents'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file,
                      color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Document Upload',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          widget.landId == 'new'
                              ? 'Upload for new registration'
                              : 'Land ID: ${widget.landId}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Document type selector
            Text('Document Type',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _docTypes.map((type) {
                final isSelected = _selectedType == type;
                return FilterChip(
                  label: Text(type, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (_) =>
                      setState(() => _selectedType = type),
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Upload area
            GestureDetector(
              onTap: _isUploading ? null : _simulateUpload,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 160,
                decoration: BoxDecoration(
                  color: _isUploading
                      ? AppColors.primary.withOpacity(0.05)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isUploading
                        ? AppColors.primary
                        : AppColors.border,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: _isUploading
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                                color: AppColors.primary),
                            const SizedBox(height: 12),
                            const Text('Uploading...',
                                style:
                                    TextStyle(color: AppColors.primary)),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cloud_upload_outlined,
                                size: 48,
                                color:
                                    AppColors.primary.withOpacity(0.6)),
                            const SizedBox(height: 10),
                            const Text(
                              'Tap to Upload Document',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'PDF, JPG, PNG — max 10MB',
                              style: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Uploaded files
            if (_uploadedDocs.isNotEmpty) ...[
              Text('Uploaded Documents (${_uploadedDocs.length})',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _uploadedDocs.length,
                  itemBuilder: (context, i) {
                    final doc = _uploadedDocs[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.picture_as_pdf,
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doc['name']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                  '${doc['type']} • ${doc['size']}',
                                  style: const TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.check_circle,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.error),
                            onPressed: () => setState(
                                () => _uploadedDocs.removeAt(i)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _uploadedDocs.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.check),
                  label: Text('Save ${_uploadedDocs.length} Document(s)'),
                ),
              ),
            )
          : null,
    );
  }
}

class DocumentViewerScreen extends StatelessWidget {
  final String url;
  final String title;

  const DocumentViewerScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Download',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf,
                size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Document viewer',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Document'),
            ),
          ],
        ),
      ),
    );
  }
}
