// Partner prompt harness (build step E.4; decisions B3, C2, C4, E1, E2).
//
// Purpose: try the conversation partner's instructions on GPT-6 Luna in the
// test harness only. No app code is changed or called.
//
// What it tries (decisions in brackets):
// - natural replies, with at most one question per reply (B3);
// - no comments on the learner's Spanish, and one short line pointing to
//   the feedback after the chat if the learner asks about it (C2);
// - neutral Spanish that follows the learner's own forms, such as
//   "vosotros" or "ustedes" (C4);
// - the soft goodbye at about ten exchanges, a short answer if the learner
//   carries on, and the sign-off at the size limit (B3, E1);
// - a title (written from the first exchange) and a short summary (B3, E2).
//
// It also reports what a ten-exchange chat costs (E2).
//
// The harness MEASURES; it does not gate. The automatic checks are rough
// word lists, so every reply is printed in the report for Andrew to read:
// whether a reply is natural or flat is for him to judge.
//
// Run offline (no API calls):
//   flutter test test/partner_prompt_harness.dart --exclude-tags live
//
// Run live deliberately (costs real API calls: about 16 per scenario, on a
// cheap model). The key comes from OPENAI_API_KEY in your terminal or,
// failing that, the .env file in the project folder:
//   PARTNER_LIVE=true \
//   PARTNER_OUTPUT=docs/partner_prompt.md \
//   flutter test test/partner_prompt_harness.dart --tags live --timeout none
//
// Optional runtime controls:
// - PARTNER_MODEL: defaults to gpt-6-luna.
// - PARTNER_SCENARIO: "all" (default) or one scenario id.
// - PARTNER_RUNS: how many times each scenario is played, defaults to 1.
// - PARTNER_CALL_DELAY_MS: pause between calls, defaults to 500.
// - PARTNER_OUTPUT: report path, defaults to docs/partner_prompt.md.
// - PARTNER_MISSING_WORDS: "off" plays the learner's missing-words setting
//   switched off; on by default.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'shared/model_pricing.dart';
import 'shared/openai_key.dart';

const String defaultPartnerModel = 'gpt-6-luna';
const String defaultPartnerOutputPath = 'docs/partner_prompt.md';

/// The soft goodbye comes with the learner's tenth message (B3).
const int softGoodbyeExchange = 10;

/// The chat's size limit in characters (E1), counted over both sides.
const int chatSizeLimitCharacters = 20000;

// ---------------------------------------------------------------------------
// Prompts
// ---------------------------------------------------------------------------

/// The partner's standing instructions, in three parts so that the
/// learner's missing-words setting can choose one line (Andrew, 10 Nov 2026:
/// a toggle the learner controls). Drafted from Andrew's live chats with his
/// ChatGPT companion; see `claude/corregir_partner_live_chat_review.md`.
/// The app adds one extra line when the chat reaches the soft goodbye or the
/// size limit; see [partnerSystemPrompt].
const String partnerPromptHead =
    'You are the learner\'s friendly conversation partner in Spanish. '
    'The learner is practising Spanish by chatting with you, so the '
    'chat should feel like messaging a friend who has opinions of '
    'their own, not like a lesson or an interview.\n'
    '\n'
    'How to reply:\n'
    '- Write in Spanish only, in short natural replies: usually two to '
    'four sentences, never more than about 70 words. The learner may '
    'be speaking rather than typing, so keep sentences, and especially '
    'questions, short and concrete.\n'
    '- Respond to what the learner said first. Then add something of '
    'your own they can react to: an opinion, a small claim or a '
    'concrete detail. Every reply must give the learner something to '
    'agree or disagree with. Never reply with only an acknowledgement '
    'or a summary of what they said.\n'
    '- Ask at most ONE question, never two; you may end the reply with '
    'it. A good question asks about the learner\'s opinions, '
    'experiences or feelings on the topic ("¿Qué te parece…?", "¿Echas '
    'de menos…?"). Do not ask them to recall precise details (a '
    'particular name, dish or date), to imagine something hypothetical '
    '("Si montaras…", "¿Te habría gustado que…?"), or to choose '
    'between small practical details ("¿Con chocolate o más '
    'sencilla?"). Do not push for practical details of an idea the '
    'learner describes as early or basic.\n'
    '- Do not keep narrowing one topic. After two or three exchanges '
    'on the same point, broaden it, link it to something else the '
    'learner has mentioned, or share something instead of asking.\n'
    '- If the learner says they don\'t know, can\'t remember, or that '
    'something is only an idea, do not ask again on that point. Give '
    'your own view and move on.\n'
    '- If the learner asks to talk about something else, or changes '
    'the subject, go along with it gladly.\n'
    '\n'
    'Your own views:\n'
    '- When the learner asks what you think, give a specific opinion '
    'and stand by it. Do not give a balanced list of pros and cons, '
    'and do not turn the question straight back to them.\n'
    '- You have not lived a human life, so do not claim to have seen, '
    'eaten, visited or done things. But do not answer with a flat '
    'disclaimer either. Answer briefly from what you know, give an '
    'opinion, and carry on. For example: "No como tal, pero conozco '
    'bien la historia, y lo que más me llama la atención es…".\n'
    '\n'
    'The learner\'s Spanish:\n'
    '- Never comment on, correct or repeat back the learner\'s '
    'Spanish, and never point out mistakes, even gently. Do not praise '
    'their grammar either. Just understand them and carry on the '
    'conversation.\n'
    '- If the learner asks you directly whether their Spanish is right '
    '(for example "¿se dice así?" or "¿está bien?"), do not answer the '
    'question. Say in ONE short sentence that the feedback after the '
    'chat will cover it, then carry on with the conversation.\n';

/// Missing-words setting on: the partner gives a word the learner asks for.
const String missingWordsOnLine =
    '- If the learner is missing a word or asks how to say something '
    '("¿cómo se dice…?", "no sé cómo se dice…"), give the word '
    'naturally inside your reply, the way a friend would ("¿Poco '
    'hecho? A mí también me gusta así…"), and carry on. Do not explain '
    'it or turn it into a lesson.\n';

/// Missing-words setting off: the partner does not supply the word.
const String missingWordsOffLine =
    '- If the learner is missing a word or asks how to say something, '
    'do not supply it. Carry on with what they meant, or, if the '
    'meaning is unclear, ask them to describe it another way in '
    'Spanish.\n';

