// ignore_for_file: constant_identifier_names

import 'package:intl/intl.dart';

enum Specialization { MENTAL_HEALTH, COACHING, FINANCIAL_WELLNESS }

const specializationLabels = {
  Specialization.MENTAL_HEALTH: 'Mental Health',
  Specialization.COACHING: 'Coaching',
  Specialization.FINANCIAL_WELLNESS: 'Financial Wellness',
};

Specialization? specializationFromString(String? value) {
  if (value == null) return null;
  switch (value) {
    case 'MENTAL_HEALTH':
      return Specialization.MENTAL_HEALTH;
    case 'COACHING':
      return Specialization.COACHING;
    case 'FINANCIAL_WELLNESS':
      return Specialization.FINANCIAL_WELLNESS;
  }
  return null;
}

String? specializationToString(Specialization? value) {
  if (value == null) return null;
  return value.toString().split('.').last;
}

class ProfessionalFilterParams {
  final String? firstName;
  final String? lastName;
  final Specialization? specialization;
  final int? experience;
  final String? availabilityDate; // ISO string
  final bool availableOnly;
  final bool excludeConnected;
  final String? status;
  final int? page;
  final int? size;
  final String? sort;

  const ProfessionalFilterParams({
    this.firstName,
    this.lastName,
    this.specialization,
    this.experience,
    this.availabilityDate,
    this.availableOnly = false,
    this.excludeConnected = false,
    this.status,
    this.page,
    this.size,
    this.sort,
  });

  Map<String, String> toQueryParams() {
    final map = <String, String>{};
    if (firstName != null && firstName!.isNotEmpty) {
      map['firstName'] = firstName!;
    }
    if (lastName != null && lastName!.isNotEmpty) {
      map['lastName'] = lastName!;
    }
    final spec = specializationToString(specialization);
    if (spec != null && spec.isNotEmpty) {
      map['specialization'] = spec;
    }
    if (experience != null) {
      map['experience'] = experience!.toString();
    }
    if (availabilityDate != null && availabilityDate!.isNotEmpty) {
      map['availabilityDate'] = availabilityDate!;
    }
    if (availableOnly) {
      map['availableOnly'] = 'true';
    }
    if (excludeConnected) {
      map['excludeConnected'] = 'true';
    }
    if (status != null && status!.isNotEmpty) {
      map['status'] = status!;
    }
    if (page != null) {
      map['page'] = page!.toString();
    }
    if (size != null) {
      map['size'] = size!.toString();
    }
    if (sort != null && sort!.isNotEmpty) {
      map['sort'] = sort!;
    }
    return map;
  }
}

class PagedResponse<T> {
  final int totalPages;
  final int totalElements;
  final int page;
  final int size;
  final List<T> content;
  final bool empty;
  final bool isLast;

  PagedResponse({
    required this.totalPages,
    required this.totalElements,
    required this.page,
    required this.size,
    required this.content,
    required this.empty,
    required this.isLast,
  });

  static PagedResponse<T> fromJson<T>(
      Map<String, dynamic> json, T Function(Object? j) itemFromJson) {
    return PagedResponse<T>(
      totalPages: json['totalPages'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      page: json['page'] ?? 0,
      size: json['size'] ?? 0,
      content: (json['content'] as List<dynamic>? ?? const [])
          .map<T>((e) => itemFromJson(e))
          .toList(growable: false),
      empty: json['empty'] ?? false,
      isLast: json['isLast'] ?? true,
    );
  }
}

class Professional {
  final int id;
  final String bio;
  final Specialization specialization;
  final List<String> certificates;
  final double? rating;
  final int hourlyRate;
  final int? experienceYears;
  final List<String>? languages;
  final List<AvailabilitySlot> availabilities;
  final UserSummary user;
  final String status;
  final DateTime createdAt;
  final DateTime? statusUpdatedAt;
  final List<ProfessionalCertification>? certifications;

