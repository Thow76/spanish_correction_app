import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';
import 'package:spanish_correction_app/core/services/prompts/partner_prompt.dart';
import 'package:spanish_correction_app/features/conversation/data/partner_client.dart';
import 'package:spanish_correction_app/features/corrections/data/openai_chat_completions_client.dart';

/// One recorded call to the pretend service.
class _Call {
  _Call(
    this.model,
    this.systemPrompt,
    this.messages,
    this.stageLabel,
    this.responseFormat,
  );
  final String model;
  final String systemPrompt;
  final List<ChatCompletionsMessage> messages;
  final String stageLabel;
  final Map<String, Object?>? responseFormat;
}

/// A partner whose service answers every call with [reply].
(PartnerClient, List<_Call>) _partner(String reply, {String? model}) {
  final calls = <_Call>[];
  Future<String> call({
    required String model,
    required String systemPrompt,
    required List<ChatCompletionsMessage> messages,
    String stageLabel = 'unspecified',
    Map<String, Object?>? responseFormat,
  }) async {
    calls.add(_Call(model, systemPrompt, messages, stageLabel, responseFormat));
    return reply;
  }

  final client = model == null
      ? PartnerClient(call: call)
      : PartnerClient(call: call, model: model);
  return (client, calls);
}

/// A chat of [exchanges] learner messages, each but the last answered.
List<PartnerMessage> _chat(int exchanges) => [
  for (var i = 1; i <= exchanges; i++) ...[
    PartnerMessage.learner('Mensaje $i'),
    if (i < exchanges) PartnerMessage.partner('Respuesta $i'),
  ],
];

String _label(String title, String summary) =>
    jsonEncode({'title': title, 'summary': summary});

