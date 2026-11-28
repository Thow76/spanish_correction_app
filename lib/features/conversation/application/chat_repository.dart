import '../../../core/enums/language.dart';
import '../domain/chat.dart';

/// What happened when a chat was handed to [ChatRepository.saveChat].
class ChatSaveResult {
  const ChatSaveResult({required this.stored, this.removed = const []});

  /// False when the chat was not stored because the learner has not sent
  /// anything in it yet.
  final bool stored;

  /// Chats deleted to make room, oldest first. Empty unless this save took
  /// the store past its limit. Each one already has a record in
  /// [ChatRepository.getDeletedChatSummaries] with an empty summary; the
  /// caller asks the partner for the summary and hands it to
  /// [ChatRepository.setDeletedChatSummary].
  final List<Chat> removed;
}

/// Where chats are kept (decision B3, point 7; build step 3.2).
///
/// The store holds up to [maxChats] chats. Storing one more deletes the one
/// that has gone longest without a change, without asking. It also keeps
/// short summaries of the [maxDeletedSummaries] most recently deleted chats.
abstract interface class ChatRepository {
  /// How many chats the store holds (decision B3).
  static const maxChats = 5;

  /// How many deleted chats keep a summary (decision B3).
  static const maxDeletedSummaries = 5;

  /// The stored chats, most recently changed first.
  Future<List<Chat>> getChats({Language? language});

  /// The stored chat with this id, or null if there is none.
  Future<Chat?> getChat(String id);

  /// Stores [chat], replacing any stored chat with the same id.
  ///
  /// A chat in which the learner has sent nothing is not stored. If the
  /// store would then hold more than [maxChats], the chats that have gone
  /// longest without a change are deleted and returned in the result.
  Future<ChatSaveResult> saveChat(Chat chat);

  /// The records of the most recently deleted chats, newest deletion first.
  Future<List<DeletedChatSummary>> getDeletedChatSummaries({
    Language? language,
  });

  /// Fills in the partner's summary for a deleted chat. Does nothing if the
  /// record is no longer kept.
  Future<void> setDeletedChatSummary(String chatId, String summary);

  /// Empties the store. Nothing in the app calls this yet; it exists for
  /// tests and for a future reset.
  Future<void> clear();
}
