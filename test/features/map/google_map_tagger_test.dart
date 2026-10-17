import 'package:flutter_test/flutter_test.dart';
import 'package:finders_keepers/features/item/domain/models/item.dart';
import 'package:finders_keepers/features/item/presentation/widgets/google_map_tagger_widget.dart';

void main() {
  group('Google Map Location Tagger & GPS Coordinates', () {
    test('contains valid campus GPS landmark presets', () {
      expect(kCampusGeoPresets.isNotEmpty, isTrue);
      for (final preset in kCampusGeoPresets) {
        expect(preset.name.isNotEmpty, isTrue);
        expect(preset.latitude, greaterThan(12.0));
        expect(preset.latitude, lessThan(13.5));
        expect(preset.longitude, greaterThan(79.0));
        expect(preset.longitude, lessThan(80.5));
      }
    });

    test('Item serializes and deserializes latitude and longitude correctly', () {
      final item = Item(
        id: 'test_tagged_item',
        title: 'Lost Calculator',
        description: 'Casio fx-991EX',
        type: ItemType.lost,
        status: ItemStatus.open,
        category: ItemCategory.electronics,
        approximateLocation: 'Main Central Library',
        latitude: 12.9692,
        longitude: 79.1559,
        reporterId: 'user_123',
        reporterName: 'Alex',
        createdAt: DateTime.now(),
      );

      final map = item.toMap();
      expect(map['latitude'], equals(12.9692));
      expect(map['longitude'], equals(79.1559));

      final restored = Item.fromMap(map, item.id);
      expect(restored.latitude, equals(12.9692));
      expect(restored.longitude, equals(79.1559));
      expect(restored.approximateLocation, equals('Main Central Library'));
    });

    test('TaggedLocationResult encapsulates location and GPS coordinates', () {
      const result = TaggedLocationResult(
        latitude: 12.9710,
        longitude: 79.1594,
        locationName: 'Engineering Hall • Technology Labs',
        description: 'GPS Pin: 12.9710° N, 79.1594° E',
      );

      expect(result.latitude, equals(12.9710));
      expect(result.longitude, equals(79.1594));
      expect(result.locationName, contains('Engineering Hall'));
      expect(result.description, contains('12.9710° N'));
    });
  });
}