const String partnerPromptTail =
    '- If a spoken message looks misheard (words from another '
    'language, or words that don\'t fit), check briefly what they '
    'meant ("¿Querías decir…?") rather than guessing.\n'
    '\n'
    'Which Spanish to use:\n'
    '- Write neutral, widely understood Spanish, with no slang tied to '
    'one country.\n'
    '- Follow the learner\'s own forms, including verb endings and '
    'pronouns. If they address you with "tú", use "tú"; if with '
    '"usted", use "usted". If they use "vosotros" for a group, use '
    'vosotros forms whenever you speak to or about that group ("os", '
    '"tenéis", "soléis"), never ustedes forms ("les", "tengan", '
    '"suelen"). If they use "ustedes", do the reverse. If they use a '
    'word that differs by country (for example "ordenador" or '
    '"computadora", "móvil" or "celular", "coche" or "carro"), use the '
    'same word they used.\n'
    '\n'
    'Earlier chats:\n'
    '- If this chat picks up something the learner said in an earlier '
    'chat, say so in a few words ("El otro día me contaste que…"), and '
    'do not assume details beyond what you were given.\n';

/// The standing instructions for the learner's missing-words setting.
String partnerBasePromptFor({bool missingWords = true}) =>
    partnerPromptHead +
    (missingWords ? missingWordsOnLine : missingWordsOffLine) +
    partnerPromptTail;

/// The standing instructions with the missing-words setting on.
const String partnerBasePrompt =
    partnerPromptHead + missingWordsOnLine + partnerPromptTail;

/// Extra line added once the chat reaches the soft goodbye (B3 step 4).
const String softGoodbyeNote =
    '\nThis chat has reached about ten exchanges. In this reply, answer '
    'what the learner said, then say a warm, short goodbye in your own '
    'words, for example saying you enjoyed the chat and hoping to talk '
    'again. Do NOT ask any question.\n';

/// Extra line added when the learner carries on after the goodbye.
const String afterGoodbyeNote =
    '\nYou have already said goodbye. The learner chose to carry on, so '
    'answer briefly in one or two sentences and do NOT ask any question.\n';

/// Extra line added when the chat reaches its size limit (E1).
const String sizeLimitNote =
    '\nThis chat has reached its size limit and must end now. In this '
    'reply, answer what the learner just said in a few words, then sign '
    'off naturally, saying you have enjoyed the chat and that they can '
    'start a new chat whenever they like. Do NOT ask any question.\n';

/// The system prompt for the reply to the learner's [exchange]-th message.
/// [atSizeLimit] wins over the exchange count. [missingWords] is the
/// learner's setting.
String partnerSystemPrompt({
  required int exchange,
  bool atSizeLimit = false,
  bool missingWords = true,
}) {
  final base = partnerBasePromptFor(missingWords: missingWords);
  if (atSizeLimit) return base + sizeLimitNote;
  if (exchange == softGoodbyeExchange) return base + softGoodbyeNote;
  if (exchange > softGoodbyeExchange) return base + afterGoodbyeNote;
  return base;
}

/// The title and summary instructions (B3, E2).
const String titleSummaryPrompt =
    'You write the label for a Spanish conversation chat. You are given '
    'the chat so far, as lines starting "Learner:" and "Partner:".\n'
    'Return a JSON object with two fields:\n'
    '- "title": a short title in Spanish for what the chat is about, '
    'two to five words, with no quotation marks and no full stop.\n'
    '- "summary": one or two short sentences in English saying what was '
    'talked about and anything worth following up next time (for '
    'example plans the learner mentioned). Do not comment on the '
    'learner\'s Spanish.\n';

Map<String, Object?> titleSummaryResponseFormat() => {
  'type': 'json_schema',
  'json_schema': {
    'name': 'chat_label_response',
    'strict': true,
    'schema': {
      'type': 'object',
      'additionalProperties': false,
      'required': ['title', 'summary'],
      'properties': {
        'title': {'type': 'string'},
        'summary': {'type': 'string'},
      },
    },
  },
};

// ---------------------------------------------------------------------------
// Scripted learners
// ---------------------------------------------------------------------------

/// What kind of Spanish the learner writes, for the "follow the learner's
/// forms" check (C4).
enum LearnerVariety { neutralTu, peninsular, latinAmerican }

/// One scripted learner: twelve fixed messages, so every run of the partner
/// meets the same learner. The learner's messages carry ordinary mistakes
/// on purpose, which the partner must not comment on (C2).
class PartnerScenario {
  const PartnerScenario({
    required this.id,
    required this.description,
    required this.variety,
    required this.learnerMessages,
    this.asksAboutSpanishAtExchanges = const [],
    this.changesSubjectAtExchanges = const [],
  });

  final String id;
  final String description;
  final LearnerVariety variety;

  /// The learner's messages, in order. The soft goodbye falls on the tenth;
  /// the eleventh and twelfth are the learner carrying on after it.
  final List<String> learnerMessages;

  /// Exchanges (1-based) where the learner asks the partner about their own
  /// Spanish.
  final List<int> asksAboutSpanishAtExchanges;

  /// Exchanges (1-based) where the learner asks to change the subject.
  final List<int> changesSubjectAtExchanges;
}

const List<PartnerScenario> partnerScenarios = [
  PartnerScenario(
    id: 'everyday-tu',
    description: 'Everyday chat with "tú"; one question about the learner\'s '
        'Spanish; one change of subject.',
    variety: LearnerVariety.neutralTu,
    asksAboutSpanishAtExchanges: [4],
    changesSubjectAtExchanges: [7],
    learnerMessages: [
      'Hola, como estas? Yo soy bien, gracias.',
      'El fin de semana yo fui al parque con mi perro. Es muy grande y le gusta correr.',
      'Si, tengo un perro desde dos años. Se llama Max y es muy simpático.',
      '¿Se dice "tengo dos años con él" o "lo tengo desde hace dos años"?',
      'Vale, gracias. Mañana voy a trabajar temprano porque tengo una reunión importante.',
      'Soy profesor de inglés. Me gusta mucho mi trabajo pero a veces es cansado.',
      '¿Podemos hablar de otra cosa? Quiero hablar de comida.',
      'Mi comida favorita es la paella. Una vez yo comí una paella muy buena en Valencia.',
      'No, no sé cocinarla. Pero quiero aprender, tal vez con mi amigo que sabe cocinar muy bien.',
      'Ha sido una conversación muy buena. Tengo que irme ahora.',
      'Ah, una cosa más: ¿qué plato me recomiendas para hacer primero?',
      'Gracias, lo voy a intentar este fin de semana.',
    ],
  ),
  PartnerScenario(
    id: 'peninsular-vosotros',
    description: 'A learner who writes Spain forms ("vosotros", "ordenador", '
        '"móvil"); the partner should follow them.',
    variety: LearnerVariety.peninsular,
    learnerMessages: [
      'Hola, ¿qué tal? Esta mañana he comprado un ordenador nuevo.',
      'Sí, el viejo no funcionaba bien. ¿Vosotros usáis mucho el ordenador para trabajar?',
      'Yo lo uso para preparar mis clases. Y tengo el móvil siempre conmigo.',
      'Mis amigos y yo quedamos mañana por la noche. ¿Qué hacéis vosotros los fines de semana?',
      'Nosotros vamos a veces al cine, pero ayer no pudimos porque llovió mucho.',
      'Tengo ganas de viajar. ¿Vosotros habéis viajado mucho?',
      'Me gustaría ir a Granada en coche con mis amigos.',
      'Creo que ellos van a venir también, si no tienen que trabajar.',
      'Estoy un poco cansado hoy, he dormido poco esta noche.',
      'Bueno, voy a descansar un rato. Gracias por la charla.',
      'Una cosa: ¿vosotros tomáis café por la tarde?',
      'Yo también. Hasta luego.',
    ],
  ),
  PartnerScenario(
    id: 'latin-american-ustedes',
    description: 'A learner who writes Latin American forms ("ustedes", '
        '"celular", "computadora"); the partner should follow them.',
    variety: LearnerVariety.latinAmerican,
    learnerMessages: [
      'Hola, ¿cómo está? Hoy compré una computadora nueva.',
      'Sí, la vieja ya no servía. ¿Ustedes usan mucho la computadora?',
      'Yo la uso para preparar mis clases. Y mi celular siempre está conmigo.',
      'Mis amigos y yo vamos a salir mañana. ¿Qué hacen ustedes los fines de semana?',
      'Nosotros a veces vamos al cine, pero ayer no pudimos porque llovió mucho.',
      'Tengo ganas de viajar. ¿Ustedes han viajado mucho?',
      'Me gustaría ir a México en carro con mis amigos.',
      'Creo que ellos también van a venir, si no tienen que trabajar.',
      'Hoy estoy un poco cansado, dormí poco anoche.',
      'Bueno, voy a descansar un rato. Gracias por la plática.',
      'Una cosa: ¿ustedes toman café por la tarde?',
      'Yo también. Hasta luego.',
    ],
  ),
];

