import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/enums/language.dart';
import '../application/chat_repository.dart';
import '../domain/chat.dart';

/// Keeps chats in `chat_store.json` in the app's documents folder, beside
/// `correction_store.json` and `learner_profile.json` (decision B3, point 7).
///
/// Follows `FileProfileRepository`: the whole store is read and written as
/// one indented JSON file, a missing or blank file reads as an empty store,
/// and a file that cannot be parsed is treated as empty rather than stopping
/// the app. Everything stays on the phone (decision E3).
///
/// Changes are made one at a time, in the order they were asked for, so a
/// message saved while the partner's reply is being saved cannot be lost.
class FileChatRepository implements ChatRepository {
  FileChatRepository({File? file, DateTime Function()? now})
    : _file = file,
      _now = now ?? DateTime.now;

  static const fileName = 'chat_store.json';

  final File? _file;
  final DateTime Function() _now;

  Future<void> _lastChange = Future<void>.value();

  @override
  Future<List<Chat>> getChats({Language? language}) async {
    await _lastChange;
    final state = await _readState();
    return List.unmodifiable(
      state.chats.where(
        (chat) => language == null || chat.language == language,
      ),
    );
  }

  @override
  Future<Chat?> getChat(String id) async {
    await _lastChange;
    final state = await _readState();
    for (final chat in state.chats) {
      if (chat.id == id) {
        return chat;
      }
    }
    return null;
  }

  @override
  Future<ChatSaveResult> saveChat(Chat chat) {
    if (!chat.hasLearnerTurn) {
      return Future.value(const ChatSaveResult(stored: false));
    }

    return _change((state) {
      final chats = _newestFirst([
        chat,
        ...state.chats.where((stored) => stored.id != chat.id),
      ]);

      // The chat being saved is never the one deleted, even if it is handed
      // over with an old last-changed time.
      final removed = <Chat>[];
      while (chats.length > ChatRepository.maxChats) {
        final index = chats.lastIndexWhere((stored) => stored.id != chat.id);
        removed.add(chats.removeAt(index));
      }

      final deletedAt = _now();
      final removedIds = {for (final gone in removed) gone.id};
      final deleted = [
        for (final gone in removed.reversed)
          DeletedChatSummary.of(gone, deletedAt: deletedAt),
        ...state.deleted.where((record) => !removedIds.contains(record.chatId)),
      ].take(ChatRepository.maxDeletedSummaries).toList();

      return (
        _ChatStoreState(chats: chats, deleted: deleted),
        ChatSaveResult(stored: true, removed: List.unmodifiable(removed)),
      );
    });
  }

  @override
  Future<List<DeletedChatSummary>> getDeletedChatSummaries({
    Language? language,
  }) async {
    await _lastChange;
    final state = await _readState();
    return List.unmodifiable(
      state.deleted.where(
        (record) => language == null || record.language == language,
      ),
    );
  }

  @override
  Future<void> setDeletedChatSummary(String chatId, String summary) {
    return _change((state) {
      final deleted = [
        for (final record in state.deleted)
          record.chatId == chatId ? record.withSummary(summary) : record,
      ];
      return (_ChatStoreState(chats: state.chats, deleted: deleted), null);
    });
  }

  @override
  Future<void> clear() {
    return _change((state) => (const _ChatStoreState.empty(), null));
  }

  /// Reads the store, applies [change], writes the result and returns what
  /// [change] reported, after every earlier change has finished.
  Future<T> _change<T>(
    (_ChatStoreState, T) Function(_ChatStoreState state) change,
  ) {
    final result = _lastChange.then((_) async {
      final (next, value) = change(await _readState());
      await _writeState(next);
      return value;
    });
    // A failed change must not block the ones after it.
    _lastChange = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  Future<_ChatStoreState> _readState() async {
    final file = await _resolveFile();
    if (!await file.exists()) {
      return const _ChatStoreState.empty();
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return const _ChatStoreState.empty();
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException catch (error) {
      debugPrint('Chat file could not be read, starting empty: $error');
      return const _ChatStoreState.empty();
    }
    if (decoded is! Map<String, Object?>) {
      return const _ChatStoreState.empty();
    }

    return _ChatStoreState.fromJson(decoded);
  }

  Future<void> _writeState(_ChatStoreState state) async {
    final file = await _resolveFile();
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(state.toJson()));
  }

  Future<File> _resolveFile() async {
    if (_file != null) {
      return _file;
    }

    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }
}

/// Most recently changed first. Chats changed at the same moment keep the
/// order they were given in.
List<Chat> _newestFirst(List<Chat> chats) {
  final indexed = chats.indexed.toList()
    ..sort((a, b) {
      final byTime = b.$2.updatedAt.compareTo(a.$2.updatedAt);
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  return [for (final (_, chat) in indexed) chat];
}

class _ChatStoreState {
  const _ChatStoreState({required this.chats, required this.deleted});

  const _ChatStoreState.empty() : chats = const [], deleted = const [];

  factory _ChatStoreState.fromJson(Map<String, Object?> json) {
    final rawChats = json['chats'];
    final rawDeleted = json['deletedChats'];
    final chats = <Chat>[
      if (rawChats is List)
        for (final chat in rawChats)
          if (chat is Map<String, Object?>) Chat.fromJson(chat),
    ];
    final deleted = <DeletedChatSummary>[
      if (rawDeleted is List)
        for (final record in rawDeleted)
          if (record is Map<String, Object?>)
            DeletedChatSummary.fromJson(record),
    ];
    return _ChatStoreState(
      chats: _newestFirst(
        chats.where((chat) => chat.id.isNotEmpty).toList(),
      ).take(ChatRepository.maxChats).toList(),
      deleted: deleted
          .where((record) => record.chatId.isNotEmpty)
          .take(ChatRepository.maxDeletedSummaries)
          .toList(),
    );
  }

  /// Most recently changed first.
  final List<Chat> chats;

  /// Newest deletion first.
  final List<DeletedChatSummary> deleted;

  Map<String, Object?> toJson() => {
    'chats': [for (final chat in chats) chat.toJson()],
    'deletedChats': [for (final record in deleted) record.toJson()],
  };
}
