import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/chat_repository.dart';

/// Chat State
abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatsLoaded extends ChatState {
  final List<Map<String, dynamic>> chats;
  ChatsLoaded(this.chats);
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}

class ChatDetailsLoaded extends ChatState {
  final Map<String, dynamic> chat;
  ChatDetailsLoaded(this.chat);
}

class MessagesLoaded extends ChatState {
  final List<Map<String, dynamic>> messages;
  final int currentPage;
  final int lastPage;
  final bool hasMore;
  MessagesLoaded({
    required this.messages,
    required this.currentPage,
    required this.lastPage,
  }) : hasMore = currentPage < lastPage;
}

class MessageSent extends ChatState {
  final Map<String, dynamic> message;
  MessageSent(this.message);
}

/// Chat Cubit
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repository;

  ChatCubit({ChatRepository? repository})
      : _repository = repository ?? ChatRepository(),
        super(ChatInitial());

  /// Get all chats
  Future<void> getChats() async {
    emit(ChatLoading());
    try {
      final chats = await _repository.getChats();
      emit(ChatsLoaded(chats));
    } catch (e) {
      emit(ChatError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Get chat details
  Future<void> getChatDetails(int chatId) async {
    emit(ChatLoading());
    try {
      final chat = await _repository.getChatDetails(chatId);
      emit(ChatDetailsLoaded(chat));
    } catch (e) {
      emit(ChatError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Get chat messages
  Future<void> getChatMessages({
    required int chatId,
    int page = 1,
  }) async {
    try {
      final response = await _repository.getChatMessages(
        chatId: chatId,
        page: page,
      );
      
      final data = response['data'] as List? ?? [];
      final currentPage = response['current_page'] as int? ?? 1;
      final lastPage = response['last_page'] as int? ?? 1;
      
      emit(MessagesLoaded(
        messages: List<Map<String, dynamic>>.from(data),
        currentPage: currentPage,
        lastPage: lastPage,
      ));
    } catch (e) {
      emit(ChatError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Send message
  Future<void> sendMessage({
    required int chatId,
    required String body,
  }) async {
    try {
      final message = await _repository.sendMessage(
        chatId: chatId,
        body: body,
      );
      emit(MessageSent(message));
      // Reload messages after sending
      await getChatMessages(chatId: chatId);
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      
      // If error suggests message might have been sent (server logging issue),
      // reload messages to check if it was actually created
      if (errorMessage.contains('تم إرسال الرسالة ولكن حدث خطأ في السيرفر')) {
        // Wait a bit for server to process, then reload messages
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          await getChatMessages(chatId: chatId);
          // If reload successful, don't show error - message was likely sent
          return;
        } catch (_) {
          // If reload fails, show the error
        }
      }
      
      emit(ChatError(errorMessage));
    }
  }

  /// Mark chat as read
  Future<void> markAsRead(int chatId) async {
    await _repository.markChatAsRead(chatId);
  }
}

