class UserPermissions {
  const UserPermissions({
    this.canViewBookings = false,
    this.canManageBookings = false,
    this.canViewPayments = false,
    this.canViewGuestContact = false,
  });

  final bool canViewBookings;
  final bool canManageBookings;
  final bool canViewPayments;
  final bool canViewGuestContact;

  factory UserPermissions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserPermissions();
    return UserPermissions(
      canViewBookings: json['can_view_bookings'] == true,
      canManageBookings: json['can_manage_bookings'] == true,
      canViewPayments: json['can_view_payments'] == true,
      canViewGuestContact: json['can_view_guest_contact'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'can_view_bookings': canViewBookings,
        'can_manage_bookings': canManageBookings,
        'can_view_payments': canViewPayments,
        'can_view_guest_contact': canViewGuestContact,
      };
}

class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.mustChangePassword = false,
    this.permissions,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final bool mustChangePassword;
  final UserPermissions? permissions;

  bool get isCeo => role == 'ceo';
  bool get isOfficeManager => role == 'admin' || role == 'manager';
  bool get isFloorStaff => role == 'staff';

  bool get canViewBookings =>
      permissions?.canViewBookings ??
      (isCeo || isOfficeManager || isFloorStaff);

  bool get canManageBookings =>
      permissions?.canManageBookings ?? (isCeo || isOfficeManager);

  bool get canViewPayments =>
      permissions?.canViewPayments ?? (isCeo || isOfficeManager);

  bool get canViewGuestContact =>
      permissions?.canViewGuestContact ?? (isCeo || isOfficeManager);

  factory SessionUser.fromApi(Map<String, dynamic> user) {
    final role = (user['role'] as String?) ?? 'admin';
    final must = user['mustChangePassword'] == true ||
        user['must_change_password'] == true;
    final permsRaw = user['permissions'];
    return SessionUser(
      id: '${user['id']}',
      name: '${user['name'] ?? ''}',
      email: '${user['email'] ?? ''}',
      role: role,
      mustChangePassword: must,
      permissions: permsRaw is Map<String, dynamic>
          ? UserPermissions.fromJson(permsRaw)
          : null,
    );
  }

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      email: '${json['email'] ?? ''}',
      role: '${json['role'] ?? 'admin'}',
      mustChangePassword: json['mustChangePassword'] == true,
      permissions: json['permissions'] is Map<String, dynamic>
          ? UserPermissions.fromJson(
              json['permissions'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'mustChangePassword': mustChangePassword,
        if (permissions != null) 'permissions': permissions!.toJson(),
      };
}

class OtpChallenge {
  const OtpChallenge({
    required this.challengeToken,
    required this.emailHint,
    required this.otpExpiresIn,
    required this.message,
    this.mustChangePassword = false,
  });

  final String challengeToken;
  final String emailHint;
  final int otpExpiresIn;
  final String message;
  final bool mustChangePassword;
}
