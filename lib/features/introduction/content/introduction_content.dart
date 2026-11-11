import '../../../core/enums/language.dart';
import 'fuller_question.dart';
import 'interest.dart';
import 'warm_up_question.dart';

/// The words of the introduction, kept as data (build plan task 1.1).
///
/// Everything the introduction says to the learner lives in this file:
///
/// * [interests]: the chips the learner taps, each with an English, Spanish
///   and Portuguese label (decision A2);
/// * [warmUpQuestions]: the two warm-ups that teach the controls, one typed
///   and one spoken, each with a small hint in English (decision A1);
/// * [fullerQuestions]: about three fuller questions per interest, each
///   written to pull a different structure (decision A1);
/// * [endScreenLine]: the closing line above "See suggestions" and "Not now".
///
/// The content here is placeholder content, enough to build and use slice 1.
/// Andrew replaces it with his own by editing the lists below; nothing else
/// has to change. In slice 1 the introduction runs for Spanish only (decision
/// F1), so the questions are Spanish; Portuguese questions are added later as
/// more entries with [Language.portuguese].
class IntroductionContent {
  const IntroductionContent._();

  /// How many fuller questions the introduction asks (decision A1: "about
  /// three").
  static const int fullerQuestionCount = 3;

  /// Whether the introduction has enough content to run for [language].
  ///
  /// Slice 1: Spanish only. A learner who picks Portuguese goes straight to
  /// today's app (decision F1).
  static bool hasContentFor(Language language) =>
      warmUpQuestionsFor(language).isNotEmpty &&
      fullerQuestionsFor(language).isNotEmpty;

  // ---------------------------------------------------------------------------
  // Interests
  // ---------------------------------------------------------------------------

  /// The interests shown as chips, in the order they appear on screen.
  static const List<Interest> interests = [
    Interest(
      id: 'travel',
      english: 'Travel',
      spanish: 'Los viajes',
      portuguese: 'As viagens',
    ),
    Interest(
      id: 'food',
      english: 'Food and cooking',
      spanish: 'La comida y la cocina',
      portuguese: 'A comida e a cozinha',
    ),
    Interest(
      id: 'music',
      english: 'Music',
      spanish: 'La música',
      portuguese: 'A música',
    ),
    Interest(
      id: 'films',
      english: 'Films and series',
      spanish: 'El cine y las series',
      portuguese: 'Filmes e séries',
    ),
    Interest(
      id: 'books',
      english: 'Books and reading',
      spanish: 'Los libros y la lectura',
      portuguese: 'Os livros e a leitura',
    ),
    Interest(
      id: 'sport',
      english: 'Sport',
      spanish: 'El deporte',
      portuguese: 'O esporte',
    ),
    Interest(
      id: 'work',
      english: 'Work',
      spanish: 'El trabajo',
      portuguese: 'O trabalho',
    ),
    Interest(
      id: 'family',
      english: 'Family and friends',
      spanish: 'La familia y los amigos',
      portuguese: 'A família e os amigos',
    ),
    Interest(
      id: 'nature',
      english: 'Nature and the outdoors',
      spanish: 'La naturaleza y el aire libre',
      portuguese: 'A natureza e o ar livre',
    ),
    Interest(
      id: 'technology',
      english: 'Technology',
      spanish: 'La tecnología',
      portuguese: 'A tecnologia',
    ),
    Interest(
      id: 'history',
      english: 'History',
      spanish: 'La historia',
      portuguese: 'A história',
    ),
    Interest(
      id: 'art',
      english: 'Art and design',
      spanish: 'El arte y el diseño',
      portuguese: 'A arte e o design',
    ),
  ];

