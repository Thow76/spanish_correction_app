enum Language {
  spanish,
  portuguese;

  String toJson() => switch (this) {
    Language.spanish => 'spanish',
    Language.portuguese => 'portuguese',
  };

  static Language fromJson(String? value) => switch (value) {
    'portuguese' => Language.portuguese,
    _ => Language.spanish,
  };
}