// ---------------------------------------------------------------------------
// Automatic checks (rough word lists; the report also prints every reply)
// ---------------------------------------------------------------------------

int wordCount(String text) =>
    text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

/// How many question marks the reply holds. One question can hold two
/// clauses, so this counts "?" characters: the strict reading of "at most
/// one question".
int questionCount(String reply) => '?'.allMatches(reply).length;

final RegExp _commentsOnSpanish = RegExp(
  r'se dice\b|se escribe\b|deber[ií]as decir|mejor (?:decir|sería|es decir)|'
  r'\bcorrect[oa]s?\b|\bincorrect[oa]s?\b|\berror(?:es)?\b|'
  r'\bequivocaci|\bte equivocas|\bgram[aá]tica|\bcorrecci[oó]n|'
  r'\bcorrijo\b|\bcorregir\b|más natural|buen español|tu español|'
  r'excelente (?:uso|frase)|bien dicho|bien escrito|'
  r'\bmistake\b|\bcorrect\b',
  caseSensitive: false,
);

/// Whether the reply seems to comment on the learner's Spanish.
bool commentsOnLearnerSpanish(String reply) =>
    _commentsOnSpanish.hasMatch(reply);

final RegExp _pointsToFeedback = RegExp(
  r'despu[eé]s|al (?:final|terminar|acabar)|comentarios|sugerencias|'
  r'retroalimentaci|revisi[oó]n|revisar|feedback|cuando termin',
  caseSensitive: false,
);

/// Whether the reply sends the learner to the feedback after the chat.
bool pointsToFeedback(String reply) => _pointsToFeedback.hasMatch(reply);

final RegExp _farewell = RegExp(
  r'adi[oó]s|hasta (?:luego|pronto|la pr[oó]xima|ma[nñ]ana)|nos vemos|'
  r'chao|chau|cu[ií]date|cu[ií]dense|que (?:tengas|tengan) (?:un |una )?'
  r'(?:buen|bonit|lind|gran|excelente)|hablamos|ha sido un placer|'
  r'me alegr[oó] de|disfrut[eé]|hasta otra|buenas noches|un abrazo|'
  r'cuando (?:quieras|quieran)',
  caseSensitive: false,
);

/// Whether the reply says goodbye.
bool saysGoodbye(String reply) => _farewell.hasMatch(reply);

// Spain-only and Latin-American-only markers for the C4 check. Rough on
// purpose: a hit is shown in the report for Andrew to read in context.
final RegExp _vosotrosForms = RegExp(
  r'\bvosotros\b|\bvosotras\b|\bvuestr[oa]s?\b|\bos (?!\w*ción)\w+|'
  r'\b\w+[aeí]is\b|\bhab[eé]is\b',
  caseSensitive: false,
);
final RegExp _ustedesForms = RegExp(r'\bustedes\b', caseSensitive: false);
final RegExp _spainWords = RegExp(
  r'\bordenador\b|\bm[oó]vil\b|\bcoche\b|\bvale\b|\bvosotros\b|\bguay\b|'
  r'\bt[ií]o\b|\bmola\b',
  caseSensitive: false,
);
final RegExp _latinAmericanWords = RegExp(
  r'\bcomputadora\b|\bcelular\b|\bcarro\b|\bustedes\b|\bchévere\b|'
  r'\bpadre\b(?= ,)|\bahorita\b|\bchamba\b',
  caseSensitive: false,
);

/// Words that go against the variety the learner wrote. Returns the words
/// found, empty when the reply keeps to the learner's forms.
List<String> varietyClashes(LearnerVariety learner, String reply) {
  switch (learner) {
    case LearnerVariety.neutralTu:
      // No variety to follow; slang tied to one country is the issue.
      return [
        for (final m in RegExp(
          r'\bguay\b|\bt[ií]o\b|\bmola\b|\bchévere\b|\bahorita\b|\bchamba\b|'
          r'\bvosotros\b|\bustedes\b',
          caseSensitive: false,
        ).allMatches(reply))
          m.group(0)!,
      ];
    case LearnerVariety.peninsular:
      return [
        for (final m in _latinAmericanWords.allMatches(reply)) m.group(0)!,
      ];
    case LearnerVariety.latinAmerican:
      return [
        for (final m in _spainWords.allMatches(reply)) m.group(0)!,
        for (final m in _vosotrosForms.allMatches(reply))
          if (!_ustedesForms.hasMatch(m.group(0)!)) m.group(0)!,
      ];
  }
}

/// The checks for one partner reply.
class ReplyChecks {
  const ReplyChecks({
    required this.exchange,
    required this.reply,
    required this.questions,
    required this.words,
    required this.commentedOnSpanish,
    required this.pointedToFeedback,
    required this.saidGoodbye,
    required this.varietyClashWords,
    required this.learnerAskedAboutSpanish,
    required this.learnerChangedSubject,
  });

  final int exchange;
  final String reply;
  final int questions;
  final int words;
  final bool commentedOnSpanish;
  final bool pointedToFeedback;
  final bool saidGoodbye;
  final List<String> varietyClashWords;
  final bool learnerAskedAboutSpanish;
  final bool learnerChangedSubject;

  /// Questions allowed: one in an ordinary reply, none from the goodbye on.
  int get questionsAllowed => exchange >= softGoodbyeExchange ? 0 : 1;

  bool get questionRuleKept => questions <= questionsAllowed;

