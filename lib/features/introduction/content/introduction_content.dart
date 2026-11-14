import '../../../core/enums/language.dart';
import '../../corrections/domain/error_category.dart';
import 'friendly_opener.dart';
import 'interest.dart';
import 'interest_question.dart';
import 'introduction_step_kind.dart';
import 'recommendation_item.dart';
import 'show_me_demo.dart';

/// The words of the introduction, kept as data (build plan tasks 1.1 and
/// 1.1b; decisions A1, A2 and A3).
///
/// Everything the introduction says to the learner lives in this file:
///
/// * [interests]: the chips the learner taps first, interests only, each
///   with an English, Spanish and Portuguese label (decisions A2, A3);
/// * [friendlyOpeners]: the small shared set of everyday questions that open
///   "Try it", answered by typing (decision A3);
/// * [interestQuestions]: at least one question about each interest, for the
///   "Something you're into" step, answered by speaking (decision A3);
/// * [recommendations]: one recommendation item per interest, for the
///   "A recommendation" card (decision A3);
/// * [demos]: the "Show me" material per interest: a question, a sample
///   answer with a couple of typical mistakes, and its pre-written feedback
///   (decision A3);
/// * [typingHint] and [speakingHint]: the small English hints under the two
///   answered steps;
/// * the three step labels, in [IntroductionStepKind];
/// * [endScreenLine]: the closing line above "See suggestions" and "Not now".
///
/// The content here is placeholder content, enough to build and use slice 1.
/// Andrew replaces it with his own by editing the lists below; nothing else
/// has to change. In slice 1 the introduction runs for Spanish only (decision
/// F1), so the questions, recommendations and demos are Spanish; Portuguese
/// content is added later as more entries with [Language.portuguese].
class IntroductionContent {
  const IntroductionContent._();

  /// How many chips the learner picks, at least (decision A3).
  static const int minimumChips = 1;

  /// How many chips the learner picks, at most (decision A3).
  static const int maximumChips = 5;

  /// Whether the introduction has enough content to run for [language]: at
  /// least one opener, and at least one interest with a question, a
  /// recommendation and a demo.
  ///
  /// Slice 1: Spanish only. A learner who picks Portuguese goes straight to
  /// today's app (decision F1).
  static bool hasContentFor(Language language) =>
      friendlyOpenersFor(language).isNotEmpty &&
      endScreenLineFor(language) != null &&
      interests.any((interest) => hasContentForInterest(interest.id, language));

  /// Whether [interestId] has everything the introduction needs in
  /// [language]: a question, a recommendation and a demo.
  static bool hasContentForInterest(String interestId, Language language) =>
      interestQuestionsForInterest(interestId, language).isNotEmpty &&
      recommendationsForInterest(interestId, language).isNotEmpty &&
      demoForInterest(interestId, language) != null;

  // ---------------------------------------------------------------------------
  // Interests
  // ---------------------------------------------------------------------------

  /// The interests shown as chips, in the order they appear on screen.
  ///
  /// Interests only (decision A3): Andrew declined everyday-life chips such
  /// as work and family, because the partner asks everyday questions anyway.
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
  // Hints and the end screen
  // ---------------------------------------------------------------------------

  /// The small English hint under the friendly opener, which is typed.
  static const String typingHint =
      'Type a short answer in the box, then send it.';

  /// The small English hint under the interest question, which is spoken.
  static const String speakingHint =
      'Tap the microphone, say your answer, then tap it again to stop.';

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

  // ---------------------------------------------------------------------------
  // Friendly openers
  // ---------------------------------------------------------------------------

  /// The small shared set of everyday questions that open "Try it". Not
  /// drawn from the chips; the same set for everyone.
  static const List<FriendlyOpener> friendlyOpeners = [
    FriendlyOpener(
      id: 'opener-how-are-you',
      language: Language.spanish,
      text: '¿Qué tal estás hoy?',
    ),
    FriendlyOpener(
      id: 'opener-your-week',
      language: Language.spanish,
      text: '¿Cómo te ha ido la semana hasta ahora?',
    ),
    FriendlyOpener(
      id: 'opener-weekend',
      language: Language.spanish,
      text: '¿Qué planes tienes para el fin de semana?',
    ),
  ];

  /// The openers written for [language], in file order.
  static List<FriendlyOpener> friendlyOpenersFor(Language language) =>
      friendlyOpeners
          .where((opener) => opener.language == language)
          .toList(growable: false);