void main() {
  group('the model', () {
    test('is GPT-6 Luna unless another is named', () {
      final (client, _) = _partner('Hola');

      expect(AppConfig.defaultPartnerModel, 'gpt-6-luna');
      expect(client.model, 'gpt-6-luna');
      expect(AppConfig.fromEnvironment().openAiPartnerModel, 'gpt-6-luna');
    });

    test('every kind of call uses the one model', () async {
      final (client, calls) = _partner(
        _label('Un título', 'A summary.'),
        model: 'gpt-6-sol',
      );

      await client.reply(_chat(1));
      await client.reply(_chat(1), atSizeLimit: true);
      await client.writeTitle(_chat(2));
      await client.writeSummary(_chat(2));

      expect(calls.map((call) => call.model).toSet(), {'gpt-6-sol'});
    });
  });

  group('a reply', () {
    test(
      'sends the whole current chat, in order, with each side\'s role',
      () async {
        final (client, calls) = _partner('¡Qué bien!');

        final reply = await client.reply([
          const PartnerMessage.partner('¡Hola! ¿Qué tal?'),
          const PartnerMessage.learner('Bien, he ido al mercado.'),
          const PartnerMessage.partner('¿Qué has comprado?'),
          const PartnerMessage.learner('Fruta y pan.'),
        ]);

        expect(reply, '¡Qué bien!');
        final call = calls.single;
        expect(call.messages.map((m) => (m.role, m.content)), [
          ('assistant', '¡Hola! ¿Qué tal?'),
          ('user', 'Bien, he ido al mercado.'),
          ('assistant', '¿Qué has comprado?'),
          ('user', 'Fruta y pan.'),
        ]);
        expect(call.stageLabel, 'partner_reply');
        expect(call.responseFormat, isNull);
      },
    );

    test('is one call, with the standing instructions', () async {
      final (client, calls) = _partner('Vale.');

      await client.reply(_chat(3));

      expect(calls, hasLength(1));
      expect(calls.single.systemPrompt, partnerBasePrompt);
    });

    test('the reply is trimmed', () async {
      final (client, _) = _partner('  Claro que sí.\n');

      expect(await client.reply(_chat(1)), 'Claro que sí.');
    });

    test('the missing-words setting chooses the line sent', () async {
      final (client, calls) = _partner('Vale.');

      await client.reply(_chat(1));
      await client.reply(_chat(1), missingWords: false);

      expect(calls[0].systemPrompt, contains(missingWordsOnLine));
      expect(calls[0].systemPrompt, isNot(contains(missingWordsOffLine)));
      expect(calls[1].systemPrompt, contains(missingWordsOffLine));
      expect(calls[1].systemPrompt, isNot(contains(missingWordsOnLine)));
    });

    test('the ninth message gets no goodbye line', () async {
      final (client, calls) = _partner('Vale.');

      await client.reply(_chat(softGoodbyeExchange - 1));

      expect(calls.single.systemPrompt, partnerBasePrompt);
    });

    test('the tenth message gets the soft goodbye line', () async {
      final (client, calls) = _partner('¡Hasta pronto!');

      await client.reply(_chat(softGoodbyeExchange));

      expect(calls.single.systemPrompt, partnerBasePrompt + softGoodbyeNote);
    });

    test('after the goodbye the partner is told to answer briefly', () async {
      final (client, calls) = _partner('Sí.');

      await client.reply(_chat(softGoodbyeExchange + 1));

      expect(calls.single.systemPrompt, partnerBasePrompt + afterGoodbyeNote);
    });

    test('at the size limit the partner is told to sign off', () async {
      final (client, calls) = _partner('Ha sido un placer.');

      await client.reply(_chat(4), atSizeLimit: true);

      expect(calls.single.systemPrompt, partnerBasePrompt + sizeLimitNote);
      expect(calls.single.stageLabel, 'partner_sign_off');
    });

    test('the size limit wins over the soft goodbye', () async {
      final (client, calls) = _partner('Ha sido un placer.');

      await client.reply(_chat(softGoodbyeExchange), atSizeLimit: true);

      expect(calls.single.systemPrompt, partnerBasePrompt + sizeLimitNote);
    });

    test('needs the newest message to be the learner\'s', () async {
      final (client, calls) = _partner('Hola');

      expect(() => client.reply(const []), throwsArgumentError);
      expect(
        () => client.reply(const [PartnerMessage.partner('¡Hola!')]),
        throwsArgumentError,
      );
      expect(calls, isEmpty);
    });

    test('a failed call is passed on, not hidden', () async {
      final client = PartnerClient(
        call:
            ({
              required String model,
              required String systemPrompt,
              required List<ChatCompletionsMessage> messages,
              String stageLabel = 'unspecified',
              Map<String, Object?>? responseFormat,
            }) async => throw const ChatCompletionsException(
              'No internet available',
              kind: ChatCompletionsFailureKind.connectivity,
            ),
      );

      await expectLater(
        client.reply(_chat(1)),
        throwsA(
          isA<ChatCompletionsException>().having(
            (error) => error.kind,
            'kind',
            ChatCompletionsFailureKind.connectivity,
          ),
        ),
      );
    });
  });

  group('the title and the summary', () {
    test('are asked for with their own instructions and reply shape', () async {
      final (client, calls) = _partner(
        _label('Planes para el finde', 'They plan a trip to the coast.'),
      );

      final label = await client.label(_chat(2));

      expect(label.title, 'Planes para el finde');
      expect(label.summary, 'They plan a trip to the coast.');
      final call = calls.single;
      expect(call.systemPrompt, titleSummaryPrompt);
      expect(call.responseFormat, titleSummaryResponseFormat());
      expect(call.stageLabel, 'partner_title_summary');
      expect(call.messages.single.role, 'user');
      expect(
        call.messages.single.content,
        'Learner: Mensaje 1\nPartner: Respuesta 1\nLearner: Mensaje 2',
      );
    });

    test('the title is written from the first exchange only', () async {
      final (client, calls) = _partner(_label('El mercado', 'Shopping.'));

      final title = await client.writeTitle([
        const PartnerMessage.learner('He ido al mercado.'),
        const PartnerMessage.partner('¿Qué has comprado?'),
        const PartnerMessage.learner('Fruta y pan.'),
        const PartnerMessage.partner('Me encanta el pan recién hecho.'),
      ]);

      expect(title, 'El mercado');
      expect(
        calls.single.messages.single.content,
        'Learner: He ido al mercado.\nPartner: ¿Qué has comprado?',
      );
    });

    test('the summary is written from the whole chat', () async {
      final (client, calls) = _partner(_label('El mercado', 'Shopping.'));

      final summary = await client.writeSummary(_chat(3));

      expect(summary, 'Shopping.');
      expect(calls.single.messages.single.content, contains('Mensaje 3'));
    });

    test('an empty chat is refused without a call', () async {
      final (client, calls) = _partner(_label('x', 'y'));

      expect(() => client.label(const []), throwsArgumentError);
      expect(calls, isEmpty);
    });
  });

  group('firstExchange', () {
    test('keeps a greeting from the partner that came first', () {
      final first = firstExchange(const [
        PartnerMessage.partner('¡Hola! ¿Qué tal?'),
        PartnerMessage.learner('Bien, gracias.'),
        PartnerMessage.partner('Me alegro.'),
        PartnerMessage.learner('¿Y tú?'),
      ]);

      expect(first.map((m) => m.text), [
        '¡Hola! ¿Qué tal?',
        'Bien, gracias.',
        'Me alegro.',
      ]);
    });

    test('stops at the learner\'s message if there is no reply yet', () {
      final first = firstExchange(const [
        PartnerMessage.learner('Hola'),
        PartnerMessage.learner('¿Estás ahí?'),
      ]);

      expect(first.single.text, 'Hola');
    });

    test('is the whole chat when the learner has written nothing', () {
      const chat = [PartnerMessage.partner('¡Hola!')];

      expect(firstExchange(chat), chat);
    });
  });

  group('parseChatLabel', () {
    test('reads the two fields', () {
      final label = parseChatLabel(_label(' Un viaje a Sevilla ', ' A trip. '));

      expect(label.title, 'Un viaje a Sevilla');
      expect(label.summary, 'A trip.');
    });

    test('tolerates Markdown fences around the JSON', () {
      final label = parseChatLabel(
        '```json\n${_label('La cena', 'Dinner.')}\n```',
      );

      expect(label.title, 'La cena');
    });

    test('removes quotation marks and a final full stop from the title', () {
      expect(parseChatLabel(_label('"La cena."', 'x')).title, 'La cena');
      expect(parseChatLabel(_label('«La cena»', 'x')).title, 'La cena');
    });

    test('a missing summary reads as empty', () {
      expect(parseChatLabel('{"title": "La cena"}').summary, '');
    });

    test('a reply that is not JSON, or has no title, is an error', () {
      expect(() => parseChatLabel('La cena'), throwsFormatException);
      expect(() => parseChatLabel('{"title": ""}'), throwsFormatException);
      expect(() => parseChatLabel('{"summary": "x"}'), throwsFormatException);
      expect(() => parseChatLabel('{not json}'), throwsFormatException);
    });
  });

  group('the instructions', () {
    test('ask for one question at most and no comments on the Spanish', () {
      expect(partnerBasePrompt, contains('at most ONE question'));
      expect(partnerBasePrompt, contains('Never comment on, correct'));
    });

    test('the soft goodbye comes at the tenth message', () {
      expect(softGoodbyeExchange, 10);
    });
  });
}
