import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/app/app_config.dart';

void main() {
  test('default config reads the OpenAI models from environment', () {
    final config = AppConfig.fromEnvironment();

    expect(config.openAiCorrectionModel, 'gpt-5.5');
    // Falls back to the correction model when OPENAI_WALKTHROUGH_MODEL is unset.
    expect(config.openAiWalkthroughModel, 'gpt-5.5');
  });

  group('the key file', () {
    test('a bare key on its own line', () {
      expect(AppConfig.parseKeyFile('sk-test-123\n'), 'sk-test-123');
    });

    test('a copy of .env, with comments and quotes', () {
      expect(
        AppConfig.parseKeyFile('# my key\nOPENAI_API_KEY="sk-test-456"\n'),
        'sk-test-456',
      );
    });

    test('an empty .env line gives no key', () {
      expect(AppConfig.parseKeyFile('OPENAI_API_KEY=\n'), '');
      expect(AppConfig.parseKeyFile(''), '');
    });

    test('load reads the key file when the build gave none', () async {
      final config = await AppConfig.load(
        bundle: _FakeBundle({AppConfig.keyFileAsset: 'sk-from-file'}),
      );
      expect(config.openAiApiKey, 'sk-from-file');
      expect(config.openAiCorrectionModel, 'gpt-5.5');
    });

    test('load carries on with no key when there is no key file', () async {
      final config = await AppConfig.load(bundle: _FakeBundle({}));
      expect(config.openAiApiKey, '');
    });
  });
}

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.files);

  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    final text = files[key];
    if (text == null) {
      throw Exception('Unable to load asset: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(text.codeUnits));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final text = files[key];
    if (text == null) {
      throw Exception('Unable to load asset: $key');
    }
    return text;
  }
}
