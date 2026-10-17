import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../item/data/item_repository.dart';
import '../../item/domain/models/item.dart';
import '../domain/match_recommendation.dart';

/// Engine that performs location, category, and keyword similarity matching between lost & found items.
class MatchEngine {
  /// Computes recommendations by comparing all open lost items with all open found items.
  static List<MatchRecommendation> computeMatches(List<Item> allItems) {
    final lostItems = allItems.where((i) => i.type == ItemType.lost && i.status == ItemStatus.open).toList();
    final foundItems = allItems.where((i) => i.type == ItemType.found && i.status == ItemStatus.open).toList();

    final List<MatchRecommendation> matches = [];

    for (final lost in lostItems) {
      for (final found in foundItems) {
        int score = 0;
        final List<String> reasons = [];

        // 1. Category Matching (Weight: 35%)
        if (lost.category == found.category) {
          score += 35;
          reasons.add('Same category (${lost.category.label})');
        }

        // 2. Location Proximity (Weight: 35%)
        final lostLoc = lost.approximateLocation.toLowerCase();
        final foundLoc = found.approximateLocation.toLowerCase();
        if (lostLoc == foundLoc) {
          score += 35;
          reasons.add('Exact landmark match (${lost.approximateLocation})');
        } else if (_isNearby(lostLoc, foundLoc)) {
          score += 20;
          reasons.add('Nearby campus zone');
        }

        // 3. Keyword / Text Similarity (Weight: 20%)
        final keywordOverlap = _computeKeywordOverlap(
          '${lost.title} ${lost.description}'.toLowerCase(),
          '${found.title} ${found.description}'.toLowerCase(),
        );
        if (keywordOverlap > 0) {
          final keywordScore = (keywordOverlap * 10).clamp(0, 20);
          score += keywordScore;
          reasons.add('Shared keywords detected');
        }

        // 4. Time Proximity (Weight: 10%)
        final timeDiff = lost.createdAt.difference(found.createdAt).abs();
        if (timeDiff.inHours < 48) {
          score += 10;
          reasons.add('Reported within 48h window');
        }

        // Include recommendation if confidence is >= 50%
        if (score >= 50) {
          matches.add(
            MatchRecommendation(
              lostItem: lost,
              foundItem: found,
              confidenceScore: score.clamp(0, 100),
              rationale: reasons.join(' • '),
              matchedAt: DateTime.now(),
            ),
          );
        }
      }
    }

    // Sort by highest confidence score first
    matches.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return matches;
  }

  static bool _isNearby(String locA, String locB) {
    const zones = [
      ['library', 'study', 'quiet'],
      ['food', 'cafeteria', 'dining', 'union'],
      ['gym', 'recreation', 'sports', 'arena'],
      ['engineering', 'lab', 'hall'],
      ['science', 'lecture', 'hall'],
    ];

    for (final zone in zones) {
      final aInZone = zone.any((keyword) => locA.contains(keyword));
      final bInZone = zone.any((keyword) => locB.contains(keyword));
      if (aInZone && bInZone) return true;
    }
    return false;
  }

  static int _computeKeywordOverlap(String textA, String textB) {
    const stopWords = {'the', 'a', 'an', 'and', 'or', 'in', 'on', 'at', 'with', 'for', 'near'};
    final wordsA = textA.split(RegExp(r'\s+')).where((w) => w.length > 2 && !stopWords.contains(w)).toSet();
    final wordsB = textB.split(RegExp(r'\s+')).where((w) => w.length > 2 && !stopWords.contains(w)).toSet();
    return wordsA.intersection(wordsB).length;
  }
}

/// Provider exposing smart match recommendations derived from active items stream.
final matchRecommendationsProvider = Provider<List<MatchRecommendation>>((ref) {
  final itemsAsync = ref.watch(itemsStreamProvider);
  final items = itemsAsync.value ?? [];
  return MatchEngine.computeMatches(items);
});
