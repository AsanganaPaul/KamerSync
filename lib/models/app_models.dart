import 'package:equatable/equatable.dart';

/// Audit log entry
class AuditLog extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String entityType;
  final String entityId;
  final String description;
  final DateTime timestamp;
  final String? ipAddress;
  final Map<String, dynamic>? metadata;

  const AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.description,
    required this.timestamp,
    this.ipAddress,
    this.metadata,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      userName: json['userName'] as String? ?? json['user_name'] as String? ?? '',
      action: json['action'] as String? ?? '',
      entityType: json['entityType'] as String? ?? json['entity_type'] as String? ?? '',
      entityId: json['entityId'] as String? ?? json['entity_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      ipAddress: json['ipAddress'] as String? ?? json['ip_address'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'ipAddress': ipAddress,
        'metadata': metadata,
      };

  @override
  List<Object?> get props => [id, timestamp];
}

/// Blockchain transaction ledger entry
class BlockchainEntry extends Equatable {
  final String id;
  final String transactionHash;
  final String previousHash;
  final String landId;
  final String action; // 'registration', 'transfer', 'update'
  final String actorId;
  final String actorName;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const BlockchainEntry({
    required this.id,
    required this.transactionHash,
    required this.previousHash,
    required this.landId,
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.timestamp,
    required this.data,
  });

  factory BlockchainEntry.fromJson(Map<String, dynamic> json) {
    return BlockchainEntry(
      id: json['id'] as String,
      transactionHash: json['transactionHash'] as String? ?? json['transaction_hash'] as String? ?? '',
      previousHash: json['previousHash'] as String? ?? json['previous_hash'] as String? ?? '',
      landId: json['landId'] as String? ?? json['land_id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      actorId: json['actorId'] as String? ?? json['actor_id'] as String? ?? '',
      actorName: json['actorName'] as String? ?? json['actor_name'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      data: json['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transactionHash': transactionHash,
        'previousHash': previousHash,
        'landId': landId,
        'action': action,
        'actorId': actorId,
        'actorName': actorName,
        'timestamp': timestamp.toIso8601String(),
        'data': data,
      };

  String get shortHash => transactionHash.length > 16
      ? '${transactionHash.substring(0, 8)}...${transactionHash.substring(transactionHash.length - 8)}'
      : transactionHash;

  @override
  List<Object?> get props => [id, transactionHash];
}

/// Chat message
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  ChatMessage copyWith({
    String? content,
    bool? isLoading,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      isUser: isUser,
      timestamp: timestamp,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [id, content, isUser];
}

/// App notification
class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final String type; // 'status_change', 'system', 'info'
  final String? landId;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.landId,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String? ?? 'info',
      landId: json['landId'] as String? ?? json['land_id'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] as bool? ?? json['is_read'] as bool? ?? false,
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      landId: landId,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, isRead];
}

/// Cameroon regions for form dropdowns
class CameroonRegions {
  static const List<String> regions = [
    'Adamawa',
    'Centre',
    'East',
    'Far North',
    'Littoral',
    'North',
    'North West',
    'South',
    'South West',
    'West',
  ];

  static const Map<String, List<String>> divisions = {
    'Centre': ['Mfoundi', 'Haute-Sanaga', 'Lekié', 'Mbam-et-Inoubou', 'Mbam-et-Kim', 'Méfou-et-Afamba', 'Méfou-et-Akono', 'Mfoundi', 'Nyong-et-Kellé', 'Nyong-et-Mfoumou', 'Nyong-et-So\'o'],
    'Littoral': ['Moungo', 'Nkam', 'Sanaga-Maritime', 'Wouri'],
    'West': ['Bamboutos', 'Haut-Nkam', 'Hauts-Plateaux', 'Koupé-Manengouba', 'Menoua', 'Mifi', 'Nde', 'Noun'],
    'North West': ['Boyo', 'Bui', 'Donga-Mantung', 'Menchum', 'Mezam', 'Momo', 'Ngo-Ketunjia'],
    'South West': ['Fako', 'Kupe-Manenguba', 'Lebialem', 'Manyu', 'Meme', 'Ndian'],
    'Adamawa': ['Djerem', 'Faro-et-Déo', 'Mayo-Banyo', 'Mbéré', 'Vina'],
    'North': ['Bénoué', 'Faro', 'Mayo-Louti', 'Mayo-Rey'],
    'Far North': ['Diamaré', 'Logone-et-Chari', 'Mayo-Danay', 'Mayo-Kani', 'Mayo-Sava', 'Mayo-Tsanaga'],
    'East': ['Boumba-et-Ngoko', 'Haut-Nyong', 'Kadey', 'Lom-et-Djérem'],
    'South': ['Dja-et-Lobo', 'Mvila', 'Océan', 'Vallée-du-Ntem'],
  };
}
