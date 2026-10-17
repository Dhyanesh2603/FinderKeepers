import '../../item/domain/models/item.dart';

/// Represents an automated match recommendation connecting a lost item with a found item.
class MatchRecommendation {
  final Item lostItem;
  final Item foundItem;
  final int confidenceScore; // 0 to 100
  final String rationale;
  final DateTime matchedAt;

  const MatchRecommendation({
    required this.lostItem,
    required this.foundItem,
    required this.confidenceScore,
    required this.rationale,
    required this.matchedAt,
  });
}
