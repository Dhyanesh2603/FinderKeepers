import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/chat_message.dart';

abstract class ChatRepository {
  Stream<List<ChatMessage>> getMessagesStream(String claimId);
  Future<void> sendMessage(ChatMessage message);
}

class InMemoryChatRepository implements ChatRepository {
  final Map<String, StreamController<List<ChatMessage>>> _controllers = {};
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'msg_01',
      claimId: 'claim_501',
      senderId: 'user_004',
      senderName: 'Jordan Vance',
      text: 'Hi Alex! Your answer matched the case engraving. I have your AirPods safe.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    ChatMessage(
      id: 'msg_02',
      claimId: 'claim_501',
      senderId: 'user_001',
      senderName: 'Alex Rivers',
      text: 'Thank you so much! Can we meet at the Student Union front desk tomorrow at 12 PM?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  StreamController<List<ChatMessage>> _getController(String claimId) {
    return _controllers.putIfAbsent(claimId, () {
      final controller = StreamController<List<ChatMessage>>.broadcast();
      final claimMsgs = _messages.where((m) => m.claimId == claimId).toList();
      controller.add(List.unmodifiable(claimMsgs));
      return controller;
    });
  }

  @override
  Stream<List<ChatMessage>> getMessagesStream(String claimId) {
    return _getController(claimId).stream;
  }

  @override
  Future<void> sendMessage(ChatMessage message) async {
    _messages.add(message);
    final claimMsgs = _messages.where((m) => m.claimId == message.claimId).toList();
    _getController(message.claimId).add(List.unmodifiable(claimMsgs));
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return InMemoryChatRepository();
});

final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, claimId) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getMessagesStream(claimId);
});