  /// The opener with [id], or null if there is none.
  static FriendlyOpener? friendlyOpenerById(String id) {
    for (final opener in friendlyOpeners) {
      if (opener.id == id) {
        return opener;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Interest questions ("Something you're into")
  // ---------------------------------------------------------------------------

  /// At least one question about each interest, spoken.
  static const List<InterestQuestion> interestQuestions = [
    InterestQuestion(
      id: 'travel-question-1',
      interestId: 'travel',
      language: Language.spanish,
      text:
          '¿Cuál es el mejor viaje que has hecho hasta ahora? ¿Qué lo hizo '
          'especial?',
    ),
    InterestQuestion(
      id: 'food-question-1',
      interestId: 'food',
      language: Language.spanish,
      text: '¿Qué plato te sale mejor cuando cocinas? ¿Cómo lo preparas?',
    ),
    InterestQuestion(
      id: 'music-question-1',
      interestId: 'music',
      language: Language.spanish,
      text: '¿Qué música escuchas normalmente, y en qué momentos del día?',
    ),
    InterestQuestion(
      id: 'films-question-1',
      interestId: 'films',
      language: Language.spanish,
      text: '¿Qué película o serie has visto hace poco? ¿Me la recomendarías?',
    ),
    InterestQuestion(
      id: 'books-question-1',
      interestId: 'books',
      language: Language.spanish,
      text:
          '¿Qué estás leyendo ahora mismo, o cuál fue el último libro que '
          'terminaste?',
    ),
    InterestQuestion(
      id: 'sport-question-1',
      interestId: 'sport',
      language: Language.spanish,
      text: '¿Haces algún deporte, o prefieres verlo? Cuéntame un poco.',
    ),
    InterestQuestion(
      id: 'nature-question-1',
      interestId: 'nature',
      language: Language.spanish,
      text: '¿Cuál es tu lugar favorito al aire libre? ¿Qué sueles hacer allí?',
    ),
    InterestQuestion(
      id: 'technology-question-1',
      interestId: 'technology',
      language: Language.spanish,
      text: '¿Qué aplicación o aparato usas más cada día? ¿Para qué lo usas?',
    ),
    InterestQuestion(
      id: 'history-question-1',
      interestId: 'history',
      language: Language.spanish,
      text: '¿Qué época de la historia te parece más interesante, y por qué?',
    ),
    InterestQuestion(
      id: 'art-question-1',
      interestId: 'art',
      language: Language.spanish,
      text:
          '¿Qué obra de arte, edificio o diseño te gusta especialmente? '
          '¿Qué tiene de especial?',
    ),
  ];

  /// The interest questions written for [language], in file order.
  static List<InterestQuestion> interestQuestionsFor(Language language) =>
      interestQuestions
          .where((question) => question.language == language)
          .toList(growable: false);

  /// The questions about [interestId] in [language], in file order.
  static List<InterestQuestion> interestQuestionsForInterest(
    String interestId,
    Language language,
  ) => interestQuestionsFor(
    language,
  ).where((question) => question.interestId == interestId).toList();

  /// The interest question with [id], or null if there is none.
  static InterestQuestion? interestQuestionById(String id) {
    for (final question in interestQuestions) {
      if (question.id == id) {
        return question;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Recommendations
  // ---------------------------------------------------------------------------

  /// One recommendation per interest.
  ///
  /// Placeholders: stable public pages that open from the UK, mostly Spanish
  /// Wikipedia articles, with one podcast site. None has a thumbnail yet;
  /// Andrew's own items can add one with [RecommendationItem.thumbnailUrl].
  static const List<RecommendationItem> recommendations = [
    RecommendationItem(
      id: 'travel-recommendation-1',
      interestId: 'travel',
      language: Language.spanish,
      title: 'Radio Ambulante: crónicas de América Latina en audio',
      url: 'https://radioambulante.org/',
      source: 'Radio Ambulante',
      type: RecommendationType.other,
    ),
    RecommendationItem(
      id: 'food-recommendation-1',
      interestId: 'food',
      language: Language.spanish,
      title: 'La paella: historia y variantes de un plato valenciano',
      url: 'https://es.wikipedia.org/wiki/Paella',
      source: 'Wikipedia en español',
      type: RecommendationType.article,
    ),
    RecommendationItem(
      id: 'music-recommendation-1',
      interestId: 'music',
      language: Language.spanish,
      title: 'El flamenco: cante, toque y baile',
      url: 'https://es.wikipedia.org/wiki/Flamenco',
      source: 'Wikipedia en español',
      type: RecommendationType.article,
    ),
    RecommendationItem(
      id: 'films-recommendation-1',
      interestId: 'films',
      language: Language.spanish,
      title: 'El laberinto del fauno, de Guillermo del Toro',
      url: 'https://es.wikipedia.org/wiki/El_laberinto_del_fauno',
      source: 'Wikipedia en español',
      type: RecommendationType.article,
    ),
    RecommendationItem(
      id: 'books-recommendation-1',
      interestId: 'books',
      language: Language.spanish,
      title: 'Cien años de soledad, de Gabriel García Márquez',
      url: 'https://es.wikipedia.org/wiki/Cien_a%C3%B1os_de_soledad',
      source: 'Wikipedia en español',
      type: RecommendationType.article,
    ),
    RecommendationItem(
      id: 'sport-recommendation-1',
      interestId: 'sport',
      language: Language.spanish,
      title: 'La Vuelta a España: la gran carrera ciclista de agosto',
      url: 'https://es.wikipedia.org/wiki/Vuelta_a_Espa%C3%B1a',
      source: 'Wikipedia en español',
      type: RecommendationType.article,
    ),
    RecommendationItem(
      id: 'nature-recommendation-1',
      interestId: 'nature',
      language: Language.spanish,
      title: 'El parque nacional de Doñana',
      url: 'https://es.wikipedia.org/wiki/Parque_nacional_de_Do%C3%B1ana',
      source: 'Wikipedia en español',
      type: RecommendationType.article,
    ),
    RecommendationItem(
      id: 'technology-recommendation-1',
      interestId: 'technology',
      language: Language.spanish,
      title: 'La inteligencia artificial, explicada',
      url: 'https://es.wikipedia.org/wiki/Inteligencia_artificial',
      source: 'Wikipedia en español',
      type: RecommendationType.article,
    ),
    RecommendationItem(
      id: 'history-recommendation-1',
      interestId: 'history',
      language: Language.spanish,
      title: 'Al-Ándalus: ocho siglos de historia en la península',
      url: 'https://es.wikipedia.org/wiki/Al-%C3%81ndalus',
      source: 'Wikipedia en español',
      type: RecommendationType.article,
    ),
    RecommendationItem(
      id: 'art-recommendation-1',
      interestId: 'art',
      language: Language.spanish,
      title: 'El Museo del Prado y su colección',
      url: 'https://es.wikipedia.org/wiki/Museo_del_Prado',
      source: 'Wikipedia en español',
      type: RecommendationType.article,
    ),
  ];

  /// The recommendations written for [language], in file order.
  static List<RecommendationItem> recommendationsFor(Language language) =>
      recommendations
          .where((item) => item.language == language)
          .toList(growable: false);

  /// The recommendations for [interestId] in [language], in file order.
  static List<RecommendationItem> recommendationsForInterest(
    String interestId,
    Language language,
  ) => recommendationsFor(
    language,
  ).where((item) => item.interestId == interestId).toList();

  /// The recommendation with [id], or null if there is none.
  static RecommendationItem? recommendationById(String id) {
    for (final item in recommendations) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // "Show me" demos
  // ---------------------------------------------------------------------------

  /// The "Show me" material, one demo per interest.
  ///
  /// Each sample answer carries two typical mistakes of an English-speaking
  /// learner, and the points use today's categories (Grammar, Spelling, Word
  /// Choice, Natural Language) until slice 2.
  static const List<ShowMeDemo> demos = [
    ShowMeDemo(
      id: 'travel-demo',
      interestId: 'travel',
      language: Language.spanish,
      question: '¿Adónde te gustaría viajar el año que viene?',
      sampleAnswer:
          'El año que viene quiero viajar a Perú con mi hermana. Estoy muy '
          'excitado porque nunca he estado en Sudamérica. Todavía tenemos que '
          'hacer una decisión sobre las fechas, pero seguro que va a ser '
          'inolvidable.',
      points: [
        DemoFeedbackPoint(
          originalPhrase: 'excitado',
          correctedPhrase: 'emocionado',
          category: ErrorCategory.wordChoice,
          shortExplanation:
              'In Spanish "excitado" usually means physically aroused; the '
              'word for excited about something is "emocionado".',
        ),
        DemoFeedbackPoint(
          originalPhrase: 'hacer una decisión',
          correctedPhrase: 'tomar una decisión',
          category: ErrorCategory.naturalLanguage,
          shortExplanation:
              'Spanish takes decisions rather than making them: "tomar una '
              'decisión".',
        ),
      ],
    ),
    ShowMeDemo(
      id: 'food-demo',
      interestId: 'food',
      language: Language.spanish,
      question: '¿Qué plato te sale mejor cuando cocinas?',
      sampleAnswer:
          'Me sale muy bien la lasaña. La hago casi cada domingo porque me '
          'gusta mucho los platos de pasta. Al principio me quedaba un poco '
          'seca, pero ahora, después de mucha practica, queda perfecta.',
      points: [
        DemoFeedbackPoint(
          originalPhrase: 'me gusta mucho los platos',
          correctedPhrase: 'me gustan mucho los platos',
          category: ErrorCategory.grammar,
          shortExplanation:
              '"Gustar" agrees with the thing liked: "los platos" is plural, '
              'so the verb is "gustan".',
        ),
        DemoFeedbackPoint(
          originalPhrase: 'practica',
          correctedPhrase: 'práctica',
          category: ErrorCategory.spelling,
          shortExplanation:
              'The noun carries a written accent, "práctica"; without it the '
              'word reads as the verb form "practica".',
        ),
      ],
    ),
    ShowMeDemo(
      id: 'music-demo',
      interestId: 'music',
      language: Language.spanish,
      question: '¿Qué música escuchas normalmente?',
      sampleAnswer:
          'Escucho de todo, pero sobre todo pop en español. Cuando trabajo '
          'pongo música tranquila para me concentrar. Hace poco descubrí un '
          'grupo argentino que me encanta: sus canciones son muy pegajosas y '
          'no puedo dejar de cantarlas.',
      points: [
        DemoFeedbackPoint(
          originalPhrase: 'para me concentrar',
          correctedPhrase: 'para concentrarme',
          category: ErrorCategory.grammar,
          shortExplanation:
              'With an infinitive the pronoun goes on the end of the verb: '
              '"concentrarme".',
        ),
        DemoFeedbackPoint(
          originalPhrase: 'pegajosas',
          correctedPhrase: 'pegadizas',
          category: ErrorCategory.wordChoice,
          shortExplanation:
              '"Pegajoso" is sticky to the touch; a tune that stays in your '
              'head is "pegadizo".',
        ),
      ],
    ),
    ShowMeDemo(
      id: 'films-demo',
      interestId: 'films',
      language: Language.spanish,
      question: '¿Qué película o serie has visto hace poco?',
      sampleAnswer:
          'La semana pasada terminé una serie española que se llama La casa '
          'de papel. Al principio no me enganchó, pero despues de dos '
          'episodios no podía parar. La trama es un poco larga, pero en el '
          'fin vale la pena.',
      points: [
        DemoFeedbackPoint(
          originalPhrase: 'despues',
          correctedPhrase: 'después',
          category: ErrorCategory.spelling,
          shortExplanation:
              '"Después" carries a written accent on the last syllable.',
        ),
        DemoFeedbackPoint(
          originalPhrase: 'en el fin',
          correctedPhrase: 'al final',
          category: ErrorCategory.naturalLanguage,
          shortExplanation:
              '"En el fin" is a word-for-word "in the end"; Spanish says '
              '"al final".',
        ),
      ],
    ),
    ShowMeDemo(
      id: 'books-demo',
      interestId: 'books',
      language: Language.spanish,
      question: '¿Qué estás leyendo ahora mismo?',
      sampleAnswer:
          'Ahora mismo estoy leyendo una novela de Isabel Allende. Es la '
          'primera vez que leo un libro entero en español, así que voy '
          'despacio. Las personajes son muy interesantes, y aunque hay '
          'palabras que no conozco, realizo que es mejor seguir leyendo sin '
          'parar a buscarlas todas.',
      points: [
        DemoFeedbackPoint(
          originalPhrase: 'Las personajes',
          correctedPhrase: 'Los personajes',
          category: ErrorCategory.grammar,
          shortExplanation:
              '"Personaje" is masculine even for a female character: "los '
              'personajes".',
        ),
        DemoFeedbackPoint(
          originalPhrase: 'realizo que',
          correctedPhrase: 'me doy cuenta de que',
          category: ErrorCategory.wordChoice,
          shortExplanation:
              '"Realizar" means to carry out. For "realise" in the sense of '
              'noticing, Spanish says "darse cuenta".',
        ),
      ],
    ),
    ShowMeDemo(
      id: 'sport-demo',
      interestId: 'sport',
      language: Language.spanish,
      question: '¿Haces algún deporte, o prefieres verlo?',
      sampleAnswer:
          'Juego al fútbol con unos amigos todos los jueves por la noche. No '
          'somos muy buenos, pero nos divertimos mucho. También me gusta '
          'correr, aunque en invierno es dificil salir cuando hace frío. Y '
          'soporto al Betis desde que era niño: voy al estadio siempre que '
          'puedo.',
      points: [
        DemoFeedbackPoint(
          originalPhrase: 'dificil',
          correctedPhrase: 'difícil',
          category: ErrorCategory.spelling,
          shortExplanation:
              '"Difícil" carries a written accent on the middle syllable.',
        ),
        DemoFeedbackPoint(
          originalPhrase: 'soporto al Betis',
          correctedPhrase: 'soy del Betis',
          category: ErrorCategory.wordChoice,
          shortExplanation:
              '"Soportar" means to put up with. For supporting a team, Spanish '
              'says "ser de" or "seguir a".',
        ),
      ],
    ),
    ShowMeDemo(
      id: 'nature-demo',
      interestId: 'nature',
      language: Language.spanish,
      question: '¿Cuál es tu lugar favorito al aire libre?',
      sampleAnswer:
          'Mi lugar favorito es un bosque que está a diez minutos de mi casa. '
          'Voy allí casi todos los fines de semana a pasear con mi perro. Hay '
          'un rio pequeño y, en otoño, las hojas cambian de color. Es un '
          'sitio muy pacífico y me ayuda a desconectar.',
      points: [
        DemoFeedbackPoint(
          originalPhrase: 'rio',
          correctedPhrase: 'río',
          category: ErrorCategory.spelling,
          shortExplanation:
              '"Río" carries a written accent; without it, "rio" is a form of '
              'the verb "reír".',
        ),
        DemoFeedbackPoint(
          originalPhrase: 'pacífico',
          correctedPhrase: 'tranquilo',
          category: ErrorCategory.wordChoice,
          shortExplanation:
              '"Pacífico" describes a person or a country that avoids '
              'conflict; a quiet place is "tranquilo".',
        ),
      ],
    ),
    ShowMeDemo(
      id: 'technology-demo',
      interestId: 'technology',
      language: Language.spanish,
      question: '¿Qué aplicación o aparato usas más cada día?',
      sampleAnswer:
          'Uso el móvil todo el tiempo, sobre todo para mensajes y para leer '
          'las noticias. Creo que la gente usan el teléfono demasiado, yo '
          'incluido. En el largo plazo me gustaría pasar menos horas delante '
          'de la pantalla.',
      points: [
        DemoFeedbackPoint(
          originalPhrase: 'la gente usan',
          correctedPhrase: 'la gente usa',
          category: ErrorCategory.grammar,
          shortExplanation:
              '"La gente" is singular in Spanish, so the verb is "usa".',
        ),
        DemoFeedbackPoint(
          originalPhrase: 'En el largo plazo',
          correctedPhrase: 'A largo plazo',
          category: ErrorCategory.naturalLanguage,
          shortExplanation:
              'The set phrase is "a largo plazo", with "a" and no article.',
        ),
      ],
    ),
    ShowMeDemo(
      id: 'history-demo',
      interestId: 'history',
      language: Language.spanish,
      question: '¿Qué época de la historia te parece más interesante?',
      sampleAnswer:
          'Soy muy interesado en la época de Al-Ándalus, cuando musulmanes, '
          'cristianos y judíos convivieron durante siglos en la península. El '
          'año pasado visité la Alhambra, que es en Granada, y me pareció '
          'impresionante.',
      points: [
        DemoFeedbackPoint(
          originalPhrase: 'Soy muy interesado en',
          correctedPhrase: 'Me interesa mucho',
          category: ErrorCategory.naturalLanguage,
          shortExplanation:
              'A word-for-word "I am interested in"; Spanish says "me '
              'interesa" or "estoy interesado en".',
        ),
        DemoFeedbackPoint(
          originalPhrase: 'es en Granada',
          correctedPhrase: 'está en Granada',
          category: ErrorCategory.grammar,
          shortExplanation:
              'Where something is takes "estar": "está en Granada".',
        ),
      ],
    ),
    ShowMeDemo(
      id: 'art-demo',
      interestId: 'art',
      language: Language.spanish,
      question: '¿Qué obra de arte, edificio o diseño te gusta especialmente?',
      sampleAnswer:
          'Me encanta la Sagrada Familia de Barcelona. Es un edificio muy '
          'largo y, cuando entras, la luz de las vidrieras te deja sin '
          'palabras. Gaudí era un genio, aunque sé que su estilo no gusta a '
          'todo el mundo. Espero que la terminan pronto.',
      points: [
        DemoFeedbackPoint(
          originalPhrase: 'muy largo',
          correctedPhrase: 'muy grande',
          category: ErrorCategory.wordChoice,
          shortExplanation:
              '"Largo" means long. For "large", Spanish says "grande".',
        ),
        DemoFeedbackPoint(
          originalPhrase: 'la terminan',
          correctedPhrase: 'la terminen',
          category: ErrorCategory.grammar,
          shortExplanation:
              'After "espero que" the verb goes in the subjunctive: '
              '"terminen".',
        ),
      ],
    ),
  ];

  /// The demos written for [language], in file order.
  static List<ShowMeDemo> demosFor(Language language) =>
      demos.where((demo) => demo.language == language).toList(growable: false);

  /// The demo for [interestId] in [language], or null if there is none.
  static ShowMeDemo? demoForInterest(String interestId, Language language) {
    for (final demo in demosFor(language)) {
      if (demo.interestId == interestId) {
        return demo;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Picking from the chosen chips
  // ---------------------------------------------------------------------------

  /// Picks which chosen chip each step of the introduction uses.
  ///
  /// The chips are taken in the order the learner tapped them, ignoring
  /// unknown and repeated ids and any chip with no content in [language]. The
  /// interest question comes from the first chip; the recommendation comes
  /// from the second chip when the learner picked more than one, and from the
  /// same chip when they picked only one (decision A3, task 1.1b); the
  /// "Show me" demo plays on the first chip.
  ///
  /// If no chosen chip has content (for example, the learner tapped nothing),
  /// the chips are taken from [interests] in list order, so the introduction
  /// can still carry on. That fallback is Claude's reading, open to
  /// correction. Returns null only when [language] has no content at all.
  static IntroductionPicks? pickForChips({
    required List<String> chosenInterestIds,
    required Language language,
  }) {
    final usable = <String>[];
    for (final id in chosenInterestIds) {
      if (!usable.contains(id) && hasContentForInterest(id, language)) {
        usable.add(id);
      }
    }
    if (usable.isEmpty) {
      for (final interest in interests) {
        if (hasContentForInterest(interest.id, language)) {
          usable.add(interest.id);
        }
      }
    }
    if (usable.isEmpty) {
      return null;
    }

    final questionInterestId = usable.first;
    final recommendationInterestId = usable.length > 1 ? usable[1] : usable[0];
    return IntroductionPicks(
      language: language,
      questionInterestId: questionInterestId,
      recommendationInterestId: recommendationInterestId,
      demoInterestId: questionInterestId,
    );
  }
}

/// Which chosen chip each step of the introduction uses, from
/// [IntroductionContent.pickForChips], with the content items resolved.
class IntroductionPicks {
  const IntroductionPicks({
    required this.language,
    required this.questionInterestId,
    required this.recommendationInterestId,
    required this.demoInterestId,
  });

  final Language language;

  /// The chip the "Something you're into" question is about.
  final String questionInterestId;

  /// The chip the recommendation card is linked to.
  final String recommendationInterestId;

  /// The chip the "Show me" demo plays on.
  final String demoInterestId;

  /// The first question about [questionInterestId].
  InterestQuestion get interestQuestion =>
      IntroductionContent.interestQuestionsForInterest(
        questionInterestId,
        language,
      ).first;

  /// The first recommendation for [recommendationInterestId].
  RecommendationItem get recommendation =>
      IntroductionContent.recommendationsForInterest(
        recommendationInterestId,
        language,
      ).first;

  /// The demo for [demoInterestId].
  ShowMeDemo get demo =>
      IntroductionContent.demoForInterest(demoInterestId, language)!;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntroductionPicks &&
          other.language == language &&
          other.questionInterestId == questionInterestId &&
          other.recommendationInterestId == recommendationInterestId &&
          other.demoInterestId == demoInterestId;

  @override
  int get hashCode => Object.hash(
    language,
    questionInterestId,
    recommendationInterestId,
    demoInterestId,
  );

  @override
  String toString() =>
      'IntroductionPicks(question: $questionInterestId, recommendation: '
      '$recommendationInterestId, demo: $demoInterestId)';
}
