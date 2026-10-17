import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finders_keepers/core/services/offline_service.dart';
import 'package:finders_keepers/features/item/domain/models/item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineService & Interrupted Submission Resilience', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saves, loads, and clears report draft', () async {
      // 1. Initially no draft
      final initialDraft = await OfflineService.loadDraft();
      expect(initialDraft, isNull);

      // 2. Save draft
      await OfflineService.saveDraft(
        title: 'Lost AirTag',
        description: 'Silver Apple AirTag lost near gym',
        type: 'lost',
        category: 'electronics',
        location: 'Campus Recreation Center • Gym',
        questions: ['What initial is engraved?'],
      );

      // 3. Load draft
      final loadedDraft = await OfflineService.loadDraft();
      expect(loadedDraft, isNotNull);
      expect(loadedDraft!['title'], 'Lost AirTag');
      expect(loadedDraft['category'], 'electronics');
      expect((loadedDraft['questions'] as List).first, 'What initial is engraved?');

      // 4. Clear draft
      await OfflineService.clearDraft();
      final clearedDraft = await OfflineService.loadDraft();
      expect(clearedDraft, isNull);
    });

    test('enqueues and drains offline reports upon reconnection', () async {
      final offlineItem = Item(
        id: 'offline_001',
        title: 'Offline Water Bottle',
        description: 'Found bottle during internet outage',
        type: ItemType.found,
        status: ItemStatus.open,
        category: ItemCategory.other,
        approximateLocation: 'Student Union Building • Food Court',
        reporterId: 'user_001',
        reporterName: 'Test Student',
        createdAt: DateTime.now(),
      );

      await OfflineService.enqueueOfflineReport(offlineItem);
      final queued = await OfflineService.drainOfflineQueue();
      expect(queued.length, 1);
      expect(queued.first.id, 'offline_001');

      // Subsequent drain should be empty
      final emptyQueue = await OfflineService.drainOfflineQueue();
      expect(emptyQueue.isEmpty, true);
    });
  });
}
