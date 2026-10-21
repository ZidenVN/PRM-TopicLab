import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/payment.dart';
import '../services/payment_api.dart';
import 'checkout_screen.dart' show formatVnd;

class BankInfo {
  final String name;
  final String shortName;
  final int bin;

  const BankInfo({
    required this.name,
    required this.shortName,
    required this.bin,
  });
}

const List<BankInfo> kSupportedBanks = [
  BankInfo(name: 'MBBank (Quân Đội)', shortName: 'MB', bin: 970422),
  BankInfo(name: 'Vietcombank', shortName: 'VCB', bin: 970436),
  BankInfo(name: 'Techcombank', shortName: 'TCB', bin: 970407),
  BankInfo(name: 'ACB', shortName: 'ACB', bin: 970416),
  BankInfo(name: 'TPBank', shortName: 'TPB', bin: 970423),
  BankInfo(name: 'VPBank', shortName: 'VPB', bin: 970432),
  BankInfo(name: 'VietinBank', shortName: 'CTG', bin: 970415),
  BankInfo(name: 'BIDV', shortName: 'BIDV', bin: 970418),
];

class PaymentStatusScreen extends StatefulWidget {
  const PaymentStatusScreen({
    super.key,
    required this.api,
    required this.payment,
  });

  final PaymentApi api;
  final Payment payment;

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  late Payment _payment = widget.payment;
  Timer? _timer;
  int _elapsed = 0;
  bool _timedOut = false;
  bool _isActionBusy = false;

  static const _interval = 2; // giây giữa mỗi lần poll
  static const _maxWait = 180; // 3 phút tối đa

  // Cấu hình tài khoản nhận
  BankInfo _selectedBank = kSupportedBanks.first;
  String _accountNo = '9999999999';
  String _accountName = 'CUA HANG FLUTTER';
  Uint8List? _qrBytes;
  bool _loadingQr = true;

  @override
  void initState() {
    super.initState();
    _startPolling();
    _generateVietQr();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: _interval), (_) => _poll());
  }

  Future<void> _poll() async {
    _elapsed += _interval;
    if (_elapsed >= _maxWait) {
      _timer?.cancel();
      if (mounted) setState(() => _timedOut = true);
      return;
    }

    try {
      final p = await widget.api.getPayment(_payment.id);
      if (!mounted) return;
      setState(() => _payment = p);
      if (p.status != PaymentStatus.pending) {
        _timer?.cancel();
      }
    } catch (_) {
      // Bỏ qua lỗi mạng tạm thời trong lúc poll
    }
  }

  Future<void> _generateVietQr() async {
    if (!mounted) return;
    setState(() => _loadingQr = true);

    try {
      final res = await http.post(
        Uri.parse('https://api.vietqr.io/v2/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'accountNo': _accountNo.trim(),
          'accountName': _accountName.trim(),
          'acqId': _selectedBank.bin,
          'amount': _payment.amount,
          'addInfo': _payment.id,
          'format': 'text',
          'template': 'compact2',
        }),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['code'] == '00' && data['data'] != null) {
          final String? qrDataUrl = data['data']['qrDataURL'];
          if (qrDataUrl != null && qrDataUrl.contains(',')) {
            final base64Str = qrDataUrl.split(',').last;
            if (mounted) {
              setState(() {
                _qrBytes = base64Decode(base64Str);
                _loadingQr = false;
              });
              return;
            }
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loadingQr = false);
    }
  }

  Future<void> _simulateConfirm(bool success) async {
    setState(() => _isActionBusy = true);
    try {
      final p = await widget.api.confirmPayment(_payment.id, success: success);
      if (!mounted) return;
      setState(() {
        _payment = p;
        _timer?.cancel();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isActionBusy = false);
    }
  }

  void _showEditBankDialog() {
    final accController = TextEditingController(text: _accountNo);
    final nameController = TextEditingController(text: _accountName);
    BankInfo tempBank = _selectedBank;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Đổi tài khoản nhận', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<BankInfo>(
                initialValue: tempBank,
                decoration: const InputDecoration(
                  labelText: 'Ngân hàng',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: kSupportedBanks
                    .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
                    .toList(),
                onChanged: (b) {
                  if (b != null) setModalState(() => tempBank = b);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tài khoản',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Tên chủ tài khoản',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _selectedBank = tempBank;
                    _accountNo = accController.text.trim().isEmpty ? '9999999999' : accController.text.trim();
                    _accountName = nameController.text.trim().isEmpty ? 'CUA HANG FLUTTER' : nameController.text.trim().toUpperCase();
                  });
                  Navigator.pop(ctx);
                  _generateVietQr();
                },
                child: const Text('Cập nhật mã QR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chép $label'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, color, text) = switch (_payment.status) {
      PaymentStatus.success => (Icons.check_circle, Colors.green, 'Thanh toán thành công'),
      PaymentStatus.failed => (Icons.cancel, Colors.red, 'Thanh toán thất bại'),
      PaymentStatus.pending => _timedOut
          ? (Icons.timer_off, Colors.orange, 'Hết thời gian chờ')
          : (Icons.hourglass_top, theme.colorScheme.primary, 'Đang chờ thanh toán'),
    };

    final isFinished = _payment.status != PaymentStatus.pending || _timedOut;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon + Trạng thái ngắn gọn
                  Icon(icon, size: 52, color: color),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Mã QR (chỉ hiện khi đang chờ)
                  if (!isFinished) ...[
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Mã VietQR',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                  onPressed: _showEditBankDialog,
                                  icon: const Icon(Icons.edit, size: 15),
                                  label: const Text('Đổi STK'),
                                ),
                              ],
                            ),
                            const Divider(height: 12),
                            if (_loadingQr)
                              const SizedBox(
                                height: 240,
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            else if (_qrBytes != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  _qrBytes!,
                                  width: 250,
                                  fit: BoxFit.contain,
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text('${_selectedBank.name}: $_accountNo', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text('Chủ TK: $_accountName'),
                                    Text('Nội dung: ${_payment.id}'),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 10),
                            // Thông tin sao chép nhanh
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${_selectedBank.shortName} · $_accountNo · ND: ${_payment.id}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Chép STK',
                                    icon: const Icon(Icons.copy, size: 16),
                                    onPressed: () => _copyToClipboard(_accountNo, 'STK'),
                                  ),
                                  IconButton(
                                    tooltip: 'Chép ND',
                                    icon: const Icon(Icons.copy_all, size: 16),
                                    onPressed: () => _copyToClipboard(_payment.id, 'Nội dung'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Tóm tắt đơn hàng
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          _buildDetailRow('Mã giao dịch', _payment.id),
                          const Divider(height: 12),
                          _buildDetailRow('Số tiền', formatVnd(_payment.amount)),
                          const Divider(height: 12),
                          _buildDetailRow(
                            'Thời gian chờ',
                            '$_elapsed / $_maxWait s',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Nút kiểm thử (chỉ hiện khi đang chờ)
                  if (!isFinished) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _isActionBusy ? null : () => _simulateConfirm(true),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('Thành công', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: _isActionBusy ? null : () => _simulateConfirm(false),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Thất bại', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (isFinished) ...[
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
