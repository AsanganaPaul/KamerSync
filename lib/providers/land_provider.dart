import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/land_parcel.dart';
import '../models/user_model.dart';
import '../services/land_service.dart';
import 'auth_provider.dart';

/// Provider for fetching all land parcels for the current user
final userLandParcelsProvider =
    FutureProvider.autoDispose<List<LandParcel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final service = ref.read(landServiceProvider);
  return service.getLandParcelsForUser(user.id);
});

/// Provider for all land parcels (officer view)
final allLandParcelsProvider =
    FutureProvider.autoDispose<List<LandParcel>>((ref) async {
  final service = ref.read(landServiceProvider);
  return service.getAllLandParcels();
});

/// Provider for a single land parcel by ID
final landParcelByIdProvider =
    FutureProvider.autoDispose.family<LandParcel?, String>((ref, id) async {
  final service = ref.read(landServiceProvider);
  return service.getLandParcelById(id);
});

/// State for land registration form
class LandRegistrationState {
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String description;
  final String address;
  final String region;
  final String division;
  final String subdivision;
  final LandUseType landUse;
  final List<Map<String, double>> boundaryPoints;
  final List<String> documentPaths;
  final bool isSubmitting;
  final String? error;
  final bool isSuccess;

  const LandRegistrationState({
    this.ownerName = '',
    this.ownerEmail = '',
    this.ownerPhone = '',
    this.description = '',
    this.address = '',
    this.region = '',
    this.division = '',
    this.subdivision = '',
    this.landUse = LandUseType.residential,
    this.boundaryPoints = const [],
    this.documentPaths = const [],
    this.isSubmitting = false,
    this.error,
    this.isSuccess = false,
  });

  LandRegistrationState copyWith({
    String? ownerName,
    String? ownerEmail,
    String? ownerPhone,
    String? description,
    String? address,
    String? region,
    String? division,
    String? subdivision,
    LandUseType? landUse,
    List<Map<String, double>>? boundaryPoints,
    List<String>? documentPaths,
    bool? isSubmitting,
    String? error,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return LandRegistrationState(
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      description: description ?? this.description,
      address: address ?? this.address,
      region: region ?? this.region,
      division: division ?? this.division,
      subdivision: subdivision ?? this.subdivision,
      landUse: landUse ?? this.landUse,
      boundaryPoints: boundaryPoints ?? this.boundaryPoints,
      documentPaths: documentPaths ?? this.documentPaths,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class LandRegistrationNotifier extends Notifier<LandRegistrationState> {
  @override
  LandRegistrationState build() => const LandRegistrationState();

  void updateField(String field, dynamic value) {
    switch (field) {
      case 'ownerName':
        state = state.copyWith(ownerName: value as String);
        break;
      case 'ownerEmail':
        state = state.copyWith(ownerEmail: value as String);
        break;
      case 'ownerPhone':
        state = state.copyWith(ownerPhone: value as String);
        break;
      case 'description':
        state = state.copyWith(description: value as String);
        break;
      case 'address':
        state = state.copyWith(address: value as String);
        break;
      case 'region':
        state = state.copyWith(region: value as String, division: '');
        break;
      case 'division':
        state = state.copyWith(division: value as String);
        break;
      case 'subdivision':
        state = state.copyWith(subdivision: value as String);
        break;
      case 'landUse':
        state = state.copyWith(landUse: value as LandUseType);
        break;
    }
  }

  void addBoundaryPoint(double lat, double lng) {
    final newPoints = List<Map<String, double>>.from(state.boundaryPoints)
      ..add({'lat': lat, 'lng': lng});
    state = state.copyWith(boundaryPoints: newPoints);
  }

  void clearBoundaryPoints() {
    state = state.copyWith(boundaryPoints: []);
  }

  void addDocument(String path) {
    final newDocs = List<String>.from(state.documentPaths)..add(path);
    state = state.copyWith(documentPaths: newDocs);
  }

  void removeDocument(int index) {
    final newDocs = List<String>.from(state.documentPaths)..removeAt(index);
    state = state.copyWith(documentPaths: newDocs);
  }

  Future<bool> submit() async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Not authenticated');

      final service = ref.read(landServiceProvider);
      await service.registerLand(
        ownerId: user.id,
        ownerName: state.ownerName.isEmpty ? user.fullName : state.ownerName,
        ownerEmail: state.ownerEmail.isEmpty ? user.email : state.ownerEmail,
        ownerPhone: state.ownerPhone.isEmpty ? user.phone : state.ownerPhone,
        description: state.description,
        address: state.address,
        region: state.region,
        division: state.division,
        subdivision: state.subdivision,
        landUse: state.landUse,
        boundaryPoints: state.boundaryPoints,
        documentPaths: state.documentPaths,
      );

      state = state.copyWith(isSubmitting: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void reset() {
    state = const LandRegistrationState();
  }
}

final landRegistrationProvider =
    NotifierProvider<LandRegistrationNotifier, LandRegistrationState>(
        LandRegistrationNotifier.new);

/// Search provider
class SearchState {
  final String query;
  final List<LandParcel> results;
  final bool isSearching;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
  });
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }
    state = SearchState(query: query, isSearching: true);
    try {
      final service = ref.read(landServiceProvider);
      final results = await service.searchLand(query);
      state = SearchState(query: query, results: results);
    } catch (_) {
      state = SearchState(query: query);
    }
  }

  void clear() {
    state = const SearchState();
  }
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
