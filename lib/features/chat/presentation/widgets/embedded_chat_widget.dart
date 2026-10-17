import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/chat_repository.dart';
import '../../domain/models/chat_message.dart';

/// Embedded in-page chat widget for seamless handover coordination directly on the item/claim screen.
class EmbeddedChatWidget extends ConsumerStatefulWidget {
  final String claimId;

  const EmbeddedChatWidget({super.key, required this.claimId});

  @override
  ConsumerState<EmbeddedChatWidget> createState() => _EmbeddedChatWidgetState();
}

class _EmbeddedChatWidgetState extends ConsumerState<EmbeddedChatWidget> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      claimId: widget.claimId,
      senderId: user.uid,
      senderName: user.displayName,
      text: text,
      timestamp: DateTime.now(),
    );

    _messageController.clear();
    await ref.read(chatRepositoryProvider).sendMessage(newMsg);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.claimId));
    final messages = messagesAsync.value ?? [];
    final currentUser = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.mutedGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Verified Handover Chat',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.mutedGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: const Text(
                  'ACTIVE CHANNEL',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.mutedGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Coordinate a safe campus meetup (e.g. Student Center desk, Library foyer).',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          ),
          const SizedBox(height: AppSpacing.m),

          // Message bubble list (fixed height inside card)
          Container(
            height: 220,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
              borderRadius: AppSpacing.borderRadiusMedium,
            ),
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'No messages yet. Send a message to arrange handover!',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: messages.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = currentUser != null && msg.senderId == currentUser.uid;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 240),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe
                                ? (isDark ? Colors.white : AppColors.charcoal)
                                : (isDark ? AppColors.surfaceDark : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  msg.senderName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.mutedAmber : AppColors.mutedGreen,
                                  ),
                                ),
                              Text(
                                msg.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMe
                                      ? (isDark ? AppColors.charcoal : Colors.white)
                                      : (isDark ? Colors.white : AppColors.charcoal),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('h:mm a').format(msg.timestamp),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isMe
                                      ? (isDark ? Colors.black54 : Colors.white60)
                                      : (isDark ? Colors.white38 : Colors.black38),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: AppSpacing.s),

          // Message input bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Type meeting spot, time...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : AppColors.charcoal,
                  foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                ),
                icon: const Icon(Icons.send, size: 16),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
