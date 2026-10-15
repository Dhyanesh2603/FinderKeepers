/// Defines the core categories for campus lost & found items.
enum ItemCategory {
  all('All'),
  electronics('Electronics'),
  wallets('Wallets'),
  idsCards('IDs & Cards'),
  keys('Keys'),
  bagsBooks('Bags & Books'),
  other('Other');

  final String label;
  const ItemCategory(this.label);
}

enum ItemType { lost, found }

enum ItemStatus { open, claimPending, reunited }

/// Immutable domain model representing a lost or found campus item.
class Item {
  final String id;
  final String title;
  final String description;
  final ItemType type;
  final ItemStatus status;
  final ItemCategory category;
  final String approximateLocation;
  final String reporterId;
  final String reporterName;
  final String? photoUrl;
  final DateTime createdAt;
  final int verificationQuestionsCount;

  const Item({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.category,
    required this.approximateLocation,
    required this.reporterId,
    required this.reporterName,
    this.photoUrl,
    required this.createdAt,
    this.verificationQuestionsCount = 0,
  });

  factory Item.fromMap(Map<String, dynamic> map, String id) {
    return Item(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: (map['type'] == 'found') ? ItemType.found : ItemType.lost,
      status: ItemStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ItemStatus.open,
      ),
      category: ItemCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => ItemCategory.other,
      ),
      approximateLocation: map['approximateLocation'] as String? ?? 'Campus Area',
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? 'Campus Member',
      photoUrl: map['photoUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      verificationQuestionsCount: map['verificationQuestionsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'status': status.name,
      'category': category.name,
      'approximateLocation': approximateLocation,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'verificationQuestionsCount': verificationQuestionsCount,
    };
  }
}
