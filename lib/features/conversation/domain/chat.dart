import '../../../core/enums/language.dart';
import '../../corrections/domain/correction_input_mode.dart';

/// Who wrote a message in a chat.
enum ChatSpeaker {
  learner,
  partner;

  String toJson() => name;

  static ChatSpeaker fromJson(Object? value) =>
      value == 'partner' ? ChatSpeaker.partner : ChatSpeaker.learner;
}

/// Who wrote the first message of a chat (decision B3, point 2).
enum ChatStarter {
  /// The learner tapped New chat and wrote first.
  learner,

  /// The partner wrote first, with a greeting or a follow-up.
  partner;

  String toJson() => name;

  static ChatStarter fromJson(Object? value) =>
      value == 'partner' ? ChatStarter.partner : ChatStarter.learner;
}

/// The three ways a chat begins in the first build (decisions B3 point 2 and
/// B4 part 2).
enum ChatKind {
  /// The learner tapped New chat.
  newChat,

  /// The partner's everyday greeting at a time the learner set.
  checkIn,

  /// The partner's follow-up to an earlier chat.
  followUp;

  String toJson() => name;

  static ChatKind fromJson(Object? value) => switch (value) {
    'checkIn' => ChatKind.checkIn,
    'followUp' => ChatKind.followUp,
    _ => ChatKind.newChat,
  };
}

/// One message in a chat.
class ChatTurn {
  const ChatTurn({
    required this.speaker,
    required this.text,
    required this.sentAt,
    this.input,
  });

  /// A message the learner sent, marked typed or spoken.
  const ChatTurn.learner({
    required this.text,
    required this.sentAt,
    CorrectionInputMode this.input = CorrectionInputMode.typed,
  }) : speaker = ChatSpeaker.learner;

  /// A message the partner wrote.
  const ChatTurn.partner({required this.text, required this.sentAt})
    : speaker = ChatSpeaker.partner,
      input = null;

  factory ChatTurn.fromJson(Map<String, Object?> json) {
    final speaker = ChatSpeaker.fromJson(json['speaker']);
    return ChatTurn(
      speaker: speaker,
      text: json['text'] as String? ?? '',
      sentAt: _readDate(json['sentAt']),
      input: speaker == ChatSpeaker.partner
          ? null
          : (json['input'] == 'spoken'
                ? CorrectionInputMode.spoken
                : CorrectionInputMode.typed),
    );
  }

  final ChatSpeaker speaker;
  final String text;

  /// When the message was sent. The chat view puts a day marker wherever
  /// two neighbouring messages fall on different days.
  final DateTime sentAt;

  /// Typed or spoken, for the learner's messages; always null for the
  /// partner's. The check after a sitting shows no Spelling points for
  /// spoken text (decision C3).
  final CorrectionInputMode? input;

  bool get isLearner => speaker == ChatSpeaker.learner;

  bool get isSpoken => input == CorrectionInputMode.spoken;

  Map<String, Object?> toJson() => {
    'speaker': speaker.toJson(),
    'text': text,
    'sentAt': sentAt.toIso8601String(),
    if (input != null) 'input': input!.name,
  };
}

/// One chat with the partner (decision B3, build step 3.2).
///
/// A chat is a plain value: every change returns a new [Chat]. It is kept on
/// the phone by `FileChatRepository`, in its own file beside History's.
class Chat {
  Chat({
    required this.id,
    required this.language,
    required this.createdAt,
    DateTime? updatedAt,
    this.title = '',
    this.startedBy = ChatStarter.learner,
    this.kind = ChatKind.newChat,
    List<ChatTurn> turns = const [],
    this.hasEnded = false,
    int checkedTurnCount = 0,
  }) : updatedAt = updatedAt ?? createdAt,
       turns = List.unmodifiable(turns),
       checkedTurnCount = checkedTurnCount < 0
           ? 0
           : (checkedTurnCount > turns.length
                 ? turns.length
                 : checkedTurnCount);

  /// An empty chat the learner is about to start by tapping New chat. It is
  /// not stored until the learner sends something.
  factory Chat.startedByLearner({
    required String id,
    required Language language,
    required DateTime now,
  }) => Chat(id: id, language: language, createdAt: now);

