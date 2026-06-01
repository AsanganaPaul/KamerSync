import 'dart:convert';
import 'dart:async' show unawaited;
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'package:latlong2/latlong.dart';

import '../models/land_parcel.dart';
import '../models/app_models.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'notification_service.dart';

/// Land service — handles all land-related API operations
class LandService {
  final String baseUrl;

  LandService({String? baseUrl})
    : baseUrl =
          baseUrl ??
          dotenv.env['API_BASE_URL'] ??
          'http://localhost:3000/api/v1';

  // In-memory demo store (simulates backend in demo mode)
  static final List<LandParcel> _demoParcels = List.from(
    DemoLandParcels.parcels,
  );
  static final List<AuditLog> _demoAuditLogs = _buildDemoAuditLogs();
  static final List<BlockchainEntry> _demoBlockchain = _buildDemoBlockchain();
  static final List<AppNotification> _demoNotifications =
      _buildDemoNotifications();
  static const _uuid = Uuid();

  /// Fetch land parcels for a specific user
  Future<List<LandParcel>> getLandParcelsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _demoParcels.where((p) => p.ownerId == userId).toList();
  }

  /// Fetch all land parcels (officer view)
  Future<List<LandParcel>> getAllLandParcels() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_demoParcels);
  }

  /// Fetch single parcel by ID
  Future<LandParcel?> getLandParcelById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _demoParcels.firstWhere((p) => p.id == id || p.landId == id);
    } catch (_) {
      return null;
    }
  }

  /// Register new land parcel
  Future<LandParcel> registerLand({
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    required String ownerPhone,
    required String description,
    required String address,
    required String region,
    required String division,
    required String subdivision,
    required LandUseType landUse,
    required List<Map<String, double>> boundaryPoints,
    required List<String> documentPaths,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final id = _uuid.v4();
    final parcel = LandParcel(
      id: id,
      landId: null,
      ownerId: ownerId,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      ownerPhone: ownerPhone,
      description: description,
      address: address,
      region: region,
      division: division,
      subdivision: subdivision,
      landUse: landUse,
      status: LandStatus.pending,
      boundary: boundaryPoints.isNotEmpty
          ? LandBoundary(
              points: boundaryPoints
                  .map((p) => LatLng(p['lat']!, p['lng']!))
                  .toList(),
            )
          : null,
      documents: [],
      applicationDate: DateTime.now(),
      timeline: LandParcel.buildTimeline(LandStatus.pending),
    );

    _demoParcels.add(parcel);

    // Add audit log
    _demoAuditLogs.add(
      AuditLog(
        id: _uuid.v4(),
        userId: ownerId,
        userName: ownerName,
        action: 'land_registration',
        entityType: 'land_parcel',
        entityId: id,
        description: 'New land registration submitted for $address',
        timestamp: DateTime.now(),
      ),
    );

    return parcel;
  }

  /// Update parcel status (officer action)
  Future<LandParcel> updateParcelStatus({
    required String parcelId,
    required LandStatus newStatus,
    required String actorId,
    required String actorName,
    String? rejectionReason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _demoParcels.indexWhere((p) => p.id == parcelId);
    if (index == -1) throw Exception('Parcel not found');

    final parcel = _demoParcels[index];
    String? landId = parcel.landId;

    // Generate Land ID on approval
    if (newStatus == LandStatus.approved && landId == null) {
      final region = parcel.region.substring(0, 3).toUpperCase();
      final year = DateTime.now().year;
      final seq = (_demoParcels.length + 1).toString().padLeft(4, '0');
      landId = 'CM-$region-$year-$seq';
    }

    // Generate blockchain hash
    String? blockchainHash;
    if (newStatus == LandStatus.approved) {
      final data =
          '${parcelId}_${landId}_${actorId}_${DateTime.now().toIso8601String()}';
      blockchainHash = sha256.convert(utf8.encode(data)).toString();

      // Store blockchain entry
      _demoBlockchain.add(
        BlockchainEntry(
          id: _uuid.v4(),
          transactionHash: blockchainHash,
          previousHash: _demoBlockchain.isNotEmpty
              ? _demoBlockchain.last.transactionHash
              : '0' * 64,
          landId: landId!,
          action: 'registration',
          actorId: actorId,
          actorName: actorName,
          timestamp: DateTime.now(),
          data: {'parcelId': parcelId, 'status': newStatus.value},
        ),
      );
    }

    final updated = parcel.copyWith(
      status: newStatus,
      landId: landId,
      approvalDate: newStatus == LandStatus.approved ? DateTime.now() : null,
      approvedBy: newStatus == LandStatus.approved ? actorId : null,
      rejectionReason: rejectionReason,
      blockchainHash: blockchainHash,
      timeline: LandParcel.buildTimeline(newStatus),
    );

    _demoParcels[index] = updated;

    // Add audit log
    _demoAuditLogs.add(
      AuditLog(
        id: _uuid.v4(),
        userId: actorId,
        userName: actorName,
        action: 'status_update',
        entityType: 'land_parcel',
        entityId: parcelId,
        description:
            'Status updated to ${newStatus.displayName} for parcel ${parcel.address}',
        timestamp: DateTime.now(),
      ),
    );

    // Add notification for owner
    _demoNotifications.add(
      AppNotification(
        id: _uuid.v4(),
        title: 'Land Application ${newStatus.displayName}',
        body: newStatus == LandStatus.approved
            ? 'Your land application for ${parcel.address} has been approved. Land ID: $landId'
            : 'Your land application for ${parcel.address} has been ${newStatus.displayName.toLowerCase()}. ${rejectionReason ?? ""}',
        type: 'status_change',
        landId: parcelId,
        createdAt: DateTime.now(),
      ),
    );

    unawaited(
      NotificationService.showNotification(
        title: 'Land Application ${newStatus.displayName}',
        body: newStatus == LandStatus.approved
            ? 'Your land application for ${parcel.address} has been approved. Land ID: $landId'
            : 'Your land application for ${parcel.address} has been ${newStatus.displayName.toLowerCase()}. ${rejectionReason ?? ""}',
        payload: parcelId,
      ),
    );

    return updated;
  }

  /// Transfer land ownership
  Future<LandParcel> transferOwnership({
    required String parcelId,
    required String newOwnerName,
    required String newOwnerEmail,
    required String newOwnerPhone,
    required String newOwnerId,
    required String actorId,
    required String actorName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _demoParcels.indexWhere((p) => p.id == parcelId);
    if (index == -1) throw Exception('Parcel not found');

    final parcel = _demoParcels[index];

    // Generate transfer hash
    final data =
        '${parcelId}_transfer_${newOwnerId}_${DateTime.now().toIso8601String()}';
    final transferHash = sha256.convert(utf8.encode(data)).toString();

    _demoBlockchain.add(
      BlockchainEntry(
        id: _uuid.v4(),
        transactionHash: transferHash,
        previousHash: _demoBlockchain.isNotEmpty
            ? _demoBlockchain.last.transactionHash
            : '0' * 64,
        landId: parcel.landId ?? parcelId,
        action: 'transfer',
        actorId: actorId,
        actorName: actorName,
        timestamp: DateTime.now(),
        data: {
          'fromOwner': parcel.ownerName,
          'toOwner': newOwnerName,
          'parcelId': parcelId,
        },
      ),
    );

    final updated = parcel.copyWith(
      ownerId: newOwnerId,
      ownerName: newOwnerName,
      ownerEmail: newOwnerEmail,
      ownerPhone: newOwnerPhone,
      status: LandStatus.transferred,
      blockchainHash: transferHash,
    );

    _demoParcels[index] = updated;

    _demoAuditLogs.add(
      AuditLog(
        id: _uuid.v4(),
        userId: actorId,
        userName: actorName,
        action: 'ownership_transfer',
        entityType: 'land_parcel',
        entityId: parcelId,
        description:
            'Ownership transferred from ${parcel.ownerName} to $newOwnerName',
        timestamp: DateTime.now(),
      ),
    );

    return updated;
  }

  /// Search land parcels
  Future<List<LandParcel>> searchLand(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final q = query.toLowerCase();
    return _demoParcels.where((p) {
      return p.landId?.toLowerCase().contains(q) == true ||
          p.ownerName.toLowerCase().contains(q) ||
          p.address.toLowerCase().contains(q) ||
          p.region.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
  }

  /// Get audit logs
  Future<List<AuditLog>> getAuditLogs({int limit = 50}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final sorted = List<AuditLog>.from(_demoAuditLogs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(limit).toList();
  }

  /// Get blockchain ledger
  Future<List<BlockchainEntry>> getBlockchainLedger() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final sorted = List<BlockchainEntry>.from(_demoBlockchain)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted;
  }

  /// Get notifications
  Future<List<AppNotification>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sorted = List<AppNotification>.from(_demoNotifications)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    final index = _demoNotifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _demoNotifications[index] = _demoNotifications[index].copyWith(
        isRead: true,
      );
    }
  }

  /// Statistics for officer dashboard
  Future<Map<String, int>> getDashboardStats() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'total': _demoParcels.length,
      'pending': _demoParcels
          .where((p) => p.status == LandStatus.pending)
          .length,
      'underReview': _demoParcels
          .where((p) => p.status == LandStatus.underReview)
          .length,
      'approved': _demoParcels
          .where((p) => p.status == LandStatus.approved)
          .length,
      'rejected': _demoParcels
          .where((p) => p.status == LandStatus.rejected)
          .length,
      'transferred': _demoParcels
          .where((p) => p.status == LandStatus.transferred)
          .length,
    };
  }

  // ---- Demo data builders ----

  static List<AuditLog> _buildDemoAuditLogs() => [
    AuditLog(
      id: 'audit-001',
      userId: 'demo-citizen-001',
      userName: 'Jean Mbeki',
      action: 'land_registration',
      entityType: 'land_parcel',
      entityId: 'parcel-001',
      description: 'Land registration submitted for Quartier Bastos',
      timestamp: DateTime(2024, 1, 10, 9, 30),
    ),
    AuditLog(
      id: 'audit-002',
      userId: 'demo-officer-001',
      userName: 'Marie Atangana',
      action: 'status_update',
      entityType: 'land_parcel',
      entityId: 'parcel-001',
      description: 'Status updated to Approved for parcel CM-CTR-2024-0001',
      timestamp: DateTime(2024, 2, 20, 14, 15),
    ),
    AuditLog(
      id: 'audit-003',
      userId: 'demo-citizen-001',
      userName: 'Jean Mbeki',
      action: 'land_registration',
      entityType: 'land_parcel',
      entityId: 'parcel-002',
      description: 'Land registration submitted for Obala farmland',
      timestamp: DateTime(2024, 3, 5, 11, 0),
    ),
  ];

  static List<BlockchainEntry> _buildDemoBlockchain() => [
    BlockchainEntry(
      id: 'bc-001',
      transactionHash:
          'a3f7b9c2d4e6f8a1b3c5d7e9f0a2b4c6d8e0f1a3b5c7d9e1f2a4b6c8d0e2f4a6',
      previousHash: '0' * 64,
      landId: 'CM-CTR-2024-0001',
      action: 'registration',
      actorId: 'demo-officer-001',
      actorName: 'Marie Atangana',
      timestamp: DateTime(2024, 2, 20, 14, 15),
      data: {'status': 'approved', 'parcelId': 'parcel-001'},
    ),
    BlockchainEntry(
      id: 'bc-002',
      transactionHash:
          'b4c8d2e6f0a4b8c2d6e0f4a8b2c6d0e4f8a2b6c0d4e8f2a6b0c4d8e2f6a0b4c8',
      previousHash:
          'a3f7b9c2d4e6f8a1b3c5d7e9f0a2b4c6d8e0f1a3b5c7d9e1f2a4b6c8d0e2f4a6',
      landId: 'CM-LIT-2023-0042',
      action: 'registration',
      actorId: 'demo-officer-001',
      actorName: 'Marie Atangana',
      timestamp: DateTime(2023, 11, 3, 10, 30),
      data: {'status': 'approved', 'parcelId': 'parcel-003'},
    ),
  ];

  static List<AppNotification> _buildDemoNotifications() => [
    AppNotification(
      id: 'notif-001',
      title: 'Land Application Approved! 🎉',
      body:
          'Your land application for Quartier Bastos has been approved. Land ID: CM-CTR-2024-0001',
      type: 'status_change',
      landId: 'parcel-001',
      createdAt: DateTime(2024, 2, 20, 14, 16),
      isRead: false,
    ),
    AppNotification(
      id: 'notif-002',
      title: 'Application Under Review',
      body:
          'Your application for Obala farmland is now being reviewed by our team.',
      type: 'status_change',
      landId: 'parcel-002',
      createdAt: DateTime(2024, 3, 8, 9, 0),
      isRead: true,
    ),
    AppNotification(
      id: 'notif-003',
      title: 'Welcome to KamerSync',
      body:
          'Welcome to the Cameroon National Land Management System. You can now apply for land registration.',
      type: 'system',
      createdAt: DateTime(2024, 1, 15, 8, 0),
      isRead: true,
    ),
  ];
}

final landServiceProvider = Provider<LandService>((ref) => LandService());

/// Dashboard stats provider
final dashboardStatsProvider = FutureProvider.autoDispose<Map<String, int>>((
  ref,
) async {
  final service = ref.read(landServiceProvider);
  return service.getDashboardStats();
});

/// Notifications provider
final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) async {
    final service = ref.read(landServiceProvider);
    return service.getNotifications();
  },
);

/// Audit log provider
final auditLogProvider = FutureProvider.autoDispose<List<AuditLog>>((
  ref,
) async {
  final service = ref.read(landServiceProvider);
  return service.getAuditLogs();
});

/// Blockchain ledger provider
final blockchainLedgerProvider =
    FutureProvider.autoDispose<List<BlockchainEntry>>((ref) async {
      final service = ref.read(landServiceProvider);
      return service.getBlockchainLedger();
    });
