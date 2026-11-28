import 'dart:convert';

import '../../../app/app_config.dart';
import '../../../core/services/prompts/partner_prompt.dart';
import '../../corrections/data/openai_chat_completions_client.dart';

/// One message of the current chat, as the partner client needs it: who
/// wrote it and what it says.
class PartnerMessage {
  /// A message the learner sent.
  const PartnerMessage.learner(this.text) : fromLearner = true;

  /// An earlier reply from the partner.
  const PartnerMessage.partner(this.text) : fromLearner = false;

  final bool fromLearner;
  final String text;
}

/// A chat's title and summary, as the partner writes them.
class ChatLabel {
  const ChatLabel({required this.title, required this.summary});

  /// A short title in Spanish, two to five words.
  final String title;

  /// One or two short sentences in English saying what the chat was about
  /// and anything worth following up.
  final String summary;
}

/// The signature of one call to the AI service with a whole conversation,
/// matching `OpenAiChatCompletionsClient.completeMessages`. A parameter so
/// tests can stand in for the service.
typedef PartnerChatCall =
    Future<String> Function({
      required String model,
      required String systemPrompt,
      required List<ChatCompletionsMessage> messages,
      String stageLabel,
      Map<String, Object?>? responseFormat,
    });

/// The chat partner (decision E2, build step 3.3).
///
/// One model, GPT-6 Luna to start with, writes the partner's replies, its
/// sign-off at the size limit, each chat's title and each chat's summary.
/// The model name is the one setting `AppConfig.openAiPartnerModel`.
///
/// Every call sends only the chat it is given (decision B3, point 7):
/// nothing from other chats, History, Saved or the profile. One call per
/// reply, with no re-runs. A failed call throws ([ChatCompletionsException]
/// from the service, or [FormatException] for a title and summary that
/// cannot be read); the caller decides what the learner sees.
class PartnerClient {
  PartnerClient({
    required PartnerChatCall call,
    this.model = AppConfig.defaultPartnerModel,
  }) : _call = call;

  /// The partner over OpenAI's chat completions service.
  factory PartnerClient.openAi(
    OpenAiChatCompletionsClient client, {
    String model = AppConfig.defaultPartnerModel,
  }) => PartnerClient(call: client.completeMessages, model: model);

  final PartnerChatCall _call;

  /// The model every partner call runs on.
  final String model;

  /// The partner's reply to the newest message in [chat], which must be the
  /// learner's.
  ///
  /// The instructions change with where the chat has got to: at the
  /// learner's tenth message the partner says its soft goodbye, after that
  /// it answers briefly and asks nothing, and with [atSizeLimit] it signs
  /// off for good (decisions B3 and E1). [missingWords] is the learner's
  /// setting for whether the partner supplies a word they ask for.
  Future<String> reply(
    List<PartnerMessage> chat, {
    bool atSizeLimit = false,
    bool missingWords = true,
  }) async {
    if (chat.isEmpty || !chat.last.fromLearner) {
      throw ArgumentError.value(
        chat,
        'chat',
        'The newest message must be the learner\'s.',
      );
    }

    final reply = await _call(
      model: model,
      systemPrompt: partnerSystemPrompt(
        exchange: exchangeCount(chat),
        atSizeLimit: atSizeLimit,
        missingWords: missingWords,
      ),
      messages: [
        for (final message in chat)
          message.fromLearner
              ? ChatCompletionsMessage.user(message.text)
              : ChatCompletionsMessage.assistant(message.text),
      ],
      stageLabel: atSizeLimit ? 'partner_sign_off' : 'partner_reply',
    );
    return reply.trim();
  }

  /// The title and the summary of [chat], written in one call.
  Future<ChatLabel> label(List<PartnerMessage> chat) async {
    if (chat.isEmpty) {
      throw ArgumentError.value(chat, 'chat', 'The chat has no messages.');
    }

    final reply = await _call(
      model: model,
      systemPrompt: titleSummaryPrompt,
      messages: [ChatCompletionsMessage.user(partnerTranscript(chat))],
      stageLabel: 'partner_title_summary',
      responseFormat: titleSummaryResponseFormat(),
    );
    return parseChatLabel(reply);
  }

  /// The chat's title, written from its first exchange: the learner's first
  /// message and the partner's reply to it, with any greeting from the
  /// partner that came before.
  Future<String> writeTitle(List<PartnerMessage> chat) async =>
      (await label(firstExchange(chat))).title;

  /// The short summary kept when a chat is deleted, written from the whole
  /// chat.
  Future<String> writeSummary(List<PartnerMessage> chat) async =>
      (await label(chat)).summary;
}

/// How many messages the learner has sent in [chat].
int exchangeCount(List<PartnerMessage> chat) =>
    chat.where((message) => message.fromLearner).length;

/// The start of [chat] up to and including the partner's first reply to the
/// learner. If the partner has not replied yet, everything up to the
/// learner's first message; if the learner has written nothing, the whole
/// chat.
List<PartnerMessage> firstExchange(List<PartnerMessage> chat) {
  final firstLearner = chat.indexWhere((message) => message.fromLearner);
  if (firstLearner < 0) {
    return chat;
  }
  final hasReply =
      firstLearner + 1 < chat.length && !chat[firstLearner + 1].fromLearner;
  return chat.sublist(0, firstLearner + (hasReply ? 2 : 1));
}

/// The chat as the title and summary instructions expect it: one line per
/// message, starting "Learner:" or "Partner:".
String partnerTranscript(List<PartnerMessage> chat) => [
  for (final message in chat)
    '${message.fromLearner ? 'Learner' : 'Partner'}: ${message.text}',
].join('\n');

/// Reads the title and summary out of the model's reply.
///
/// Throws [FormatException] if the reply is not the JSON object asked for
/// or has no title. Quotation marks around the title and a full stop at its
/// end are removed, since the instructions ask for neither.
ChatLabel parseChatLabel(String reply) {
  final start = reply.indexOf('{');
  final end = reply.lastIndexOf('}');
  if (start < 0 || end <= start) {
    throw const FormatException('The title and summary reply is not JSON.');
  }

  final decoded = jsonDecode(reply.substring(start, end + 1));
  if (decoded is! Map<String, Object?>) {
    throw const FormatException(
      'The title and summary reply is not an object.',
    );
  }

  final title = _tidyTitle(decoded['title']);
  if (title.isEmpty) {
    throw const FormatException('The title and summary reply has no title.');
  }
  final summary = decoded['summary'];
  return ChatLabel(
    title: title,
    summary: summary is String ? summary.trim() : '',
  );
}

String _tidyTitle(Object? value) {
  if (value is! String) {
    return '';
  }
  var title = value.trim();
  const quotes = ['"', '\'', '«', '»', '“', '”'];
  while (title.isNotEmpty && quotes.any(title.startsWith)) {
    title = title.substring(1).trimLeft();
  }
  while (title.isNotEmpty &&
      (quotes.any(title.endsWith) || title.endsWith('.'))) {
    title = title.substring(0, title.length - 1).trimRight();
  }
  return title;
}