  factory Chat.fromJson(Map<String, Object?> json) {
    final createdAt = _readDate(json['createdAt']);
    final rawTurns = json['turns'];
    return Chat(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      language: Language.fromJson(json['language'] as String?),
      createdAt: createdAt,
      updatedAt: json['updatedAt'] == null
          ? createdAt
          : _readDate(json['updatedAt']),
      startedBy: ChatStarter.fromJson(json['startedBy']),
      kind: ChatKind.fromJson(json['kind']),
      turns: [
        if (rawTurns is List)
          for (final turn in rawTurns)
            if (turn is Map<String, Object?>) ChatTurn.fromJson(turn),
      ],
      hasEnded: json['hasEnded'] == true,
      checkedTurnCount: (json['checkedTurnCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;

  /// A short title the partner writes from the first exchange. Empty until
  /// then.
  final String title;

  final Language language;

  /// When the chat was begun.
  final DateTime createdAt;

  /// When the chat last changed: its newest message, or a later change such
  /// as its title or its ending. The Home list is ordered by this, newest
  /// first.
  final DateTime updatedAt;

  final ChatStarter startedBy;
  final ChatKind kind;

  /// Every message, oldest first.
  final List<ChatTurn> turns;

  /// True once the chat has reached its size limit and the partner has
  /// signed off (decision E1). Nothing more can be sent in an ended chat.
  final bool hasEnded;

  /// How far the chat has been checked: the number of messages, counted
  /// from the start, that have already been through the check after a
  /// sitting. The next check reads the learner's messages after this point.
  final int checkedTurnCount;

  /// The number of messages the learner has sent. The soft goodbye comes at
  /// about the tenth (decision B3, point 4).
  int get exchangeCount => turns.where((turn) => turn.isLearner).length;

  /// True once the learner has sent at least one message. Only then is the
  /// chat stored.
  bool get hasLearnerTurn => turns.any((turn) => turn.isLearner);

  /// The newest message, or null in an empty chat.
  ChatTurn? get lastTurn => turns.isEmpty ? null : turns.last;

  /// The messages not yet through the check after a sitting.
  List<ChatTurn> get uncheckedTurns => turns.sublist(checkedTurnCount);

  Chat copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatTurn>? turns,
    bool? hasEnded,
    int? checkedTurnCount,
  }) {
    return Chat(
      id: id,
      language: language,
      createdAt: createdAt,
      startedBy: startedBy,
      kind: kind,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
      turns: turns ?? this.turns,
      hasEnded: hasEnded ?? this.hasEnded,
      checkedTurnCount: checkedTurnCount ?? this.checkedTurnCount,
    );
  }

  /// The chat with [turn] added at the end. The chat's last-changed time
  /// becomes the message's time.
  Chat withTurn(ChatTurn turn) =>
      copyWith(turns: [...turns, turn], updatedAt: turn.sentAt);

  /// The chat with its title set, as the partner writes it from the first
  /// exchange. The order of the Home list does not change.
  Chat withTitle(String title) => copyWith(title: title.trim());

  /// The chat marked as ended at its size limit.
  Chat ended({required DateTime now}) =>
      copyWith(hasEnded: true, updatedAt: now);

  /// The chat with every message so far marked as checked.
  Chat withAllTurnsChecked() => copyWith(checkedTurnCount: turns.length);

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'language': language.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'startedBy': startedBy.toJson(),
    'kind': kind.toJson(),
    'hasEnded': hasEnded,
    // Written so the file can be read by eye; worked out from the turns
    // when the file is read back.
    'exchangeCount': exchangeCount,
    'checkedTurnCount': checkedTurnCount,
    'turns': [for (final turn in turns) turn.toJson()],
  };
}

/// What is kept of a chat after it has been pushed off Home by a sixth chat
/// (decision B3, points 2 and 7): its title, its dates and the partner's
/// short summary, which the partner's follow-ups draw on.
class DeletedChatSummary {
  const DeletedChatSummary({
    required this.chatId,
    required this.title,
    required this.language,
    required this.createdAt,
    required this.lastActiveAt,
    required this.deletedAt,
    this.summary = '',
  });

  /// The record made at the moment [chat] is deleted. The summary is empty
  /// until the partner has written it.
  factory DeletedChatSummary.of(Chat chat, {required DateTime deletedAt}) =>
      DeletedChatSummary(
        chatId: chat.id,
        title: chat.title,
        language: chat.language,
        createdAt: chat.createdAt,
        lastActiveAt: chat.updatedAt,
        deletedAt: deletedAt,
      );

  factory DeletedChatSummary.fromJson(Map<String, Object?> json) {
    final createdAt = _readDate(json['createdAt']);
    return DeletedChatSummary(
      chatId: json['chatId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      language: Language.fromJson(json['language'] as String?),
      createdAt: createdAt,
      lastActiveAt: json['lastActiveAt'] == null
          ? createdAt
          : _readDate(json['lastActiveAt']),
      deletedAt: json['deletedAt'] == null
          ? createdAt
          : _readDate(json['deletedAt']),
      summary: json['summary'] as String? ?? '',
    );
  }

  final String chatId;
  final String title;
  final Language language;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final DateTime deletedAt;

  /// One or two short sentences from the partner saying what the chat was
  /// about. Empty if it has not been written, for example with no
  /// connection when the chat was deleted.
  final String summary;

  bool get hasSummary => summary.trim().isNotEmpty;

  DeletedChatSummary withSummary(String summary) => DeletedChatSummary(
    chatId: chatId,
    title: title,
    language: language,
    createdAt: createdAt,
    lastActiveAt: lastActiveAt,
    deletedAt: deletedAt,
    summary: summary.trim(),
  );

  Map<String, Object?> toJson() => {
    'chatId': chatId,
    'title': title,
    'language': language.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'lastActiveAt': lastActiveAt.toIso8601String(),
    'deletedAt': deletedAt.toIso8601String(),
    'summary': summary,
  };
}

/// A date from the file. A missing or unreadable date reads as the earliest
/// possible time, so a damaged entry sorts last and is the first to go.
DateTime _readDate(Object? value) =>
    (value is String ? DateTime.tryParse(value) : null) ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
