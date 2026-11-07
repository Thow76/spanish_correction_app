// Where the test programs get the OpenAI key from, in this order:
//   1. OPENAI_API_KEY in the environment (your terminal);
//   2. a `.env` file in the project folder, with a line
//      OPENAI_API_KEY=sk-...  (copy `.env.example`; `.env` is not committed);
//   3. whatever the app was built with (`--dart-define-from-file=.env`).
//
// The key is no longer written in lib/app/app_config.dart, because GitHub
// refuses any push that contains one.

import 'dart:io';

import 'package:spanish_correction_app/app/app_config.dart';

/// Reads `KEY=VALUE` lines from a `.env` file. Blank lines and lines
/// starting with `#` are ignored; surrounding quotes are stripped.
Map<String, String> parseDotenv(String contents) {
  final values = <String, String>{};
  for (final rawLine in contents.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final key = line.substring(0, eq).trim();
    var value = line.substring(eq + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    values[key] = value;
  }
  return values;
}

/// The OpenAI key for a live test run, or an empty string if none is set.
String openAiApiKeyFor(
  Map<String, String> environment, {
  String dotenvPath = '.env',
}) {
  final fromEnvironment = environment['OPENAI_API_KEY']?.trim() ?? '';
  if (fromEnvironment.isNotEmpty) return fromEnvironment;

  final file = File(dotenvPath);
  if (file.existsSync()) {
    final fromFile = parseDotenv(file.readAsStringSync())['OPENAI_API_KEY'];
    if (fromFile != null && fromFile.trim().isNotEmpty) {
      return fromFile.trim();
    }
  }

  return AppConfig.fromEnvironment().openAiApiKey.trim();
}

/// The message a live test fails with when no key can be found.
const String noApiKeyMessage =
    'No API key found. Set OPENAI_API_KEY in your terminal, or put '
    'OPENAI_API_KEY=sk-... in a .env file in the project folder '
    '(see .env.example).';
