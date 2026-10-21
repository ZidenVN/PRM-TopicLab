import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'database/app_database.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? initializationError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    initializationError = error;
  }

  runApp(MyApp(initializationError: initializationError));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    this.initializationError,
    this.database,
    this.messagesStream,
  });

  final Object? initializationError;
  final AppDatabase? database;
  final Stream<List<StoredMessage>>? messagesStream;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Topic 1: Local SQLite & Firebase',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: DatabasePage(
        initializationError: initializationError,
        database: database,
        messagesStream: messagesStream,
      ),
    );
  }
}

class DatabasePage extends StatefulWidget {
  const DatabasePage({
    super.key,
    this.initializationError,
    this.database,
    this.messagesStream,
  });

  final Object? initializationError;
  final AppDatabase? database;
  final Stream<List<StoredMessage>>? messagesStream;

  @override
  State<DatabasePage> createState() => _DatabasePageState();
}

class _DatabasePageState extends State<DatabasePage> {
  final _contentController = TextEditingController();
  final _uuid = const Uuid();

  late final AppDatabase _database;
  late final bool _ownsDatabase;
  late final Stream<List<StoredMessage>> _messagesStream;

  bool _isBusy = false;
  bool _isLocalReady = false;
  bool _isFirebaseReady = false;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    _ownsDatabase = widget.database == null;
    _database = widget.database ?? AppDatabase();
    _messagesStream = widget.messagesStream ?? _database.watchMessages();

