import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  /// Si [embedded] es true se renderiza sin Scaffold ni AppBar propios,
  /// para poder incrustarse como tab dentro de la HomeScreen.
  final bool embedded;

  const ChatListScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        ref.read(chatProvider.notifier).loadConversations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final user = ref.watch(authStateProvider).value;
    final userName = user?.fullName.split(' ').first ?? 'Usuario';

    final Widget body = Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          color: const Color(0xFFF0F7FF),
          child: Text(
            'Hola, $userName. Conversa con tu médico sobre tu tratamiento y tus mediciones.',
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 13,
              color: const Color(0xFF023E8A).withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ),
        Expanded(
          child: chat.isLoadingConversations
              ? const Center(child: CircularProgressIndicator())
              : chat.conversations.isEmpty
                  ? _EmptyState(hasError: chat.errorMessage != null)
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(chatProvider.notifier)
                          .loadConversations(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: chat.conversations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final conv = chat.conversations[index];
                          return _ConversationTile(conversation: conv);
                        },
                      ),
                    ),
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Mensajes',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Satoshi',
          ),
        ),
        centerTitle: true,
      ),
      body: body,
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final dynamic conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = conversation.participantName;
    final unread = conversation.unreadCount;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFF023E8A).withOpacity(0.12),
        child: Icon(
          conversation.isDoctor ? Icons.medical_services_outlined : Icons.person_outline,
          color: const Color(0xFF023E8A),
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontFamily: 'Satoshi',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          conversation.lastMessage ?? 'Sin mensajes aún',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 13,
            color: unread > 0
                ? Colors.black87
                : Colors.grey.shade600,
            fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
      trailing: unread > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD90429),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: () => context.push(
        '/chat/${conversation.id}',
        extra: conversation,
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  final bool hasError;
  const _EmptyState({required this.hasError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasError ? Icons.wifi_off_rounded : Icons.chat_bubble_outline_rounded,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            hasError
                ? 'No se pudieron cargar tus conversaciones.'
                : 'Aún no tienes conversaciones.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  ref.read(chatProvider.notifier).loadConversations(),
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Color(0xFF023E8A)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
