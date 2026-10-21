import 'package:connect_db/database/app_database.dart';
import 'package:connect_db/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CRUD operations on SQLite database', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    // 1. Create (Thêm bản ghi)
    await database.addMessage(
      id: 'msg-1',
      content: 'Nội dung ban đầu',
      createdAt: DateTime(2026, 10, 6),
    );

    // 2. Read (Đọc danh sách)
    var messages = await database.getAllMessages();
    expect(messages, hasLength(1));
    expect(messages.first.content, 'Nội dung ban đầu');
    expect(messages.first.isSynced, isFalse);

    // Mark as Synced (Đồng bộ Cloud)
    await database.markAsSynced('msg-1');
    messages = await database.getAllMessages();
    expect(messages.first.isSynced, isTrue);

    // 3. Update (Cập nhật nội dung)
    await database.updateMessageContent('msg-1', 'Nội dung đã sửa');
    messages = await database.getAllMessages();
    expect(messages.first.content, 'Nội dung đã sửa');
    expect(messages.first.isSynced, isFalse); // Cờ được reset để sync lại

    // 4. Delete (Xóa từng bản ghi)
    await database.deleteMessage('msg-1');
    messages = await database.getAllMessages();
    expect(messages, isEmpty);

    // 5. Clear All (Xóa tất cả bản ghi)
    await database.addMessage(id: 'msg-2', content: 'Tin 2', createdAt: DateTime.now());
    await database.addMessage(id: 'msg-3', content: 'Tin 3', createdAt: DateTime.now());
    expect(await database.getAllMessages(), hasLength(2));

    await database.clearAllMessages();
    expect(await database.getAllMessages(), isEmpty);
  });

  testWidgets('renders UI components and connection badges', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      MyApp(
        initializationError: 'Lỗi cấu hình thử nghiệm',
        database: database,
        messagesStream: const Stream<List<StoredMessage>>.empty(),
      ),
    );
    await tester.pumpAndSettle();

    // Kiểm tra các thành phần giao diện
    expect(find.text('SQLite: Sẵn sàng'), findsOneWidget);
    expect(find.text('Cloud: Ngoại tuyến'), findsOneWidget);
    expect(find.text('Lưu vào SQLite'), findsOneWidget);
    expect(find.text('Chưa có bản ghi nào trong SQLite'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await database.close();
    await tester.pump();
  });
}
