import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/core/enums/language.dart';
import 'package:spanish_correction_app/features/conversation/domain/chat.dart';
import 'package:spanish_correction_app/features/corrections/domain/correction_input_mode.dart';

void main() {
  final monday = DateTime(2026, 11, 23, 18, 30);

  Chat newChat() =>
      Chat.startedByLearner(id: 'c1', language: Language.spanish, now: monday);

  group('a new chat', () {
    test('is empty, started by the learner, with no title', () {
      final chat = newChat();

      expect(chat.turns, isEmpty);
      expect(chat.title, '');
      expect(chat.startedBy, ChatStarter.learner);
      expect(chat.kind, ChatKind.newChat);
      expect(chat.hasEnded, isFalse);
      expect(chat.exchangeCount, 0);
      expect(chat.checkedTurnCount, 0);
      expect(chat.hasLearnerTurn, isFalse);
      expect(chat.lastTurn, isNull);
      expect(chat.createdAt, monday);
      expect(chat.updatedAt, monday);
    });
  });

  group('messages', () {
    test('a learner message is typed unless marked spoken', () {
      final typed = ChatTurn.learner(text: 'Hola', sentAt: monday);
      final spoken = ChatTurn.learner(
        text: 'Hola',
        sentAt: monday,
        input: CorrectionInputMode.spoken,
      );

      expect(typed.input, CorrectionInputMode.typed);
      expect(typed.isSpoken, isFalse);
      expect(spoken.isSpoken, isTrue);
    });

    test('a partner message is neither typed nor spoken', () {
      final turn = ChatTurn.partner(text: '¡Hola!', sentAt: monday);

      expect(turn.isLearner, isFalse);
      expect(turn.input, isNull);
    });

    test('adding a message moves the last-changed time to its time', () {
      final later = monday.add(const Duration(minutes: 5));
      final chat = newChat().withTurn(
        ChatTurn.learner(text: 'Hola', sentAt: later),
      );

      expect(chat.turns, hasLength(1));
      expect(chat.updatedAt, later);
      expect(chat.createdAt, monday);
      expect(chat.hasLearnerTurn, isTrue);
      expect(chat.lastTurn!.text, 'Hola');
    });

    test('the exchange count is the number of learner messages', () {
      var chat = newChat();
      for (var i = 0; i < 3; i++) {
        chat = chat
            .withTurn(ChatTurn.learner(text: 'Mensaje $i', sentAt: monday))
            .withTurn(ChatTurn.partner(text: 'Respuesta $i', sentAt: monday));
      }

      expect(chat.turns, hasLength(6));
      expect(chat.exchangeCount, 3);
    });

    test('a chat the partner started has no learner message yet', () {
      final chat = Chat(
        id: 'c2',
        language: Language.spanish,
        createdAt: monday,
        startedBy: ChatStarter.partner,
        kind: ChatKind.checkIn,
        turns: [ChatTurn.partner(text: '¡Hola! ¿Qué tal?', sentAt: monday)],
      );

      expect(chat.hasLearnerTurn, isFalse);
      expect(chat.exchangeCount, 0);
    });

    test('the list of messages cannot be changed from outside', () {
      final chat = newChat().withTurn(
        ChatTurn.learner(text: 'Hola', sentAt: monday),
      );

      expect(
        () => chat.turns.add(ChatTurn.partner(text: 'x', sentAt: monday)),
        throwsUnsupportedError,
      );
    });
  });

  group('title, ending and checking', () {
    test('setting the title trims it and keeps the last-changed time', () {
      final chat = newChat().withTitle('  Planes para el finde ');

      expect(chat.title, 'Planes para el finde');
      expect(chat.updatedAt, monday);
    });

    test('ending a chat marks it ended', () {
      final later = monday.add(const Duration(hours: 1));
      final chat = newChat().ended(now: later);

      expect(chat.hasEnded, isTrue);
      expect(chat.updatedAt, later);
    });

    test('how far the chat has been checked', () {
      var chat = newChat()
          .withTurn(ChatTurn.learner(text: 'Uno', sentAt: monday))
          .withTurn(ChatTurn.partner(text: 'Dos', sentAt: monday));
      expect(chat.uncheckedTurns, hasLength(2));

      chat = chat.withAllTurnsChecked();
      expect(chat.checkedTurnCount, 2);
      expect(chat.uncheckedTurns, isEmpty);

      chat = chat.withTurn(ChatTurn.learner(text: 'Tres', sentAt: monday));
      expect(chat.checkedTurnCount, 2);
      expect(chat.uncheckedTurns.single.text, 'Tres');
    });

    test('the checked count never runs past the messages', () {
      final chat = Chat(
        id: 'c3',
        language: Language.spanish,
        createdAt: monday,
        checkedTurnCount: 7,
      );

      expect(chat.checkedTurnCount, 0);
    });
  });

  group('reading and writing', () {
    test('a chat comes back from JSON as it went in', () {
      final tuesday = monday.add(const Duration(days: 1));
      final chat = Chat(
        id: 'c4',
        title: 'El partido de ayer',
        language: Language.spanish,
        createdAt: monday,
        updatedAt: tuesday,
        startedBy: ChatStarter.partner,
        kind: ChatKind.followUp,
        turns: [
          ChatTurn.partner(text: 'El otro día me contaste…', sentAt: monday),
          ChatTurn.learner(
            text: 'Sí, fuimos al estadio',
            sentAt: tuesday,
            input: CorrectionInputMode.spoken,
          ),
        ],
        hasEnded: true,
        checkedTurnCount: 1,
      );

      final json = chat.toJson();
      final back = Chat.fromJson(json);

      expect(json['exchangeCount'], 1);
      expect(back.id, 'c4');
      expect(back.title, 'El partido de ayer');
      expect(back.language, Language.spanish);
      expect(back.createdAt, monday);
      expect(back.updatedAt, tuesday);
      expect(back.startedBy, ChatStarter.partner);
      expect(back.kind, ChatKind.followUp);
      expect(back.hasEnded, isTrue);
      expect(back.checkedTurnCount, 1);
      expect(back.exchangeCount, 1);
      expect(back.turns, hasLength(2));
      expect(back.turns[0].speaker, ChatSpeaker.partner);
      expect(back.turns[0].input, isNull);
      expect(back.turns[1].isSpoken, isTrue);
      expect(back.turns[1].sentAt, tuesday);
    });

    test('missing fields read as a plain learner-started chat', () {
      final chat = Chat.fromJson({
        'id': 'c5',
        'createdAt': monday.toIso8601String(),
      });

      expect(chat.title, '');
      expect(chat.language, Language.spanish);
      expect(chat.startedBy, ChatStarter.learner);
      expect(chat.kind, ChatKind.newChat);
      expect(chat.turns, isEmpty);
      expect(chat.hasEnded, isFalse);
      expect(chat.updatedAt, monday);
    });

    test('a deleted chat record keeps the title and dates', () {
      final tuesday = monday.add(const Duration(days: 1));
      final wednesday = monday.add(const Duration(days: 2));
      final chat = newChat()
          .withTitle('La mudanza')
          .withTurn(ChatTurn.learner(text: 'Hola', sentAt: tuesday));

      final record = DeletedChatSummary.of(chat, deletedAt: wednesday);
      expect(record.chatId, 'c1');
      expect(record.title, 'La mudanza');
      expect(record.createdAt, monday);
      expect(record.lastActiveAt, tuesday);
      expect(record.deletedAt, wednesday);
      expect(record.hasSummary, isFalse);

      final back = DeletedChatSummary.fromJson(
        record.withSummary(' Talked about moving flat. ').toJson(),
      );
      expect(back.summary, 'Talked about moving flat.');
      expect(back.hasSummary, isTrue);
      expect(back.deletedAt, wednesday);
    });
  });
}
