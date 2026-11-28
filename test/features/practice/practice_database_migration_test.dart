// The practice database's layout test (practice track, step P.5; decision
// G3, point 4: "each change to the tables comes with a migration and a
// test").
//
// `drift_schemas/drift_schema_v1.json` is a saved copy of the table layout
// at version 1, and `generated_migrations/` is written from it by a tool
// (see `drift_schemas/README.md`). This test checks that a database made
// new by the app has exactly that layout. When a table changes, the version
// goes up, a new saved copy is added, and a test here upgrades a database
// from each older layout and checks it ends up the same as a new one.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spanish_correction_app/features/practice/data/practice_database.dart';

import 'generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('the newest saved layout is the version the app uses', () async {
    final database = PracticeDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    expect(GeneratedHelper.versions.last, database.schemaVersion);
  });

  test('a database the app makes from nothing has the saved version 1 '
      'layout', () async {
    final database = PracticeDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    // Opens the database, which makes every table, then compares each
    // table, column, key and rule with the saved copy.
    await verifier.migrateAndValidate(database, 1);

    final tables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .map((row) => row.read<String>('name'))
        .get();
    expect(tables, [
      'practice_attempts',
      'practice_group_items',
      'practice_groups',
      'practice_items',
      'practice_questions',
      'practice_rules',
    ]);
  });

  test('a database already at version 1 opens without being changed', () async {
    final connection = await verifier.startAt(1);
    final database = PracticeDatabase(connection);
    addTearDown(database.close);

    await verifier.migrateAndValidate(database, 1);
  });
}