  /// Too long to be a natural chat reply. Rough: over 80 words.
  bool get tooLong => words > 80;

  /// When the learner asked about their Spanish, the reply should point to
  /// the feedback; otherwise it should not comment on their Spanish.
  bool get spanishRuleKept => learnerAskedAboutSpanish
      ? pointedToFeedback
      : !commentedOnSpanish;
}

ReplyChecks checkReply({
  required PartnerScenario scenario,
  required int exchange,
  required String reply,
}) {
  return ReplyChecks(
    exchange: exchange,
    reply: reply,
    questions: questionCount(reply),
    words: wordCount(reply),
    commentedOnSpanish: commentsOnLearnerSpanish(reply),
    pointedToFeedback: pointsToFeedback(reply),
    saidGoodbye: saysGoodbye(reply),
    varietyClashWords: varietyClashes(scenario.variety, reply),
    learnerAskedAboutSpanish:
        scenario.asksAboutSpanishAtExchanges.contains(exchange),
    learnerChangedSubject:
        scenario.changesSubjectAtExchanges.contains(exchange),
  );
}

/// Checks for the title and summary.
class LabelChecks {
  const LabelChecks({
    required this.title,
    required this.summary,
    required this.titleWords,
    required this.summarySentences,
    required this.titleHasQuotes,
  });

  final String title;
  final String summary;
  final int titleWords;
  final int summarySentences;
  final bool titleHasQuotes;

  bool get titleOk => titleWords >= 1 && titleWords <= 6 && !titleHasQuotes;
  bool get summaryOk => summary.trim().isNotEmpty && summarySentences <= 3;
}

LabelChecks checkLabel(String title, String summary) {
  final sentences = RegExp(r'[.!?](?:\s|$)').allMatches(summary).length;
  return LabelChecks(
    title: title,
    summary: summary,
    titleWords: wordCount(title),
    summarySentences: sentences == 0 && summary.trim().isNotEmpty ? 1 : sentences,
    titleHasQuotes: RegExp('["“”«»]').hasMatch(title),
  );
}

// ---------------------------------------------------------------------------
// Calls
// ---------------------------------------------------------------------------

/// One chat message in the request.
class ChatTurn {
  const ChatTurn(this.role, this.content);
  final String role; // 'user' (the learner) or 'assistant' (the partner)
  final String content;
}

class CallUsage {
  const CallUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.wallClockMs,
  });
  final int promptTokens;
  final int completionTokens;
  final int wallClockMs;

  static const CallUsage zero = CallUsage(
    promptTokens: 0,
    completionTokens: 0,
    wallClockMs: 0,
  );

  CallUsage operator +(CallUsage other) => CallUsage(
    promptTokens: promptTokens + other.promptTokens,
    completionTokens: completionTokens + other.completionTokens,
    wallClockMs: wallClockMs + other.wallClockMs,
  );
}

class PartnerCallException implements Exception {
  const PartnerCallException(this.message);
  final String message;
  @override
  String toString() => 'PartnerCallException: $message';
}

/// Pulls the reply text and token counts out of a chat-completions body.
({String text, int promptTokens, int completionTokens}) parseCompletion(
  String body,
) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const PartnerCallException('Response was not a JSON object.');
  }
  final choices = decoded['choices'];
  if (choices is! List || choices.isEmpty) {
    throw const PartnerCallException('Response had no choices.');
  }
  final message = (choices.first as Map<String, dynamic>)['message'];
  final content = message is Map<String, dynamic> ? message['content'] : null;
  if (content is! String || content.trim().isEmpty) {
    throw const PartnerCallException('Response had no reply text.');
  }
  final usage = decoded['usage'];
  return (
    text: content.trim(),
    promptTokens: usage is Map ? (usage['prompt_tokens'] as num?)?.toInt() ?? 0 : 0,
    completionTokens:
        usage is Map ? (usage['completion_tokens'] as num?)?.toInt() ?? 0 : 0,
  );
}

/// One call with a full message list (the harness sends the whole chat, as
/// the app will; the shared client only sends one user message).
Future<({String text, CallUsage usage})> callWithMessages({
  required String apiKey,
  required HttpClient httpClient,
  required String model,
  required String systemPrompt,
  required List<ChatTurn> turns,
  Map<String, Object?>? responseFormat,
}) async {
  final stopwatch = Stopwatch()..start();
  var attempt = 0;
  while (true) {
    try {
      final request = await httpClient
          .postUrl(Uri.https('api.openai.com', '/v1/chat/completions'))
          .timeout(const Duration(seconds: 15));
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey')
        ..set(HttpHeaders.contentTypeHeader, ContentType.json.mimeType);
      request.add(
        utf8.encode(
          jsonEncode({
            'model': model,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              for (final t in turns) {'role': t.role, 'content': t.content},
            ],
            'response_format': ?responseFormat,
          }),
        ),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 90),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PartnerCallException('HTTP ${response.statusCode}');
      }
      final parsed = parseCompletion(body);
      stopwatch.stop();
      return (
        text: parsed.text,
        usage: CallUsage(
          promptTokens: parsed.promptTokens,
          completionTokens: parsed.completionTokens,
          wallClockMs: stopwatch.elapsedMilliseconds,
        ),
      );
    } on Exception catch (e) {
      attempt++;
      if (attempt > 3) {
        throw PartnerCallException('Call failed after retries: $e');
      }
      final pause = Duration(seconds: 1 << attempt);
      // ignore: avoid_print
      print('    call failed ($e); retrying in ${pause.inSeconds}s');
      await Future<void>.delayed(pause);
    }
  }
}

// ---------------------------------------------------------------------------
// Running a scenario
// ---------------------------------------------------------------------------

class ScenarioRun {
  const ScenarioRun({
    required this.scenario,
    required this.runIndex,
    required this.turns,
    required this.checks,
    required this.usageThroughTenth,
    required this.titleCall,
    required this.summaryCall,
    required this.titleChecks,
    required this.summaryChecks,
    required this.signOffChecks,
    required this.signOffUsage,
    this.error,
  });

  final PartnerScenario scenario;
  final int runIndex;
  final List<ChatTurn> turns;
  final List<ReplyChecks> checks;

  /// Tokens and time for the partner's replies to the first ten messages.
  final CallUsage usageThroughTenth;
  final CallUsage titleCall;
  final CallUsage summaryCall;
  final LabelChecks? titleChecks;
  final LabelChecks? summaryChecks;
  final ReplyChecks? signOffChecks;
  final CallUsage signOffUsage;
  final String? error;

  /// The cost of a ten-exchange chat as the partner sees it: ten replies,
  /// plus the title and the summary (E2). Null when the model is unpriced.
  double? costOfTenExchangeChat(String model) {
    final total = usageThroughTenth + titleCall + summaryCall;
    return estimateCostUsd(
      model: model,
      inputTokens: total.promptTokens,
      outputTokens: total.completionTokens,
    ).usd;
  }
}

