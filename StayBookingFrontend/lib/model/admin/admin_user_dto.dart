enum AdminUserStatus {
  active,
  suspended,
  deleted,
  pendingVerification,
}

extension AdminUserStatusX on AdminUserStatus {
  String get apiValue {
    switch (this) {
      case AdminUserStatus.active:
        return 'ACTIVE';
      case AdminUserStatus.suspended:
        return 'SUSPENDED';
      case AdminUserStatus.deleted:
        return 'DELETED';
      case AdminUserStatus.pendingVerification:
        return 'PENDING_VERIFICATION';
    }
  }

  String get label {
    switch (this) {
      case AdminUserStatus.active:
        return 'Active';
      case AdminUserStatus.suspended:
        return 'Suspended';
      case AdminUserStatus.deleted:
        return 'Deleted';
      case AdminUserStatus.pendingVerification:
        return 'Pending Verification';
    }
  }
}

AdminUserStatus? adminUserStatusFromApi(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'ACTIVE':
      return AdminUserStatus.active;
    case 'SUSPENDED':
      return AdminUserStatus.suspended;
    case 'DELETED':
      return AdminUserStatus.deleted;
    case 'PENDING_VERIFICATION':
      return AdminUserStatus.pendingVerification;
    default:
      return null;
  }
}

class AdminUserDto {
  const AdminUserDto({
    required this.id,
    required this.fname,
    required this.lname,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String fname;
  final String lname;
  final String email;
  final String role;
  final String status;
  final String createdAt;
  final String updatedAt;

  String get fullName => '$fname $lname'.trim();

  AdminUserDto copyWith({
    int? id,
    String? fname,
    String? lname,
    String? email,
    String? role,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return AdminUserDto(
      id: id ?? this.id,
      fname: fname ?? this.fname,
      lname: lname ?? this.lname,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AdminUserDto.fromJson(Map<String, dynamic> json) {
    return AdminUserDto(
      id: _toInt(json['id']),
      fname: (json['fname'] as String?)?.trim() ?? '',
      lname: (json['lname'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      role: (json['role'] as String?)?.trim().toUpperCase() ?? '',
      status: (json['status'] as String?)?.trim().toUpperCase() ?? '',
      createdAt: (json['createdat'] as String?)?.trim() ?? '',
      updatedAt: (json['updatedat'] as String?)?.trim() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class UpdateUserAccessRequest {
  const UpdateUserAccessRequest({
    this.role,
    this.status,
    required this.updatedBy,
  });

  final String? role;
  final String? status;
  final String updatedBy;

  Map<String, dynamic> toJson() {
    return {
      if ((role ?? '').trim().isNotEmpty) 'role': role!.trim().toUpperCase(),
      if ((status ?? '').trim().isNotEmpty)
        'status': status!.trim().toUpperCase(),
      'updatedBy': updatedBy.trim(),
    };
  }
}