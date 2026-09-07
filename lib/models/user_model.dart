import 'package:equatable/equatable.dart';

/// The four roles defined in the spec (§1, §5).
enum UserRole { teacher, student, admin, parent }

UserRole userRoleFromString(String value) {
  return UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.student,
  );
}

/// Mirrors the `profiles` table in Supabase (see supabase/migrations).
/// This is the shared shape for every role; role-specific extra fields
/// (e.g. institution, class/grade) are captured during profile setup (§1).
class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.email,
    this.phone,
    this.classGrade,
    this.institution,
    this.avatarUrl,
    this.languagePreference = 'en',
    this.profileCompleted = false,
    this.createdAt,
  });

  final String id; // matches Supabase auth.users.id
  final String fullName;
  final UserRole role;
  final String? email;
  final String? phone;
  final String?
      classGrade; // e.g. "Class 9" — captured at registration (§1, §4)
  final String? institution;
  final String? avatarUrl;
  final String languagePreference; // 'en' or 'bn' (§1)
  final bool profileCompleted;
  final DateTime? createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      role: userRoleFromString(json['role'] as String? ?? 'student'),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      classGrade: json['class_grade'] as String?,
      institution: json['institution'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      languagePreference: json['language_preference'] as String? ?? 'en',
      profileCompleted: json['profile_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role.name,
      'email': email,
      'phone': phone,
      'class_grade': classGrade,
      'institution': institution,
      'avatar_url': avatarUrl,
      'language_preference': languagePreference,
      'profile_completed': profileCompleted,
    };
  }

  UserModel copyWith({
    String? fullName,
    UserRole? role,
    String? email,
    String? phone,
    String? classGrade,
    String? institution,
    String? avatarUrl,
    String? languagePreference,
  }) {
    return UserModel(
      id: id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      classGrade: classGrade ?? this.classGrade,
      institution: institution ?? this.institution,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      languagePreference: languagePreference ?? this.languagePreference,
      profileCompleted: profileCompleted,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        role,
        email,
        phone,
        classGrade,
        institution,
        avatarUrl,
        languagePreference,
        profileCompleted,
      ];
}