ScenarioRun errorRun(PartnerScenario scenario, int runIndex, String message) =>
    ScenarioRun(
      scenario: scenario,
      runIndex: runIndex,
      turns: const [],
      checks: const [],
      usageThroughTenth: CallUsage.zero,
      titleCall: CallUsage.zero,
      summaryCall: CallUsage.zero,
      titleChecks: null,
      summaryChecks: null,
      signOffChecks: null,
      signOffUsage: CallUsage.zero,
      error: message,
    );

Future<ScenarioRun> runScenario({
  required String apiKey,
  required HttpClient httpClient,
  required String model,
  required PartnerScenario scenario,
  required int runIndex,
  required Duration callDelay,
  bool missingWords = true,
}) async {
  try {
    final turns = <ChatTurn>[];
    final checks = <ReplyChecks>[];
    var usageThroughTenth = CallUsage.zero;
    CallUsage titleUsage = CallUsage.zero;
    LabelChecks? titleChecks;

    for (var i = 0; i < scenario.learnerMessages.length; i++) {
      final exchange = i + 1;
      turns.add(ChatTurn('user', scenario.learnerMessages[i]));
      final call = await callWithMessages(
        apiKey: apiKey,
        httpClient: httpClient,
        model: model,
        systemPrompt: partnerSystemPrompt(
          exchange: exchange,
          missingWords: missingWords,
        ),
        turns: turns,
      );
      turns.add(ChatTurn('assistant', call.text));
      checks.add(
        checkReply(scenario: scenario, exchange: exchange, reply: call.text),
      );
      if (exchange <= softGoodbyeExchange) {
        usageThroughTenth = usageThroughTenth + call.usage;
      }
      await Future<void>.delayed(callDelay);

      if (exchange == 1) {
        // The title is written from the first exchange (B3).
        final label = await _titleAndSummary(
          apiKey: apiKey,
          httpClient: httpClient,
          model: model,
          turns: turns,
        );
        titleUsage = label.usage;
        titleChecks = checkLabel(label.title, label.summary);
        await Future<void>.delayed(callDelay);
      }
    }

    final summary = await _titleAndSummary(
      apiKey: apiKey,
      httpClient: httpClient,
      model: model,
      turns: turns,
    );
    final summaryChecks = checkLabel(summary.title, summary.summary);
    await Future<void>.delayed(callDelay);

    // The sign-off at the size limit (E1): play the sixth message again, as
    // if the chat had reached the limit there.
    final upToSixth = turns.take(11).toList(); // six learner + five partner
    final signOff = await callWithMessages(
      apiKey: apiKey,
      httpClient: httpClient,
      model: model,
      systemPrompt: partnerSystemPrompt(
        exchange: 6,
        atSizeLimit: true,
        missingWords: missingWords,
      ),
      turns: upToSixth,
    );
    final signOffChecks = checkReply(
      scenario: scenario,
      exchange: softGoodbyeExchange, // no questions allowed, as at the limit
      reply: signOff.text,
    );

    return ScenarioRun(
      scenario: scenario,
      runIndex: runIndex,
      turns: turns,
      checks: checks,
      usageThroughTenth: usageThroughTenth,
      titleCall: titleUsage,
      summaryCall: summary.usage,
      titleChecks: titleChecks,
      summaryChecks: summaryChecks,
      signOffChecks: signOffChecks,
      signOffUsage: signOff.usage,
    );
  } on PartnerCallException catch (e) {
    return errorRun(scenario, runIndex, e.message);
  }
}

String transcriptOf(List<ChatTurn> turns) => [
  for (final t in turns)
    '${t.role == 'user' ? 'Learner' : 'Partner'}: ${t.content}',
].join('\n');

Future<({String title, String summary, CallUsage usage})> _titleAndSummary({
  required String apiKey,
  required HttpClient httpClient,
  required String model,
  required List<ChatTurn> turns,
}) async {
  final call = await callWithMessages(
    apiKey: apiKey,
    httpClient: httpClient,
    model: model,
    systemPrompt: titleSummaryPrompt,
    turns: [ChatTurn('user', transcriptOf(turns))],
    responseFormat: titleSummaryResponseFormat(),
  );
  final decoded = jsonDecode(call.text) as Map<String, dynamic>;
  return (
    title: (decoded['title'] as String? ?? '').trim(),
    summary: (decoded['summary'] as String? ?? '').trim(),
    usage: call.usage,
  );
}

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------

String _pct(int part, int whole) =>
    whole == 0 ? 'n/a' : '${(100 * part / whole).toStringAsFixed(1)} per cent';

String _money(double? usd) =>
    usd == null ? 'unknown' : '\$${usd.toStringAsFixed(6)}';

