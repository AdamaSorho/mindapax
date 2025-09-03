enum ConnectionStatus { PENDING, ACCEPTED, TRANSFERRED, ESCALATED, BLOCKED }

ConnectionStatus? connectionStatusFromString(String? value) {
  if (value == null) return null;
  switch (value.toUpperCase()) {
    case 'PENDING':
      return ConnectionStatus.PENDING;
    case 'ACCEPTED':
      return ConnectionStatus.ACCEPTED;
    case 'TRANSFERRED':
      return ConnectionStatus.TRANSFERRED;
    case 'ESCALATED':
      return ConnectionStatus.ESCALATED;
    case 'BLOCKED':
      return ConnectionStatus.BLOCKED;
  }
  return null;
}

String connectionStatusLabel(ConnectionStatus s) {
  return s.toString().split('.').last;
}

class ConnectionItem {
  final int id;
  final ConnectionStatus status;
  final DateTime createdAt;
  final String? message;
  final String? requestType; // Specialization enum name
  final String? urgency; // UrgencyStatus enum name
  final int userId;
  final String userName;
  final String? userAvatar;
  final int professionalId;
  final String professionalName;
  final String? professionalSpecialization;

  ConnectionItem({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.message,
    required this.requestType,
    required this.urgency,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.professionalId,
    required this.professionalName,
    required this.professionalSpecialization,
  });

  factory ConnectionItem.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>? ?? const {};
    final pro = j['professional'] as Map<String, dynamic>? ?? const {};
    final proUser = pro['user'] as Map<String, dynamic>? ?? const {};
    final status = connectionStatusFromString(j['status']?.toString()) ?? ConnectionStatus.PENDING;
    final created = DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now();
    final userName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final proName = '${proUser['firstName'] ?? ''} ${proUser['lastName'] ?? ''}'.trim();
    return ConnectionItem(
      id: (j['id'] as num?)?.toInt() ?? 0,
      status: status,
      createdAt: created,
      message: j['message']?.toString(),
      requestType: j['requestType']?.toString(),
      urgency: (j['urgencyStatus'] ?? j['urgency'])?.toString(),
      userId: (user['id'] as num?)?.toInt() ?? 0,
      userName: userName.isEmpty ? 'User' : userName,
      userAvatar: user['avatar']?.toString(),
      professionalId: (pro['id'] as num?)?.toInt() ?? 0,
      professionalName: proName.isEmpty ? 'Professional' : proName,
      professionalSpecialization: pro['specialization']?.toString(),
    );
  }
}