    Future<void>.microtask(_checkAllConnections);
  }

  @override
  void dispose() {
    _contentController.dispose();
    if (_ownsDatabase) {
      _database.close();
    }
    super.dispose();
  }

  Future<void> _checkAllConnections() async {
    if (mounted) setState(() => _isBusy = true);

    await Future.wait([_checkLocalConnection(), _checkFirebaseConnection()]);

    if (mounted) setState(() => _isBusy = false);
  }

  Future<void> _checkLocalConnection() async {
    try {
      await _database.getAllMessages();
      if (!mounted) return;
      setState(() => _isLocalReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLocalReady = false);
    }
  }

  Future<void> _checkFirebaseConnection() async {
    if (widget.initializationError != null) {
      if (!mounted) return;
      setState(() => _isFirebaseReady = false);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('connection_tests')
          .doc('flutter_app')
          .get(const GetOptions(source: Source.server));

      if (!mounted) return;
      setState(() => _isFirebaseReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isFirebaseReady = false);
    }
  }

  // --- C (Create): Lưu bản ghi mới ---
  Future<void> _saveMessage() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      setState(() => _inputError = 'Vui lòng nhập nội dung');
      return;
    }

    if (!_isLocalReady) {
      _showSnackBar('Database SQLite chưa sẵn sàng!', isError: true);
      return;
    }

    setState(() {
      _isBusy = true;
      _inputError = null;
    });

    final id = _uuid.v4();
    final createdAt = DateTime.now();

    try {
      // 1. Lưu vào SQLite cục bộ trước (Offline-First)
      await _database.addMessage(
        id: id,
        content: content,
        createdAt: createdAt,
      );

      if (!mounted) return;
      _contentController.clear();
      FocusScope.of(context).unfocus();

      // 2. Thử đồng bộ lên Cloud Firestore nếu có mạng
      if (_isFirebaseReady) {
        try {
          await FirebaseFirestore.instance.collection('messages').doc(id).set({
            'id': id,
            'content': content,
            'createdAt': Timestamp.fromDate(createdAt),
          });
          await _database.markAsSynced(id);
          _showSnackBar('Đã lưu SQLite & đồng bộ Firebase!');
        } catch (_) {
          _showSnackBar('Đã lưu SQLite (Chờ đồng bộ Cloud)');
        }
      } else {
        _showSnackBar('Đã lưu vào SQLite cục bộ (Offline)');
      }
    } catch (e) {
      _showSnackBar('Lỗi khi lưu: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // --- U (Update): Sửa nội dung bản ghi ---
  void _openEditDialog(StoredMessage message) {
    final editController = TextEditingController(text: message.content);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chỉnh sửa nội dung', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Nhập nội dung mới...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isEmpty || newText == message.content) {
                Navigator.pop(ctx);
                return;
              }

              Navigator.pop(ctx);
              await _updateMessage(message.id, newText);
            },
            child: const Text('Lưu thay đổi'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMessage(String id, String newContent) async {
    try {
      await _database.updateMessageContent(id, newContent);

      if (_isFirebaseReady) {
        try {
          await FirebaseFirestore.instance.collection('messages').doc(id).update({
            'content': newContent,
          });
          await _database.markAsSynced(id);
        } catch (_) {}
      }

      _showSnackBar('Đã cập nhật bản ghi thành công!');
    } catch (e) {
      _showSnackBar('Lỗi khi cập nhật: $e', isError: true);
    }
  }

  // --- D (Delete): Xóa bản ghi ---
  Future<void> _deleteMessage(String id) async {
    try {
      await _database.deleteMessage(id);

      if (_isFirebaseReady) {
        try {
          await FirebaseFirestore.instance.collection('messages').doc(id).delete();
        } catch (_) {}
      }

      _showSnackBar('Đã xóa bản ghi khỏi SQLite');
    } catch (e) {
      _showSnackBar('Lỗi khi xóa: $e', isError: true);
    }
  }

  // --- Clear All: Xóa toàn bộ dữ liệu SQLite ---
  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa toàn bộ dữ liệu?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text('Hành động này sẽ xóa sạch toàn bộ các bản ghi đang lưu trong SQLite.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await _database.clearAllMessages();
              _showSnackBar('Đã dọn sạch database SQLite!');
            },
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  // --- Retry Sync: Đồng bộ thủ công 1 bản ghi lên Cloud ---
  Future<void> _syncSingleMessage(StoredMessage msg) async {
    if (!_isFirebaseReady) {
      _showSnackBar('Cloud đang ngoại tuyến, chưa thể đồng bộ!', isError: true);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('messages').doc(msg.id).set({
        'id': msg.id,
        'content': msg.content,
        'createdAt': Timestamp.fromDate(msg.createdAt),
      });
      await _database.markAsSynced(msg.id);
      _showSnackBar('Đồng bộ lên Firebase thành công!');
    } catch (e) {
      _showSnackBar('Lỗi đồng bộ: $e', isError: true);
    }
  }

  void _showSnackBar(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red.shade700 : Colors.indigo.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(d.hour)}:${pad(d.minute)} ${pad(d.day)}/${pad(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Topic 1: Local SQLite (Drift)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Mô hình Offline-First & Reactive Stream', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Kiểm tra lại kết nối',
            onPressed: _isBusy ? null : _checkAllConnections,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Thanh trạng thái kết nối tinh gọn (Compact Status)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Badge SQLite
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                _isLocalReady ? Icons.check_circle : Icons.error,
                                size: 16,
                                color: _isLocalReady ? const Color(0xFF10B981) : Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _isLocalReady ? 'SQLite: Sẵn sàng' : 'SQLite: Chưa kết nối',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isLocalReady ? const Color(0xFF065F46) : Colors.red,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 20, color: Colors.grey.shade300),
                        const SizedBox(width: 12),
                        // Badge Firebase
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                _isFirebaseReady ? Icons.cloud_done : Icons.cloud_off,
                                size: 16,
                                color: _isFirebaseReady ? const Color(0xFF10B981) : Colors.amber.shade800,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _isFirebaseReady ? 'Cloud: Đã kết nối' : 'Cloud: Ngoại tuyến',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _isFirebaseReady ? const Color(0xFF065F46) : Colors.amber.shade900,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Khung nhập liệu (Create)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _contentController,
                          enabled: !_isBusy,
                          decoration: InputDecoration(
                            hintText: 'Nhập nội dung cần lưu vào SQLite...',
                            hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                            errorText: _inputError,
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          minLines: 1,
                          maxLines: 3,
                          onChanged: (_) {
                            if (_inputError != null) setState(() => _inputError = null);
                          },
                          onSubmitted: (_) {
                            if (!_isBusy) _saveMessage();
                          },
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _isBusy ? null : _saveMessage,
                          icon: _isBusy
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.add, size: 18),
                          label: Text(_isBusy ? 'Đang ghi dữ liệu...' : 'Lưu vào SQLite'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Tiêu đề danh sách & Nút xóa tất cả
                  StreamBuilder<List<StoredMessage>>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      final count = snapshot.data?.length ?? 0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Dữ liệu SQLite',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$count bản ghi',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                                ),
                              ),
                            ],
                          ),
                          if (count > 0)
                            TextButton.icon(
                              onPressed: _isBusy ? null : _confirmClearAll,
                              icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.red),
                              label: const Text('Xóa tất cả', style: TextStyle(fontSize: 12, color: Colors.red)),
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // 4. Danh sách bản ghi Reactive Stream (CRUD items)
                  StreamBuilder<List<StoredMessage>>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('Lỗi tải dữ liệu: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                          ),
                        );
                      }

                      final messages = snapshot.data ?? const <StoredMessage>[];
                      if (messages.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                'Chưa có bản ghi nào trong SQLite',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hãy nhập nội dung ở trên và bấm "Lưu vào SQLite"',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: messages.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isSynced = msg.isSynced;

                          return InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: msg.content));
                              _showSnackBar('Đã sao chép nội dung vào Clipboard!');
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon trạng thái
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      isSynced ? Icons.cloud_done : Icons.storage,
                                      size: 18,
                                      color: isSynced ? const Color(0xFF10B981) : Colors.indigo,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Nội dung và ngày tạo
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          msg.content,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              _formatDate(msg.createdAt),
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: isSynced ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isSynced ? 'Đã đồng bộ' : 'Chỉ có ở local',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSynced ? const Color(0xFF065F46) : Colors.amber.shade900,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Các nút thao tác CRUD (Sync, Edit, Delete)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isSynced)
                                        IconButton(
                                          icon: const Icon(Icons.sync, size: 18, color: Colors.amber),
                                          tooltip: 'Thử đồng bộ lên Cloud',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _syncSingleMessage(msg),
                                        ),
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, size: 18, color: Colors.blue.shade700),
                                        tooltip: 'Chỉnh sửa (Update)',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _openEditDialog(msg),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        tooltip: 'Xóa (Delete)',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _deleteMessage(msg.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
