import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/land_provider.dart';
import '../../widgets/land/land_card.dart';
import '../../widgets/common/custom_text_field.dart';
import 'package:go_router/go_router.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _ctrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              hintText: 'Search by Land ID, owner, region...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              border: InputBorder.none,
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _ctrl.clear();
                        ref.read(searchProvider.notifier).clear();
                      },
                    )
                  : null,
            ),
            onChanged: (v) =>
                ref.read(searchProvider.notifier).search(v),
          ),
        ),
      ),
      body: searchState.query.isEmpty
          ? _buildEmptySearch()
          : searchState.isSearching
              ? const Center(child: CircularProgressIndicator())
              : searchState.results.isEmpty
                  ? _buildNoResults(searchState.query)
                  : _buildResults(context, searchState),
    );
  }

  Widget _buildEmptySearch() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(Icons.search, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'Search Land Records',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search by Land ID, owner name, address, or region.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          _buildQuickSearch(),
        ],
      ),
    );
  }

  Widget _buildQuickSearch() {
    final examples = [
      'CM-CTR-2024-0001',
      'Jean Mbeki',
      'Bastos',
      'Douala',
      'Littoral',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Try searching for:',
          style: TextStyle(
              fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: examples.map((e) {
            return InkWell(
              onTap: () {
                _ctrl.text = e;
                ref.read(searchProvider.notifier).search(e);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(e,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text('No results for "$query"'),
          const SizedBox(height: 8),
          const Text(
            'Try a different Land ID or owner name',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, searchState) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: AppColors.surfaceVariant,
          child: Row(
            children: [
              Text(
                '${searchState.results.length} result(s) found',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: searchState.results.length,
            itemBuilder: (context, i) {
              final parcel = searchState.results[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LandCard(
                  parcel: parcel,
                  onTap: () => context.push('/land/detail/${parcel.id}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