  /// The interest with [id], or null if there is none. Used by the profile
  /// screen to show the English label for a stored id.
  static Interest? interestById(String id) {
    for (final interest in interests) {
      if (interest.id == id) {
        return interest;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Warm-ups
  // ---------------------------------------------------------------------------

  /// The two warm-up questions, in order: one typed, then one spoken.
  static const List<WarmUpQuestion> warmUpQuestions = [
    WarmUpQuestion(
      id: 'warm-up-typed',
      text: '¿Cómo estás?',
      hint: 'Type a short answer in the box, then send it.',
      input: WarmUpInput.typed,
    ),
    WarmUpQuestion(
      id: 'warm-up-spoken',
      text: '¿De dónde eres?',
      hint: 'Tap the microphone, say your answer, then tap it again to stop.',
      input: WarmUpInput.spoken,
    ),
  ];

  /// The warm-ups for [language]. Spanish only in slice 1.
  static List<WarmUpQuestion> warmUpQuestionsFor(Language language) =>
      switch (language) {
        Language.spanish => warmUpQuestions,
        Language.portuguese => const [],
      };

  // ---------------------------------------------------------------------------
  // Fuller questions
  // ---------------------------------------------------------------------------

  /// Every fuller question, grouped by interest. Each interest has three
  /// questions with three different structures, and neighbouring interests
  /// start on different structures, so three chosen chips usually give three
  /// different structures.
  static const List<FullerQuestion> fullerQuestions = [
    // Travel
    FullerQuestion(
      id: 'travel-1',
      interestId: 'travel',
      language: Language.spanish,
      text:
          'Cuéntame el último viaje que hiciste: adónde fuiste, con quién y '
          'qué fue lo que más te gustó.',
      structure: QuestionStructure.pastNarrative,
    ),
    FullerQuestion(
      id: 'travel-2',
      interestId: 'travel',
      language: Language.spanish,
      text:
          'Si pudieras pasar un mes en cualquier lugar del mundo, ¿adónde '
          'irías y qué harías allí?',
      structure: QuestionStructure.hypothetical,
    ),
    FullerQuestion(
      id: 'travel-3',
      interestId: 'travel',
      language: Language.spanish,
      text:
          '¿Tienes algún viaje pensado para los próximos meses? ¿Qué te '
          'gustaría hacer?',
      structure: QuestionStructure.futurePlans,
    ),

    // Food and cooking
    FullerQuestion(
      id: 'food-1',
      interestId: 'food',
      language: Language.spanish,
      text:
          '¿Qué sueles comer en un día normal? ¿Cocinas tú o prefieres que '
          'cocinen otros?',
      structure: QuestionStructure.presentHabits,
    ),
    FullerQuestion(
      id: 'food-2',
      interestId: 'food',
      language: Language.spanish,
      text:
          'Describe un plato que te encante. ¿En qué se diferencia de lo que '
          'comías de pequeño?',
      structure: QuestionStructure.descriptionAndComparison,
    ),
    FullerQuestion(
      id: 'food-3',
      interestId: 'food',
      language: Language.spanish,
      text:
          'Hay quien dice que comer bien es caro. ¿Qué te parece? ¿Crees que '
          'es verdad?',
      structure: QuestionStructure.opinionAndReason,
    ),

    // Music
    FullerQuestion(
      id: 'music-1',
      interestId: 'music',
      language: Language.spanish,
      text: '¿Qué música escuchas normalmente, y en qué momentos del día?',
      structure: QuestionStructure.presentHabits,
    ),
    FullerQuestion(
      id: 'music-2',
      interestId: 'music',
      language: Language.spanish,
      text: '¿Recuerdas el primer concierto al que fuiste? Cuéntame cómo fue.',
      structure: QuestionStructure.pastNarrative,
    ),
    FullerQuestion(
      id: 'music-3',
      interestId: 'music',
      language: Language.spanish,
      text: '¿Crees que la música de hoy es peor que la de antes? ¿Por qué?',
      structure: QuestionStructure.opinionAndReason,
    ),

    // Films and series
    FullerQuestion(
      id: 'films-1',
      interestId: 'films',
      language: Language.spanish,
      text:
          'Háblame de una película o una serie que hayas visto hace poco. '
          '¿Qué fue lo que más te gustó, y lo que menos?',
      structure: QuestionStructure.descriptionAndComparison,
    ),
    FullerQuestion(
      id: 'films-2',
      interestId: 'films',
      language: Language.spanish,
      text:
          '¿Prefieres ver las películas en versión original o dobladas? '
          '¿Por qué?',
      structure: QuestionStructure.opinionAndReason,
    ),
    FullerQuestion(
      id: 'films-3',
      interestId: 'films',
      language: Language.spanish,
      text:
          'Si pudieras vivir dentro de una película o una serie durante una '
          'semana, ¿cuál elegirías y por qué?',
      structure: QuestionStructure.hypothetical,
    ),

    // Books and reading
    FullerQuestion(
      id: 'books-1',
      interestId: 'books',
      language: Language.spanish,
      text: '¿Qué tipo de libros lees, y cuándo encuentras tiempo para leer?',
      structure: QuestionStructure.presentHabits,
    ),
    FullerQuestion(
      id: 'books-2',
      interestId: 'books',
      language: Language.spanish,
      text:
          'Cuéntame un libro que te marcó cuando eras más joven. ¿De qué '
          'trataba y por qué te gustó tanto?',
      structure: QuestionStructure.pastNarrative,
    ),
    FullerQuestion(
      id: 'books-3',
      interestId: 'books',
      language: Language.spanish,
      text:
          '¿Qué piensas leer próximamente? ¿Hay algún libro que tengas '
          'pendiente desde hace tiempo?',
      structure: QuestionStructure.futurePlans,
    ),

    // Sport
    FullerQuestion(
      id: 'sport-1',
      interestId: 'sport',
      language: Language.spanish,
      text: '¿Haces algún deporte? ¿Con qué frecuencia y con quién?',
      structure: QuestionStructure.presentHabits,
    ),
    FullerQuestion(
      id: 'sport-2',
      interestId: 'sport',
      language: Language.spanish,
      text:
          'Cuéntame un partido o una competición que recuerdes especialmente. '
          '¿Qué pasó?',
      structure: QuestionStructure.pastNarrative,
    ),
    FullerQuestion(
      id: 'sport-3',
      interestId: 'sport',
      language: Language.spanish,
      text:
          'Si tuvieras tiempo y dinero de sobra, ¿qué deporte te gustaría '
          'aprender?',
      structure: QuestionStructure.hypothetical,
    ),

    // Work
    FullerQuestion(
      id: 'work-1',
      interestId: 'work',
      language: Language.spanish,
      text: '¿En qué consiste tu trabajo? Cuéntame cómo es un día normal.',
      structure: QuestionStructure.presentHabits,
    ),
    FullerQuestion(
      id: 'work-2',
      interestId: 'work',
      language: Language.spanish,
      text:
          '¿Cómo llegaste a dedicarte a lo que haces? ¿Fue lo que siempre '
          'quisiste?',
      structure: QuestionStructure.pastNarrative,
    ),
    FullerQuestion(
      id: 'work-3',
      interestId: 'work',
      language: Language.spanish,
      text:
          '¿Crees que es mejor trabajar desde casa o en una oficina? '
          '¿Por qué?',
      structure: QuestionStructure.opinionAndReason,
    ),

    // Family and friends
    FullerQuestion(
      id: 'family-1',
      interestId: 'family',
      language: Language.spanish,
      text:
          'Háblame de alguien de tu familia o de un amigo que sea importante '
          'para ti. ¿Cómo es?',
      structure: QuestionStructure.descriptionAndComparison,
    ),
    FullerQuestion(
      id: 'family-2',
      interestId: 'family',
      language: Language.spanish,
      text: '¿Cómo conociste a tu mejor amigo o amiga? Cuéntame cómo fue.',
      structure: QuestionStructure.pastNarrative,
    ),
    FullerQuestion(
      id: 'family-3',
      interestId: 'family',
      language: Language.spanish,
      text:
          '¿Tienes algún plan con tu familia o tus amigos para las próximas '
          'semanas?',
      structure: QuestionStructure.futurePlans,
    ),

    // Nature and the outdoors
    FullerQuestion(
      id: 'nature-1',
      interestId: 'nature',
      language: Language.spanish,
      text:
          '¿Pasas mucho tiempo al aire libre? ¿Qué sueles hacer cuando sales?',
      structure: QuestionStructure.presentHabits,
    ),
    FullerQuestion(
      id: 'nature-2',
      interestId: 'nature',
      language: Language.spanish,
      text:
          'Describe un lugar al aire libre que te guste mucho. ¿Qué lo hace '
          'especial?',
      structure: QuestionStructure.descriptionAndComparison,
    ),
    FullerQuestion(
      id: 'nature-3',
      interestId: 'nature',
      language: Language.spanish,
      text:
          'Si pudieras vivir en el campo, en la montaña o junto al mar, ¿qué '
          'elegirías y por qué?',
      structure: QuestionStructure.hypothetical,
    ),

    // Technology
    FullerQuestion(
      id: 'technology-1',
      interestId: 'technology',
      language: Language.spanish,
      text:
          '¿Qué aplicaciones o aparatos usas todos los días? ¿Para qué los '
          'usas?',
      structure: QuestionStructure.presentHabits,
    ),
    FullerQuestion(
      id: 'technology-2',
      interestId: 'technology',
      language: Language.spanish,
      text: '¿Crees que pasamos demasiado tiempo con el móvil? ¿Qué te parece?',
      structure: QuestionStructure.opinionAndReason,
    ),
    FullerQuestion(
      id: 'technology-3',
      interestId: 'technology',
      language: Language.spanish,
      text:
          '¿Qué tecnología crees que cambiará más nuestra vida en los '
          'próximos diez años?',
      structure: QuestionStructure.futurePlans,
    ),

    // History
    FullerQuestion(
      id: 'history-1',
      interestId: 'history',
      language: Language.spanish,
      text: '¿Qué época de la historia te parece más interesante? ¿Por qué?',
      structure: QuestionStructure.opinionAndReason,
    ),
    FullerQuestion(
      id: 'history-2',
      interestId: 'history',
      language: Language.spanish,
      text:
          'Si pudieras viajar a cualquier momento del pasado, ¿adónde irías '
          'y a quién te gustaría conocer?',
      structure: QuestionStructure.hypothetical,
    ),
    FullerQuestion(
      id: 'history-3',
      interestId: 'history',
      language: Language.spanish,
      text:
          '¿Cómo empezó tu interés por la historia? ¿Hubo algún libro, '
          'profesor o viaje que lo despertara?',
      structure: QuestionStructure.pastNarrative,
    ),

    // Art and design
    FullerQuestion(
      id: 'art-1',
      interestId: 'art',
      language: Language.spanish,
      text:
          'Describe una obra de arte, un edificio o un diseño que te guste '
          'mucho. ¿Qué tiene de especial?',
      structure: QuestionStructure.descriptionAndComparison,
    ),
    FullerQuestion(
      id: 'art-2',
      interestId: 'art',
      language: Language.spanish,
      text:
          '¿Has visitado alguna exposición o algún museo últimamente? '
          'Cuéntame qué viste.',
      structure: QuestionStructure.pastNarrative,
    ),
    FullerQuestion(
      id: 'art-3',
      interestId: 'art',
      language: Language.spanish,
      text:
          'Si pudieras aprender cualquier arte u oficio, ¿cuál elegirías y '
          'por qué?',
      structure: QuestionStructure.hypothetical,
    ),
  ];

  /// The fuller questions written for [language], in file order.
  static List<FullerQuestion> fullerQuestionsFor(Language language) =>
      fullerQuestions
          .where((question) => question.language == language)
          .toList(growable: false);

  /// The fuller questions for [interestId] in [language], in file order.
  static List<FullerQuestion> fullerQuestionsForInterest(
    String interestId,
    Language language,
  ) => fullerQuestionsFor(
    language,
  ).where((question) => question.interestId == interestId).toList();

  /// Draws the fuller questions to ask from the interests the learner chose.
  ///
  /// It takes turns around the chosen interests, in the order they were
  /// chosen, and from each takes the first question whose structure has not
  /// been used yet (or, failing that, its first remaining question), until
  /// [count] questions are drawn or the interests run out. So one chosen
  /// interest gives its three questions; three chosen interests give one
  /// question each, with different structures wherever the content allows.
  ///
  /// Unknown ids are ignored. If no chosen interest has questions (for
  /// example, the learner tapped nothing), the questions are drawn from every
  /// interest in [interests] order, so the introduction can still carry on.
  /// That fallback is Claude's reading of decision A1, open to correction.
  static List<FullerQuestion> drawFullerQuestions({
    required List<String> chosenInterestIds,
    required Language language,
    int count = fullerQuestionCount,
  }) {
    final queues = <List<FullerQuestion>>[];
    final seen = <String>{};
    for (final id in chosenInterestIds) {
      if (!seen.add(id)) {
        continue;
      }
      final questions = fullerQuestionsForInterest(id, language);
      if (questions.isNotEmpty) {
        queues.add(questions);
      }
    }
    if (queues.isEmpty) {
      for (final interest in interests) {
        final questions = fullerQuestionsForInterest(interest.id, language);
        if (questions.isNotEmpty) {
          queues.add(questions);
        }
      }
    }

    final drawn = <FullerQuestion>[];
    final usedStructures = <QuestionStructure>{};
    while (drawn.length < count && queues.any((queue) => queue.isNotEmpty)) {
      for (final queue in queues) {
        if (drawn.length >= count || queue.isEmpty) {
          continue;
        }
        var index = queue.indexWhere(
          (question) => !usedStructures.contains(question.structure),
        );
        if (index < 0) {
          index = 0;
        }
        final question = queue.removeAt(index);
        usedStructures.add(question.structure);
        drawn.add(question);
      }
    }
    return drawn;
  }

  // ---------------------------------------------------------------------------
  // End screen
  // ---------------------------------------------------------------------------

  /// The closing line on the end screen, above "See suggestions" and
  /// "Not now".
  static const String endScreenLine =
      '¡Gracias! Ya nos conocemos un poco mejor. Si quieres, puedes ver ahora '
      'las sugerencias sobre tus respuestas, o dejarlas para más tarde.';

  /// The closing line for [language]. Spanish only in slice 1.
  static String? endScreenLineFor(Language language) => switch (language) {
    Language.spanish => endScreenLine,
    Language.portuguese => null,
  };
}
