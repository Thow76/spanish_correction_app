// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_database.dart';

// ignore_for_file: type=lint
class $PracticeItemsTable extends PracticeItems
    with TableInfo<$PracticeItemsTable, PracticeItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newPracticeId,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalSentenceMeta = const VerificationMeta(
    'originalSentence',
  );
  @override
  late final GeneratedColumn<String> originalSentence = GeneratedColumn<String>(
    'original_sentence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctedSentenceMeta = const VerificationMeta(
    'correctedSentence',
  );
  @override
  late final GeneratedColumn<String> correctedSentence =
      GeneratedColumn<String>(
        'corrected_sentence',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _originalPhraseMeta = const VerificationMeta(
    'originalPhrase',
  );
  @override
  late final GeneratedColumn<String> originalPhrase = GeneratedColumn<String>(
    'original_phrase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctedPhraseMeta = const VerificationMeta(
    'correctedPhrase',
  );
  @override
  late final GeneratedColumn<String> correctedPhrase = GeneratedColumn<String>(
    'corrected_phrase',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalStartMeta = const VerificationMeta(
    'originalStart',
  );
  @override
  late final GeneratedColumn<int> originalStart = GeneratedColumn<int>(
    'original_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalEndMeta = const VerificationMeta(
    'originalEnd',
  );
  @override
  late final GeneratedColumn<int> originalEnd = GeneratedColumn<int>(
    'original_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctedStartMeta = const VerificationMeta(
    'correctedStart',
  );
  @override
  late final GeneratedColumn<int> correctedStart = GeneratedColumn<int>(
    'corrected_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctedEndMeta = const VerificationMeta(
    'correctedEnd',
  );
  @override
  late final GeneratedColumn<int> correctedEnd = GeneratedColumn<int>(
    'corrected_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _englishSentenceMeta = const VerificationMeta(
    'englishSentence',
  );
  @override
  late final GeneratedColumn<String> englishSentence = GeneratedColumn<String>(
    'english_sentence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _englishHighlightStartMeta =
      const VerificationMeta('englishHighlightStart');
  @override
  late final GeneratedColumn<int> englishHighlightStart = GeneratedColumn<int>(
    'english_highlight_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _englishHighlightEndMeta =
      const VerificationMeta('englishHighlightEnd');
  @override
  late final GeneratedColumn<int> englishHighlightEnd = GeneratedColumn<int>(
    'english_highlight_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    check: () => category.isIn(const [
      'Spelling',
      'Grammar',
      'Word Choice',
      'Natural phrasing',
    ]),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PracticeSubcategory?, String>
  subcategory =
      GeneratedColumn<String>(
        'subcategory',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      ).withConverter<PracticeSubcategory?>(
        $PracticeItemsTable.$convertersubcategory,
      );
  static const VerificationMeta _contextTextMeta = const VerificationMeta(
    'contextText',
  );
  @override
  late final GeneratedColumn<String> contextText = GeneratedColumn<String>(
    'context_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
    'chat_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PracticeInputMode, String>
  inputMode = GeneratedColumn<String>(
    'input_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<PracticeInputMode>($PracticeItemsTable.$converterinputMode);
  static const VerificationMeta _savedCorrectionIdMeta = const VerificationMeta(
    'savedCorrectionId',
  );
  @override
  late final GeneratedColumn<String> savedCorrectionId =
      GeneratedColumn<String>(
        'saved_correction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
      );
  static const VerificationMeta _ladderStageMeta = const VerificationMeta(
    'ladderStage',
  );
  @override
  late final GeneratedColumn<int> ladderStage = GeneratedColumn<int>(
    'ladder_stage',
    aliasedName,
    false,
    check: () => ComparableExpr(ladderStage).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lockedStageMeta = const VerificationMeta(
    'lockedStage',
  );
  @override
  late final GeneratedColumn<int> lockedStage = GeneratedColumn<int>(
    'locked_stage',
    aliasedName,
    false,
    check: () => ComparableExpr(lockedStage).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _retiredMeta = const VerificationMeta(
    'retired',
  );
  @override
  late final GeneratedColumn<bool> retired = GeneratedColumn<bool>(
    'retired',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retired" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    changedAt,
    createdAt,
    language,
    originalSentence,
    correctedSentence,
    originalPhrase,
    correctedPhrase,
    originalStart,
    originalEnd,
    correctedStart,
    correctedEnd,
    explanation,
    englishSentence,
    englishHighlightStart,
    englishHighlightEnd,
    category,
    subcategory,
    contextText,
    chatId,
    inputMode,
    savedCorrectionId,
    ladderStage,
    lockedStage,
    retired,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('original_sentence')) {
      context.handle(
        _originalSentenceMeta,
        originalSentence.isAcceptableOrUnknown(
          data['original_sentence']!,
          _originalSentenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalSentenceMeta);
    }
    if (data.containsKey('corrected_sentence')) {
      context.handle(
        _correctedSentenceMeta,
        correctedSentence.isAcceptableOrUnknown(
          data['corrected_sentence']!,
          _correctedSentenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctedSentenceMeta);
    }
    if (data.containsKey('original_phrase')) {
      context.handle(
        _originalPhraseMeta,
        originalPhrase.isAcceptableOrUnknown(
          data['original_phrase']!,
          _originalPhraseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalPhraseMeta);
    }
    if (data.containsKey('corrected_phrase')) {
      context.handle(
        _correctedPhraseMeta,
        correctedPhrase.isAcceptableOrUnknown(
          data['corrected_phrase']!,
          _correctedPhraseMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctedPhraseMeta);
    }
    if (data.containsKey('original_start')) {
      context.handle(
        _originalStartMeta,
        originalStart.isAcceptableOrUnknown(
          data['original_start']!,
          _originalStartMeta,
        ),
      );
    }
    if (data.containsKey('original_end')) {
      context.handle(
        _originalEndMeta,
        originalEnd.isAcceptableOrUnknown(
          data['original_end']!,
          _originalEndMeta,
        ),
      );
    }
    if (data.containsKey('corrected_start')) {
      context.handle(
        _correctedStartMeta,
        correctedStart.isAcceptableOrUnknown(
          data['corrected_start']!,
          _correctedStartMeta,
        ),
      );
    }
    if (data.containsKey('corrected_end')) {
      context.handle(
        _correctedEndMeta,
        correctedEnd.isAcceptableOrUnknown(
          data['corrected_end']!,
          _correctedEndMeta,
        ),
      );
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    }
    if (data.containsKey('english_sentence')) {
      context.handle(
        _englishSentenceMeta,
        englishSentence.isAcceptableOrUnknown(
          data['english_sentence']!,
          _englishSentenceMeta,
        ),
      );
    }
    if (data.containsKey('english_highlight_start')) {
      context.handle(
        _englishHighlightStartMeta,
        englishHighlightStart.isAcceptableOrUnknown(
          data['english_highlight_start']!,
          _englishHighlightStartMeta,
        ),
      );
    }
    if (data.containsKey('english_highlight_end')) {
      context.handle(
        _englishHighlightEndMeta,
        englishHighlightEnd.isAcceptableOrUnknown(
          data['english_highlight_end']!,
          _englishHighlightEndMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('context_text')) {
      context.handle(
        _contextTextMeta,
        contextText.isAcceptableOrUnknown(
          data['context_text']!,
          _contextTextMeta,
        ),
      );
    }
    if (data.containsKey('chat_id')) {
      context.handle(
        _chatIdMeta,
        chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta),
      );
    }
    if (data.containsKey('saved_correction_id')) {
      context.handle(
        _savedCorrectionIdMeta,
        savedCorrectionId.isAcceptableOrUnknown(
          data['saved_correction_id']!,
          _savedCorrectionIdMeta,
        ),
      );
    }
    if (data.containsKey('ladder_stage')) {
      context.handle(
        _ladderStageMeta,
        ladderStage.isAcceptableOrUnknown(
          data['ladder_stage']!,
          _ladderStageMeta,
        ),
      );
    }
    if (data.containsKey('locked_stage')) {
      context.handle(
        _lockedStageMeta,
        lockedStage.isAcceptableOrUnknown(
          data['locked_stage']!,
          _lockedStageMeta,
        ),
      );
    }
    if (data.containsKey('retired')) {
      context.handle(
        _retiredMeta,
        retired.isAcceptableOrUnknown(data['retired']!, _retiredMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      originalSentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_sentence'],
      )!,
      correctedSentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corrected_sentence'],
      )!,
      originalPhrase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_phrase'],
      )!,
      correctedPhrase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}corrected_phrase'],
      )!,
      originalStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_start'],
      ),
      originalEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_end'],
      ),
      correctedStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}corrected_start'],
      ),
      correctedEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}corrected_end'],
      ),
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      )!,
      englishSentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_sentence'],
      )!,
      englishHighlightStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}english_highlight_start'],
      ),
      englishHighlightEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}english_highlight_end'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      subcategory: $PracticeItemsTable.$convertersubcategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}subcategory'],
        )!,
      ),
      contextText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context_text'],
      )!,
      chatId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chat_id'],
      ),
      inputMode: $PracticeItemsTable.$converterinputMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}input_mode'],
        )!,
      ),
      savedCorrectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}saved_correction_id'],
      ),
      ladderStage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ladder_stage'],
      )!,
      lockedStage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}locked_stage'],
      )!,
      retired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retired'],
      )!,
    );
  }

  @override
  $PracticeItemsTable createAlias(String alias) {
    return $PracticeItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<PracticeSubcategory?, String> $convertersubcategory =
      const PracticeSubcategoryConverter();
  static JsonTypeConverter2<PracticeInputMode, String, String>
  $converterinputMode = const EnumNameConverter<PracticeInputMode>(
    PracticeInputMode.values,
  );
}

class PracticeItem extends DataClass implements Insertable<PracticeItem> {
  /// Stable id of this practice item.
  final String id;

  /// When this row was last changed (G2).
  final DateTime changedAt;

  /// When the games' copy was made.
  final DateTime createdAt;

  /// The language of the mistake, as `Language.name` ("spanish").
  final String language;

  /// The sentence as the learner wrote it.
  final String originalSentence;

  /// The sentence as suggested.
  final String correctedSentence;

  /// The phrase as written.
  final String originalPhrase;

  /// The phrase as suggested.
  final String correctedPhrase;

  /// Where the phrase sits in [originalSentence], when known.
  final int? originalStart;
  final int? originalEnd;

  /// Where the phrase sits in [correctedSentence], when known.
  final int? correctedStart;
  final int? correctedEnd;

  /// The short explanation of the point.
  final String explanation;

  /// The English version of the sentence; empty when there is none.
  final String englishSentence;

  /// Where the matching part sits in [englishSentence], when known.
  final int? englishHighlightStart;
  final int? englishHighlightEnd;

  /// One of the four category names (`ErrorCategory.label`).
  final String category;

  /// One of G4's fixed list for [category], or none. Never free text.
  final PracticeSubcategory? subcategory;

  /// The learner's whole message or checked text, kept as a copy so "Show
  /// context" still works after the chat has gone (G4, point 4).
  final String contextText;

  /// The chat the mistake came from, or none.
  final String? chatId;

  /// Whether the text was typed or spoken.
  final PracticeInputMode inputMode;

  /// The id of the Saved point this copy was made from, or none (a mistake
  /// brought in from the old sheet has no Saved point). One copy per Saved
  /// point.
  final String? savedCorrectionId;

  /// Where the mistake stands on the stage ladder, as step P.2's rank
  /// (0 = not on the ladder yet).
  final int ladderStage;

  /// The stage the mistake dropped back from and has to win back, as a
  /// rank, or 0 when nothing is locked.
  final int lockedStage;

  /// Whether the mistake is finished: every step passed, nothing left to
  /// play.
  final bool retired;
  const PracticeItem({
    required this.id,
    required this.changedAt,
    required this.createdAt,
    required this.language,
    required this.originalSentence,
    required this.correctedSentence,
    required this.originalPhrase,
    required this.correctedPhrase,
    this.originalStart,
    this.originalEnd,
    this.correctedStart,
    this.correctedEnd,
    required this.explanation,
    required this.englishSentence,
    this.englishHighlightStart,
    this.englishHighlightEnd,
    required this.category,
    this.subcategory,
    required this.contextText,
    this.chatId,
    required this.inputMode,
    this.savedCorrectionId,
    required this.ladderStage,
    required this.lockedStage,
    required this.retired,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['changed_at'] = Variable<DateTime>(changedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['language'] = Variable<String>(language);
    map['original_sentence'] = Variable<String>(originalSentence);
    map['corrected_sentence'] = Variable<String>(correctedSentence);
    map['original_phrase'] = Variable<String>(originalPhrase);
    map['corrected_phrase'] = Variable<String>(correctedPhrase);
    if (!nullToAbsent || originalStart != null) {
      map['original_start'] = Variable<int>(originalStart);
    }
    if (!nullToAbsent || originalEnd != null) {
      map['original_end'] = Variable<int>(originalEnd);
    }
    if (!nullToAbsent || correctedStart != null) {
      map['corrected_start'] = Variable<int>(correctedStart);
    }
    if (!nullToAbsent || correctedEnd != null) {
      map['corrected_end'] = Variable<int>(correctedEnd);
    }
    map['explanation'] = Variable<String>(explanation);
    map['english_sentence'] = Variable<String>(englishSentence);
    if (!nullToAbsent || englishHighlightStart != null) {
      map['english_highlight_start'] = Variable<int>(englishHighlightStart);
    }
    if (!nullToAbsent || englishHighlightEnd != null) {
      map['english_highlight_end'] = Variable<int>(englishHighlightEnd);
    }
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || subcategory != null) {
      map['subcategory'] = Variable<String>(
        $PracticeItemsTable.$convertersubcategory.toSql(subcategory),
      );
    }
    map['context_text'] = Variable<String>(contextText);
    if (!nullToAbsent || chatId != null) {
      map['chat_id'] = Variable<String>(chatId);
    }
    {
      map['input_mode'] = Variable<String>(
        $PracticeItemsTable.$converterinputMode.toSql(inputMode),
      );
    }
    if (!nullToAbsent || savedCorrectionId != null) {
      map['saved_correction_id'] = Variable<String>(savedCorrectionId);
    }
    map['ladder_stage'] = Variable<int>(ladderStage);
    map['locked_stage'] = Variable<int>(lockedStage);
    map['retired'] = Variable<bool>(retired);
    return map;
  }

  PracticeItemsCompanion toCompanion(bool nullToAbsent) {
    return PracticeItemsCompanion(
      id: Value(id),
      changedAt: Value(changedAt),
      createdAt: Value(createdAt),
      language: Value(language),
      originalSentence: Value(originalSentence),
      correctedSentence: Value(correctedSentence),
      originalPhrase: Value(originalPhrase),
      correctedPhrase: Value(correctedPhrase),
      originalStart: originalStart == null && nullToAbsent
          ? const Value.absent()
          : Value(originalStart),
      originalEnd: originalEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(originalEnd),
      correctedStart: correctedStart == null && nullToAbsent
          ? const Value.absent()
          : Value(correctedStart),
      correctedEnd: correctedEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(correctedEnd),
      explanation: Value(explanation),
      englishSentence: Value(englishSentence),
      englishHighlightStart: englishHighlightStart == null && nullToAbsent
          ? const Value.absent()
          : Value(englishHighlightStart),
      englishHighlightEnd: englishHighlightEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(englishHighlightEnd),
      category: Value(category),
      subcategory: subcategory == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategory),
      contextText: Value(contextText),
      chatId: chatId == null && nullToAbsent
          ? const Value.absent()
          : Value(chatId),
      inputMode: Value(inputMode),
      savedCorrectionId: savedCorrectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(savedCorrectionId),
      ladderStage: Value(ladderStage),
      lockedStage: Value(lockedStage),
      retired: Value(retired),
    );
  }

