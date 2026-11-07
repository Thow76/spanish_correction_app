import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'openai_key.dart';

void main() {
  group('the OpenAI key for live runs', () {
    test('parses a .env file, ignoring comments and quotes', () {
      final values = parseDotenv(
        '# comment\n\nOPENAI_API_KEY="sk-test"\nOTHER=\'x\'\nBAD LINE\n',
      );
      expect(values, {'OPENAI_API_KEY': 'sk-test', 'OTHER': 'x'});
    });

    test('the terminal wins over the .env file', () async {
      final dir = await Directory.systemTemp.createTemp('dotenv');
      final path = '${dir.path}/.env';
      File(path).writeAsStringSync('OPENAI_API_KEY=sk-from-file\n');
      try {
        expect(
          openAiApiKeyFor({'OPENAI_API_KEY': 'sk-from-terminal'},
              dotenvPath: path),
          'sk-from-terminal',
        );
        expect(openAiApiKeyFor({}, dotenvPath: path), 'sk-from-file');
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('with no terminal key and no file, falls back to the build', () {
      expect(openAiApiKeyFor({}, dotenvPath: '/nowhere/.env'), '');
    });
  });
}
