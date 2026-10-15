/// Represents an authenticated student user within the campus platform.
///
/// Immutable domain model designed to be serialized to and from Firestore.
class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String studentId;
  final bool isVerified;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.studentId,
    this.isVerified = false,
    required this.createdAt,
  });

  /// Factory constructor to deserialize Firestore document data.
  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      uid: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Student',
      studentId: map['studentId'] as String? ?? '',
      isVerified: map['isVerified'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  /// Converts the domain model into a map for storage in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'studentId': studentId,
      'isVerified': isVerified,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a copy with modified fields.
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? studentId,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      studentId: studentId ?? this.studentId,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