  factory PracticeItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeItem(
      id: serializer.fromJson<String>(json['id']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      language: serializer.fromJson<String>(json['language']),
      originalSentence: serializer.fromJson<String>(json['originalSentence']),
      correctedSentence: serializer.fromJson<String>(json['correctedSentence']),
      originalPhrase: serializer.fromJson<String>(json['originalPhrase']),
      correctedPhrase: serializer.fromJson<String>(json['correctedPhrase']),
      originalStart: serializer.fromJson<int?>(json['originalStart']),
      originalEnd: serializer.fromJson<int?>(json['originalEnd']),
      correctedStart: serializer.fromJson<int?>(json['correctedStart']),
      correctedEnd: serializer.fromJson<int?>(json['correctedEnd']),
      explanation: serializer.fromJson<String>(json['explanation']),
      englishSentence: serializer.fromJson<String>(json['englishSentence']),
      englishHighlightStart: serializer.fromJson<int?>(
        json['englishHighlightStart'],
      ),
      englishHighlightEnd: serializer.fromJson<int?>(
        json['englishHighlightEnd'],
      ),
      category: serializer.fromJson<String>(json['category']),
      subcategory: serializer.fromJson<PracticeSubcategory?>(
        json['subcategory'],
      ),
      contextText: serializer.fromJson<String>(json['contextText']),
      chatId: serializer.fromJson<String?>(json['chatId']),
      inputMode: $PracticeItemsTable.$converterinputMode.fromJson(
        serializer.fromJson<String>(json['inputMode']),
      ),
      savedCorrectionId: serializer.fromJson<String?>(
        json['savedCorrectionId'],
      ),
      ladderStage: serializer.fromJson<int>(json['ladderStage']),
      lockedStage: serializer.fromJson<int>(json['lockedStage']),
      retired: serializer.fromJson<bool>(json['retired']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'changedAt': serializer.toJson<DateTime>(changedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'language': serializer.toJson<String>(language),
      'originalSentence': serializer.toJson<String>(originalSentence),
      'correctedSentence': serializer.toJson<String>(correctedSentence),
      'originalPhrase': serializer.toJson<String>(originalPhrase),
      'correctedPhrase': serializer.toJson<String>(correctedPhrase),
      'originalStart': serializer.toJson<int?>(originalStart),
      'originalEnd': serializer.toJson<int?>(originalEnd),
      'correctedStart': serializer.toJson<int?>(correctedStart),
      'correctedEnd': serializer.toJson<int?>(correctedEnd),
      'explanation': serializer.toJson<String>(explanation),
      'englishSentence': serializer.toJson<String>(englishSentence),
      'englishHighlightStart': serializer.toJson<int?>(englishHighlightStart),
      'englishHighlightEnd': serializer.toJson<int?>(englishHighlightEnd),
      'category': serializer.toJson<String>(category),
      'subcategory': serializer.toJson<PracticeSubcategory?>(subcategory),
      'contextText': serializer.toJson<String>(contextText),
      'chatId': serializer.toJson<String?>(chatId),
      'inputMode': serializer.toJson<String>(
        $PracticeItemsTable.$converterinputMode.toJson(inputMode),
      ),
      'savedCorrectionId': serializer.toJson<String?>(savedCorrectionId),
      'ladderStage': serializer.toJson<int>(ladderStage),
      'lockedStage': serializer.toJson<int>(lockedStage),
      'retired': serializer.toJson<bool>(retired),
    };
  }

  PracticeItem copyWith({
    String? id,
    DateTime? changedAt,
    DateTime? createdAt,
    String? language,
    String? originalSentence,
    String? correctedSentence,
    String? originalPhrase,
    String? correctedPhrase,
    Value<int?> originalStart = const Value.absent(),
    Value<int?> originalEnd = const Value.absent(),
    Value<int?> correctedStart = const Value.absent(),
    Value<int?> correctedEnd = const Value.absent(),
    String? explanation,
    String? englishSentence,
    Value<int?> englishHighlightStart = const Value.absent(),
    Value<int?> englishHighlightEnd = const Value.absent(),
    String? category,
    Value<PracticeSubcategory?> subcategory = const Value.absent(),
    String? contextText,
    Value<String?> chatId = const Value.absent(),
    PracticeInputMode? inputMode,
    Value<String?> savedCorrectionId = const Value.absent(),
    int? ladderStage,
    int? lockedStage,
    bool? retired,
  }) => PracticeItem(
    id: id ?? this.id,
    changedAt: changedAt ?? this.changedAt,
    createdAt: createdAt ?? this.createdAt,
    language: language ?? this.language,
    originalSentence: originalSentence ?? this.originalSentence,
    correctedSentence: correctedSentence ?? this.correctedSentence,
    originalPhrase: originalPhrase ?? this.originalPhrase,
    correctedPhrase: correctedPhrase ?? this.correctedPhrase,
    originalStart: originalStart.present
        ? originalStart.value
        : this.originalStart,
    originalEnd: originalEnd.present ? originalEnd.value : this.originalEnd,
    correctedStart: correctedStart.present
        ? correctedStart.value
        : this.correctedStart,
    correctedEnd: correctedEnd.present ? correctedEnd.value : this.correctedEnd,
    explanation: explanation ?? this.explanation,
    englishSentence: englishSentence ?? this.englishSentence,
    englishHighlightStart: englishHighlightStart.present
        ? englishHighlightStart.value
        : this.englishHighlightStart,
    englishHighlightEnd: englishHighlightEnd.present
        ? englishHighlightEnd.value
        : this.englishHighlightEnd,
    category: category ?? this.category,
    subcategory: subcategory.present ? subcategory.value : this.subcategory,
    contextText: contextText ?? this.contextText,
    chatId: chatId.present ? chatId.value : this.chatId,
    inputMode: inputMode ?? this.inputMode,
    savedCorrectionId: savedCorrectionId.present
        ? savedCorrectionId.value
        : this.savedCorrectionId,
    ladderStage: ladderStage ?? this.ladderStage,
    lockedStage: lockedStage ?? this.lockedStage,
    retired: retired ?? this.retired,
  );
  PracticeItem copyWithCompanion(PracticeItemsCompanion data) {
    return PracticeItem(
      id: data.id.present ? data.id.value : this.id,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      language: data.language.present ? data.language.value : this.language,
      originalSentence: data.originalSentence.present
          ? data.originalSentence.value
          : this.originalSentence,
      correctedSentence: data.correctedSentence.present
          ? data.correctedSentence.value
          : this.correctedSentence,
      originalPhrase: data.originalPhrase.present
          ? data.originalPhrase.value
          : this.originalPhrase,
      correctedPhrase: data.correctedPhrase.present
          ? data.correctedPhrase.value
          : this.correctedPhrase,
      originalStart: data.originalStart.present
          ? data.originalStart.value
          : this.originalStart,
      originalEnd: data.originalEnd.present
          ? data.originalEnd.value
          : this.originalEnd,
      correctedStart: data.correctedStart.present
          ? data.correctedStart.value
          : this.correctedStart,
      correctedEnd: data.correctedEnd.present
          ? data.correctedEnd.value
          : this.correctedEnd,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      englishSentence: data.englishSentence.present
          ? data.englishSentence.value
          : this.englishSentence,
      englishHighlightStart: data.englishHighlightStart.present
          ? data.englishHighlightStart.value
          : this.englishHighlightStart,
      englishHighlightEnd: data.englishHighlightEnd.present
          ? data.englishHighlightEnd.value
          : this.englishHighlightEnd,
      category: data.category.present ? data.category.value : this.category,
      subcategory: data.subcategory.present
          ? data.subcategory.value
          : this.subcategory,
      contextText: data.contextText.present
          ? data.contextText.value
          : this.contextText,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      inputMode: data.inputMode.present ? data.inputMode.value : this.inputMode,
      savedCorrectionId: data.savedCorrectionId.present
          ? data.savedCorrectionId.value
          : this.savedCorrectionId,
      ladderStage: data.ladderStage.present
          ? data.ladderStage.value
          : this.ladderStage,
      lockedStage: data.lockedStage.present
          ? data.lockedStage.value
          : this.lockedStage,
      retired: data.retired.present ? data.retired.value : this.retired,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeItem(')
          ..write('id: $id, ')
          ..write('changedAt: $changedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('language: $language, ')
          ..write('originalSentence: $originalSentence, ')
          ..write('correctedSentence: $correctedSentence, ')
          ..write('originalPhrase: $originalPhrase, ')
          ..write('correctedPhrase: $correctedPhrase, ')
          ..write('originalStart: $originalStart, ')
          ..write('originalEnd: $originalEnd, ')
          ..write('correctedStart: $correctedStart, ')
          ..write('correctedEnd: $correctedEnd, ')
          ..write('explanation: $explanation, ')
          ..write('englishSentence: $englishSentence, ')
          ..write('englishHighlightStart: $englishHighlightStart, ')
          ..write('englishHighlightEnd: $englishHighlightEnd, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('contextText: $contextText, ')
          ..write('chatId: $chatId, ')
          ..write('inputMode: $inputMode, ')
          ..write('savedCorrectionId: $savedCorrectionId, ')
          ..write('ladderStage: $ladderStage, ')
          ..write('lockedStage: $lockedStage, ')
          ..write('retired: $retired')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    changedAt,
    createdAt,
    language,
    originalSentence,
    correctedSentence,
    originalPhrase,
    correctedPhrase,
    originalStart,
    originalEnd,
    correctedStart,
    correctedEnd,
    explanation,
    englishSentence,
    englishHighlightStart,
    englishHighlightEnd,
    category,
    subcategory,
    contextText,
    chatId,
    inputMode,
    savedCorrectionId,
    ladderStage,
    lockedStage,
    retired,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeItem &&
          other.id == this.id &&
          other.changedAt == this.changedAt &&
          other.createdAt == this.createdAt &&
          other.language == this.language &&
          other.originalSentence == this.originalSentence &&
          other.correctedSentence == this.correctedSentence &&
          other.originalPhrase == this.originalPhrase &&
          other.correctedPhrase == this.correctedPhrase &&
          other.originalStart == this.originalStart &&
          other.originalEnd == this.originalEnd &&
          other.correctedStart == this.correctedStart &&
          other.correctedEnd == this.correctedEnd &&
          other.explanation == this.explanation &&
          other.englishSentence == this.englishSentence &&
          other.englishHighlightStart == this.englishHighlightStart &&
          other.englishHighlightEnd == this.englishHighlightEnd &&
          other.category == this.category &&
          other.subcategory == this.subcategory &&
          other.contextText == this.contextText &&
          other.chatId == this.chatId &&
          other.inputMode == this.inputMode &&
          other.savedCorrectionId == this.savedCorrectionId &&
          other.ladderStage == this.ladderStage &&
          other.lockedStage == this.lockedStage &&
          other.retired == this.retired);
}

class PracticeItemsCompanion extends UpdateCompanion<PracticeItem> {
  final Value<String> id;
  final Value<DateTime> changedAt;
  final Value<DateTime> createdAt;
  final Value<String> language;
  final Value<String> originalSentence;
  final Value<String> correctedSentence;
  final Value<String> originalPhrase;
  final Value<String> correctedPhrase;
  final Value<int?> originalStart;
  final Value<int?> originalEnd;
  final Value<int?> correctedStart;
  final Value<int?> correctedEnd;
  final Value<String> explanation;
  final Value<String> englishSentence;
  final Value<int?> englishHighlightStart;
  final Value<int?> englishHighlightEnd;
  final Value<String> category;
  final Value<PracticeSubcategory?> subcategory;
  final Value<String> contextText;
  final Value<String?> chatId;
  final Value<PracticeInputMode> inputMode;
  final Value<String?> savedCorrectionId;
  final Value<int> ladderStage;
  final Value<int> lockedStage;
  final Value<bool> retired;
  final Value<int> rowid;
  const PracticeItemsCompanion({
    this.id = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.language = const Value.absent(),
    this.originalSentence = const Value.absent(),
    this.correctedSentence = const Value.absent(),
    this.originalPhrase = const Value.absent(),
    this.correctedPhrase = const Value.absent(),
    this.originalStart = const Value.absent(),
    this.originalEnd = const Value.absent(),
    this.correctedStart = const Value.absent(),
    this.correctedEnd = const Value.absent(),
    this.explanation = const Value.absent(),
    this.englishSentence = const Value.absent(),
    this.englishHighlightStart = const Value.absent(),
    this.englishHighlightEnd = const Value.absent(),
    this.category = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.contextText = const Value.absent(),
    this.chatId = const Value.absent(),
    this.inputMode = const Value.absent(),
    this.savedCorrectionId = const Value.absent(),
    this.ladderStage = const Value.absent(),
    this.lockedStage = const Value.absent(),
    this.retired = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeItemsCompanion.insert({
    this.id = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    required String language,
    required String originalSentence,
    required String correctedSentence,
    required String originalPhrase,
    required String correctedPhrase,
    this.originalStart = const Value.absent(),
    this.originalEnd = const Value.absent(),
    this.correctedStart = const Value.absent(),
    this.correctedEnd = const Value.absent(),
    this.explanation = const Value.absent(),
    this.englishSentence = const Value.absent(),
    this.englishHighlightStart = const Value.absent(),
    this.englishHighlightEnd = const Value.absent(),
    required String category,
    this.subcategory = const Value.absent(),
    this.contextText = const Value.absent(),
    this.chatId = const Value.absent(),
    required PracticeInputMode inputMode,
    this.savedCorrectionId = const Value.absent(),
    this.ladderStage = const Value.absent(),
    this.lockedStage = const Value.absent(),
    this.retired = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : language = Value(language),
       originalSentence = Value(originalSentence),
       correctedSentence = Value(correctedSentence),
       originalPhrase = Value(originalPhrase),
       correctedPhrase = Value(correctedPhrase),
       category = Value(category),
       inputMode = Value(inputMode);
  static Insertable<PracticeItem> custom({
    Expression<String>? id,
    Expression<DateTime>? changedAt,
    Expression<DateTime>? createdAt,
    Expression<String>? language,
    Expression<String>? originalSentence,
    Expression<String>? correctedSentence,
    Expression<String>? originalPhrase,
    Expression<String>? correctedPhrase,
    Expression<int>? originalStart,
    Expression<int>? originalEnd,
    Expression<int>? correctedStart,
    Expression<int>? correctedEnd,
    Expression<String>? explanation,
    Expression<String>? englishSentence,
    Expression<int>? englishHighlightStart,
    Expression<int>? englishHighlightEnd,
    Expression<String>? category,
    Expression<String>? subcategory,
    Expression<String>? contextText,
    Expression<String>? chatId,
    Expression<String>? inputMode,
    Expression<String>? savedCorrectionId,
    Expression<int>? ladderStage,
    Expression<int>? lockedStage,
    Expression<bool>? retired,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (changedAt != null) 'changed_at': changedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (language != null) 'language': language,
      if (originalSentence != null) 'original_sentence': originalSentence,
      if (correctedSentence != null) 'corrected_sentence': correctedSentence,
      if (originalPhrase != null) 'original_phrase': originalPhrase,
      if (correctedPhrase != null) 'corrected_phrase': correctedPhrase,
      if (originalStart != null) 'original_start': originalStart,
      if (originalEnd != null) 'original_end': originalEnd,
      if (correctedStart != null) 'corrected_start': correctedStart,
      if (correctedEnd != null) 'corrected_end': correctedEnd,
      if (explanation != null) 'explanation': explanation,
      if (englishSentence != null) 'english_sentence': englishSentence,
      if (englishHighlightStart != null)
        'english_highlight_start': englishHighlightStart,
      if (englishHighlightEnd != null)
        'english_highlight_end': englishHighlightEnd,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (contextText != null) 'context_text': contextText,
      if (chatId != null) 'chat_id': chatId,
      if (inputMode != null) 'input_mode': inputMode,
      if (savedCorrectionId != null) 'saved_correction_id': savedCorrectionId,
      if (ladderStage != null) 'ladder_stage': ladderStage,
      if (lockedStage != null) 'locked_stage': lockedStage,
      if (retired != null) 'retired': retired,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeItemsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? changedAt,
    Value<DateTime>? createdAt,
    Value<String>? language,
    Value<String>? originalSentence,
    Value<String>? correctedSentence,
    Value<String>? originalPhrase,
    Value<String>? correctedPhrase,
    Value<int?>? originalStart,
    Value<int?>? originalEnd,
    Value<int?>? correctedStart,
    Value<int?>? correctedEnd,
    Value<String>? explanation,
    Value<String>? englishSentence,
    Value<int?>? englishHighlightStart,
    Value<int?>? englishHighlightEnd,
    Value<String>? category,
    Value<PracticeSubcategory?>? subcategory,
    Value<String>? contextText,
    Value<String?>? chatId,
    Value<PracticeInputMode>? inputMode,
    Value<String?>? savedCorrectionId,
    Value<int>? ladderStage,
    Value<int>? lockedStage,
    Value<bool>? retired,
    Value<int>? rowid,
  }) {
    return PracticeItemsCompanion(
      id: id ?? this.id,
      changedAt: changedAt ?? this.changedAt,
      createdAt: createdAt ?? this.createdAt,
      language: language ?? this.language,
      originalSentence: originalSentence ?? this.originalSentence,
      correctedSentence: correctedSentence ?? this.correctedSentence,
      originalPhrase: originalPhrase ?? this.originalPhrase,
      correctedPhrase: correctedPhrase ?? this.correctedPhrase,
      originalStart: originalStart ?? this.originalStart,
      originalEnd: originalEnd ?? this.originalEnd,
      correctedStart: correctedStart ?? this.correctedStart,
      correctedEnd: correctedEnd ?? this.correctedEnd,
      explanation: explanation ?? this.explanation,
      englishSentence: englishSentence ?? this.englishSentence,
      englishHighlightStart:
          englishHighlightStart ?? this.englishHighlightStart,
      englishHighlightEnd: englishHighlightEnd ?? this.englishHighlightEnd,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      contextText: contextText ?? this.contextText,
      chatId: chatId ?? this.chatId,
      inputMode: inputMode ?? this.inputMode,
      savedCorrectionId: savedCorrectionId ?? this.savedCorrectionId,
      ladderStage: ladderStage ?? this.ladderStage,
      lockedStage: lockedStage ?? this.lockedStage,
      retired: retired ?? this.retired,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (originalSentence.present) {
      map['original_sentence'] = Variable<String>(originalSentence.value);
    }
    if (correctedSentence.present) {
      map['corrected_sentence'] = Variable<String>(correctedSentence.value);
    }
    if (originalPhrase.present) {
      map['original_phrase'] = Variable<String>(originalPhrase.value);
    }
    if (correctedPhrase.present) {
      map['corrected_phrase'] = Variable<String>(correctedPhrase.value);
    }
    if (originalStart.present) {
      map['original_start'] = Variable<int>(originalStart.value);
    }
    if (originalEnd.present) {
      map['original_end'] = Variable<int>(originalEnd.value);
    }
    if (correctedStart.present) {
      map['corrected_start'] = Variable<int>(correctedStart.value);
    }
    if (correctedEnd.present) {
      map['corrected_end'] = Variable<int>(correctedEnd.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (englishSentence.present) {
      map['english_sentence'] = Variable<String>(englishSentence.value);
    }
    if (englishHighlightStart.present) {
      map['english_highlight_start'] = Variable<int>(
        englishHighlightStart.value,
      );
    }
    if (englishHighlightEnd.present) {
      map['english_highlight_end'] = Variable<int>(englishHighlightEnd.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (subcategory.present) {
      map['subcategory'] = Variable<String>(
        $PracticeItemsTable.$convertersubcategory.toSql(subcategory.value),
      );
    }
    if (contextText.present) {
      map['context_text'] = Variable<String>(contextText.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (inputMode.present) {
      map['input_mode'] = Variable<String>(
        $PracticeItemsTable.$converterinputMode.toSql(inputMode.value),
      );
    }
    if (savedCorrectionId.present) {
      map['saved_correction_id'] = Variable<String>(savedCorrectionId.value);
    }
    if (ladderStage.present) {
      map['ladder_stage'] = Variable<int>(ladderStage.value);
    }
    if (lockedStage.present) {
      map['locked_stage'] = Variable<int>(lockedStage.value);
    }
    if (retired.present) {
      map['retired'] = Variable<bool>(retired.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeItemsCompanion(')
          ..write('id: $id, ')
          ..write('changedAt: $changedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('language: $language, ')
          ..write('originalSentence: $originalSentence, ')
          ..write('correctedSentence: $correctedSentence, ')
          ..write('originalPhrase: $originalPhrase, ')
          ..write('correctedPhrase: $correctedPhrase, ')
          ..write('originalStart: $originalStart, ')
          ..write('originalEnd: $originalEnd, ')
          ..write('correctedStart: $correctedStart, ')
          ..write('correctedEnd: $correctedEnd, ')
          ..write('explanation: $explanation, ')
          ..write('englishSentence: $englishSentence, ')
          ..write('englishHighlightStart: $englishHighlightStart, ')
          ..write('englishHighlightEnd: $englishHighlightEnd, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('contextText: $contextText, ')
          ..write('chatId: $chatId, ')
          ..write('inputMode: $inputMode, ')
          ..write('savedCorrectionId: $savedCorrectionId, ')
          ..write('ladderStage: $ladderStage, ')
          ..write('lockedStage: $lockedStage, ')
          ..write('retired: $retired, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeQuestionsTable extends PracticeQuestions
    with TableInfo<$PracticeQuestionsTable, PracticeQuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newPracticeId,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _gameMeta = const VerificationMeta('game');
  @override
  late final GeneratedColumn<String> game = GeneratedColumn<String>(
    'game',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<int> stage = GeneratedColumn<int>(
    'stage',
    aliasedName,
    false,
    check: () => ComparableExpr(stage).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    changedAt,
    createdAt,
    itemId,
    game,
    stage,
    body,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeQuestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('game')) {
      context.handle(
        _gameMeta,
        game.isAcceptableOrUnknown(data['game']!, _gameMeta),
      );
    } else if (isInserting) {
      context.missing(_gameMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeQuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeQuestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      game: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
    );
  }

  @override
  $PracticeQuestionsTable createAlias(String alias) {
    return $PracticeQuestionsTable(attachedDatabase, alias);
  }
}

class PracticeQuestionRow extends DataClass
    implements Insertable<PracticeQuestionRow> {
  /// Stable id of this question (the question's own `id` in P.1's format).
  final String id;
  final DateTime changedAt;
  final DateTime createdAt;

  /// The mistake this question practises. Removing the mistake removes the
  /// question.
  final String itemId;

  /// The game, as P.1 writes it ("choose_correction", "fill_gap", ...).
  final String game;

  /// The question's stage on the ladder, as step P.2's rank.
  final int stage;

  /// The whole question as one JSON object in P.1's format
  /// (`Question.toJson`), read back with P.1's parser.
  final String body;
  const PracticeQuestionRow({
    required this.id,
    required this.changedAt,
    required this.createdAt,
    required this.itemId,
    required this.game,
    required this.stage,
    required this.body,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['changed_at'] = Variable<DateTime>(changedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['item_id'] = Variable<String>(itemId);
    map['game'] = Variable<String>(game);
    map['stage'] = Variable<int>(stage);
    map['body'] = Variable<String>(body);
    return map;
  }

  PracticeQuestionsCompanion toCompanion(bool nullToAbsent) {
    return PracticeQuestionsCompanion(
      id: Value(id),
      changedAt: Value(changedAt),
      createdAt: Value(createdAt),
      itemId: Value(itemId),
      game: Value(game),
      stage: Value(stage),
      body: Value(body),
    );
  }

  factory PracticeQuestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeQuestionRow(
      id: serializer.fromJson<String>(json['id']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      itemId: serializer.fromJson<String>(json['itemId']),
      game: serializer.fromJson<String>(json['game']),
      stage: serializer.fromJson<int>(json['stage']),
      body: serializer.fromJson<String>(json['body']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'changedAt': serializer.toJson<DateTime>(changedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'itemId': serializer.toJson<String>(itemId),
      'game': serializer.toJson<String>(game),
      'stage': serializer.toJson<int>(stage),
      'body': serializer.toJson<String>(body),
    };
  }

  PracticeQuestionRow copyWith({
    String? id,
    DateTime? changedAt,
    DateTime? createdAt,
    String? itemId,
    String? game,
    int? stage,
    String? body,
  }) => PracticeQuestionRow(
    id: id ?? this.id,
    changedAt: changedAt ?? this.changedAt,
    createdAt: createdAt ?? this.createdAt,
    itemId: itemId ?? this.itemId,
    game: game ?? this.game,
    stage: stage ?? this.stage,
    body: body ?? this.body,
  );
  PracticeQuestionRow copyWithCompanion(PracticeQuestionsCompanion data) {
    return PracticeQuestionRow(
      id: data.id.present ? data.id.value : this.id,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      game: data.game.present ? data.game.value : this.game,
      stage: data.stage.present ? data.stage.value : this.stage,
      body: data.body.present ? data.body.value : this.body,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeQuestionRow(')
          ..write('id: $id, ')
          ..write('changedAt: $changedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('itemId: $itemId, ')
          ..write('game: $game, ')
          ..write('stage: $stage, ')
          ..write('body: $body')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, changedAt, createdAt, itemId, game, stage, body);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeQuestionRow &&
          other.id == this.id &&
          other.changedAt == this.changedAt &&
          other.createdAt == this.createdAt &&
          other.itemId == this.itemId &&
          other.game == this.game &&
          other.stage == this.stage &&
          other.body == this.body);
}

class PracticeQuestionsCompanion extends UpdateCompanion<PracticeQuestionRow> {
  final Value<String> id;
  final Value<DateTime> changedAt;
  final Value<DateTime> createdAt;
  final Value<String> itemId;
  final Value<String> game;
  final Value<int> stage;
  final Value<String> body;
  final Value<int> rowid;
  const PracticeQuestionsCompanion({
    this.id = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.itemId = const Value.absent(),
    this.game = const Value.absent(),
    this.stage = const Value.absent(),
    this.body = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeQuestionsCompanion.insert({
    this.id = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    required String itemId,
    required String game,
    required int stage,
    required String body,
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       game = Value(game),
       stage = Value(stage),
       body = Value(body);
  static Insertable<PracticeQuestionRow> custom({
    Expression<String>? id,
    Expression<DateTime>? changedAt,
    Expression<DateTime>? createdAt,
    Expression<String>? itemId,
    Expression<String>? game,
    Expression<int>? stage,
    Expression<String>? body,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (changedAt != null) 'changed_at': changedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (itemId != null) 'item_id': itemId,
      if (game != null) 'game': game,
      if (stage != null) 'stage': stage,
      if (body != null) 'body': body,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeQuestionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? changedAt,
    Value<DateTime>? createdAt,
    Value<String>? itemId,
    Value<String>? game,
    Value<int>? stage,
    Value<String>? body,
    Value<int>? rowid,
  }) {
    return PracticeQuestionsCompanion(
      id: id ?? this.id,
      changedAt: changedAt ?? this.changedAt,
      createdAt: createdAt ?? this.createdAt,
      itemId: itemId ?? this.itemId,
      game: game ?? this.game,
      stage: stage ?? this.stage,
      body: body ?? this.body,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (game.present) {
      map['game'] = Variable<String>(game.value);
    }
    if (stage.present) {
      map['stage'] = Variable<int>(stage.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('changedAt: $changedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('itemId: $itemId, ')
          ..write('game: $game, ')
          ..write('stage: $stage, ')
          ..write('body: $body, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeGroupsTable extends PracticeGroups
    with TableInfo<$PracticeGroupsTable, PracticeGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newPracticeId,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PracticeGroupKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PracticeGroupKind>($PracticeGroupsTable.$converterkind);
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PracticeSubcategory?, String>
  subcategory =
      GeneratedColumn<String>(
        'subcategory',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      ).withConverter<PracticeSubcategory?>(
        $PracticeGroupsTable.$convertersubcategory,
      );
  static const VerificationMeta _isRevisionMeta = const VerificationMeta(
    'isRevision',
  );
  @override
  late final GeneratedColumn<bool> isRevision = GeneratedColumn<bool>(
    'is_revision',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_revision" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<int> stage = GeneratedColumn<int>(
    'stage',
    aliasedName,
    false,
    check: () => ComparableExpr(stage).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _retriesAtStageMeta = const VerificationMeta(
    'retriesAtStage',
  );
  @override
  late final GeneratedColumn<int> retriesAtStage = GeneratedColumn<int>(
    'retries_at_stage',
    aliasedName,
    false,
    check: () => ComparableExpr(retriesAtStage).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPassedAtMeta = const VerificationMeta(
    'lastPassedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPassedAt = GeneratedColumn<DateTime>(
    'last_passed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unlocksAtMeta = const VerificationMeta(
    'unlocksAt',
  );
  @override
  late final GeneratedColumn<DateTime> unlocksAt = GeneratedColumn<DateTime>(
    'unlocks_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finishedMeta = const VerificationMeta(
    'finished',
  );
  @override
  late final GeneratedColumn<bool> finished = GeneratedColumn<bool>(
    'finished',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("finished" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    changedAt,
    createdAt,
    language,
    kind,
    category,
    subcategory,
    isRevision,
    stage,
    retriesAtStage,
    lastPassedAt,
    unlocksAt,
    finished,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('is_revision')) {
      context.handle(
        _isRevisionMeta,
        isRevision.isAcceptableOrUnknown(data['is_revision']!, _isRevisionMeta),
      );
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    }
    if (data.containsKey('retries_at_stage')) {
      context.handle(
        _retriesAtStageMeta,
        retriesAtStage.isAcceptableOrUnknown(
          data['retries_at_stage']!,
          _retriesAtStageMeta,
        ),
      );
    }
    if (data.containsKey('last_passed_at')) {
      context.handle(
        _lastPassedAtMeta,
        lastPassedAt.isAcceptableOrUnknown(
          data['last_passed_at']!,
          _lastPassedAtMeta,
        ),
      );
    }
    if (data.containsKey('unlocks_at')) {
      context.handle(
        _unlocksAtMeta,
        unlocksAt.isAcceptableOrUnknown(data['unlocks_at']!, _unlocksAtMeta),
      );
    }
    if (data.containsKey('finished')) {
      context.handle(
        _finishedMeta,
        finished.isAcceptableOrUnknown(data['finished']!, _finishedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeGroup(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      kind: $PracticeGroupsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      subcategory: $PracticeGroupsTable.$convertersubcategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}subcategory'],
        )!,
      ),
      isRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_revision'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage'],
      )!,
      retriesAtStage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retries_at_stage'],
      )!,
      lastPassedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_passed_at'],
      ),
      unlocksAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocks_at'],
      ),
      finished: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}finished'],
      )!,
    );
  }

  @override
  $PracticeGroupsTable createAlias(String alias) {
    return $PracticeGroupsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PracticeGroupKind, String, String> $converterkind =
      const EnumNameConverter<PracticeGroupKind>(PracticeGroupKind.values);
  static TypeConverter<PracticeSubcategory?, String> $convertersubcategory =
      const PracticeSubcategoryConverter();
}

class PracticeGroup extends DataClass implements Insertable<PracticeGroup> {
  final String id;
  final DateTime changedAt;
  final DateTime createdAt;

  /// The language of the group's mistakes, as `Language.name`.
  final String language;

  /// How the group was put together.
  final PracticeGroupKind kind;

  /// For a group of one kind: its category name; otherwise empty.
  final String category;

  /// For a group of one subcategory: that subcategory; otherwise none.
  final PracticeSubcategory? subcategory;

  /// True for the revision group of a stage, where mistakes that stayed
  /// wrong after two retries collect (G6, points 1 and 2).
  final bool isRevision;

  /// The stage the group is playing, as step P.2's rank.
  final int stage;

  /// How many retries the group has had at this stage since its last full
  /// round.
  final int retriesAtStage;

  /// When the group last passed a stage, or none yet.
  final DateTime? lastPassedAt;

  /// When the group's current stage opens (G6, point 4). None means it is
  /// open now. Kept so Learn can show it and a reminder can be set for it.
  final DateTime? unlocksAt;

  /// True once the group has nothing left to play.
  final bool finished;
  const PracticeGroup({
    required this.id,
    required this.changedAt,
    required this.createdAt,
    required this.language,
    required this.kind,
    required this.category,
    this.subcategory,
    required this.isRevision,
    required this.stage,
    required this.retriesAtStage,
    this.lastPassedAt,
    this.unlocksAt,
    required this.finished,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['changed_at'] = Variable<DateTime>(changedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['language'] = Variable<String>(language);
    {
      map['kind'] = Variable<String>(
        $PracticeGroupsTable.$converterkind.toSql(kind),
      );
    }
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || subcategory != null) {
      map['subcategory'] = Variable<String>(
        $PracticeGroupsTable.$convertersubcategory.toSql(subcategory),
      );
    }
    map['is_revision'] = Variable<bool>(isRevision);
    map['stage'] = Variable<int>(stage);
    map['retries_at_stage'] = Variable<int>(retriesAtStage);
    if (!nullToAbsent || lastPassedAt != null) {
      map['last_passed_at'] = Variable<DateTime>(lastPassedAt);
    }
    if (!nullToAbsent || unlocksAt != null) {
      map['unlocks_at'] = Variable<DateTime>(unlocksAt);
    }
    map['finished'] = Variable<bool>(finished);
    return map;
  }

  PracticeGroupsCompanion toCompanion(bool nullToAbsent) {
    return PracticeGroupsCompanion(
      id: Value(id),
      changedAt: Value(changedAt),
      createdAt: Value(createdAt),
      language: Value(language),
      kind: Value(kind),
      category: Value(category),
      subcategory: subcategory == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategory),
      isRevision: Value(isRevision),
      stage: Value(stage),
      retriesAtStage: Value(retriesAtStage),
      lastPassedAt: lastPassedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPassedAt),
      unlocksAt: unlocksAt == null && nullToAbsent
          ? const Value.absent()
          : Value(unlocksAt),
      finished: Value(finished),
    );
  }

  factory PracticeGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeGroup(
      id: serializer.fromJson<String>(json['id']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      language: serializer.fromJson<String>(json['language']),
      kind: $PracticeGroupsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      category: serializer.fromJson<String>(json['category']),
      subcategory: serializer.fromJson<PracticeSubcategory?>(
        json['subcategory'],
      ),
      isRevision: serializer.fromJson<bool>(json['isRevision']),
      stage: serializer.fromJson<int>(json['stage']),
      retriesAtStage: serializer.fromJson<int>(json['retriesAtStage']),
      lastPassedAt: serializer.fromJson<DateTime?>(json['lastPassedAt']),
      unlocksAt: serializer.fromJson<DateTime?>(json['unlocksAt']),
      finished: serializer.fromJson<bool>(json['finished']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'changedAt': serializer.toJson<DateTime>(changedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'language': serializer.toJson<String>(language),
      'kind': serializer.toJson<String>(
        $PracticeGroupsTable.$converterkind.toJson(kind),
      ),
      'category': serializer.toJson<String>(category),
      'subcategory': serializer.toJson<PracticeSubcategory?>(subcategory),
      'isRevision': serializer.toJson<bool>(isRevision),
      'stage': serializer.toJson<int>(stage),
      'retriesAtStage': serializer.toJson<int>(retriesAtStage),
      'lastPassedAt': serializer.toJson<DateTime?>(lastPassedAt),
      'unlocksAt': serializer.toJson<DateTime?>(unlocksAt),
      'finished': serializer.toJson<bool>(finished),
    };
  }

  PracticeGroup copyWith({
    String? id,
    DateTime? changedAt,
    DateTime? createdAt,
    String? language,
    PracticeGroupKind? kind,
    String? category,
    Value<PracticeSubcategory?> subcategory = const Value.absent(),
    bool? isRevision,
    int? stage,
    int? retriesAtStage,
    Value<DateTime?> lastPassedAt = const Value.absent(),
    Value<DateTime?> unlocksAt = const Value.absent(),
    bool? finished,
  }) => PracticeGroup(
    id: id ?? this.id,
    changedAt: changedAt ?? this.changedAt,
    createdAt: createdAt ?? this.createdAt,
    language: language ?? this.language,
    kind: kind ?? this.kind,
    category: category ?? this.category,
    subcategory: subcategory.present ? subcategory.value : this.subcategory,
    isRevision: isRevision ?? this.isRevision,
    stage: stage ?? this.stage,
    retriesAtStage: retriesAtStage ?? this.retriesAtStage,
    lastPassedAt: lastPassedAt.present ? lastPassedAt.value : this.lastPassedAt,
    unlocksAt: unlocksAt.present ? unlocksAt.value : this.unlocksAt,
    finished: finished ?? this.finished,
  );
  PracticeGroup copyWithCompanion(PracticeGroupsCompanion data) {
    return PracticeGroup(
      id: data.id.present ? data.id.value : this.id,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      language: data.language.present ? data.language.value : this.language,
      kind: data.kind.present ? data.kind.value : this.kind,
      category: data.category.present ? data.category.value : this.category,
      subcategory: data.subcategory.present
          ? data.subcategory.value
          : this.subcategory,
      isRevision: data.isRevision.present
          ? data.isRevision.value
          : this.isRevision,
      stage: data.stage.present ? data.stage.value : this.stage,
      retriesAtStage: data.retriesAtStage.present
          ? data.retriesAtStage.value
          : this.retriesAtStage,
      lastPassedAt: data.lastPassedAt.present
          ? data.lastPassedAt.value
          : this.lastPassedAt,
      unlocksAt: data.unlocksAt.present ? data.unlocksAt.value : this.unlocksAt,
      finished: data.finished.present ? data.finished.value : this.finished,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeGroup(')
          ..write('id: $id, ')
          ..write('changedAt: $changedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('language: $language, ')
          ..write('kind: $kind, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('isRevision: $isRevision, ')
          ..write('stage: $stage, ')
          ..write('retriesAtStage: $retriesAtStage, ')
          ..write('lastPassedAt: $lastPassedAt, ')
          ..write('unlocksAt: $unlocksAt, ')
          ..write('finished: $finished')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    changedAt,
    createdAt,
    language,
    kind,
    category,
    subcategory,
    isRevision,
    stage,
    retriesAtStage,
    lastPassedAt,
    unlocksAt,
    finished,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeGroup &&
          other.id == this.id &&
          other.changedAt == this.changedAt &&
          other.createdAt == this.createdAt &&
          other.language == this.language &&
          other.kind == this.kind &&
          other.category == this.category &&
          other.subcategory == this.subcategory &&
          other.isRevision == this.isRevision &&
          other.stage == this.stage &&
          other.retriesAtStage == this.retriesAtStage &&
          other.lastPassedAt == this.lastPassedAt &&
          other.unlocksAt == this.unlocksAt &&
          other.finished == this.finished);
}

class PracticeGroupsCompanion extends UpdateCompanion<PracticeGroup> {
  final Value<String> id;
  final Value<DateTime> changedAt;
  final Value<DateTime> createdAt;
  final Value<String> language;
  final Value<PracticeGroupKind> kind;
  final Value<String> category;
  final Value<PracticeSubcategory?> subcategory;
  final Value<bool> isRevision;
  final Value<int> stage;
  final Value<int> retriesAtStage;
  final Value<DateTime?> lastPassedAt;
  final Value<DateTime?> unlocksAt;
  final Value<bool> finished;
  final Value<int> rowid;
  const PracticeGroupsCompanion({
    this.id = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.language = const Value.absent(),
    this.kind = const Value.absent(),
    this.category = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.isRevision = const Value.absent(),
    this.stage = const Value.absent(),
    this.retriesAtStage = const Value.absent(),
    this.lastPassedAt = const Value.absent(),
    this.unlocksAt = const Value.absent(),
    this.finished = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeGroupsCompanion.insert({
    this.id = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    required String language,
    required PracticeGroupKind kind,
    this.category = const Value.absent(),
    this.subcategory = const Value.absent(),
    this.isRevision = const Value.absent(),
    this.stage = const Value.absent(),
    this.retriesAtStage = const Value.absent(),
    this.lastPassedAt = const Value.absent(),
    this.unlocksAt = const Value.absent(),
    this.finished = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : language = Value(language),
       kind = Value(kind);
  static Insertable<PracticeGroup> custom({
    Expression<String>? id,
    Expression<DateTime>? changedAt,
    Expression<DateTime>? createdAt,
    Expression<String>? language,
    Expression<String>? kind,
    Expression<String>? category,
    Expression<String>? subcategory,
    Expression<bool>? isRevision,
    Expression<int>? stage,
    Expression<int>? retriesAtStage,
    Expression<DateTime>? lastPassedAt,
    Expression<DateTime>? unlocksAt,
    Expression<bool>? finished,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (changedAt != null) 'changed_at': changedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (language != null) 'language': language,
      if (kind != null) 'kind': kind,
      if (category != null) 'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      if (isRevision != null) 'is_revision': isRevision,
      if (stage != null) 'stage': stage,
      if (retriesAtStage != null) 'retries_at_stage': retriesAtStage,
      if (lastPassedAt != null) 'last_passed_at': lastPassedAt,
      if (unlocksAt != null) 'unlocks_at': unlocksAt,
      if (finished != null) 'finished': finished,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeGroupsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? changedAt,
    Value<DateTime>? createdAt,
    Value<String>? language,
    Value<PracticeGroupKind>? kind,
    Value<String>? category,
    Value<PracticeSubcategory?>? subcategory,
    Value<bool>? isRevision,
    Value<int>? stage,
    Value<int>? retriesAtStage,
    Value<DateTime?>? lastPassedAt,
    Value<DateTime?>? unlocksAt,
    Value<bool>? finished,
    Value<int>? rowid,
  }) {
    return PracticeGroupsCompanion(
      id: id ?? this.id,
      changedAt: changedAt ?? this.changedAt,
      createdAt: createdAt ?? this.createdAt,
      language: language ?? this.language,
      kind: kind ?? this.kind,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      isRevision: isRevision ?? this.isRevision,
      stage: stage ?? this.stage,
      retriesAtStage: retriesAtStage ?? this.retriesAtStage,
      lastPassedAt: lastPassedAt ?? this.lastPassedAt,
      unlocksAt: unlocksAt ?? this.unlocksAt,
      finished: finished ?? this.finished,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $PracticeGroupsTable.$converterkind.toSql(kind.value),
      );
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (subcategory.present) {
      map['subcategory'] = Variable<String>(
        $PracticeGroupsTable.$convertersubcategory.toSql(subcategory.value),
      );
    }
    if (isRevision.present) {
      map['is_revision'] = Variable<bool>(isRevision.value);
    }
    if (stage.present) {
      map['stage'] = Variable<int>(stage.value);
    }
    if (retriesAtStage.present) {
      map['retries_at_stage'] = Variable<int>(retriesAtStage.value);
    }
    if (lastPassedAt.present) {
      map['last_passed_at'] = Variable<DateTime>(lastPassedAt.value);
    }
    if (unlocksAt.present) {
      map['unlocks_at'] = Variable<DateTime>(unlocksAt.value);
    }
    if (finished.present) {
      map['finished'] = Variable<bool>(finished.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeGroupsCompanion(')
          ..write('id: $id, ')
          ..write('changedAt: $changedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('language: $language, ')
          ..write('kind: $kind, ')
          ..write('category: $category, ')
          ..write('subcategory: $subcategory, ')
          ..write('isRevision: $isRevision, ')
          ..write('stage: $stage, ')
          ..write('retriesAtStage: $retriesAtStage, ')
          ..write('lastPassedAt: $lastPassedAt, ')
          ..write('unlocksAt: $unlocksAt, ')
          ..write('finished: $finished, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeGroupItemsTable extends PracticeGroupItems
    with TableInfo<$PracticeGroupItemsTable, PracticeGroupItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeGroupItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newPracticeId,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_groups (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _missedLastRoundMeta = const VerificationMeta(
    'missedLastRound',
  );
  @override
  late final GeneratedColumn<bool> missedLastRound = GeneratedColumn<bool>(
    'missed_last_round',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("missed_last_round" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _failedRetriesMeta = const VerificationMeta(
    'failedRetries',
  );
  @override
  late final GeneratedColumn<int> failedRetries = GeneratedColumn<int>(
    'failed_retries',
    aliasedName,
    false,
    check: () => ComparableExpr(failedRetries).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    changedAt,
    groupId,
    itemId,
    position,
    missedLastRound,
    failedRetries,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_group_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeGroupItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('missed_last_round')) {
      context.handle(
        _missedLastRoundMeta,
        missedLastRound.isAcceptableOrUnknown(
          data['missed_last_round']!,
          _missedLastRoundMeta,
        ),
      );
    }
    if (data.containsKey('failed_retries')) {
      context.handle(
        _failedRetriesMeta,
        failedRetries.isAcceptableOrUnknown(
          data['failed_retries']!,
          _failedRetriesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {groupId, itemId},
  ];
  @override
  PracticeGroupItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeGroupItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      missedLastRound: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}missed_last_round'],
      )!,
      failedRetries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_retries'],
      )!,
    );
  }

  @override
  $PracticeGroupItemsTable createAlias(String alias) {
    return $PracticeGroupItemsTable(attachedDatabase, alias);
  }
}

class PracticeGroupItem extends DataClass
    implements Insertable<PracticeGroupItem> {
  final String id;
  final DateTime changedAt;
  final String groupId;
  final String itemId;

  /// The mistake's place in the group's order.
  final int position;

  /// True when the mistake was answered wrong in the group's latest round,
  /// so a retry holds only these (G6).
  final bool missedLastRound;

  /// How many retries in a row the mistake has stayed wrong. After two it
  /// leaves for the stage's revision group (G6, point 1).
  final int failedRetries;
  const PracticeGroupItem({
    required this.id,
    required this.changedAt,
    required this.groupId,
    required this.itemId,
    required this.position,
    required this.missedLastRound,
    required this.failedRetries,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['changed_at'] = Variable<DateTime>(changedAt);
    map['group_id'] = Variable<String>(groupId);
    map['item_id'] = Variable<String>(itemId);
    map['position'] = Variable<int>(position);
    map['missed_last_round'] = Variable<bool>(missedLastRound);
    map['failed_retries'] = Variable<int>(failedRetries);
    return map;
  }

  PracticeGroupItemsCompanion toCompanion(bool nullToAbsent) {
    return PracticeGroupItemsCompanion(
      id: Value(id),
      changedAt: Value(changedAt),
      groupId: Value(groupId),
      itemId: Value(itemId),
      position: Value(position),
      missedLastRound: Value(missedLastRound),
      failedRetries: Value(failedRetries),
    );
  }

  factory PracticeGroupItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeGroupItem(
      id: serializer.fromJson<String>(json['id']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
      groupId: serializer.fromJson<String>(json['groupId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      position: serializer.fromJson<int>(json['position']),
      missedLastRound: serializer.fromJson<bool>(json['missedLastRound']),
      failedRetries: serializer.fromJson<int>(json['failedRetries']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'changedAt': serializer.toJson<DateTime>(changedAt),
      'groupId': serializer.toJson<String>(groupId),
      'itemId': serializer.toJson<String>(itemId),
      'position': serializer.toJson<int>(position),
      'missedLastRound': serializer.toJson<bool>(missedLastRound),
      'failedRetries': serializer.toJson<int>(failedRetries),
    };
  }

  PracticeGroupItem copyWith({
    String? id,
    DateTime? changedAt,
    String? groupId,
    String? itemId,
    int? position,
    bool? missedLastRound,
    int? failedRetries,
  }) => PracticeGroupItem(
    id: id ?? this.id,
    changedAt: changedAt ?? this.changedAt,
    groupId: groupId ?? this.groupId,
    itemId: itemId ?? this.itemId,
    position: position ?? this.position,
    missedLastRound: missedLastRound ?? this.missedLastRound,
    failedRetries: failedRetries ?? this.failedRetries,
  );
  PracticeGroupItem copyWithCompanion(PracticeGroupItemsCompanion data) {
    return PracticeGroupItem(
      id: data.id.present ? data.id.value : this.id,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      position: data.position.present ? data.position.value : this.position,
      missedLastRound: data.missedLastRound.present
          ? data.missedLastRound.value
          : this.missedLastRound,
      failedRetries: data.failedRetries.present
          ? data.failedRetries.value
          : this.failedRetries,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeGroupItem(')
          ..write('id: $id, ')
          ..write('changedAt: $changedAt, ')
          ..write('groupId: $groupId, ')
          ..write('itemId: $itemId, ')
          ..write('position: $position, ')
          ..write('missedLastRound: $missedLastRound, ')
          ..write('failedRetries: $failedRetries')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    changedAt,
    groupId,
    itemId,
    position,
    missedLastRound,
    failedRetries,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeGroupItem &&
          other.id == this.id &&
          other.changedAt == this.changedAt &&
          other.groupId == this.groupId &&
          other.itemId == this.itemId &&
          other.position == this.position &&
          other.missedLastRound == this.missedLastRound &&
          other.failedRetries == this.failedRetries);
}

class PracticeGroupItemsCompanion extends UpdateCompanion<PracticeGroupItem> {
  final Value<String> id;
  final Value<DateTime> changedAt;
  final Value<String> groupId;
  final Value<String> itemId;
  final Value<int> position;
  final Value<bool> missedLastRound;
  final Value<int> failedRetries;
  final Value<int> rowid;
  const PracticeGroupItemsCompanion({
    this.id = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.groupId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.position = const Value.absent(),
    this.missedLastRound = const Value.absent(),
    this.failedRetries = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeGroupItemsCompanion.insert({
    this.id = const Value.absent(),
    this.changedAt = const Value.absent(),
    required String groupId,
    required String itemId,
    this.position = const Value.absent(),
    this.missedLastRound = const Value.absent(),
    this.failedRetries = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       itemId = Value(itemId);
  static Insertable<PracticeGroupItem> custom({
    Expression<String>? id,
    Expression<DateTime>? changedAt,
    Expression<String>? groupId,
    Expression<String>? itemId,
    Expression<int>? position,
    Expression<bool>? missedLastRound,
    Expression<int>? failedRetries,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (changedAt != null) 'changed_at': changedAt,
      if (groupId != null) 'group_id': groupId,
      if (itemId != null) 'item_id': itemId,
      if (position != null) 'position': position,
      if (missedLastRound != null) 'missed_last_round': missedLastRound,
      if (failedRetries != null) 'failed_retries': failedRetries,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeGroupItemsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? changedAt,
    Value<String>? groupId,
    Value<String>? itemId,
    Value<int>? position,
    Value<bool>? missedLastRound,
    Value<int>? failedRetries,
    Value<int>? rowid,
  }) {
    return PracticeGroupItemsCompanion(
      id: id ?? this.id,
      changedAt: changedAt ?? this.changedAt,
      groupId: groupId ?? this.groupId,
      itemId: itemId ?? this.itemId,
      position: position ?? this.position,
      missedLastRound: missedLastRound ?? this.missedLastRound,
      failedRetries: failedRetries ?? this.failedRetries,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (missedLastRound.present) {
      map['missed_last_round'] = Variable<bool>(missedLastRound.value);
    }
    if (failedRetries.present) {
      map['failed_retries'] = Variable<int>(failedRetries.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeGroupItemsCompanion(')
          ..write('id: $id, ')
          ..write('changedAt: $changedAt, ')
          ..write('groupId: $groupId, ')
          ..write('itemId: $itemId, ')
          ..write('position: $position, ')
          ..write('missedLastRound: $missedLastRound, ')
          ..write('failedRetries: $failedRetries, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeAttemptsTable extends PracticeAttempts
    with TableInfo<$PracticeAttemptsTable, PracticeAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newPracticeId,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_items (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_questions (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_groups (id) ON DELETE SET NULL',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PracticeMode, String> mode =
      GeneratedColumn<String>(
        'mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<PracticeMode>($PracticeAttemptsTable.$convertermode);
  static const VerificationMeta _gameMeta = const VerificationMeta('game');
  @override
  late final GeneratedColumn<String> game = GeneratedColumn<String>(
    'game',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<int> stage = GeneratedColumn<int>(
    'stage',
    aliasedName,
    false,
    check: () => ComparableExpr(stage).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<bool> correct = GeneratedColumn<bool>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>(
    'answered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    changedAt,
    itemId,
    questionId,
    groupId,
    mode,
    game,
    stage,
    answer,
    correct,
    answeredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeAttempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('game')) {
      context.handle(
        _gameMeta,
        game.isAcceptableOrUnknown(data['game']!, _gameMeta),
      );
    } else if (isInserting) {
      context.missing(_gameMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeAttempt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      mode: $PracticeAttemptsTable.$convertermode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}mode'],
        )!,
      ),
      game: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stage'],
      )!,
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}correct'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}answered_at'],
      )!,
    );
  }

  @override
  $PracticeAttemptsTable createAlias(String alias) {
    return $PracticeAttemptsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PracticeMode, String, String> $convertermode =
      const EnumNameConverter<PracticeMode>(PracticeMode.values);
}

class PracticeAttempt extends DataClass implements Insertable<PracticeAttempt> {
  final String id;
  final DateTime changedAt;

  /// The mistake that was practised. Removing the mistake removes its
  /// attempts.
  final String itemId;

  /// The question that was asked, or none once that question has gone.
  final String? questionId;

  /// The group it was answered in, or none (Free play, or the group has
  /// gone).
  final String? groupId;

  /// Guided or Free play.
  final PracticeMode mode;

  /// The game, as P.1 writes it.
  final String game;

  /// The stage the question was at, as step P.2's rank.
  final int stage;

  /// What the learner answered, as given.
  final String answer;

  /// Whether the answer was right.
  final bool correct;

  /// When the answer was given.
  final DateTime answeredAt;
  const PracticeAttempt({
    required this.id,
    required this.changedAt,
    required this.itemId,
    this.questionId,
    this.groupId,
    required this.mode,
    required this.game,
    required this.stage,
    required this.answer,
    required this.correct,
    required this.answeredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['changed_at'] = Variable<DateTime>(changedAt);
    map['item_id'] = Variable<String>(itemId);
    if (!nullToAbsent || questionId != null) {
      map['question_id'] = Variable<String>(questionId);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    {
      map['mode'] = Variable<String>(
        $PracticeAttemptsTable.$convertermode.toSql(mode),
      );
    }
    map['game'] = Variable<String>(game);
    map['stage'] = Variable<int>(stage);
    map['answer'] = Variable<String>(answer);
    map['correct'] = Variable<bool>(correct);
    map['answered_at'] = Variable<DateTime>(answeredAt);
    return map;
  }

  PracticeAttemptsCompanion toCompanion(bool nullToAbsent) {
    return PracticeAttemptsCompanion(
      id: Value(id),
      changedAt: Value(changedAt),
      itemId: Value(itemId),
      questionId: questionId == null && nullToAbsent
          ? const Value.absent()
          : Value(questionId),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      mode: Value(mode),
      game: Value(game),
      stage: Value(stage),
      answer: Value(answer),
      correct: Value(correct),
      answeredAt: Value(answeredAt),
    );
  }

  factory PracticeAttempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeAttempt(
      id: serializer.fromJson<String>(json['id']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
      itemId: serializer.fromJson<String>(json['itemId']),
      questionId: serializer.fromJson<String?>(json['questionId']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      mode: $PracticeAttemptsTable.$convertermode.fromJson(
        serializer.fromJson<String>(json['mode']),
      ),
      game: serializer.fromJson<String>(json['game']),
      stage: serializer.fromJson<int>(json['stage']),
      answer: serializer.fromJson<String>(json['answer']),
      correct: serializer.fromJson<bool>(json['correct']),
      answeredAt: serializer.fromJson<DateTime>(json['answeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'changedAt': serializer.toJson<DateTime>(changedAt),
      'itemId': serializer.toJson<String>(itemId),
      'questionId': serializer.toJson<String?>(questionId),
      'groupId': serializer.toJson<String?>(groupId),
      'mode': serializer.toJson<String>(
        $PracticeAttemptsTable.$convertermode.toJson(mode),
      ),
      'game': serializer.toJson<String>(game),
      'stage': serializer.toJson<int>(stage),
      'answer': serializer.toJson<String>(answer),
      'correct': serializer.toJson<bool>(correct),
      'answeredAt': serializer.toJson<DateTime>(answeredAt),
    };
  }

  PracticeAttempt copyWith({
    String? id,
    DateTime? changedAt,
    String? itemId,
    Value<String?> questionId = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
    PracticeMode? mode,
    String? game,
    int? stage,
    String? answer,
    bool? correct,
    DateTime? answeredAt,
  }) => PracticeAttempt(
    id: id ?? this.id,
    changedAt: changedAt ?? this.changedAt,
    itemId: itemId ?? this.itemId,
    questionId: questionId.present ? questionId.value : this.questionId,
    groupId: groupId.present ? groupId.value : this.groupId,
    mode: mode ?? this.mode,
    game: game ?? this.game,
    stage: stage ?? this.stage,
    answer: answer ?? this.answer,
    correct: correct ?? this.correct,
    answeredAt: answeredAt ?? this.answeredAt,
  );
  PracticeAttempt copyWithCompanion(PracticeAttemptsCompanion data) {
    return PracticeAttempt(
      id: data.id.present ? data.id.value : this.id,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      mode: data.mode.present ? data.mode.value : this.mode,
      game: data.game.present ? data.game.value : this.game,
      stage: data.stage.present ? data.stage.value : this.stage,
      answer: data.answer.present ? data.answer.value : this.answer,
      correct: data.correct.present ? data.correct.value : this.correct,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeAttempt(')
          ..write('id: $id, ')
          ..write('changedAt: $changedAt, ')
          ..write('itemId: $itemId, ')
          ..write('questionId: $questionId, ')
          ..write('groupId: $groupId, ')
          ..write('mode: $mode, ')
          ..write('game: $game, ')
          ..write('stage: $stage, ')
          ..write('answer: $answer, ')
          ..write('correct: $correct, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    changedAt,
    itemId,
    questionId,
    groupId,
    mode,
    game,
    stage,
    answer,
    correct,
    answeredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeAttempt &&
          other.id == this.id &&
          other.changedAt == this.changedAt &&
          other.itemId == this.itemId &&
          other.questionId == this.questionId &&
          other.groupId == this.groupId &&
          other.mode == this.mode &&
          other.game == this.game &&
          other.stage == this.stage &&
          other.answer == this.answer &&
          other.correct == this.correct &&
          other.answeredAt == this.answeredAt);
}

class PracticeAttemptsCompanion extends UpdateCompanion<PracticeAttempt> {
  final Value<String> id;
  final Value<DateTime> changedAt;
  final Value<String> itemId;
  final Value<String?> questionId;
  final Value<String?> groupId;
  final Value<PracticeMode> mode;
  final Value<String> game;
  final Value<int> stage;
  final Value<String> answer;
  final Value<bool> correct;
  final Value<DateTime> answeredAt;
  final Value<int> rowid;
  const PracticeAttemptsCompanion({
    this.id = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.itemId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.mode = const Value.absent(),
    this.game = const Value.absent(),
    this.stage = const Value.absent(),
    this.answer = const Value.absent(),
    this.correct = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeAttemptsCompanion.insert({
    this.id = const Value.absent(),
    this.changedAt = const Value.absent(),
    required String itemId,
    this.questionId = const Value.absent(),
    this.groupId = const Value.absent(),
    required PracticeMode mode,
    required String game,
    required int stage,
    this.answer = const Value.absent(),
    required bool correct,
    this.answeredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : itemId = Value(itemId),
       mode = Value(mode),
       game = Value(game),
       stage = Value(stage),
       correct = Value(correct);
  static Insertable<PracticeAttempt> custom({
    Expression<String>? id,
    Expression<DateTime>? changedAt,
    Expression<String>? itemId,
    Expression<String>? questionId,
    Expression<String>? groupId,
    Expression<String>? mode,
    Expression<String>? game,
    Expression<int>? stage,
    Expression<String>? answer,
    Expression<bool>? correct,
    Expression<DateTime>? answeredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (changedAt != null) 'changed_at': changedAt,
      if (itemId != null) 'item_id': itemId,
      if (questionId != null) 'question_id': questionId,
      if (groupId != null) 'group_id': groupId,
      if (mode != null) 'mode': mode,
      if (game != null) 'game': game,
      if (stage != null) 'stage': stage,
      if (answer != null) 'answer': answer,
      if (correct != null) 'correct': correct,
      if (answeredAt != null) 'answered_at': answeredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeAttemptsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? changedAt,
    Value<String>? itemId,
    Value<String?>? questionId,
    Value<String?>? groupId,
    Value<PracticeMode>? mode,
    Value<String>? game,
    Value<int>? stage,
    Value<String>? answer,
    Value<bool>? correct,
    Value<DateTime>? answeredAt,
    Value<int>? rowid,
  }) {
    return PracticeAttemptsCompanion(
      id: id ?? this.id,
      changedAt: changedAt ?? this.changedAt,
      itemId: itemId ?? this.itemId,
      questionId: questionId ?? this.questionId,
      groupId: groupId ?? this.groupId,
      mode: mode ?? this.mode,
      game: game ?? this.game,
      stage: stage ?? this.stage,
      answer: answer ?? this.answer,
      correct: correct ?? this.correct,
      answeredAt: answeredAt ?? this.answeredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(
        $PracticeAttemptsTable.$convertermode.toSql(mode.value),
      );
    }
    if (game.present) {
      map['game'] = Variable<String>(game.value);
    }
    if (stage.present) {
      map['stage'] = Variable<int>(stage.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (correct.present) {
      map['correct'] = Variable<bool>(correct.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<DateTime>(answeredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('changedAt: $changedAt, ')
          ..write('itemId: $itemId, ')
          ..write('questionId: $questionId, ')
          ..write('groupId: $groupId, ')
          ..write('mode: $mode, ')
          ..write('game: $game, ')
          ..write('stage: $stage, ')
          ..write('answer: $answer, ')
          ..write('correct: $correct, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PracticeRulesTable extends PracticeRules
    with TableInfo<$PracticeRulesTable, PracticeRuleSlot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newPracticeId,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<String> ruleId = GeneratedColumn<String>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleNameMeta = const VerificationMeta(
    'ruleName',
  );
  @override
  late final GeneratedColumn<String> ruleName = GeneratedColumn<String>(
    'rule_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _needsMeta = const VerificationMeta('needs');
  @override
  late final GeneratedColumn<String> needs = GeneratedColumn<String>(
    'needs',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _startsMeta = const VerificationMeta('starts');
  @override
  late final GeneratedColumn<String> starts = GeneratedColumn<String>(
    'starts',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _fixedAnswerMeta = const VerificationMeta(
    'fixedAnswer',
  );
  @override
  late final GeneratedColumn<String> fixedAnswer = GeneratedColumn<String>(
    'fixed_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    changedAt,
    language,
    ruleId,
    ruleName,
    slot,
    needs,
    starts,
    fixedAnswer,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeRuleSlot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleIdMeta);
    }
    if (data.containsKey('rule_name')) {
      context.handle(
        _ruleNameMeta,
        ruleName.isAcceptableOrUnknown(data['rule_name']!, _ruleNameMeta),
      );
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('needs')) {
      context.handle(
        _needsMeta,
        needs.isAcceptableOrUnknown(data['needs']!, _needsMeta),
      );
    }
    if (data.containsKey('starts')) {
      context.handle(
        _startsMeta,
        starts.isAcceptableOrUnknown(data['starts']!, _startsMeta),
      );
    }
    if (data.containsKey('fixed_answer')) {
      context.handle(
        _fixedAnswerMeta,
        fixedAnswer.isAcceptableOrUnknown(
          data['fixed_answer']!,
          _fixedAnswerMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {language, ruleId, slot},
  ];
  @override
  PracticeRuleSlot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeRuleSlot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_id'],
      )!,
      ruleName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_name'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      needs: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}needs'],
      )!,
      starts: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}starts'],
      )!,
      fixedAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fixed_answer'],
      )!,
    );
  }

  @override
  $PracticeRulesTable createAlias(String alias) {
    return $PracticeRulesTable(attachedDatabase, alias);
  }
}

class PracticeRuleSlot extends DataClass
    implements Insertable<PracticeRuleSlot> {
  final String id;
  final DateTime changedAt;

  /// The language the rule belongs to, as `Language.name`.
  final String language;

  /// The rule's id, for example "subj-esperar". Shared by its slots.
  final String ruleId;

  /// The rule's name, for the person reading it.
  final String ruleName;

  /// The slot's name or number.
  final String slot;

  /// What the slot needs, in words.
  final String needs;

  /// The starts this slot accepts, as a JSON list of text.
  final String starts;

  /// The one answer every start in this slot must be matched with; empty
  /// when the answer is free.
  final String fixedAnswer;
  const PracticeRuleSlot({
    required this.id,
    required this.changedAt,
    required this.language,
    required this.ruleId,
    required this.ruleName,
    required this.slot,
    required this.needs,
    required this.starts,
    required this.fixedAnswer,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['changed_at'] = Variable<DateTime>(changedAt);
    map['language'] = Variable<String>(language);
    map['rule_id'] = Variable<String>(ruleId);
    map['rule_name'] = Variable<String>(ruleName);
    map['slot'] = Variable<String>(slot);
    map['needs'] = Variable<String>(needs);
    map['starts'] = Variable<String>(starts);
    map['fixed_answer'] = Variable<String>(fixedAnswer);
    return map;
  }

  PracticeRulesCompanion toCompanion(bool nullToAbsent) {
    return PracticeRulesCompanion(
      id: Value(id),
      changedAt: Value(changedAt),
      language: Value(language),
      ruleId: Value(ruleId),
      ruleName: Value(ruleName),
      slot: Value(slot),
      needs: Value(needs),
      starts: Value(starts),
      fixedAnswer: Value(fixedAnswer),
    );
  }

  factory PracticeRuleSlot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeRuleSlot(
      id: serializer.fromJson<String>(json['id']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
      language: serializer.fromJson<String>(json['language']),
      ruleId: serializer.fromJson<String>(json['ruleId']),
      ruleName: serializer.fromJson<String>(json['ruleName']),
      slot: serializer.fromJson<String>(json['slot']),
      needs: serializer.fromJson<String>(json['needs']),
      starts: serializer.fromJson<String>(json['starts']),
      fixedAnswer: serializer.fromJson<String>(json['fixedAnswer']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'changedAt': serializer.toJson<DateTime>(changedAt),
      'language': serializer.toJson<String>(language),
      'ruleId': serializer.toJson<String>(ruleId),
      'ruleName': serializer.toJson<String>(ruleName),
      'slot': serializer.toJson<String>(slot),
      'needs': serializer.toJson<String>(needs),
      'starts': serializer.toJson<String>(starts),
      'fixedAnswer': serializer.toJson<String>(fixedAnswer),
    };
  }

  PracticeRuleSlot copyWith({
    String? id,
    DateTime? changedAt,
    String? language,
    String? ruleId,
    String? ruleName,
    String? slot,
    String? needs,
    String? starts,
    String? fixedAnswer,
  }) => PracticeRuleSlot(
    id: id ?? this.id,
    changedAt: changedAt ?? this.changedAt,
    language: language ?? this.language,
    ruleId: ruleId ?? this.ruleId,
    ruleName: ruleName ?? this.ruleName,
    slot: slot ?? this.slot,
    needs: needs ?? this.needs,
    starts: starts ?? this.starts,
    fixedAnswer: fixedAnswer ?? this.fixedAnswer,
  );
  PracticeRuleSlot copyWithCompanion(PracticeRulesCompanion data) {
    return PracticeRuleSlot(
      id: data.id.present ? data.id.value : this.id,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      language: data.language.present ? data.language.value : this.language,
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
      ruleName: data.ruleName.present ? data.ruleName.value : this.ruleName,
      slot: data.slot.present ? data.slot.value : this.slot,
      needs: data.needs.present ? data.needs.value : this.needs,
      starts: data.starts.present ? data.starts.value : this.starts,
      fixedAnswer: data.fixedAnswer.present
          ? data.fixedAnswer.value
          : this.fixedAnswer,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeRuleSlot(')
          ..write('id: $id, ')
          ..write('changedAt: $changedAt, ')
          ..write('language: $language, ')
          ..write('ruleId: $ruleId, ')
          ..write('ruleName: $ruleName, ')
          ..write('slot: $slot, ')
          ..write('needs: $needs, ')
          ..write('starts: $starts, ')
          ..write('fixedAnswer: $fixedAnswer')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    changedAt,
    language,
    ruleId,
    ruleName,
    slot,
    needs,
    starts,
    fixedAnswer,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeRuleSlot &&
          other.id == this.id &&
          other.changedAt == this.changedAt &&
          other.language == this.language &&
          other.ruleId == this.ruleId &&
          other.ruleName == this.ruleName &&
          other.slot == this.slot &&
          other.needs == this.needs &&
          other.starts == this.starts &&
          other.fixedAnswer == this.fixedAnswer);
}

class PracticeRulesCompanion extends UpdateCompanion<PracticeRuleSlot> {
  final Value<String> id;
  final Value<DateTime> changedAt;
  final Value<String> language;
  final Value<String> ruleId;
  final Value<String> ruleName;
  final Value<String> slot;
  final Value<String> needs;
  final Value<String> starts;
  final Value<String> fixedAnswer;
  final Value<int> rowid;
  const PracticeRulesCompanion({
    this.id = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.language = const Value.absent(),
    this.ruleId = const Value.absent(),
    this.ruleName = const Value.absent(),
    this.slot = const Value.absent(),
    this.needs = const Value.absent(),
    this.starts = const Value.absent(),
    this.fixedAnswer = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PracticeRulesCompanion.insert({
    this.id = const Value.absent(),
    this.changedAt = const Value.absent(),
    required String language,
    required String ruleId,
    this.ruleName = const Value.absent(),
    required String slot,
    this.needs = const Value.absent(),
    this.starts = const Value.absent(),
    this.fixedAnswer = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : language = Value(language),
       ruleId = Value(ruleId),
       slot = Value(slot);
  static Insertable<PracticeRuleSlot> custom({
    Expression<String>? id,
    Expression<DateTime>? changedAt,
    Expression<String>? language,
    Expression<String>? ruleId,
    Expression<String>? ruleName,
    Expression<String>? slot,
    Expression<String>? needs,
    Expression<String>? starts,
    Expression<String>? fixedAnswer,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (changedAt != null) 'changed_at': changedAt,
      if (language != null) 'language': language,
      if (ruleId != null) 'rule_id': ruleId,
      if (ruleName != null) 'rule_name': ruleName,
      if (slot != null) 'slot': slot,
      if (needs != null) 'needs': needs,
      if (starts != null) 'starts': starts,
      if (fixedAnswer != null) 'fixed_answer': fixedAnswer,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PracticeRulesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? changedAt,
    Value<String>? language,
    Value<String>? ruleId,
    Value<String>? ruleName,
    Value<String>? slot,
    Value<String>? needs,
    Value<String>? starts,
    Value<String>? fixedAnswer,
    Value<int>? rowid,
  }) {
    return PracticeRulesCompanion(
      id: id ?? this.id,
      changedAt: changedAt ?? this.changedAt,
      language: language ?? this.language,
      ruleId: ruleId ?? this.ruleId,
      ruleName: ruleName ?? this.ruleName,
      slot: slot ?? this.slot,
      needs: needs ?? this.needs,
      starts: starts ?? this.starts,
      fixedAnswer: fixedAnswer ?? this.fixedAnswer,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<String>(ruleId.value);
    }
    if (ruleName.present) {
      map['rule_name'] = Variable<String>(ruleName.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (needs.present) {
      map['needs'] = Variable<String>(needs.value);
    }
    if (starts.present) {
      map['starts'] = Variable<String>(starts.value);
    }
    if (fixedAnswer.present) {
      map['fixed_answer'] = Variable<String>(fixedAnswer.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeRulesCompanion(')
          ..write('id: $id, ')
          ..write('changedAt: $changedAt, ')
          ..write('language: $language, ')
          ..write('ruleId: $ruleId, ')
          ..write('ruleName: $ruleName, ')
          ..write('slot: $slot, ')
          ..write('needs: $needs, ')
          ..write('starts: $starts, ')
          ..write('fixedAnswer: $fixedAnswer, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$PracticeDatabase extends GeneratedDatabase {
  _$PracticeDatabase(QueryExecutor e) : super(e);
  $PracticeDatabaseManager get managers => $PracticeDatabaseManager(this);
  late final $PracticeItemsTable practiceItems = $PracticeItemsTable(this);
  late final $PracticeQuestionsTable practiceQuestions =
      $PracticeQuestionsTable(this);
  late final $PracticeGroupsTable practiceGroups = $PracticeGroupsTable(this);
  late final $PracticeGroupItemsTable practiceGroupItems =
      $PracticeGroupItemsTable(this);
  late final $PracticeAttemptsTable practiceAttempts = $PracticeAttemptsTable(
    this,
  );
  late final $PracticeRulesTable practiceRules = $PracticeRulesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    practiceItems,
    practiceQuestions,
    practiceGroups,
    practiceGroupItems,
    practiceAttempts,
    practiceRules,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('practice_questions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('practice_group_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('practice_group_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_items',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('practice_attempts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_questions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('practice_attempts', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'practice_groups',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('practice_attempts', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$PracticeItemsTableCreateCompanionBuilder =
    PracticeItemsCompanion Function({
      Value<String> id,
      Value<DateTime> changedAt,
      Value<DateTime> createdAt,
      required String language,
      required String originalSentence,
      required String correctedSentence,
      required String originalPhrase,
      required String correctedPhrase,
      Value<int?> originalStart,
      Value<int?> originalEnd,
      Value<int?> correctedStart,
      Value<int?> correctedEnd,
      Value<String> explanation,
      Value<String> englishSentence,
      Value<int?> englishHighlightStart,
      Value<int?> englishHighlightEnd,
      required String category,
      Value<PracticeSubcategory?> subcategory,
      Value<String> contextText,
      Value<String?> chatId,
      required PracticeInputMode inputMode,
      Value<String?> savedCorrectionId,
      Value<int> ladderStage,
      Value<int> lockedStage,
      Value<bool> retired,
      Value<int> rowid,
    });
typedef $$PracticeItemsTableUpdateCompanionBuilder =
    PracticeItemsCompanion Function({
      Value<String> id,
      Value<DateTime> changedAt,
      Value<DateTime> createdAt,
      Value<String> language,
      Value<String> originalSentence,
      Value<String> correctedSentence,
      Value<String> originalPhrase,
      Value<String> correctedPhrase,
      Value<int?> originalStart,
      Value<int?> originalEnd,
      Value<int?> correctedStart,
      Value<int?> correctedEnd,
      Value<String> explanation,
      Value<String> englishSentence,
      Value<int?> englishHighlightStart,
      Value<int?> englishHighlightEnd,
      Value<String> category,
      Value<PracticeSubcategory?> subcategory,
      Value<String> contextText,
      Value<String?> chatId,
      Value<PracticeInputMode> inputMode,
      Value<String?> savedCorrectionId,
      Value<int> ladderStage,
      Value<int> lockedStage,
      Value<bool> retired,
      Value<int> rowid,
    });

final class $$PracticeItemsTableReferences
    extends
        BaseReferences<_$PracticeDatabase, $PracticeItemsTable, PracticeItem> {
  $$PracticeItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PracticeQuestionsTable, List<PracticeQuestionRow>>
  _practiceQuestionsRefsTable(_$PracticeDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.practiceQuestions,
        aliasName: $_aliasNameGenerator(
          db.practiceItems.id,
          db.practiceQuestions.itemId,
        ),
      );

  $$PracticeQuestionsTableProcessedTableManager get practiceQuestionsRefs {
    final manager = $$PracticeQuestionsTableTableManager(
      $_db,
      $_db.practiceQuestions,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _practiceQuestionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PracticeGroupItemsTable, List<PracticeGroupItem>>
  _practiceGroupItemsRefsTable(_$PracticeDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.practiceGroupItems,
        aliasName: $_aliasNameGenerator(
          db.practiceItems.id,
          db.practiceGroupItems.itemId,
        ),
      );

  $$PracticeGroupItemsTableProcessedTableManager get practiceGroupItemsRefs {
    final manager = $$PracticeGroupItemsTableTableManager(
      $_db,
      $_db.practiceGroupItems,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _practiceGroupItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PracticeAttemptsTable, List<PracticeAttempt>>
  _practiceAttemptsRefsTable(_$PracticeDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.practiceAttempts,
        aliasName: $_aliasNameGenerator(
          db.practiceItems.id,
          db.practiceAttempts.itemId,
        ),
      );

  $$PracticeAttemptsTableProcessedTableManager get practiceAttemptsRefs {
    final manager = $$PracticeAttemptsTableTableManager(
      $_db,
      $_db.practiceAttempts,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _practiceAttemptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PracticeItemsTableFilterComposer
    extends Composer<_$PracticeDatabase, $PracticeItemsTable> {
  $$PracticeItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalSentence => $composableBuilder(
    column: $table.originalSentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctedSentence => $composableBuilder(
    column: $table.correctedSentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalPhrase => $composableBuilder(
    column: $table.originalPhrase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get correctedPhrase => $composableBuilder(
    column: $table.correctedPhrase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalStart => $composableBuilder(
    column: $table.originalStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalEnd => $composableBuilder(
    column: $table.originalEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctedStart => $composableBuilder(
    column: $table.correctedStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctedEnd => $composableBuilder(
    column: $table.correctedEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishSentence => $composableBuilder(
    column: $table.englishSentence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get englishHighlightStart => $composableBuilder(
    column: $table.englishHighlightStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get englishHighlightEnd => $composableBuilder(
    column: $table.englishHighlightEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    PracticeSubcategory?,
    PracticeSubcategory,
    String
  >
  get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get contextText => $composableBuilder(
    column: $table.contextText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PracticeInputMode, PracticeInputMode, String>
  get inputMode => $composableBuilder(
    column: $table.inputMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get savedCorrectionId => $composableBuilder(
    column: $table.savedCorrectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ladderStage => $composableBuilder(
    column: $table.ladderStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lockedStage => $composableBuilder(
    column: $table.lockedStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get retired => $composableBuilder(
    column: $table.retired,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> practiceQuestionsRefs(
    Expression<bool> Function($$PracticeQuestionsTableFilterComposer f) f,
  ) {
    final $$PracticeQuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceQuestions,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeQuestionsTableFilterComposer(
            $db: $db,
            $table: $db.practiceQuestions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> practiceGroupItemsRefs(
    Expression<bool> Function($$PracticeGroupItemsTableFilterComposer f) f,
  ) {
    final $$PracticeGroupItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceGroupItems,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeGroupItemsTableFilterComposer(
            $db: $db,
            $table: $db.practiceGroupItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> practiceAttemptsRefs(
    Expression<bool> Function($$PracticeAttemptsTableFilterComposer f) f,
  ) {
    final $$PracticeAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceAttempts,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.practiceAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PracticeItemsTableOrderingComposer
    extends Composer<_$PracticeDatabase, $PracticeItemsTable> {
  $$PracticeItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalSentence => $composableBuilder(
    column: $table.originalSentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctedSentence => $composableBuilder(
    column: $table.correctedSentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalPhrase => $composableBuilder(
    column: $table.originalPhrase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get correctedPhrase => $composableBuilder(
    column: $table.correctedPhrase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalStart => $composableBuilder(
    column: $table.originalStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalEnd => $composableBuilder(
    column: $table.originalEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctedStart => $composableBuilder(
    column: $table.correctedStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctedEnd => $composableBuilder(
    column: $table.correctedEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishSentence => $composableBuilder(
    column: $table.englishSentence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get englishHighlightStart => $composableBuilder(
    column: $table.englishHighlightStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get englishHighlightEnd => $composableBuilder(
    column: $table.englishHighlightEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contextText => $composableBuilder(
    column: $table.contextText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chatId => $composableBuilder(
    column: $table.chatId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputMode => $composableBuilder(
    column: $table.inputMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get savedCorrectionId => $composableBuilder(
    column: $table.savedCorrectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ladderStage => $composableBuilder(
    column: $table.ladderStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lockedStage => $composableBuilder(
    column: $table.lockedStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get retired => $composableBuilder(
    column: $table.retired,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PracticeItemsTableAnnotationComposer
    extends Composer<_$PracticeDatabase, $PracticeItemsTable> {
  $$PracticeItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get originalSentence => $composableBuilder(
    column: $table.originalSentence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correctedSentence => $composableBuilder(
    column: $table.correctedSentence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originalPhrase => $composableBuilder(
    column: $table.originalPhrase,
    builder: (column) => column,
  );

  GeneratedColumn<String> get correctedPhrase => $composableBuilder(
    column: $table.correctedPhrase,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originalStart => $composableBuilder(
    column: $table.originalStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originalEnd => $composableBuilder(
    column: $table.originalEnd,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctedStart => $composableBuilder(
    column: $table.correctedStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctedEnd => $composableBuilder(
    column: $table.correctedEnd,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get englishSentence => $composableBuilder(
    column: $table.englishSentence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get englishHighlightStart => $composableBuilder(
    column: $table.englishHighlightStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get englishHighlightEnd => $composableBuilder(
    column: $table.englishHighlightEnd,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PracticeSubcategory?, String>
  get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contextText => $composableBuilder(
    column: $table.contextText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PracticeInputMode, String> get inputMode =>
      $composableBuilder(column: $table.inputMode, builder: (column) => column);

  GeneratedColumn<String> get savedCorrectionId => $composableBuilder(
    column: $table.savedCorrectionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ladderStage => $composableBuilder(
    column: $table.ladderStage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lockedStage => $composableBuilder(
    column: $table.lockedStage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get retired =>
      $composableBuilder(column: $table.retired, builder: (column) => column);

  Expression<T> practiceQuestionsRefs<T extends Object>(
    Expression<T> Function($$PracticeQuestionsTableAnnotationComposer a) f,
  ) {
    final $$PracticeQuestionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.practiceQuestions,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeQuestionsTableAnnotationComposer(
                $db: $db,
                $table: $db.practiceQuestions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> practiceGroupItemsRefs<T extends Object>(
    Expression<T> Function($$PracticeGroupItemsTableAnnotationComposer a) f,
  ) {
    final $$PracticeGroupItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.practiceGroupItems,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeGroupItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.practiceGroupItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> practiceAttemptsRefs<T extends Object>(
    Expression<T> Function($$PracticeAttemptsTableAnnotationComposer a) f,
  ) {
    final $$PracticeAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceAttempts,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeAttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PracticeItemsTableTableManager
    extends
        RootTableManager<
          _$PracticeDatabase,
          $PracticeItemsTable,
          PracticeItem,
          $$PracticeItemsTableFilterComposer,
          $$PracticeItemsTableOrderingComposer,
          $$PracticeItemsTableAnnotationComposer,
          $$PracticeItemsTableCreateCompanionBuilder,
          $$PracticeItemsTableUpdateCompanionBuilder,
          (PracticeItem, $$PracticeItemsTableReferences),
          PracticeItem,
          PrefetchHooks Function({
            bool practiceQuestionsRefs,
            bool practiceGroupItemsRefs,
            bool practiceAttemptsRefs,
          })
        > {
  $$PracticeItemsTableTableManager(
    _$PracticeDatabase db,
    $PracticeItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> originalSentence = const Value.absent(),
                Value<String> correctedSentence = const Value.absent(),
                Value<String> originalPhrase = const Value.absent(),
                Value<String> correctedPhrase = const Value.absent(),
                Value<int?> originalStart = const Value.absent(),
                Value<int?> originalEnd = const Value.absent(),
                Value<int?> correctedStart = const Value.absent(),
                Value<int?> correctedEnd = const Value.absent(),
                Value<String> explanation = const Value.absent(),
                Value<String> englishSentence = const Value.absent(),
                Value<int?> englishHighlightStart = const Value.absent(),
                Value<int?> englishHighlightEnd = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<PracticeSubcategory?> subcategory = const Value.absent(),
                Value<String> contextText = const Value.absent(),
                Value<String?> chatId = const Value.absent(),
                Value<PracticeInputMode> inputMode = const Value.absent(),
                Value<String?> savedCorrectionId = const Value.absent(),
                Value<int> ladderStage = const Value.absent(),
                Value<int> lockedStage = const Value.absent(),
                Value<bool> retired = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeItemsCompanion(
                id: id,
                changedAt: changedAt,
                createdAt: createdAt,
                language: language,
                originalSentence: originalSentence,
                correctedSentence: correctedSentence,
                originalPhrase: originalPhrase,
                correctedPhrase: correctedPhrase,
                originalStart: originalStart,
                originalEnd: originalEnd,
                correctedStart: correctedStart,
                correctedEnd: correctedEnd,
                explanation: explanation,
                englishSentence: englishSentence,
                englishHighlightStart: englishHighlightStart,
                englishHighlightEnd: englishHighlightEnd,
                category: category,
                subcategory: subcategory,
                contextText: contextText,
                chatId: chatId,
                inputMode: inputMode,
                savedCorrectionId: savedCorrectionId,
                ladderStage: ladderStage,
                lockedStage: lockedStage,
                retired: retired,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                required String language,
                required String originalSentence,
                required String correctedSentence,
                required String originalPhrase,
                required String correctedPhrase,
                Value<int?> originalStart = const Value.absent(),
                Value<int?> originalEnd = const Value.absent(),
                Value<int?> correctedStart = const Value.absent(),
                Value<int?> correctedEnd = const Value.absent(),
                Value<String> explanation = const Value.absent(),
                Value<String> englishSentence = const Value.absent(),
                Value<int?> englishHighlightStart = const Value.absent(),
                Value<int?> englishHighlightEnd = const Value.absent(),
                required String category,
                Value<PracticeSubcategory?> subcategory = const Value.absent(),
                Value<String> contextText = const Value.absent(),
                Value<String?> chatId = const Value.absent(),
                required PracticeInputMode inputMode,
                Value<String?> savedCorrectionId = const Value.absent(),
                Value<int> ladderStage = const Value.absent(),
                Value<int> lockedStage = const Value.absent(),
                Value<bool> retired = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeItemsCompanion.insert(
                id: id,
                changedAt: changedAt,
                createdAt: createdAt,
                language: language,
                originalSentence: originalSentence,
                correctedSentence: correctedSentence,
                originalPhrase: originalPhrase,
                correctedPhrase: correctedPhrase,
                originalStart: originalStart,
                originalEnd: originalEnd,
                correctedStart: correctedStart,
                correctedEnd: correctedEnd,
                explanation: explanation,
                englishSentence: englishSentence,
                englishHighlightStart: englishHighlightStart,
                englishHighlightEnd: englishHighlightEnd,
                category: category,
                subcategory: subcategory,
                contextText: contextText,
                chatId: chatId,
                inputMode: inputMode,
                savedCorrectionId: savedCorrectionId,
                ladderStage: ladderStage,
                lockedStage: lockedStage,
                retired: retired,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                practiceQuestionsRefs = false,
                practiceGroupItemsRefs = false,
                practiceAttemptsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (practiceQuestionsRefs) db.practiceQuestions,
                    if (practiceGroupItemsRefs) db.practiceGroupItems,
                    if (practiceAttemptsRefs) db.practiceAttempts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (practiceQuestionsRefs)
                        await $_getPrefetchedData<
                          PracticeItem,
                          $PracticeItemsTable,
                          PracticeQuestionRow
                        >(
                          currentTable: table,
                          referencedTable: $$PracticeItemsTableReferences
                              ._practiceQuestionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PracticeItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).practiceQuestionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (practiceGroupItemsRefs)
                        await $_getPrefetchedData<
                          PracticeItem,
                          $PracticeItemsTable,
                          PracticeGroupItem
                        >(
                          currentTable: table,
                          referencedTable: $$PracticeItemsTableReferences
                              ._practiceGroupItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PracticeItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).practiceGroupItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (practiceAttemptsRefs)
                        await $_getPrefetchedData<
                          PracticeItem,
                          $PracticeItemsTable,
                          PracticeAttempt
                        >(
                          currentTable: table,
                          referencedTable: $$PracticeItemsTableReferences
                              ._practiceAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PracticeItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).practiceAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PracticeItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$PracticeDatabase,
      $PracticeItemsTable,
      PracticeItem,
      $$PracticeItemsTableFilterComposer,
      $$PracticeItemsTableOrderingComposer,
      $$PracticeItemsTableAnnotationComposer,
      $$PracticeItemsTableCreateCompanionBuilder,
      $$PracticeItemsTableUpdateCompanionBuilder,
      (PracticeItem, $$PracticeItemsTableReferences),
      PracticeItem,
      PrefetchHooks Function({
        bool practiceQuestionsRefs,
        bool practiceGroupItemsRefs,
        bool practiceAttemptsRefs,
      })
    >;
typedef $$PracticeQuestionsTableCreateCompanionBuilder =
    PracticeQuestionsCompanion Function({
      Value<String> id,
      Value<DateTime> changedAt,
      Value<DateTime> createdAt,
      required String itemId,
      required String game,
      required int stage,
      required String body,
      Value<int> rowid,
    });
typedef $$PracticeQuestionsTableUpdateCompanionBuilder =
    PracticeQuestionsCompanion Function({
      Value<String> id,
      Value<DateTime> changedAt,
      Value<DateTime> createdAt,
      Value<String> itemId,
      Value<String> game,
      Value<int> stage,
      Value<String> body,
      Value<int> rowid,
    });

final class $$PracticeQuestionsTableReferences
    extends
        BaseReferences<
          _$PracticeDatabase,
          $PracticeQuestionsTable,
          PracticeQuestionRow
        > {
  $$PracticeQuestionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PracticeItemsTable _itemIdTable(_$PracticeDatabase db) =>
      db.practiceItems.createAlias(
        $_aliasNameGenerator(db.practiceQuestions.itemId, db.practiceItems.id),
      );

  $$PracticeItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$PracticeItemsTableTableManager(
      $_db,
      $_db.practiceItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PracticeAttemptsTable, List<PracticeAttempt>>
  _practiceAttemptsRefsTable(_$PracticeDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.practiceAttempts,
        aliasName: $_aliasNameGenerator(
          db.practiceQuestions.id,
          db.practiceAttempts.questionId,
        ),
      );

  $$PracticeAttemptsTableProcessedTableManager get practiceAttemptsRefs {
    final manager = $$PracticeAttemptsTableTableManager(
      $_db,
      $_db.practiceAttempts,
    ).filter((f) => f.questionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _practiceAttemptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PracticeQuestionsTableFilterComposer
    extends Composer<_$PracticeDatabase, $PracticeQuestionsTable> {
  $$PracticeQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get game => $composableBuilder(
    column: $table.game,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  $$PracticeItemsTableFilterComposer get itemId {
    final $$PracticeItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.practiceItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeItemsTableFilterComposer(
            $db: $db,
            $table: $db.practiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> practiceAttemptsRefs(
    Expression<bool> Function($$PracticeAttemptsTableFilterComposer f) f,
  ) {
    final $$PracticeAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceAttempts,
      getReferencedColumn: (t) => t.questionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.practiceAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PracticeQuestionsTableOrderingComposer
    extends Composer<_$PracticeDatabase, $PracticeQuestionsTable> {
  $$PracticeQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get game => $composableBuilder(
    column: $table.game,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  $$PracticeItemsTableOrderingComposer get itemId {
    final $$PracticeItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.practiceItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeItemsTableOrderingComposer(
            $db: $db,
            $table: $db.practiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeQuestionsTableAnnotationComposer
    extends Composer<_$PracticeDatabase, $PracticeQuestionsTable> {
  $$PracticeQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get game =>
      $composableBuilder(column: $table.game, builder: (column) => column);

  GeneratedColumn<int> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  $$PracticeItemsTableAnnotationComposer get itemId {
    final $$PracticeItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.practiceItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> practiceAttemptsRefs<T extends Object>(
    Expression<T> Function($$PracticeAttemptsTableAnnotationComposer a) f,
  ) {
    final $$PracticeAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceAttempts,
      getReferencedColumn: (t) => t.questionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeAttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PracticeQuestionsTableTableManager
    extends
        RootTableManager<
          _$PracticeDatabase,
          $PracticeQuestionsTable,
          PracticeQuestionRow,
          $$PracticeQuestionsTableFilterComposer,
          $$PracticeQuestionsTableOrderingComposer,
          $$PracticeQuestionsTableAnnotationComposer,
          $$PracticeQuestionsTableCreateCompanionBuilder,
          $$PracticeQuestionsTableUpdateCompanionBuilder,
          (PracticeQuestionRow, $$PracticeQuestionsTableReferences),
          PracticeQuestionRow,
          PrefetchHooks Function({bool itemId, bool practiceAttemptsRefs})
        > {
  $$PracticeQuestionsTableTableManager(
    _$PracticeDatabase db,
    $PracticeQuestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeQuestionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> game = const Value.absent(),
                Value<int> stage = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeQuestionsCompanion(
                id: id,
                changedAt: changedAt,
                createdAt: createdAt,
                itemId: itemId,
                game: game,
                stage: stage,
                body: body,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                required String itemId,
                required String game,
                required int stage,
                required String body,
                Value<int> rowid = const Value.absent(),
              }) => PracticeQuestionsCompanion.insert(
                id: id,
                changedAt: changedAt,
                createdAt: createdAt,
                itemId: itemId,
                game: game,
                stage: stage,
                body: body,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeQuestionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({itemId = false, practiceAttemptsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (practiceAttemptsRefs) db.practiceAttempts,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (itemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.itemId,
                                    referencedTable:
                                        $$PracticeQuestionsTableReferences
                                            ._itemIdTable(db),
                                    referencedColumn:
                                        $$PracticeQuestionsTableReferences
                                            ._itemIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (practiceAttemptsRefs)
                        await $_getPrefetchedData<
                          PracticeQuestionRow,
                          $PracticeQuestionsTable,
                          PracticeAttempt
                        >(
                          currentTable: table,
                          referencedTable: $$PracticeQuestionsTableReferences
                              ._practiceAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PracticeQuestionsTableReferences(
                                db,
                                table,
                                p0,
                              ).practiceAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.questionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PracticeQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$PracticeDatabase,
      $PracticeQuestionsTable,
      PracticeQuestionRow,
      $$PracticeQuestionsTableFilterComposer,
      $$PracticeQuestionsTableOrderingComposer,
      $$PracticeQuestionsTableAnnotationComposer,
      $$PracticeQuestionsTableCreateCompanionBuilder,
      $$PracticeQuestionsTableUpdateCompanionBuilder,
      (PracticeQuestionRow, $$PracticeQuestionsTableReferences),
      PracticeQuestionRow,
      PrefetchHooks Function({bool itemId, bool practiceAttemptsRefs})
    >;
typedef $$PracticeGroupsTableCreateCompanionBuilder =
    PracticeGroupsCompanion Function({
      Value<String> id,
      Value<DateTime> changedAt,
      Value<DateTime> createdAt,
      required String language,
      required PracticeGroupKind kind,
      Value<String> category,
      Value<PracticeSubcategory?> subcategory,
      Value<bool> isRevision,
      Value<int> stage,
      Value<int> retriesAtStage,
      Value<DateTime?> lastPassedAt,
      Value<DateTime?> unlocksAt,
      Value<bool> finished,
      Value<int> rowid,
    });
typedef $$PracticeGroupsTableUpdateCompanionBuilder =
    PracticeGroupsCompanion Function({
      Value<String> id,
      Value<DateTime> changedAt,
      Value<DateTime> createdAt,
      Value<String> language,
      Value<PracticeGroupKind> kind,
      Value<String> category,
      Value<PracticeSubcategory?> subcategory,
      Value<bool> isRevision,
      Value<int> stage,
      Value<int> retriesAtStage,
      Value<DateTime?> lastPassedAt,
      Value<DateTime?> unlocksAt,
      Value<bool> finished,
      Value<int> rowid,
    });

final class $$PracticeGroupsTableReferences
    extends
        BaseReferences<
          _$PracticeDatabase,
          $PracticeGroupsTable,
          PracticeGroup
        > {
  $$PracticeGroupsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PracticeGroupItemsTable, List<PracticeGroupItem>>
  _practiceGroupItemsRefsTable(_$PracticeDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.practiceGroupItems,
        aliasName: $_aliasNameGenerator(
          db.practiceGroups.id,
          db.practiceGroupItems.groupId,
        ),
      );

  $$PracticeGroupItemsTableProcessedTableManager get practiceGroupItemsRefs {
    final manager = $$PracticeGroupItemsTableTableManager(
      $_db,
      $_db.practiceGroupItems,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _practiceGroupItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PracticeAttemptsTable, List<PracticeAttempt>>
  _practiceAttemptsRefsTable(_$PracticeDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.practiceAttempts,
        aliasName: $_aliasNameGenerator(
          db.practiceGroups.id,
          db.practiceAttempts.groupId,
        ),
      );

  $$PracticeAttemptsTableProcessedTableManager get practiceAttemptsRefs {
    final manager = $$PracticeAttemptsTableTableManager(
      $_db,
      $_db.practiceAttempts,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _practiceAttemptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PracticeGroupsTableFilterComposer
    extends Composer<_$PracticeDatabase, $PracticeGroupsTable> {
  $$PracticeGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PracticeGroupKind, PracticeGroupKind, String>
  get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    PracticeSubcategory?,
    PracticeSubcategory,
    String
  >
  get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isRevision => $composableBuilder(
    column: $table.isRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retriesAtStage => $composableBuilder(
    column: $table.retriesAtStage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPassedAt => $composableBuilder(
    column: $table.lastPassedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlocksAt => $composableBuilder(
    column: $table.unlocksAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get finished => $composableBuilder(
    column: $table.finished,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> practiceGroupItemsRefs(
    Expression<bool> Function($$PracticeGroupItemsTableFilterComposer f) f,
  ) {
    final $$PracticeGroupItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceGroupItems,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeGroupItemsTableFilterComposer(
            $db: $db,
            $table: $db.practiceGroupItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> practiceAttemptsRefs(
    Expression<bool> Function($$PracticeAttemptsTableFilterComposer f) f,
  ) {
    final $$PracticeAttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceAttempts,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeAttemptsTableFilterComposer(
            $db: $db,
            $table: $db.practiceAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PracticeGroupsTableOrderingComposer
    extends Composer<_$PracticeDatabase, $PracticeGroupsTable> {
  $$PracticeGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRevision => $composableBuilder(
    column: $table.isRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retriesAtStage => $composableBuilder(
    column: $table.retriesAtStage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPassedAt => $composableBuilder(
    column: $table.lastPassedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlocksAt => $composableBuilder(
    column: $table.unlocksAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get finished => $composableBuilder(
    column: $table.finished,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PracticeGroupsTableAnnotationComposer
    extends Composer<_$PracticeDatabase, $PracticeGroupsTable> {
  $$PracticeGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PracticeGroupKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PracticeSubcategory?, String>
  get subcategory => $composableBuilder(
    column: $table.subcategory,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isRevision => $composableBuilder(
    column: $table.isRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<int> get retriesAtStage => $composableBuilder(
    column: $table.retriesAtStage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPassedAt => $composableBuilder(
    column: $table.lastPassedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get unlocksAt =>
      $composableBuilder(column: $table.unlocksAt, builder: (column) => column);

  GeneratedColumn<bool> get finished =>
      $composableBuilder(column: $table.finished, builder: (column) => column);

  Expression<T> practiceGroupItemsRefs<T extends Object>(
    Expression<T> Function($$PracticeGroupItemsTableAnnotationComposer a) f,
  ) {
    final $$PracticeGroupItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.practiceGroupItems,
          getReferencedColumn: (t) => t.groupId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeGroupItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.practiceGroupItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> practiceAttemptsRefs<T extends Object>(
    Expression<T> Function($$PracticeAttemptsTableAnnotationComposer a) f,
  ) {
    final $$PracticeAttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceAttempts,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeAttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceAttempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PracticeGroupsTableTableManager
    extends
        RootTableManager<
          _$PracticeDatabase,
          $PracticeGroupsTable,
          PracticeGroup,
          $$PracticeGroupsTableFilterComposer,
          $$PracticeGroupsTableOrderingComposer,
          $$PracticeGroupsTableAnnotationComposer,
          $$PracticeGroupsTableCreateCompanionBuilder,
          $$PracticeGroupsTableUpdateCompanionBuilder,
          (PracticeGroup, $$PracticeGroupsTableReferences),
          PracticeGroup,
          PrefetchHooks Function({
            bool practiceGroupItemsRefs,
            bool practiceAttemptsRefs,
          })
        > {
  $$PracticeGroupsTableTableManager(
    _$PracticeDatabase db,
    $PracticeGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<PracticeGroupKind> kind = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<PracticeSubcategory?> subcategory = const Value.absent(),
                Value<bool> isRevision = const Value.absent(),
                Value<int> stage = const Value.absent(),
                Value<int> retriesAtStage = const Value.absent(),
                Value<DateTime?> lastPassedAt = const Value.absent(),
                Value<DateTime?> unlocksAt = const Value.absent(),
                Value<bool> finished = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeGroupsCompanion(
                id: id,
                changedAt: changedAt,
                createdAt: createdAt,
                language: language,
                kind: kind,
                category: category,
                subcategory: subcategory,
                isRevision: isRevision,
                stage: stage,
                retriesAtStage: retriesAtStage,
                lastPassedAt: lastPassedAt,
                unlocksAt: unlocksAt,
                finished: finished,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                required String language,
                required PracticeGroupKind kind,
                Value<String> category = const Value.absent(),
                Value<PracticeSubcategory?> subcategory = const Value.absent(),
                Value<bool> isRevision = const Value.absent(),
                Value<int> stage = const Value.absent(),
                Value<int> retriesAtStage = const Value.absent(),
                Value<DateTime?> lastPassedAt = const Value.absent(),
                Value<DateTime?> unlocksAt = const Value.absent(),
                Value<bool> finished = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeGroupsCompanion.insert(
                id: id,
                changedAt: changedAt,
                createdAt: createdAt,
                language: language,
                kind: kind,
                category: category,
                subcategory: subcategory,
                isRevision: isRevision,
                stage: stage,
                retriesAtStage: retriesAtStage,
                lastPassedAt: lastPassedAt,
                unlocksAt: unlocksAt,
                finished: finished,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeGroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({practiceGroupItemsRefs = false, practiceAttemptsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (practiceGroupItemsRefs) db.practiceGroupItems,
                    if (practiceAttemptsRefs) db.practiceAttempts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (practiceGroupItemsRefs)
                        await $_getPrefetchedData<
                          PracticeGroup,
                          $PracticeGroupsTable,
                          PracticeGroupItem
                        >(
                          currentTable: table,
                          referencedTable: $$PracticeGroupsTableReferences
                              ._practiceGroupItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PracticeGroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).practiceGroupItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (practiceAttemptsRefs)
                        await $_getPrefetchedData<
                          PracticeGroup,
                          $PracticeGroupsTable,
                          PracticeAttempt
                        >(
                          currentTable: table,
                          referencedTable: $$PracticeGroupsTableReferences
                              ._practiceAttemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PracticeGroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).practiceAttemptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PracticeGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$PracticeDatabase,
      $PracticeGroupsTable,
      PracticeGroup,
      $$PracticeGroupsTableFilterComposer,
      $$PracticeGroupsTableOrderingComposer,
      $$PracticeGroupsTableAnnotationComposer,
      $$PracticeGroupsTableCreateCompanionBuilder,
      $$PracticeGroupsTableUpdateCompanionBuilder,
      (PracticeGroup, $$PracticeGroupsTableReferences),
      PracticeGroup,
      PrefetchHooks Function({
        bool practiceGroupItemsRefs,
        bool practiceAttemptsRefs,
      })
    >;
typedef $$PracticeGroupItemsTableCreateCompanionBuilder =
    PracticeGroupItemsCompanion Function({
      Value<String> id,
      Value<DateTime> changedAt,
      required String groupId,
      required String itemId,
      Value<int> position,
      Value<bool> missedLastRound,
      Value<int> failedRetries,
      Value<int> rowid,
    });
typedef $$PracticeGroupItemsTableUpdateCompanionBuilder =
    PracticeGroupItemsCompanion Function({
      Value<String> id,
      Value<DateTime> changedAt,
      Value<String> groupId,
      Value<String> itemId,
      Value<int> position,
      Value<bool> missedLastRound,
      Value<int> failedRetries,
      Value<int> rowid,
    });

final class $$PracticeGroupItemsTableReferences
    extends
        BaseReferences<
          _$PracticeDatabase,
          $PracticeGroupItemsTable,
          PracticeGroupItem
        > {
  $$PracticeGroupItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PracticeGroupsTable _groupIdTable(_$PracticeDatabase db) =>
      db.practiceGroups.createAlias(
        $_aliasNameGenerator(
          db.practiceGroupItems.groupId,
          db.practiceGroups.id,
        ),
      );

  $$PracticeGroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$PracticeGroupsTableTableManager(
      $_db,
      $_db.practiceGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PracticeItemsTable _itemIdTable(_$PracticeDatabase db) =>
      db.practiceItems.createAlias(
        $_aliasNameGenerator(db.practiceGroupItems.itemId, db.practiceItems.id),
      );

  $$PracticeItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$PracticeItemsTableTableManager(
      $_db,
      $_db.practiceItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PracticeGroupItemsTableFilterComposer
    extends Composer<_$PracticeDatabase, $PracticeGroupItemsTable> {
  $$PracticeGroupItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get missedLastRound => $composableBuilder(
    column: $table.missedLastRound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedRetries => $composableBuilder(
    column: $table.failedRetries,
    builder: (column) => ColumnFilters(column),
  );

  $$PracticeGroupsTableFilterComposer get groupId {
    final $$PracticeGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.practiceGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeGroupsTableFilterComposer(
            $db: $db,
            $table: $db.practiceGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PracticeItemsTableFilterComposer get itemId {
    final $$PracticeItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.practiceItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeItemsTableFilterComposer(
            $db: $db,
            $table: $db.practiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeGroupItemsTableOrderingComposer
    extends Composer<_$PracticeDatabase, $PracticeGroupItemsTable> {
  $$PracticeGroupItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get missedLastRound => $composableBuilder(
    column: $table.missedLastRound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedRetries => $composableBuilder(
    column: $table.failedRetries,
    builder: (column) => ColumnOrderings(column),
  );

  $$PracticeGroupsTableOrderingComposer get groupId {
    final $$PracticeGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.practiceGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.practiceGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PracticeItemsTableOrderingComposer get itemId {
    final $$PracticeItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.practiceItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeItemsTableOrderingComposer(
            $db: $db,
            $table: $db.practiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeGroupItemsTableAnnotationComposer
    extends Composer<_$PracticeDatabase, $PracticeGroupItemsTable> {
  $$PracticeGroupItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get missedLastRound => $composableBuilder(
    column: $table.missedLastRound,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failedRetries => $composableBuilder(
    column: $table.failedRetries,
    builder: (column) => column,
  );

  $$PracticeGroupsTableAnnotationComposer get groupId {
    final $$PracticeGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.practiceGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PracticeItemsTableAnnotationComposer get itemId {
    final $$PracticeItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.practiceItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeGroupItemsTableTableManager
    extends
        RootTableManager<
          _$PracticeDatabase,
          $PracticeGroupItemsTable,
          PracticeGroupItem,
          $$PracticeGroupItemsTableFilterComposer,
          $$PracticeGroupItemsTableOrderingComposer,
          $$PracticeGroupItemsTableAnnotationComposer,
          $$PracticeGroupItemsTableCreateCompanionBuilder,
          $$PracticeGroupItemsTableUpdateCompanionBuilder,
          (PracticeGroupItem, $$PracticeGroupItemsTableReferences),
          PracticeGroupItem,
          PrefetchHooks Function({bool groupId, bool itemId})
        > {
  $$PracticeGroupItemsTableTableManager(
    _$PracticeDatabase db,
    $PracticeGroupItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeGroupItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeGroupItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeGroupItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> missedLastRound = const Value.absent(),
                Value<int> failedRetries = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeGroupItemsCompanion(
                id: id,
                changedAt: changedAt,
                groupId: groupId,
                itemId: itemId,
                position: position,
                missedLastRound: missedLastRound,
                failedRetries: failedRetries,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                required String groupId,
                required String itemId,
                Value<int> position = const Value.absent(),
                Value<bool> missedLastRound = const Value.absent(),
                Value<int> failedRetries = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeGroupItemsCompanion.insert(
                id: id,
                changedAt: changedAt,
                groupId: groupId,
                itemId: itemId,
                position: position,
                missedLastRound: missedLastRound,
                failedRetries: failedRetries,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeGroupItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false, itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupId,
                                referencedTable:
                                    $$PracticeGroupItemsTableReferences
                                        ._groupIdTable(db),
                                referencedColumn:
                                    $$PracticeGroupItemsTableReferences
                                        ._groupIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$PracticeGroupItemsTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$PracticeGroupItemsTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PracticeGroupItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$PracticeDatabase,
      $PracticeGroupItemsTable,
      PracticeGroupItem,
      $$PracticeGroupItemsTableFilterComposer,
      $$PracticeGroupItemsTableOrderingComposer,
      $$PracticeGroupItemsTableAnnotationComposer,
      $$PracticeGroupItemsTableCreateCompanionBuilder,
      $$PracticeGroupItemsTableUpdateCompanionBuilder,
      (PracticeGroupItem, $$PracticeGroupItemsTableReferences),
      PracticeGroupItem,
      PrefetchHooks Function({bool groupId, bool itemId})
    >;
typedef $$PracticeAttemptsTableCreateCompanionBuilder =
    PracticeAttemptsCompanion Function({
      Value<String> id,
      Value<DateTime> changedAt,
      required String itemId,
      Value<String?> questionId,
      Value<String?> groupId,
      required PracticeMode mode,
      required String game,
      required int stage,
      Value<String> answer,
      required bool correct,
      Value<DateTime> answeredAt,
      Value<int> rowid,
    });
typedef $$PracticeAttemptsTableUpdateCompanionBuilder =
    PracticeAttemptsCompanion Function({
      Value<String> id,
      Value<DateTime> changedAt,
      Value<String> itemId,
      Value<String?> questionId,
      Value<String?> groupId,
      Value<PracticeMode> mode,
      Value<String> game,
      Value<int> stage,
      Value<String> answer,
      Value<bool> correct,
      Value<DateTime> answeredAt,
      Value<int> rowid,
    });

final class $$PracticeAttemptsTableReferences
    extends
        BaseReferences<
          _$PracticeDatabase,
          $PracticeAttemptsTable,
          PracticeAttempt
        > {
  $$PracticeAttemptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PracticeItemsTable _itemIdTable(_$PracticeDatabase db) =>
      db.practiceItems.createAlias(
        $_aliasNameGenerator(db.practiceAttempts.itemId, db.practiceItems.id),
      );

  $$PracticeItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$PracticeItemsTableTableManager(
      $_db,
      $_db.practiceItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PracticeQuestionsTable _questionIdTable(_$PracticeDatabase db) =>
      db.practiceQuestions.createAlias(
        $_aliasNameGenerator(
          db.practiceAttempts.questionId,
          db.practiceQuestions.id,
        ),
      );

  $$PracticeQuestionsTableProcessedTableManager? get questionId {
    final $_column = $_itemColumn<String>('question_id');
    if ($_column == null) return null;
    final manager = $$PracticeQuestionsTableTableManager(
      $_db,
      $_db.practiceQuestions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_questionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PracticeGroupsTable _groupIdTable(_$PracticeDatabase db) =>
      db.practiceGroups.createAlias(
        $_aliasNameGenerator(db.practiceAttempts.groupId, db.practiceGroups.id),
      );

  $$PracticeGroupsTableProcessedTableManager? get groupId {
    final $_column = $_itemColumn<String>('group_id');
    if ($_column == null) return null;
    final manager = $$PracticeGroupsTableTableManager(
      $_db,
      $_db.practiceGroups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PracticeAttemptsTableFilterComposer
    extends Composer<_$PracticeDatabase, $PracticeAttemptsTable> {
  $$PracticeAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PracticeMode, PracticeMode, String> get mode =>
      $composableBuilder(
        column: $table.mode,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get game => $composableBuilder(
    column: $table.game,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PracticeItemsTableFilterComposer get itemId {
    final $$PracticeItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.practiceItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeItemsTableFilterComposer(
            $db: $db,
            $table: $db.practiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PracticeQuestionsTableFilterComposer get questionId {
    final $$PracticeQuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.practiceQuestions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeQuestionsTableFilterComposer(
            $db: $db,
            $table: $db.practiceQuestions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PracticeGroupsTableFilterComposer get groupId {
    final $$PracticeGroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.practiceGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeGroupsTableFilterComposer(
            $db: $db,
            $table: $db.practiceGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeAttemptsTableOrderingComposer
    extends Composer<_$PracticeDatabase, $PracticeAttemptsTable> {
  $$PracticeAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get game => $composableBuilder(
    column: $table.game,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PracticeItemsTableOrderingComposer get itemId {
    final $$PracticeItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.practiceItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeItemsTableOrderingComposer(
            $db: $db,
            $table: $db.practiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PracticeQuestionsTableOrderingComposer get questionId {
    final $$PracticeQuestionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.questionId,
      referencedTable: $db.practiceQuestions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeQuestionsTableOrderingComposer(
            $db: $db,
            $table: $db.practiceQuestions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PracticeGroupsTableOrderingComposer get groupId {
    final $$PracticeGroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.practiceGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeGroupsTableOrderingComposer(
            $db: $db,
            $table: $db.practiceGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeAttemptsTableAnnotationComposer
    extends Composer<_$PracticeDatabase, $PracticeAttemptsTable> {
  $$PracticeAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PracticeMode, String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get game =>
      $composableBuilder(column: $table.game, builder: (column) => column);

  GeneratedColumn<int> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<bool> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );

  $$PracticeItemsTableAnnotationComposer get itemId {
    final $$PracticeItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.practiceItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PracticeQuestionsTableAnnotationComposer get questionId {
    final $$PracticeQuestionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.questionId,
          referencedTable: $db.practiceQuestions,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$PracticeQuestionsTableAnnotationComposer(
                $db: $db,
                $table: $db.practiceQuestions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$PracticeGroupsTableAnnotationComposer get groupId {
    final $$PracticeGroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.practiceGroups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeGroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceGroups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeAttemptsTableTableManager
    extends
        RootTableManager<
          _$PracticeDatabase,
          $PracticeAttemptsTable,
          PracticeAttempt,
          $$PracticeAttemptsTableFilterComposer,
          $$PracticeAttemptsTableOrderingComposer,
          $$PracticeAttemptsTableAnnotationComposer,
          $$PracticeAttemptsTableCreateCompanionBuilder,
          $$PracticeAttemptsTableUpdateCompanionBuilder,
          (PracticeAttempt, $$PracticeAttemptsTableReferences),
          PracticeAttempt,
          PrefetchHooks Function({bool itemId, bool questionId, bool groupId})
        > {
  $$PracticeAttemptsTableTableManager(
    _$PracticeDatabase db,
    $PracticeAttemptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String?> questionId = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<PracticeMode> mode = const Value.absent(),
                Value<String> game = const Value.absent(),
                Value<int> stage = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<bool> correct = const Value.absent(),
                Value<DateTime> answeredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeAttemptsCompanion(
                id: id,
                changedAt: changedAt,
                itemId: itemId,
                questionId: questionId,
                groupId: groupId,
                mode: mode,
                game: game,
                stage: stage,
                answer: answer,
                correct: correct,
                answeredAt: answeredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                required String itemId,
                Value<String?> questionId = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                required PracticeMode mode,
                required String game,
                required int stage,
                Value<String> answer = const Value.absent(),
                required bool correct,
                Value<DateTime> answeredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeAttemptsCompanion.insert(
                id: id,
                changedAt: changedAt,
                itemId: itemId,
                questionId: questionId,
                groupId: groupId,
                mode: mode,
                game: game,
                stage: stage,
                answer: answer,
                correct: correct,
                answeredAt: answeredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeAttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({itemId = false, questionId = false, groupId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (itemId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.itemId,
                                    referencedTable:
                                        $$PracticeAttemptsTableReferences
                                            ._itemIdTable(db),
                                    referencedColumn:
                                        $$PracticeAttemptsTableReferences
                                            ._itemIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (questionId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.questionId,
                                    referencedTable:
                                        $$PracticeAttemptsTableReferences
                                            ._questionIdTable(db),
                                    referencedColumn:
                                        $$PracticeAttemptsTableReferences
                                            ._questionIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (groupId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.groupId,
                                    referencedTable:
                                        $$PracticeAttemptsTableReferences
                                            ._groupIdTable(db),
                                    referencedColumn:
                                        $$PracticeAttemptsTableReferences
                                            ._groupIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$PracticeAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$PracticeDatabase,
      $PracticeAttemptsTable,
      PracticeAttempt,
      $$PracticeAttemptsTableFilterComposer,
      $$PracticeAttemptsTableOrderingComposer,
      $$PracticeAttemptsTableAnnotationComposer,
      $$PracticeAttemptsTableCreateCompanionBuilder,
      $$PracticeAttemptsTableUpdateCompanionBuilder,
      (PracticeAttempt, $$PracticeAttemptsTableReferences),
      PracticeAttempt,
      PrefetchHooks Function({bool itemId, bool questionId, bool groupId})
    >;
typedef $$PracticeRulesTableCreateCompanionBuilder =
    PracticeRulesCompanion Function({
      Value<String> id,
      Value<DateTime> changedAt,
      required String language,
      required String ruleId,
      Value<String> ruleName,
      required String slot,
      Value<String> needs,
      Value<String> starts,
      Value<String> fixedAnswer,
      Value<int> rowid,
    });
typedef $$PracticeRulesTableUpdateCompanionBuilder =
    PracticeRulesCompanion Function({
      Value<String> id,
      Value<DateTime> changedAt,
      Value<String> language,
      Value<String> ruleId,
      Value<String> ruleName,
      Value<String> slot,
      Value<String> needs,
      Value<String> starts,
      Value<String> fixedAnswer,
      Value<int> rowid,
    });

class $$PracticeRulesTableFilterComposer
    extends Composer<_$PracticeDatabase, $PracticeRulesTable> {
  $$PracticeRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleName => $composableBuilder(
    column: $table.ruleName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get needs => $composableBuilder(
    column: $table.needs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get starts => $composableBuilder(
    column: $table.starts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fixedAnswer => $composableBuilder(
    column: $table.fixedAnswer,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PracticeRulesTableOrderingComposer
    extends Composer<_$PracticeDatabase, $PracticeRulesTable> {
  $$PracticeRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleName => $composableBuilder(
    column: $table.ruleName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get needs => $composableBuilder(
    column: $table.needs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get starts => $composableBuilder(
    column: $table.starts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fixedAnswer => $composableBuilder(
    column: $table.fixedAnswer,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PracticeRulesTableAnnotationComposer
    extends Composer<_$PracticeDatabase, $PracticeRulesTable> {
  $$PracticeRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get ruleId =>
      $composableBuilder(column: $table.ruleId, builder: (column) => column);

  GeneratedColumn<String> get ruleName =>
      $composableBuilder(column: $table.ruleName, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get needs =>
      $composableBuilder(column: $table.needs, builder: (column) => column);

  GeneratedColumn<String> get starts =>
      $composableBuilder(column: $table.starts, builder: (column) => column);

  GeneratedColumn<String> get fixedAnswer => $composableBuilder(
    column: $table.fixedAnswer,
    builder: (column) => column,
  );
}

class $$PracticeRulesTableTableManager
    extends
        RootTableManager<
          _$PracticeDatabase,
          $PracticeRulesTable,
          PracticeRuleSlot,
          $$PracticeRulesTableFilterComposer,
          $$PracticeRulesTableOrderingComposer,
          $$PracticeRulesTableAnnotationComposer,
          $$PracticeRulesTableCreateCompanionBuilder,
          $$PracticeRulesTableUpdateCompanionBuilder,
          (
            PracticeRuleSlot,
            BaseReferences<
              _$PracticeDatabase,
              $PracticeRulesTable,
              PracticeRuleSlot
            >,
          ),
          PracticeRuleSlot,
          PrefetchHooks Function()
        > {
  $$PracticeRulesTableTableManager(
    _$PracticeDatabase db,
    $PracticeRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<String> language = const Value.absent(),
                Value<String> ruleId = const Value.absent(),
                Value<String> ruleName = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<String> needs = const Value.absent(),
                Value<String> starts = const Value.absent(),
                Value<String> fixedAnswer = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeRulesCompanion(
                id: id,
                changedAt: changedAt,
                language: language,
                ruleId: ruleId,
                ruleName: ruleName,
                slot: slot,
                needs: needs,
                starts: starts,
                fixedAnswer: fixedAnswer,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                required String language,
                required String ruleId,
                Value<String> ruleName = const Value.absent(),
                required String slot,
                Value<String> needs = const Value.absent(),
                Value<String> starts = const Value.absent(),
                Value<String> fixedAnswer = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PracticeRulesCompanion.insert(
                id: id,
                changedAt: changedAt,
                language: language,
                ruleId: ruleId,
                ruleName: ruleName,
                slot: slot,
                needs: needs,
                starts: starts,
                fixedAnswer: fixedAnswer,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PracticeRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$PracticeDatabase,
      $PracticeRulesTable,
      PracticeRuleSlot,
      $$PracticeRulesTableFilterComposer,
      $$PracticeRulesTableOrderingComposer,
      $$PracticeRulesTableAnnotationComposer,
      $$PracticeRulesTableCreateCompanionBuilder,
      $$PracticeRulesTableUpdateCompanionBuilder,
      (
        PracticeRuleSlot,
        BaseReferences<
          _$PracticeDatabase,
          $PracticeRulesTable,
          PracticeRuleSlot
        >,
      ),
      PracticeRuleSlot,
      PrefetchHooks Function()
    >;

class $PracticeDatabaseManager {
  final _$PracticeDatabase _db;
  $PracticeDatabaseManager(this._db);
  $$PracticeItemsTableTableManager get practiceItems =>
      $$PracticeItemsTableTableManager(_db, _db.practiceItems);
  $$PracticeQuestionsTableTableManager get practiceQuestions =>
      $$PracticeQuestionsTableTableManager(_db, _db.practiceQuestions);
  $$PracticeGroupsTableTableManager get practiceGroups =>
      $$PracticeGroupsTableTableManager(_db, _db.practiceGroups);
  $$PracticeGroupItemsTableTableManager get practiceGroupItems =>
      $$PracticeGroupItemsTableTableManager(_db, _db.practiceGroupItems);
  $$PracticeAttemptsTableTableManager get practiceAttempts =>
      $$PracticeAttemptsTableTableManager(_db, _db.practiceAttempts);
  $$PracticeRulesTableTableManager get practiceRules =>
      $$PracticeRulesTableTableManager(_db, _db.practiceRules);
}
