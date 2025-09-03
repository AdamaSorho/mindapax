enum SessionTimeFilter { PAST, UPCOMING }

enum SessionStatus { SCHEDULED, COMPLETED, CANCELLED }

enum SessionMode { CHAT, VIDEO, MESSAGE }

SessionMode? sessionModeFromString(String? value) {
  if (value == null) return null;
  switch (value.toUpperCase()) {
    case 'CHAT':
      return SessionMode.CHAT;
    case 'VIDEO':
      return SessionMode.VIDEO;
    case 'MESSAGE':
      return SessionMode.MESSAGE;
  }
  return null;
}

String? sessionModeToString(SessionMode? mode) {
  if (mode == null) return null;
  return mode.toString().split('.').last;
}

SessionStatus? sessionStatusFromString(String? value) {
  if (value == null) return null;
  switch (value.toUpperCase()) {
    case 'SCHEDULED':
      return SessionStatus.SCHEDULED;
    case 'COMPLETED':
      return SessionStatus.COMPLETED;
    case 'CANCELLED':
      return SessionStatus.CANCELLED;
  }
  return null;
}

String? sessionStatusToString(SessionStatus? status) {
  if (status == null) return null;
  return status.toString().split('.').last;
}

class Session {
  final int? id;
  final int userId;
  final int? professionalId;
  final String? professionalName;
  final String? professionalSpecialization;
  final DateTime startTime;
  final int durationMinutes;
  final SessionMode mode;
  final String? notes;
  final SessionStatus? status;

  Session({
    required this.id,
    required this.userId,
    required this.professionalId,
    required this.professionalName,
    required this.professionalSpecialization,
    required this.startTime,
    required this.durationMinutes,
    required this.mode,
    required this.notes,
    required this.status,
  });

  factory Session.fromJson(Map<String, dynamic> j) {
    return Session(
      id: j['id'] == null ? null : (j['id'] as num).toInt(),
      userId: (j['userId'] as num).toInt(),
      professionalId: j['professionalId'] == null ? null : (j['professionalId'] as num).toInt(),
      professionalName: j['professionalName']?.toString(),
      professionalSpecialization: j['professionalSpecialization']?.toString(),
      startTime: DateTime.tryParse(j['startTime']?.toString() ?? '') ?? DateTime.now(),
      durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
      mode: sessionModeFromString(j['mode']?.toString()) ?? SessionMode.CHAT,
      notes: j['notes']?.toString(),
      status: sessionStatusFromString(j['status']?.toString()),
    );
  }
}

class SessionQueryParams {
  final int userId;
  final SessionTimeFilter filter;
  final DateTime? date;
  final SessionStatus? status;
  final int? page;
  final int? size;
  final String? sort;

  const SessionQueryParams({
    required this.userId,
    required this.filter,
    this.date,
    this.status,
    this.page,
    this.size,
    this.sort,
  });

  Map<String, String> toQueryParams() {
    final map = <String, String>{
      'userId': userId.toString(),
      'filter': filter.toString().split('.').last,
    };
    if (date != null) {
      final d = date!;
      // Backend expects OffsetDateTime; ensure an explicit offset by using UTC (ends with 'Z').
      final isoWithOffset = (d.isUtc ? d : d.toUtc()).toIso8601String();
      map['date'] = isoWithOffset;
    }
    final s = sessionStatusToString(status);
    if (s != null) map['status'] = s;
    if (page != null) map['page'] = page.toString();
    if (size != null) map['size'] = size.toString();
    if (sort != null && sort!.isNotEmpty) map['sort'] = sort!;
    return map;
  }
}

class ZoomSignatureResponse {
  final String apiKey;
  final String meetingNumber;
  final String signature;
  final String? password;

  ZoomSignatureResponse({
    required this.apiKey,
    required this.meetingNumber,
    required this.signature,
    this.password,
  });

  factory ZoomSignatureResponse.fromJson(Map<String, dynamic> j) {
    return ZoomSignatureResponse(
      apiKey: j['apiKey']?.toString() ?? '',
      meetingNumber: j['meetingNumber']?.toString() ?? '',
      signature: j['signature']?.toString() ?? '',
      password: j['password']?.toString(),
    );
  }
}
