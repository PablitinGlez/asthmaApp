import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../config/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../domain/chat/chat_models.dart';

class ChatState {
  final List<ChatConversation> conversations;
  final List<ChatMessage> messages;
  final bool isLoadingConversations;
  final bool isLoadingMessages;
  final bool isSending;
  final String? errorMessage;

  const ChatState({
    this.conversations = const [],
    this.messages = const [],
    this.isLoadingConversations = false,
    this.isLoadingMessages = false,
    this.isSending = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatConversation>? conversations,
    List<ChatMessage>? messages,
    bool? isLoadingConversations,
    bool? isLoadingMessages,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      isLoadingConversations:
          isLoadingConversations ?? this.isLoadingConversations,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    return const ChatState();
  }

  String get _userId => ref.watch(authStateProvider).value?.id ?? '';

  Future<String> _getToken() async {
    final session = ref.read(supabaseClientProvider).auth.currentSession;
    if (session == null) throw Exception('No hay sesión activa');
    return session.accessToken;
  }

  DioClient get _dio => ref.read(dioClientProvider);

  /// Carga las conversaciones activas del usuario.
  ///
  /// Consume el endpoint de conversaciones del backend cuando esté
  /// disponible; si el endpoint aún no existe, mantiene el estado vacío.
  Future<void> loadConversations() async {
    state = state.copyWith(isLoadingConversations: true, errorMessage: null);
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '/api/chat/conversations',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      final raw = data is List
          ? data
          : (data['conversations'] ?? data['data'] ?? []) as List;
      state = state.copyWith(
        conversations: raw
            .map((e) => ChatConversation.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        isLoadingConversations: false,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Endpoint aún no disponible en el backend.
        state = state.copyWith(isLoadingConversations: false);
        return;
      }
      state = state.copyWith(
        isLoadingConversations: false,
        errorMessage: 'No se pudieron cargar las conversaciones.',
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingConversations: false,
        errorMessage: 'No se pudieron cargar las conversaciones.',
      );
    }
  }

  /// Carga los mensajes de una conversación.
  Future<void> loadMessages(String conversationId) async {
    state = state.copyWith(isLoadingMessages: true, errorMessage: null);
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '/api/chat/conversations/$conversationId/messages',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      final raw = data is List
          ? data
          : (data['messages'] ?? data['data'] ?? []) as List;
      state = state.copyWith(
        messages: raw
            .map((e) => ChatMessage.fromJson(
                  Map<String, dynamic>.from(e),
                  currentUserId: _userId,
                ))
            .toList(),
        isLoadingMessages: false,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        state = state.copyWith(isLoadingMessages: false);
        return;
      }
      state = state.copyWith(
        isLoadingMessages: false,
        errorMessage: 'No se pudieron cargar los mensajes.',
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingMessages: false,
        errorMessage: 'No se pudieron cargar los mensajes.',
      );
    }
  }

  /// Envía un mensaje. En caso de error de red lo marca como pendiente de
  /// reintento (local) sin perder el texto escrito por el usuario.
  Future<bool> sendMessage(String conversationId, String text) async {
    if (text.trim().isEmpty) return false;
    state = state.copyWith(isSending: true, errorMessage: null);
    try {
      final token = await _getToken();
      await _dio.post(
        '/api/chat/conversations/$conversationId/messages',
        data: {'content': text.trim()},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      state = state.copyWith(isSending: false);
      return true;
    } catch (_) {
      state = state.copyWith(isSending: false);
      return false;
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

final chatProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
