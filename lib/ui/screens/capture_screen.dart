import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infra/ocr/receipt_ocr_service.dart';
import '../state/bill_state.dart';
import 'review_edit_screen.dart';

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  static const routeName = '/capture';

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  final _ocrService = ReceiptOcrService();
  bool _isProcessing = false;
  String? _error;

  Future<void> _capture() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    final result = await _ocrService.captureAndParse();
    if (!mounted) {
      return;
    }
    if (result == null) {
      setState(() {
        _isProcessing = false;
        _error = 'Capture cancelled.';
      });
      return;
    }
    ref.read(billDraftProvider.notifier).updateFromParse(result);
    setState(() {
      _isProcessing = false;
    });
    Navigator.pushReplacementNamed(context, ReviewEditScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture receipt')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Use your camera to capture the receipt. You can crop and rotate '
              'before OCR runs.',
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _capture,
              icon: const Icon(Icons.camera_alt),
              label: Text(_isProcessing ? 'Processing...' : 'Capture & Scan'),
            ),
          ],
        ),
      ),
    );
  }
}