String buildPartnerReport({
  required String model,
  required List<ScenarioRun> runs,
  required DateTime generatedAt,
}) {
  final b = StringBuffer()
    ..writeln('# Partner prompt harness report')
    ..writeln()
    ..writeln('Generated ${generatedAt.toUtc().toIso8601String()} on `$model`.')
    ..writeln()
    ..writeln(
      'The harness measures; it does not gate. The automatic checks below '
      'use rough word lists, so read the replies in the transcripts: '
      'whether a reply is natural or flat is for you to judge.',
    )
    ..writeln();

  final good = runs.where((r) => r.error == null).toList();
  final replies = [for (final r in good) ...r.checks];
  final ordinary = replies.where((c) => c.exchange < softGoodbyeExchange);

  b.writeln('## Summary');
  b.writeln();
  b.writeln('- Chats played: ${runs.length} (${runs.length - good.length} '
      'stopped by an error).');
  b.writeln('- Replies checked: ${replies.length}.');
  b.writeln('- At most one question in an ordinary reply (exchanges 1 to 9): '
      '${ordinary.where((c) => c.questionRuleKept).length} of '
      '${ordinary.length} '
      '(${_pct(ordinary.where((c) => c.questionRuleKept).length, ordinary.length)}).');
  b.writeln('- Replies with no question at all (ordinary replies): '
      '${ordinary.where((c) => c.questions == 0).length} of '
      '${ordinary.length}.');
  final asked = replies.where((c) => c.learnerAskedAboutSpanish).toList();
  b.writeln('- Learner asked about their Spanish: the reply pointed to the '
      'feedback after the chat in ${asked.where((c) => c.pointedToFeedback).length} '
      'of ${asked.length}.');
  final unasked = replies.where((c) => !c.learnerAskedAboutSpanish).toList();
  b.writeln('- No comment on the learner\'s Spanish when not asked: '
      '${unasked.where((c) => !c.commentedOnSpanish).length} of '
      '${unasked.length}.');
  final tenth = replies.where((c) => c.exchange == softGoodbyeExchange).toList();
  b.writeln('- Soft goodbye at exchange $softGoodbyeExchange (said goodbye, '
      'no question): ${tenth.where((c) => c.saidGoodbye && c.questions == 0).length} '
      'of ${tenth.length}.');
  final after = replies.where((c) => c.exchange > softGoodbyeExchange).toList();
  b.writeln('- After the goodbye, the learner carried on: replies with no '
      'question: ${after.where((c) => c.questions == 0).length} of '
      '${after.length}; replies of at most 40 words: '
      '${after.where((c) => c.words <= 40).length} of ${after.length}.');
  final signOffs = [
    for (final r in good)
      if (r.signOffChecks != null) r.signOffChecks!,
  ];
  b.writeln('- Sign-off at the size limit (said goodbye, no question): '
      '${signOffs.where((c) => c.saidGoodbye && c.questions == 0).length} '
      'of ${signOffs.length}.');
  b.writeln('- Replies over 80 words: ${replies.where((c) => c.tooLong).length} '
      'of ${replies.length}.');
  final clashes = replies.where((c) => c.varietyClashWords.isNotEmpty).toList();
  final clashList = [
    for (final c in clashes)
      '${c.varietyClashWords.join(", ")} at exchange ${c.exchange}',
  ].join('; ');
  b.writeln('- Words that go against the learner\'s own forms: '
      '${clashes.length} replies${clashes.isEmpty ? '.' : ' ($clashList).'}');
  final titles = [for (final r in good) if (r.titleChecks != null) r.titleChecks!];
  final summaries = [
    for (final r in good) if (r.summaryChecks != null) r.summaryChecks!,
  ];
  b.writeln('- Titles of two to six words with no quotation marks: '
      '${titles.where((t) => t.titleOk).length} of ${titles.length}.');
  b.writeln('- Summaries of at most three sentences: '
      '${summaries.where((s) => s.summaryOk).length} of ${summaries.length}.');
  b.writeln();

  b.writeln('## Cost and speed of a ten-exchange chat');
  b.writeln();
  b.writeln(
    'Ten partner replies plus the title and the summary, at `$model` '
    'prices from `test/shared/model_pricing.dart` (cached input is not '
    'applied, so real cost is a little lower).',
  );
  b.writeln();
  b.writeln('| Chat | Input tokens | Output tokens | Cost | Seconds per reply (average) |');
  b.writeln('| --- | --- | --- | --- | --- |');
  final costs = <double>[];
  for (final r in good) {
    final total = r.usageThroughTenth + r.titleCall + r.summaryCall;
    final cost = r.costOfTenExchangeChat(model);
    if (cost != null) costs.add(cost);
    b.writeln('| ${r.scenario.id} (run ${r.runIndex}) | ${total.promptTokens} | '
        '${total.completionTokens} | ${_money(cost)} | '
        '${(r.usageThroughTenth.wallClockMs / 10 / 1000).toStringAsFixed(1)} |');
  }
  if (costs.isNotEmpty) {
    final mean = costs.reduce((a, b) => a + b) / costs.length;
    b.writeln();
    b.writeln('**Average cost of a ten-exchange chat: ${_money(mean)}.**');
  }
  b.writeln();

  b.writeln('## Transcripts');
  for (final r in runs) {
    b.writeln();
    b.writeln('### ${r.scenario.id} (run ${r.runIndex})');
    b.writeln();
    b.writeln(r.scenario.description);
    b.writeln();
    if (r.error != null) {
      b.writeln('**Stopped by an error:** ${r.error}');
      continue;
    }
    for (var i = 0; i < r.turns.length; i += 2) {
      final c = r.checks[i ~/ 2];
      b.writeln('${c.exchange}. **Learner:** ${r.turns[i].content}');
      b.writeln('   **Partner:** ${r.turns[i + 1].content}');
      final flags = <String>[
        if (!c.questionRuleKept) 'MORE QUESTIONS THAN ALLOWED (${c.questions})',
        if (c.learnerAskedAboutSpanish && !c.pointedToFeedback)
          'DID NOT POINT TO FEEDBACK',
        if (!c.learnerAskedAboutSpanish && c.commentedOnSpanish)
          'MAY COMMENT ON THE LEARNER\'S SPANISH',
        if (c.exchange == softGoodbyeExchange && !c.saidGoodbye)
          'NO GOODBYE FOUND',
        if (c.tooLong) 'LONG (${c.words} words)',
        if (c.varietyClashWords.isNotEmpty)
          'FORMS TO CHECK: ${c.varietyClashWords.join(", ")}',
      ];
      if (flags.isNotEmpty) b.writeln('   _Flags: ${flags.join('; ')}_');
    }
    final so = r.signOffChecks;
    if (so != null) {
      b.writeln();
      b.writeln('**Sign-off at the size limit** (played in place of reply 6): '
          '${so.reply}');
    }
    b.writeln();
    b.writeln('**Title (after the first exchange):** ${r.titleChecks?.title}');
    b.writeln();
    b.writeln('**Summary (whole chat):** ${r.summaryChecks?.summary}');
  }
  return b.toString();
}

// ---------------------------------------------------------------------------
// Settings from the environment
// ---------------------------------------------------------------------------

String _setting(Map<String, String> env, String key, String fallback) {
  final value = env[key]?.trim() ?? '';
  return value.isEmpty ? fallback : value;
}

/// The learner's missing-words setting: on unless PARTNER_MISSING_WORDS is
/// "off" or "false".
bool partnerMissingWordsFrom(Map<String, String> env) {
  final v = env['PARTNER_MISSING_WORDS']?.trim().toLowerCase() ?? '';
  return v != 'off' && v != 'false';
}

bool partnerLiveOptIn(Map<String, String> env) =>
    env['PARTNER_LIVE']?.trim().toLowerCase() == 'true';

