# Saved layouts of the practice database

The practice database (`lib/features/practice/data/practice_database.dart`,
build step P.5) keeps the games' data in tables. Each time a table changes,
the app has to carry the data on a learner's phone across to the new layout
without losing any. That carrying-across is called a migration, and decision
G3 says every one comes with a test.

This folder holds one saved copy of the table layout per version
(`drift_schema_v1.json` is version 1, the first). The tests in
`test/features/practice/practice_database_migration_test.dart` compare the
database the app makes with these copies.

## When a table changes

Run these from the project folder, in order.

1. Change the table in `practice_database.dart`, raise `schemaVersion` by one,
   and add the step to `onUpgrade` in the same file.
2. Rewrite the generated code:
   `dart run build_runner build`
3. Save the new layout (it is written as the next numbered file here):
   `dart run drift_dev schema dump lib/features/practice/data/practice_database.dart drift_schemas/`
4. Rewrite the test helpers from the saved layouts:
   `dart run drift_dev schema generate drift_schemas/ test/features/practice/generated_migrations/`
5. Add a test that upgrades a database from the older version and checks it
   matches the new one, then run `flutter test test/features/practice/`.

Never edit or delete an older saved layout: it is the record of what is on
phones that have not yet been upgraded.
