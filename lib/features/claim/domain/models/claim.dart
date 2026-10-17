enum ClaimStatus { pending, approved, rejected }

/// Represents a formal ownership claim submitted by a student.
class Claim {
  final String id;
  final String itemId;
  final String itemTitle;
  final String claimantId;
  final String claimantName;
  final String claimantEmail;
  final Map<String, String> answers; // Question -> Answer
  final ClaimStatus status;
  final DateTime createdAt;

  const Claim({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.claimantId,
    required this.claimantName,
    required this.claimantEmail,
    required this.answers,
    this.status = ClaimStatus.pending,
    required this.createdAt,
  });

  factory Claim.fromMap(Map<String, dynamic> map, String id) {
    return Claim(
      id: id,
      itemId: map['itemId'] as String? ?? '',
      itemTitle: map['itemTitle'] as String? ?? '',
      claimantId: map['claimantId'] as String? ?? '',
      claimantName: map['claimantName'] as String? ?? 'Student',
      claimantEmail: map['claimantEmail'] as String? ?? '',
      answers: Map<String, String>.from(map['answers'] as Map? ?? {}),
      status: ClaimStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ClaimStatus.pending,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'claimantId': claimantId,
      'claimantName': claimantName,
      'claimantEmail': claimantEmail,
      'answers': answers,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  factory Claim.fromJson(Map<String, dynamic> json) =>
      Claim.fromMap(json, json['id'] as String? ?? '');
}