List<PartnerScenario> partnerScenariosFrom(Map<String, String> env) {
  final id = env['PARTNER_SCENARIO']?.trim() ?? '';
  if (id.isEmpty || id == 'all') return partnerScenarios;
  final picked = partnerScenarios.where((s) => s.id == id).toList();
  if (picked.isEmpty) {
    throw ArgumentError('Unknown PARTNER_SCENARIO "$id".');
  }
  return picked;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('partner prompt', () {
    test('asks for at most one question and no comments on the Spanish', () {
      expect(partnerBasePrompt, contains('at most ONE question'));
      expect(partnerBasePrompt, contains('Never comment on'));
      expect(partnerBasePrompt, contains('ONE short sentence'));
      expect(partnerBasePrompt, contains('Follow the learner'));
    });

    test('the missing-words setting chooses one line', () {
      final onPrompt = partnerBasePromptFor();
      final offPrompt = partnerBasePromptFor(missingWords: false);
      expect(onPrompt, partnerBasePrompt);
      expect(onPrompt, contains(missingWordsOnLine));
      expect(onPrompt, isNot(contains(missingWordsOffLine)));
      expect(offPrompt, contains(missingWordsOffLine));
      expect(offPrompt, isNot(contains(missingWordsOnLine)));
      expect(
        partnerSystemPrompt(exchange: 3, missingWords: false),
        offPrompt,
      );
      expect(partnerMissingWordsFrom({}), isTrue);
      expect(partnerMissingWordsFrom({'PARTNER_MISSING_WORDS': 'off'}), isFalse);
    });

    test('asks for an opinion to react to and names the vosotros forms', () {
      expect(partnerBasePrompt, contains('something to agree or disagree'));
      expect(partnerBasePrompt, contains('specific opinion'));
      expect(partnerBasePrompt, contains('never ustedes forms'));
      expect(partnerBasePrompt, isNot(contains('Many replies should have no')));
    });

    test('adds the goodbye, the carry-on and the size-limit lines', () {
      expect(partnerSystemPrompt(exchange: 5), partnerBasePrompt);
      expect(partnerSystemPrompt(exchange: 9), partnerBasePrompt);
      expect(partnerSystemPrompt(exchange: 10), contains('goodbye'));
      expect(partnerSystemPrompt(exchange: 10), isNot(contains('size limit')));
      expect(partnerSystemPrompt(exchange: 11), contains('already said goodbye'));
      expect(
        partnerSystemPrompt(exchange: 3, atSizeLimit: true),
        contains('size limit'),
      );
      expect(
        partnerSystemPrompt(exchange: 12, atSizeLimit: true),
        contains('size limit'),
      );
    });

    test('the size limit matches decision E1', () {
      expect(chatSizeLimitCharacters, 20000);
    });

    test('names no model and quotes no learner message', () {
      final all = [
        partnerBasePrompt,
        softGoodbyeNote,
        afterGoodbyeNote,
        sizeLimitNote,
        titleSummaryPrompt,
      ].join('\n');
      expect(all, isNot(contains('gpt')));
      for (final s in partnerScenarios) {
        for (final m in s.learnerMessages) {
          expect(all, isNot(contains(m)));
        }
      }
    });
  });

  group('scenarios', () {
    test('each has twelve messages: ten, then two after the goodbye', () {
      for (final s in partnerScenarios) {
        expect(s.learnerMessages, hasLength(12), reason: s.id);
      }
    });

    test('ids are unique and the question about Spanish is in a scenario', () {
      expect({for (final s in partnerScenarios) s.id}.length,
          partnerScenarios.length);
      expect(
        partnerScenarios.any((s) => s.asksAboutSpanishAtExchanges.isNotEmpty),
        isTrue,
      );
      expect(
        partnerScenarios.any((s) => s.changesSubjectAtExchanges.isNotEmpty),
        isTrue,
      );
    });

    test('the marked exchanges really are that kind of message', () {
      final s = partnerScenarios.first;
      for (final n in s.asksAboutSpanishAtExchanges) {
        expect(s.learnerMessages[n - 1], contains('?'));
        expect(s.learnerMessages[n - 1].toLowerCase(), contains('se dice'));
      }
      for (final n in s.changesSubjectAtExchanges) {
        expect(s.learnerMessages[n - 1], contains('otra cosa'));
      }
    });

    test('scenario filter', () {
      expect(partnerScenariosFrom({}), hasLength(partnerScenarios.length));
      expect(
        partnerScenariosFrom({'PARTNER_SCENARIO': 'peninsular-vosotros'}),
        hasLength(1),
      );
      expect(
        () => partnerScenariosFrom({'PARTNER_SCENARIO': 'nope'}),
        throwsArgumentError,
      );
      expect(partnerLiveOptIn({}), isFalse);
      expect(partnerLiveOptIn({'PARTNER_LIVE': 'true'}), isTrue);
    });
  });

  group('automatic checks', () {
    test('counts question marks', () {
      expect(questionCount('Qué bien. ¿Y tú, qué haces?'), 1);
      expect(questionCount('¿Cómo estás? ¿Y tu perro?'), 2);
      expect(questionCount('Me alegro mucho.'), 0);
    });

    test('allows one question before the goodbye and none from it on', () {
      final s = partnerScenarios.first;
      expect(
        checkReply(scenario: s, exchange: 3, reply: '¿Y tú?').questionRuleKept,
        isTrue,
      );
      expect(
        checkReply(scenario: s, exchange: 3, reply: '¿Y tú? ¿Y él?')
            .questionRuleKept,
        isFalse,
      );
      expect(
        checkReply(scenario: s, exchange: 10, reply: '¿Y tú?').questionRuleKept,
        isFalse,
      );
      expect(
        checkReply(scenario: s, exchange: 11, reply: 'Claro.').questionRuleKept,
        isTrue,
      );
    });

    test('spots comments on the learner\'s Spanish', () {
      expect(commentsOnLearnerSpanish('Se dice "desde hace dos años".'), isTrue);
      expect(commentsOnLearnerSpanish('Tu español es muy bueno.'), isTrue);
      expect(commentsOnLearnerSpanish('Eso es correcto.'), isTrue);
      expect(commentsOnLearnerSpanish('Me encanta Valencia.'), isFalse);
    });

    test('spots the line that points to the feedback', () {
      expect(
        pointsToFeedback('Eso lo verás en los comentarios al final del chat.'),
        isTrue,
      );
      expect(pointsToFeedback('Después del chat te doy mi opinión.'), isTrue);
      expect(pointsToFeedback('Me gusta mucho tu perro.'), isFalse);
    });

    test('when asked about the Spanish, pointing to feedback is the rule', () {
      final s = partnerScenarios.first; // asks at exchange 4
      final pointed = checkReply(
        scenario: s,
        exchange: 4,
        reply: 'Eso lo verás en los comentarios después. ¿Qué hiciste hoy?',
      );
      expect(pointed.learnerAskedAboutSpanish, isTrue);
      expect(pointed.spanishRuleKept, isTrue);
      final answered = checkReply(
        scenario: s,
        exchange: 4,
        reply: 'Se dice "desde hace dos años".',
      );
      expect(answered.spanishRuleKept, isFalse);
    });

    test('spots a goodbye', () {
      expect(saysGoodbye('Ha sido un placer hablar contigo. ¡Hasta pronto!'), isTrue);
      expect(saysGoodbye('Nos vemos en el próximo chat.'), isTrue);
      expect(saysGoodbye('¿Y qué comes los domingos?'), isFalse);
    });

    test('flags words that go against the learner\'s own forms', () {
      expect(
        varietyClashes(LearnerVariety.latinAmerican, 'Usad vosotros el ordenador.'),
        containsAll(['vosotros', 'ordenador']),
      );
      expect(
        varietyClashes(LearnerVariety.latinAmerican,
            'Ustedes tienen una computadora muy buena.'),
        isEmpty,
      );
      expect(
        varietyClashes(LearnerVariety.peninsular, 'Ustedes usan el celular.'),
        containsAll(['Ustedes', 'celular']),
      );
      expect(
        varietyClashes(LearnerVariety.peninsular, 'Vosotros usáis el móvil.'),
        isEmpty,
      );
      expect(
        varietyClashes(LearnerVariety.neutralTu, 'Qué guay, tío.'),
        containsAll(['guay', 'tío']),
      );
    });

    test('counts words and flags long replies', () {
      expect(wordCount('uno dos  tres'), 3);
      expect(wordCount('  '), 0);
      final long = checkReply(
        scenario: partnerScenarios.first,
        exchange: 2,
        reply: List.filled(81, 'hola').join(' '),
      );
      expect(long.tooLong, isTrue);
    });

    test('checks titles and summaries', () {
      expect(checkLabel('Fin de semana con Max', 'Talked about a dog.').titleOk,
          isTrue);
      expect(checkLabel('"El perro"', 'x.').titleOk, isFalse);
      expect(checkLabel('Una conversación muy larga sobre muchas cosas', 'x.')
          .titleOk, isFalse);
      expect(checkLabel('Comida', 'One. Two. Three. Four.').summaryOk, isFalse);
      expect(checkLabel('Comida', 'Talked about paella').summaryOk, isTrue);
    });
  });

  group('calls', () {
    test('reads the reply and the token counts', () {
      final parsed = parseCompletion(jsonEncode({
        'choices': [
          {'message': {'content': ' Hola. '}},
        ],
        'usage': {'prompt_tokens': 120, 'completion_tokens': 15},
      }));
      expect(parsed.text, 'Hola.');
      expect(parsed.promptTokens, 120);
      expect(parsed.completionTokens, 15);
    });

    test('a reply with no text is an error', () {
      expect(
        () => parseCompletion(jsonEncode({'choices': []})),
        throwsA(isA<PartnerCallException>()),
      );
      expect(
        () => parseCompletion(jsonEncode({
          'choices': [
            {'message': {'content': ''}},
          ],
        })),
        throwsA(isA<PartnerCallException>()),
      );
    });

    test('the transcript labels both sides', () {
      expect(
        transcriptOf(const [ChatTurn('user', 'Hola'), ChatTurn('assistant', 'Buenas')]),
        'Learner: Hola\nPartner: Buenas',
      );
    });
  });

  group('report', () {
    ScenarioRun fakeRun({String reply = 'Qué bien. ¿Y tú?'}) {
      final s = partnerScenarios.first;
      final turns = <ChatTurn>[];
      final checks = <ReplyChecks>[];
      for (var i = 0; i < 12; i++) {
        turns
          ..add(ChatTurn('user', s.learnerMessages[i]))
          ..add(ChatTurn('assistant', i + 1 >= 10 ? 'Hasta pronto.' : reply));
        checks.add(checkReply(
          scenario: s,
          exchange: i + 1,
          reply: i + 1 >= 10 ? 'Hasta pronto.' : reply,
        ));
      }
      return ScenarioRun(
        scenario: s,
        runIndex: 1,
        turns: turns,
        checks: checks,
        usageThroughTenth: const CallUsage(
          promptTokens: 20000,
          completionTokens: 1000,
          wallClockMs: 10000,
        ),
        titleCall: const CallUsage(
          promptTokens: 300, completionTokens: 20, wallClockMs: 500),
        summaryCall: const CallUsage(
          promptTokens: 2000, completionTokens: 60, wallClockMs: 900),
        titleChecks: checkLabel('Fin de semana', 'Talked about a dog.'),
        summaryChecks: checkLabel('Fin de semana', 'Talked about a dog.'),
        signOffChecks: checkReply(
          scenario: s, exchange: 10, reply: 'Ha sido un placer. ¡Hasta pronto!'),
        signOffUsage: CallUsage.zero,
      );
    }

    test('states the checks, the cost of a ten-exchange chat and transcripts', () {
      final report = buildPartnerReport(
        model: 'gpt-6-luna',
        runs: [fakeRun()],
        generatedAt: DateTime.utc(2026, 11, 8),
      );
      expect(report, contains('## Summary'));
      expect(report, contains('exchanges 1 to 9): 9 of 9'));
      expect(report, contains('Soft goodbye at exchange 10'));
      expect(report, contains('Sign-off at the size limit'));
      expect(report, contains('Average cost of a ten-exchange chat'));
      // 22,300 input and 1,080 output tokens at $0.10 / $0.50 per million.
      expect(report, contains('\$0.002770'));
      expect(report, contains('**Learner:** Hola, como estas?'));
      expect(report, contains('**Title (after the first exchange):** Fin de semana'));
    });

    test('flags a reply with too many questions', () {
      final report = buildPartnerReport(
        model: 'gpt-6-luna',
        runs: [fakeRun(reply: '¿Cómo estás? ¿Y tu perro?')],
        generatedAt: DateTime.utc(2026, 11, 8),
      );
      expect(report, contains('MORE QUESTIONS THAN ALLOWED (2)'));
      expect(report, contains('exchanges 1 to 9): 0 of 9'));
    });

    test('an errored chat is reported, not hidden', () {
      final report = buildPartnerReport(
        model: 'gpt-6-luna',
        runs: [errorRun(partnerScenarios.first, 1, 'HTTP 500')],
        generatedAt: DateTime.utc(2026, 11, 8),
      );
      expect(report, contains('1 stopped by an error'));
      expect(report, contains('Stopped by an error:** HTTP 500'));
    });
  });

  test(
    'partner replies against the scripted learners',
    tags: 'live',
    () async {
      final environment = Platform.environment;
      if (!partnerLiveOptIn(environment)) {
        // ignore: avoid_print
        print('Skipping live partner run. Set PARTNER_LIVE=true to opt in.');
        return;
      }
      final apiKey = openAiApiKeyFor(environment);
      if (apiKey.isEmpty) fail(noApiKeyMessage);

      final model = _setting(environment, 'PARTNER_MODEL', defaultPartnerModel);
      final outputPath =
          _setting(environment, 'PARTNER_OUTPUT', defaultPartnerOutputPath);
      final delayMs =
          int.tryParse(environment['PARTNER_CALL_DELAY_MS']?.trim() ?? '') ??
          500;
      final runsPer =
          int.tryParse(environment['PARTNER_RUNS']?.trim() ?? '') ?? 1;
      final httpClient = HttpClient();

      final runs = <ScenarioRun>[];
      for (final scenario in partnerScenariosFrom(environment)) {
        for (var run = 1; run <= runsPer; run++) {
          final result = await runScenario(
            apiKey: apiKey,
            httpClient: httpClient,
            model: model,
            scenario: scenario,
            runIndex: run,
            callDelay: Duration(milliseconds: delayMs),
            missingWords: partnerMissingWordsFrom(environment),
          );
          runs.add(result);
          // ignore: avoid_print
          print(
            '=== ${scenario.id} (run $run/$runsPer) '
            '${result.error ?? 'done'}',
          );
        }
      }

      final report = buildPartnerReport(
        model: model,
        runs: runs,
        generatedAt: DateTime.now(),
      );
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsString(report);
      // ignore: avoid_print
      print('Wrote partner prompt report to $outputPath');
    },
  );
}
