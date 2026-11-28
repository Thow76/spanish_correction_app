import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/conversation/application/chat_repository.dart';
import 'package:spanish_correction_app/features/conversation/data/file_chat_repository.dart';
import 'package:spanish_correction_app/features/conversation/domain/chat.dart';

void main() {
  late Directory tempDirectory;
  late File file;
  late FileChatRepository repository;
  late DateTime clock;

  final start = DateTime(2026, 11, 23, 9);

  /// A chat with one learner message, last changed [day] days after [start].
  Chat chatOn(int day, {String? id, Language language = Language.spanish}) {
    final when = start.add(Duration(days: day));
    return Chat(
      id: id ?? 'chat-$day',
      title: 'Chat $day',
      language: language,
      createdAt: when,
    ).withTurn(ChatTurn.learner(text: 'Hola $day', sentAt: when));
  }

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'chat_repository_test_',
    );
    file = File('${tempDirectory.path}/${FileChatRepository.fileName}');
    clock = start.add(const Duration(days: 30));
    repository = FileChatRepository(file: file, now: () => clock);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('the file is named chat_store.json', () {
    expect(FileChatRepository.fileName, 'chat_store.json');
  });

  test('the limits are five chats and five summaries', () {
    expect(ChatRepository.maxChats, 5);
    expect(ChatRepository.maxDeletedSummaries, 5);
  });

  test('reads nothing when there is no file yet', () async {
    expect(await repository.getChats(), isEmpty);
    expect(await repository.getDeletedChatSummaries(), isEmpty);
    expect(await repository.getChat('nope'), isNull);
    expect(await file.exists(), isFalse);
  });

  test('an empty New chat is not stored', () async {
    final empty = Chat.startedByLearner(
      id: 'empty',
      language: Language.spanish,
      now: start,
    );

    final result = await repository.saveChat(empty);

    expect(result.stored, isFalse);
    expect(result.removed, isEmpty);
    expect(await repository.getChats(), isEmpty);
    expect(await file.exists(), isFalse);
  });

  test('a chat with only a partner message is not stored', () async {
    final greeting = Chat(
      id: 'greeting',
      language: Language.spanish,
      createdAt: start,
      startedBy: ChatStarter.partner,
      kind: ChatKind.checkIn,
      turns: [ChatTurn.partner(text: '¡Hola! ¿Qué tal?', sentAt: start)],
    );

    expect((await repository.saveChat(greeting)).stored, isFalse);
    expect(await repository.getChats(), isEmpty);
  });

  test('a chat is stored once the learner has sent something', () async {
    final result = await repository.saveChat(chatOn(0));

    expect(result.stored, isTrue);
    expect(result.removed, isEmpty);

    final stored = await repository.getChat('chat-0');
    expect(stored, isNotNull);
    expect(stored!.title, 'Chat 0');
    expect(stored.turns.single.text, 'Hola 0');
  });

  test('a new repository reads what an earlier one wrote', () async {
    await repository.saveChat(chatOn(0));

    final reopened = FileChatRepository(file: file);
    expect((await reopened.getChats()).single.id, 'chat-0');
  });

  test('saving a chat again replaces it rather than adding one', () async {
    await repository.saveChat(chatOn(0));
    final longer = (await repository.getChat('chat-0'))!.withTurn(
      ChatTurn.partner(
        text: '¡Hola!',
        sentAt: start.add(const Duration(minutes: 1)),
      ),
    );
    await repository.saveChat(longer);

    final chats = await repository.getChats();
    expect(chats, hasLength(1));
    expect(chats.single.turns, hasLength(2));
  });

  test('chats are listed most recently changed first', () async {
    await repository.saveChat(chatOn(1));
    await repository.saveChat(chatOn(3));
    await repository.saveChat(chatOn(2));

    expect((await repository.getChats()).map((chat) => chat.id), [
      'chat-3',
      'chat-2',
      'chat-1',
    ]);

    // Picking up the oldest chat again moves it to the top.
    final pickedUp = (await repository.getChat('chat-1'))!.withTurn(
      ChatTurn.learner(
        text: 'Otra vez',
        sentAt: start.add(const Duration(days: 4)),
      ),
    );
    await repository.saveChat(pickedUp);

    expect((await repository.getChats()).first.id, 'chat-1');
  });

  test('chats can be listed for one language', () async {
    await repository.saveChat(chatOn(1));
    await repository.saveChat(chatOn(2, language: Language.portuguese));

    final spanish = await repository.getChats(language: Language.spanish);
    expect(spanish.single.id, 'chat-1');
  });

  test('five chats are kept', () async {
    for (var day = 0; day < 5; day++) {
      final result = await repository.saveChat(chatOn(day));
      expect(result.removed, isEmpty);
    }

    expect(await repository.getChats(), hasLength(5));
    expect(await repository.getDeletedChatSummaries(), isEmpty);
  });

  test('a sixth chat deletes the oldest without asking', () async {
    for (var day = 0; day < 5; day++) {
      await repository.saveChat(chatOn(day));
    }

    final result = await repository.saveChat(chatOn(5));

    expect(result.stored, isTrue);
    expect(result.removed.single.id, 'chat-0');
    final chats = await repository.getChats();
    expect(chats.map((chat) => chat.id), [
      'chat-5',
      'chat-4',
      'chat-3',
      'chat-2',
      'chat-1',
    ]);
    expect(await repository.getChat('chat-0'), isNull);
  });

  test('the oldest is the one longest without a change', () async {
    for (var day = 0; day < 5; day++) {
      await repository.saveChat(chatOn(day));
    }
    // The first chat is picked up again, so the second is now the oldest.
    await repository.saveChat(
      (await repository.getChat('chat-0'))!.withTurn(
        ChatTurn.learner(
          text: 'Sigo aquí',
          sentAt: start.add(const Duration(days: 6)),
        ),
      ),
    );

    final result = await repository.saveChat(chatOn(7));

    expect(result.removed.single.id, 'chat-1');
    expect(await repository.getChat('chat-0'), isNotNull);
  });

  test('the chat being saved is never the one deleted', () async {
    for (var day = 1; day <= 5; day++) {
      await repository.saveChat(chatOn(day));
    }

    final result = await repository.saveChat(chatOn(0));

    expect(result.removed.single.id, 'chat-1');
    expect(await repository.getChat('chat-0'), isNotNull);
  });

  test('a deleted chat leaves a record with an empty summary', () async {
    for (var day = 0; day < 6; day++) {
      await repository.saveChat(chatOn(day));
    }

    final record = (await repository.getDeletedChatSummaries()).single;
    expect(record.chatId, 'chat-0');
    expect(record.title, 'Chat 0');
    expect(record.lastActiveAt, start);
    expect(record.deletedAt, clock);
    expect(record.hasSummary, isFalse);
  });

  test('the summary of a deleted chat can be filled in later', () async {
    for (var day = 0; day < 6; day++) {
      await repository.saveChat(chatOn(day));
    }

    await repository.setDeletedChatSummary('chat-0', 'Talked about work.');

    final record = (await repository.getDeletedChatSummaries()).single;
    expect(record.summary, 'Talked about work.');
    expect(await repository.getChats(), hasLength(5));
  });

  test('a summary for a chat with no record changes nothing', () async {
    await repository.saveChat(chatOn(0));

    await repository.setDeletedChatSummary('unknown', 'Something.');

    expect(await repository.getDeletedChatSummaries(), isEmpty);
    expect(await repository.getChats(), hasLength(1));
  });

  test('only the five most recently deleted chats keep a record', () async {
    for (var day = 0; day < 11; day++) {
      clock = start.add(Duration(days: 30 + day));
      await repository.saveChat(chatOn(day));
    }

    final records = await repository.getDeletedChatSummaries();
    expect(records.map((record) => record.chatId), [
      'chat-5',
      'chat-4',
      'chat-3',
      'chat-2',
      'chat-1',
    ]);
    expect(await repository.getChats(), hasLength(5));
  });

  test('changes asked for together are all kept', () async {
    await Future.wait([
      for (var day = 0; day < 5; day++) repository.saveChat(chatOn(day)),
    ]);

    expect(await repository.getChats(), hasLength(5));
  });

  test('a file that cannot be read is treated as empty', () async {
    await file.writeAsString('{ this is not json');

    expect(await repository.getChats(), isEmpty);

    await repository.saveChat(chatOn(0));
    expect((await repository.getChats()).single.id, 'chat-0');
  });

  test('a blank file is treated as empty', () async {
    await file.writeAsString('   \n');

    expect(await repository.getChats(), isEmpty);
  });

  test('the file is indented JSON with chats and deleted chats', () async {
    await repository.saveChat(chatOn(0));

    final content = await file.readAsString();
    final decoded = jsonDecode(content) as Map<String, Object?>;
    expect(content, contains('\n  '));
    expect(decoded.keys, containsAll(['chats', 'deletedChats']));
    expect((decoded['chats'] as List).single, containsPair('id', 'chat-0'));
  });

  test('clear empties the store', () async {
    for (var day = 0; day < 6; day++) {
      await repository.saveChat(chatOn(day));
    }

    await repository.clear();

    expect(await repository.getChats(), isEmpty);
    expect(await repository.getDeletedChatSummaries(), isEmpty);
  });
}