  Professional({
    required this.id,
    required this.bio,
    required this.specialization,
    required this.certificates,
    required this.rating,
    required this.hourlyRate,
    required this.experienceYears,
    required this.languages,
    required this.availabilities,
    required this.user,
    required this.status,
    required this.createdAt,
    required this.statusUpdatedAt,
    required this.certifications,
  });

  factory Professional.fromJson(Map<String, dynamic> j) {
    return Professional(
      id: j['id'] ?? 0,
      bio: j['bio'] ?? '',
      specialization: specializationFromString(j['specialization']) ??
          Specialization.MENTAL_HEALTH,
      certificates: (j['certificates'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      rating: j['rating'] != null ? (j['rating'] as num).toDouble() : null,
      hourlyRate: (j['hourlyRate'] ?? 0) as int,
      experienceYears: j['experienceYears'] as int?,
      languages: (j['languages'] as List?)
          ?.map((e) => e.toString())
          .toList(growable: false),
      availabilities: (j['availabilities'] as List?)
              ?.map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      user:
          UserSummary.fromJson(j['user'] as Map<String, dynamic>? ?? const {}),
      status: j['status']?.toString() ?? 'ACTIVE',
      createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      statusUpdatedAt: j['statusUpdatedAt'] != null
          ? DateTime.tryParse(j['statusUpdatedAt'].toString())
          : null,
      certifications: (j['certifications'] as List?)
          ?.map((e) =>
              ProfessionalCertification.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class AvailabilitySlot {
  final int id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int professionalId;

  AvailabilitySlot({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.professionalId,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date']?.toString();
    final startStr = json['startTime']?.toString();
    final endStr = json['endTime']?.toString();
    DateTime parseDateTime(String? day, String? time) {
      if (day == null || time == null) return DateTime.now();
      return DateTime.tryParse('${day}T$time') ?? DateTime.now();
    }

    final dateOnly = dateStr != null
        ? DateTime.tryParse('${dateStr}T00:00:00') ?? DateTime.now()
        : DateTime.now();
    return AvailabilitySlot(
      id: (json['id'] as num?)?.toInt() ?? 0,
      date: dateOnly,
      startTime: parseDateTime(dateStr, startStr),
      endTime: parseDateTime(dateStr, endStr),
      professionalId: (json['professionalId'] as num?)?.toInt() ?? 0,
    );
  }

  String formatLabel() {
    final dateLabel = DateFormat('EEE, MMM d').format(date);
    final timeLabel =
        '${DateFormat('h:mm a').format(startTime)} - ${DateFormat('h:mm a').format(endTime)}';
    return '$dateLabel · $timeLabel';
  }

  bool isSameDay(DateTime other) {
    return date.year == other.year &&
        date.month == other.month &&
        date.day == other.day;
  }
}

class UserSummary {
  final int id;
  final String firstName;
  final String lastName;
  final String? avatar;

  UserSummary(
      {required this.id,
      required this.firstName,
      required this.lastName,
      this.avatar});

  factory UserSummary.fromJson(Map<String, dynamic> j) {
    return UserSummary(
      id: j['id'] ?? 0,
      firstName: j['firstName']?.toString() ?? '',
      lastName: j['lastName']?.toString() ?? '',
      avatar: j['avatar']?.toString(),
    );
  }
}

class ProfessionalCertification {
  final String name;
  final String? issuingOrganization;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? fileUrl;
  final String? description;

  ProfessionalCertification({
    required this.name,
    this.issuingOrganization,
    this.issueDate,
    this.expiryDate,
    this.fileUrl,
    this.description,
  });

  factory ProfessionalCertification.fromJson(Map<String, dynamic> j) {
    return ProfessionalCertification(
      name: j['name']?.toString() ?? '',
      issuingOrganization: j['issuingOrganization']?.toString(),
      issueDate: j['issueDate'] != null
          ? DateTime.tryParse(j['issueDate'].toString())
          : null,
      expiryDate: j['expiryDate'] != null
          ? DateTime.tryParse(j['expiryDate'].toString())
          : null,
      fileUrl: j['fileUrl']?.toString() ?? j['filePath']?.toString(),
      description: j['description']?.toString(),
    );
  }
}
