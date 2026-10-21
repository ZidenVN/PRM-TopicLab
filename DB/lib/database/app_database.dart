import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class StoredMessages extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [StoredMessages])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'connect_db',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 1;

  Future<List<StoredMessage>> getAllMessages() {
    return (select(
      storedMessages,
    )..orderBy([(table) => OrderingTerm.desc(table.createdAt)])).get();
  }

  Stream<List<StoredMessage>> watchMessages() {
    return (select(
      storedMessages,
    )..orderBy([(table) => OrderingTerm.desc(table.createdAt)])).watch();
  }

  Future<void> addMessage({
    required String id,
    required String content,
    required DateTime createdAt,
  }) {
    return into(storedMessages).insert(
      StoredMessagesCompanion.insert(
        id: id,
        content: content,
        createdAt: createdAt,
      ),
    );
  }

  Future<void> markAsSynced(String id) {
    return (update(storedMessages)..where((table) => table.id.equals(id)))
        .write(const StoredMessagesCompanion(isSynced: Value(true)));
  }

  /// Cập nhật nội dung bản ghi (Update)
  Future<int> updateMessageContent(String id, String newContent) {
    return (update(storedMessages)..where((table) => table.id.equals(id)))
        .write(StoredMessagesCompanion(
          content: Value(newContent),
          isSynced: const Value(false),
        ));
  }

  /// Xóa một bản ghi theo ID (Delete)
  Future<int> deleteMessage(String id) {
    return (delete(storedMessages)..where((table) => table.id.equals(id))).go();
  }

  /// Xóa toàn bộ dữ liệu (Clear All)
  Future<int> clearAllMessages() {
    return delete(storedMessages).go();
  }
}
