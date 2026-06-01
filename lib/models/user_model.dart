// ============================================================
// Models: User
// ============================================================
import 'package:equatable/equatable.dart';

enum UserRole {
  citizen,
  mindcafOfficer,
  surveyor,
  notary,
  bank,
  localCouncil,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.citizen:
        return 'Citizen / Land Owner';
      case UserRole.mindcafOfficer:
        return 'MINDCAF Officer';
      case UserRole.surveyor:
        return 'Surveyor';
      case UserRole.notary:
        return 'Notary';
      case UserRole.bank:
        return 'Bank / Financial Institution';
      case UserRole.localCouncil:
        return 'Local Council';
      case UserRole.admin:
        return 'System Administrator';
    }
  }

  String get value {
    switch (this) {
      case UserRole.citizen:
        return 'citizen';
      case UserRole.mindcafOfficer:
        return 'mindcaf_officer';
      case UserRole.surveyor:
        return 'surveyor';
      case UserRole.notary:
        return 'notary';
      case UserRole.bank:
        return 'bank';
      case UserRole.localCouncil:
        return 'local_council';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'citizen':
        return UserRole.citizen;
      case 'mindcaf_officer':
        return UserRole.mindcafOfficer;
      case 'surveyor':
        return UserRole.surveyor;
      case 'notary':
        return UserRole.notary;
      case 'bank':
        return UserRole.bank;
      case 'local_council':
        return UserRole.localCouncil;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.citizen;
    }
  }
}

class UserModel extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final UserRole role;
  final String? profileImageUrl;
  final String? nationalId;
  final String? region;
  final DateTime createdAt;
  final bool isVerified;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
    this.profileImageUrl,
    this.nationalId,
    this.region,
    required this.createdAt,
    this.isVerified = false,
    this.isActive = true,
  });

  String get fullName => '$firstName $lastName';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String? ?? json['first_name'] as String? ?? '',
      lastName: json['lastName'] as String? ?? json['last_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: UserRoleExtension.fromString(json['role'] as String? ?? 'citizen'),
      profileImageUrl: json['profileImageUrl'] as String? ?? json['profile_image_url'] as String?,
      nationalId: json['nationalId'] as String? ?? json['national_id'] as String?,
      region: json['region'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now(),
      isVerified: json['isVerified'] as bool? ?? json['is_verified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'role': role.value,
      'profileImageUrl': profileImageUrl,
      'nationalId': nationalId,
      'region': region,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    UserRole? role,
    String? profileImageUrl,
    String? nationalId,
    String? region,
    DateTime? createdAt,
    bool? isVerified,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      nationalId: nationalId ?? this.nationalId,
      region: region ?? this.region,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, email, role, isVerified, isActive];
}

/// Demo user for development testing
class DemoUsers {
  static final citizen = UserModel(
    id: 'demo-citizen-001',
    email: 'citizen@kamer.cm',
    firstName: 'Jean',
    lastName: 'Mbeki',
    phone: '+237670000001',
    role: UserRole.citizen,
    nationalId: '123456789',
    region: 'Centre',
    createdAt: DateTime(2024, 1, 15),
    isVerified: true,
    isActive: true,
  );

  static final officer = UserModel(
    id: 'demo-officer-001',
    email: 'officer@mindcaf.cm',
    firstName: 'Marie',
    lastName: 'Atangana',
    phone: '+237691000002',
    role: UserRole.mindcafOfficer,
    region: 'Centre',
    createdAt: DateTime(2023, 6, 1),
    isVerified: true,
    isActive: true,
  );

  static final surveyor = UserModel(
    id: 'demo-surveyor-001',
    email: 'surveyor@kamer.cm',
    firstName: 'Paul',
    lastName: 'Nkeng',
    phone: '+237677000003',
    role: UserRole.surveyor,
    region: 'Littoral',
    createdAt: DateTime(2023, 3, 10),
    isVerified: true,
    isActive: true,
  );
}
