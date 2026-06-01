import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Land parcel status
enum LandStatus {
  pending,
  underReview,
  approved,
  rejected,
  transferred,
}

extension LandStatusExtension on LandStatus {
  String get displayName {
    switch (this) {
      case LandStatus.pending:
        return 'Pending';
      case LandStatus.underReview:
        return 'Under Review';
      case LandStatus.approved:
        return 'Approved';
      case LandStatus.rejected:
        return 'Rejected';
      case LandStatus.transferred:
        return 'Transferred';
    }
  }

  String get value {
    switch (this) {
      case LandStatus.pending:
        return 'pending';
      case LandStatus.underReview:
        return 'under_review';
      case LandStatus.approved:
        return 'approved';
      case LandStatus.rejected:
        return 'rejected';
      case LandStatus.transferred:
        return 'transferred';
    }
  }

  static LandStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return LandStatus.pending;
      case 'under_review':
        return LandStatus.underReview;
      case 'approved':
        return LandStatus.approved;
      case 'rejected':
        return LandStatus.rejected;
      case 'transferred':
        return LandStatus.transferred;
      default:
        return LandStatus.pending;
    }
  }
}

/// Land use type
enum LandUseType {
  residential,
  commercial,
  agricultural,
  industrial,
  mixed,
  government,
  forested,
}

extension LandUseTypeExtension on LandUseType {
  String get displayName {
    switch (this) {
      case LandUseType.residential:
        return 'Residential';
      case LandUseType.commercial:
        return 'Commercial';
      case LandUseType.agricultural:
        return 'Agricultural';
      case LandUseType.industrial:
        return 'Industrial';
      case LandUseType.mixed:
        return 'Mixed Use';
      case LandUseType.government:
        return 'Government';
      case LandUseType.forested:
        return 'Forested';
    }
  }

  String get value => name;

  static LandUseType fromString(String value) {
    return LandUseType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LandUseType.residential,
    );
  }
}

/// GIS Boundary — a polygon defined by lat/lng points
class LandBoundary extends Equatable {
  final List<LatLng> points;
  final double? areaHectares;

  const LandBoundary({
    required this.points,
    this.areaHectares,
  });

