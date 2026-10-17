import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../item/data/item_repository.dart';
import '../../../item/domain/models/item.dart';
import '../../../item/presentation/widgets/google_map_tagger_widget.dart';
import '../../../../core/services/offline_service.dart';

/// Form screen allowing students to report lost or found items with photo and secret questions.
class ReportItemScreen extends ConsumerStatefulWidget {
  const ReportItemScreen({super.key});

  @override
  ConsumerState<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends ConsumerState<ReportItemScreen> {
  ItemType _type = ItemType.found;
  ItemCategory _category = ItemCategory.electronics;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _questionController = TextEditingController();

  final List<String> _verificationQuestions = [];
  String _selectedLocation = 'Main Library • 2nd Floor';
  double? _taggedLat;
  double? _taggedLng;
  Uint8List? _selectedImageBytes;
  bool _isSubmitting = false;

  final List<String> _campusLocations = [
    'Main Library • 2nd Floor',
    'Main Library • 3rd Floor Quiet Zone',
    'Student Union Building • Food Court',
    'Engineering Hall • Lab 204',
    'Science Center • Lecture Hall B',
    'Business Complex • Auditorium A',
    'Campus Recreation Center • Gym',
    'Central Cafeteria Bench',
  ];

  @override
  void initState() {
    super.initState();
    _checkAndRestoreDraft();
  }

  Future<void> _checkAndRestoreDraft() async {
    final draft = await OfflineService.loadDraft();
    if (draft != null && mounted) {
      setState(() {
        _titleController.text = draft['title'] as String? ?? '';
        _descriptionController.text = draft['description'] as String? ?? '';
        if (draft['location'] != null) _selectedLocation = draft['location'] as String;
        if (draft['type'] != null) {
          _type = draft['type'] == 'lost' ? ItemType.lost : ItemType.found;
        }
        if (draft['category'] != null) {
          _category = ItemCategory.values.firstWhere(
            (e) => e.name == draft['category'],
            orElse: () => ItemCategory.electronics,
          );
        }
        if (draft['questions'] is List) {
          _verificationQuestions.addAll(List<String>.from(draft['questions'] as List));
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restored unsaved report draft.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _persistDraft() {
    OfflineService.saveDraft(
      title: _titleController.text,
      description: _descriptionController.text,
      type: _type.name,
      category: _category.name,
      location: _selectedLocation,
      questions: _verificationQuestions,
    );
  }

  @override
  void dispose() {
    _persistDraft();
    _titleController.dispose();
    _descriptionController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _selectedImageBytes = bytes);
    }
  }

  void _addVerificationQuestion() {
    final text = _questionController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _verificationQuestions.add(text);
        _questionController.clear();
      });
      _persistDraft();
    }
  }

  Future<void> _openGoogleMapTagger() async {
    final result = await showModalBottomSheet<TaggedLocationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoogleMapTaggerWidget(
        initialLat: _taggedLat,
        initialLng: _taggedLng,
        initialLocationName: _selectedLocation,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _taggedLat = result.latitude;
        _taggedLng = result.longitude;
        _selectedLocation = result.locationName;
      });
      _persistDraft();
    }
  }

  Future<void> _submitReport() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item title and description.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final currentUser = ref.read(currentUserProvider);
    final isOffline = ref.read(isOfflineModeProvider);

    final newItem = Item(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      type: _type,
      status: ItemStatus.open,
      category: _category,
      approximateLocation: _selectedLocation,
      latitude: _taggedLat,
      longitude: _taggedLng,
      reporterId: currentUser?.uid ?? 'anon_user',
      reporterName: currentUser?.displayName ?? 'Campus Student',
      photoUrl: _selectedImageBytes != null ? 'attached_image' : null,
      createdAt: DateTime.now(),
      verificationQuestions: _verificationQuestions.isEmpty
          ? ['What distinctive mark or contents confirm you are the owner?']
          : _verificationQuestions,
    );

    if (isOffline) {
      await OfflineService.enqueueOfflineReport(newItem);
    }
    await ref.read(itemRepositoryProvider).addItem(newItem);
    await OfflineService.clearDraft();

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isOffline
            ? 'Saved to offline queue. Will auto-sync when online.'
            : 'Report published for "${newItem.title}"!'),
        backgroundColor: AppColors.mutedGreen,
      ),
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Campus Item'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.s),
          child: AppButton(
            label: _type == ItemType.found ? 'Publish Found Report' : 'Publish Lost Report',
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submitReport,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Type Selector Pill
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = ItemType.found),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == ItemType.found
                              ? (isDark ? AppColors.surfaceDark : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Center(
                          child: Text(
                            'I Found Something',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _type == ItemType.found ? FontWeight.w600 : FontWeight.w400,
                              color: _type == ItemType.found ? AppColors.mutedGreen : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _type = ItemType.lost),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == ItemType.lost
                              ? (isDark ? AppColors.surfaceDark : Colors.white)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                        child: Center(
                          child: Text(
                            'I Lost Something',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _type == ItemType.lost ? FontWeight.w600 : FontWeight.w400,
                              color: _type == ItemType.lost ? AppColors.mutedAmber : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.l),

            // Item Title
            AppTextField(
              label: 'Item Title',
              hintText: 'e.g. Blue Hydro Flask / Sony Headphones',
              controller: _titleController,
            ),

            const SizedBox(height: AppSpacing.m),

            // Category Selection
            const Text(
              'Category',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ItemCategory.values.where((c) => c != ItemCategory.all).map((cat) {
                final isSelected = cat == _category;
                return ChoiceChip(
                  label: Text(cat.label, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _category = cat),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.l),

            // Approximate Campus Location Dropdown
            const Text(
              'Approximate Campus Location',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                borderRadius: AppSpacing.borderRadiusMedium,
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedLocation,
                  isExpanded: true,
                  items: _campusLocations.map((loc) {
                    return DropdownMenuItem(value: loc, child: Text(loc, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLocation = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.s),

            // Google Map Tagging Action Card
            if (_taggedLat == null)
              InkWell(
                onTap: _openGoogleMapTagger,
                borderRadius: AppSpacing.borderRadiusMedium,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceVariantDark : Colors.white,
                    borderRadius: AppSpacing.borderRadiusMedium,
                    border: Border.all(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA4335).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_location_alt, color: Color(0xFFEA4335), size: 22),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Text(
                                  'Tag Location on Google Map',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'PIN DROP',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF4285F4)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Drop a pin on the campus map so the owner knows exactly where you found it.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.mutedGreenLight,
                  borderRadius: AppSpacing.borderRadiusMedium,
                  border: Border.all(color: AppColors.mutedGreen, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.mutedGreen, size: 24),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location Tagged on Google Map ✓',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF14532D)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_selectedLocation • (${_taggedLat!.toStringAsFixed(4)}° N, ${_taggedLng!.toStringAsFixed(4)}° E)',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: _openGoogleMapTagger,
                      child: const Text('Change Pin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.l),

            // Description
            AppTextField(
              label: 'Description & Context',
              hintText: 'Provide general details without revealing confidential identifiers...',
              controller: _descriptionController,
            ),

            const SizedBox(height: AppSpacing.l),

            // Image Picker Section
            const Text('Photo Attachment (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            if (_selectedImageBytes != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: AppSpacing.borderRadiusMedium,
                    child: Image.memory(_selectedImageBytes!, height: 160, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                      onPressed: () => setState(() => _selectedImageBytes = null),
                    ),
                  ),
                ],
              )
            else
              AppCard(
                onTap: _pickImage,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Attach Photo from Gallery', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

            const SizedBox(height: AppSpacing.l),

            // Anti-Fraud Verification Questions Setup
            const Text('Anti-Fraud Ownership Quiz', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              'Add questions only the real owner can answer (e.g. scratch location, case sticker).',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: AppSpacing.xs),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. What is the lockscreen wallpaper?',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addVerificationQuestion,
                ),
              ],
            ),

            if (_verificationQuestions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s),
              ..._verificationQuestions.map((q) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 16, color: AppColors.mutedGreen),
                        const SizedBox(width: 6),
                        Expanded(child: Text(q, style: const TextStyle(fontSize: 12))),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