  factory LandBoundary.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? [];
    return LandBoundary(
      points: rawPoints.map((p) {
        final point = p as Map<String, dynamic>;
        return LatLng(
          (point['lat'] as num).toDouble(),
          (point['lng'] as num).toDouble(),
        );
      }).toList(),
      areaHectares: (json['areaHectares'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'areaHectares': areaHectares,
    };
  }

  LatLng get centroid {
    if (points.isEmpty) return const LatLng(3.848, 11.502); // Yaoundé default
    double latSum = 0;
    double lngSum = 0;
    for (final p in points) {
      latSum += p.latitude;
      lngSum += p.longitude;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  @override
  List<Object?> get props => [points, areaHectares];
}

/// Land parcel document
class LandDocument extends Equatable {
  final String id;
  final String name;
  final String type; // 'title_deed', 'survey_plan', 'id_card', etc.
  final String url;
  final String mimeType;
  final int sizeBytes;
  final DateTime uploadedAt;
  final String uploadedBy;

  const LandDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    required this.mimeType,
    required this.sizeBytes,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory LandDocument.fromJson(Map<String, dynamic> json) {
    return LandDocument(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'document',
      url: json['url'] as String,
      mimeType: json['mimeType'] as String? ?? json['mime_type'] as String? ?? 'application/pdf',
      sizeBytes: json['sizeBytes'] as int? ?? json['size_bytes'] as int? ?? 0,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String? ?? json['uploaded_at'] as String? ?? DateTime.now().toIso8601String()),
      uploadedBy: json['uploadedBy'] as String? ?? json['uploaded_by'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'url': url,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'uploadedAt': uploadedAt.toIso8601String(),
        'uploadedBy': uploadedBy,
      };

  bool get isPdf => mimeType == 'application/pdf';
  bool get isImage => mimeType.startsWith('image/');

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [id, url];
}

/// Application timeline step
class ApplicationStep extends Equatable {
  final String title;
  final String? description;
  final DateTime? completedAt;
  final bool isCompleted;
  final bool isActive;
  final String? actor;

  const ApplicationStep({
    required this.title,
    this.description,
    this.completedAt,
    required this.isCompleted,
    required this.isActive,
    this.actor,
  });

  factory ApplicationStep.fromJson(Map<String, dynamic> json) {
    return ApplicationStep(
      title: json['title'] as String,
      description: json['description'] as String?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      actor: json['actor'] as String?,
    );
  }

  @override
  List<Object?> get props => [title, isCompleted, isActive];
}

/// Main land parcel model
class LandParcel extends Equatable {
  final String id;
  final String? landId; // Official Land ID after approval
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String description;
  final String address;
  final String region;
  final String division;
  final String subdivision;
  final LandUseType landUse;
  final LandStatus status;
  final LandBoundary? boundary;
  final double? areaHectares;
  final List<LandDocument> documents;
  final DateTime applicationDate;
  final DateTime? approvalDate;
  final String? approvedBy;
  final String? rejectionReason;
  final String? surveyorId;
  final String? surveyData;
  final String? blockchainHash;
  final List<ApplicationStep> timeline;
  final List<String> tags;

  const LandParcel({
    required this.id,
    this.landId,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.description,
    required this.address,
    required this.region,
    required this.division,
    required this.subdivision,
    required this.landUse,
    required this.status,
    this.boundary,
    this.areaHectares,
    required this.documents,
    required this.applicationDate,
    this.approvalDate,
    this.approvedBy,
    this.rejectionReason,
    this.surveyorId,
    this.surveyData,
    this.blockchainHash,
    required this.timeline,
    this.tags = const [],
  });

  factory LandParcel.fromJson(Map<String, dynamic> json) {
    return LandParcel(
      id: json['id'] as String,
      landId: json['landId'] as String? ?? json['land_id'] as String?,
      ownerId: json['ownerId'] as String? ?? json['owner_id'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? json['owner_name'] as String? ?? '',
      ownerEmail: json['ownerEmail'] as String? ?? json['owner_email'] as String? ?? '',
      ownerPhone: json['ownerPhone'] as String? ?? json['owner_phone'] as String? ?? '',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      region: json['region'] as String? ?? '',
      division: json['division'] as String? ?? '',
      subdivision: json['subdivision'] as String? ?? '',
      landUse: LandUseTypeExtension.fromString(json['landUse'] as String? ?? json['land_use'] as String? ?? 'residential'),
      status: LandStatusExtension.fromString(json['status'] as String? ?? 'pending'),
      boundary: json['boundary'] != null
          ? LandBoundary.fromJson(json['boundary'] as Map<String, dynamic>)
          : null,
      areaHectares: (json['areaHectares'] as num?)?.toDouble() ?? (json['area_hectares'] as num?)?.toDouble(),
      documents: (json['documents'] as List<dynamic>? ?? [])
          .map((d) => LandDocument.fromJson(d as Map<String, dynamic>))
          .toList(),
      applicationDate: DateTime.parse(json['applicationDate'] as String? ?? json['application_date'] as String? ?? DateTime.now().toIso8601String()),
      approvalDate: json['approvalDate'] != null
          ? DateTime.parse(json['approvalDate'] as String)
          : json['approval_date'] != null
              ? DateTime.parse(json['approval_date'] as String)
              : null,
      approvedBy: json['approvedBy'] as String? ?? json['approved_by'] as String?,
      rejectionReason: json['rejectionReason'] as String? ?? json['rejection_reason'] as String?,
      surveyorId: json['surveyorId'] as String? ?? json['surveyor_id'] as String?,
      surveyData: json['surveyData'] as String? ?? json['survey_data'] as String?,
      blockchainHash: json['blockchainHash'] as String? ?? json['blockchain_hash'] as String?,
      timeline: (json['timeline'] as List<dynamic>? ?? [])
          .map((s) => ApplicationStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? []).map((t) => t.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'landId': landId,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerEmail': ownerEmail,
        'ownerPhone': ownerPhone,
        'description': description,
        'address': address,
        'region': region,
        'division': division,
        'subdivision': subdivision,
        'landUse': landUse.value,
        'status': status.value,
        'boundary': boundary?.toJson(),
        'areaHectares': areaHectares,
        'documents': documents.map((d) => d.toJson()).toList(),
        'applicationDate': applicationDate.toIso8601String(),
        'approvalDate': approvalDate?.toIso8601String(),
        'approvedBy': approvedBy,
        'rejectionReason': rejectionReason,
        'surveyorId': surveyorId,
        'surveyData': surveyData,
        'blockchainHash': blockchainHash,
        'timeline': timeline.map((s) => {
              'title': s.title,
              'description': s.description,
              'completedAt': s.completedAt?.toIso8601String(),
              'isCompleted': s.isCompleted,
              'isActive': s.isActive,
              'actor': s.actor,
            }).toList(),
        'tags': tags,
      };

  LandParcel copyWith({
    String? id,
    String? landId,
    String? ownerId,
    String? ownerName,
    String? ownerEmail,
    String? ownerPhone,
    String? description,
    String? address,
    String? region,
    String? division,
    String? subdivision,
    LandUseType? landUse,
    LandStatus? status,
    LandBoundary? boundary,
    double? areaHectares,
    List<LandDocument>? documents,
    DateTime? applicationDate,
    DateTime? approvalDate,
    String? approvedBy,
    String? rejectionReason,
    String? surveyorId,
    String? surveyData,
    String? blockchainHash,
    List<ApplicationStep>? timeline,
    List<String>? tags,
  }) {
    return LandParcel(
      id: id ?? this.id,
      landId: landId ?? this.landId,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      description: description ?? this.description,
      address: address ?? this.address,
      region: region ?? this.region,
      division: division ?? this.division,
      subdivision: subdivision ?? this.subdivision,
      landUse: landUse ?? this.landUse,
      status: status ?? this.status,
      boundary: boundary ?? this.boundary,
      areaHectares: areaHectares ?? this.areaHectares,
      documents: documents ?? this.documents,
      applicationDate: applicationDate ?? this.applicationDate,
      approvalDate: approvalDate ?? this.approvalDate,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      surveyorId: surveyorId ?? this.surveyorId,
      surveyData: surveyData ?? this.surveyData,
      blockchainHash: blockchainHash ?? this.blockchainHash,
      timeline: timeline ?? this.timeline,
      tags: tags ?? this.tags,
    );
  }

  /// Build default application timeline based on status
  static List<ApplicationStep> buildTimeline(LandStatus status) {
    final steps = [
      ApplicationStep(
        title: 'Application Submitted',
        description: 'Land registration application submitted by citizen',
        isCompleted: true,
        isActive: false,
        completedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      ApplicationStep(
        title: 'Documents Verified',
        description: 'Supporting documents reviewed and validated',
        isCompleted: status != LandStatus.pending,
        isActive: status == LandStatus.pending,
        completedAt: status != LandStatus.pending
            ? DateTime.now().subtract(const Duration(days: 5))
            : null,
      ),
      ApplicationStep(
        title: 'Survey Completed',
        description: 'Official survey conducted and boundaries confirmed',
        isCompleted: status == LandStatus.approved ||
            status == LandStatus.rejected ||
            status == LandStatus.transferred,
        isActive: status == LandStatus.underReview,
        completedAt: status == LandStatus.approved
            ? DateTime.now().subtract(const Duration(days: 2))
            : null,
      ),
      ApplicationStep(
        title: 'MINDCAF Review',
        description: 'Application reviewed by MINDCAF Officer',
        isCompleted: status == LandStatus.approved ||
            status == LandStatus.rejected ||
            status == LandStatus.transferred,
        isActive: false,
        completedAt: status == LandStatus.approved ? DateTime.now() : null,
      ),
      ApplicationStep(
        title: 'Title Issued',
        description: 'Official Land Title issued and registered',
        isCompleted: status == LandStatus.approved || status == LandStatus.transferred,
        isActive: false,
        completedAt: status == LandStatus.approved ? DateTime.now() : null,
      ),
    ];
    return steps;
  }

  @override
  List<Object?> get props => [id, landId, ownerId, status];
}

/// Demo land parcels for development
class DemoLandParcels {
  static final List<LandParcel> parcels = [
    LandParcel(
      id: 'parcel-001',
      landId: 'CM-CTR-2024-0001',
      ownerId: 'demo-citizen-001',
      ownerName: 'Jean Mbeki',
      ownerEmail: 'jean.mbeki@email.cm',
      ownerPhone: '+237670000001',
      description: 'Residential plot in Bastos neighbourhood, ideal for family home construction.',
      address: 'Quartier Bastos, Avenue Kennedy',
      region: 'Centre',
      division: 'Mfoundi',
      subdivision: 'Yaoundé 1er',
      landUse: LandUseType.residential,
      status: LandStatus.approved,
      boundary: LandBoundary(
        points: [
          const LatLng(3.8702, 11.5125),
          const LatLng(3.8712, 11.5135),
          const LatLng(3.8705, 11.5148),
          const LatLng(3.8695, 11.5138),
        ],
        areaHectares: 0.35,
      ),
      areaHectares: 0.35,
      documents: [],
      applicationDate: DateTime(2024, 1, 10),
      approvalDate: DateTime(2024, 2, 20),
      approvedBy: 'demo-officer-001',
      blockchainHash: 'a3f7b9c2d4e6f8a1b3c5d7e9f0a2b4c6d8e0f1a3b5c7d9e1f2a4b6c8d0e2f4a6',
      timeline: LandParcel.buildTimeline(LandStatus.approved),
    ),
    LandParcel(
      id: 'parcel-002',
      landId: null,
      ownerId: 'demo-citizen-001',
      ownerName: 'Jean Mbeki',
      ownerEmail: 'jean.mbeki@email.cm',
      ownerPhone: '+237670000001',
      description: 'Agricultural land near Obala for farming activities.',
      address: 'Obala, Route Nationale 1',
      region: 'Centre',
      division: 'Haute-Sanaga',
      subdivision: 'Obala',
      landUse: LandUseType.agricultural,
      status: LandStatus.underReview,
      boundary: LandBoundary(
        points: [
          const LatLng(4.1680, 11.5340),
          const LatLng(4.1700, 11.5370),
          const LatLng(4.1685, 11.5395),
          const LatLng(4.1665, 11.5365),
        ],
        areaHectares: 2.5,
      ),
      areaHectares: 2.5,
      documents: [],
      applicationDate: DateTime(2024, 3, 5),
      timeline: LandParcel.buildTimeline(LandStatus.underReview),
    ),
    LandParcel(
      id: 'parcel-003',
      landId: 'CM-LIT-2023-0042',
      ownerId: 'demo-citizen-002',
      ownerName: 'Sophie Nkemdirim',
      ownerEmail: 'sophie@email.cm',
      ownerPhone: '+237699000003',
      description: 'Commercial plot in Akwa district, Douala — prime business location.',
      address: 'Akwa, Boulevard de la Liberté',
      region: 'Littoral',
      division: 'Wouri',
      subdivision: 'Douala 1er',
      landUse: LandUseType.commercial,
      status: LandStatus.approved,
      boundary: LandBoundary(
        points: [
          const LatLng(4.0418, 9.7040),
          const LatLng(4.0430, 9.7055),
          const LatLng(4.0422, 9.7068),
          const LatLng(4.0410, 9.7053),
        ],
        areaHectares: 0.18,
      ),
      areaHectares: 0.18,
      documents: [],
      applicationDate: DateTime(2023, 8, 12),
      approvalDate: DateTime(2023, 11, 3),
      approvedBy: 'demo-officer-001',
      blockchainHash: 'b4c8d2e6f0a4b8c2d6e0f4a8b2c6d0e4f8a2b6c0d4e8f2a6b0c4d8e2f6a0b4c8',
      timeline: LandParcel.buildTimeline(LandStatus.approved),
    ),
  ];
}
