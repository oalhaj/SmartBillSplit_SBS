import 'package:flutter/material.dart';

import '../../infra/storage/bill_repository.dart';
import 'capture_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repository = BillRepository();
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _repository.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SplitSnap')),
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          return FutureBuilder(
            future: _repository.fetchBills(),
            builder: (context, billsSnapshot) {
              final bills = billsSnapshot.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Past bills',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (bills.isEmpty)
                    const Text('No saved bills yet.'),
                  for (final bill in bills)
                    ListTile(
                      title: Text(bill.merchantName ?? 'Receipt'),
                      subtitle: Text(
                        '${bill.currency} ${bill.total.toStringAsFixed(2)}',
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, CaptureScreen.routeName),
        label: const Text('Capture receipt'),
        icon: const Icon(Icons.camera_alt),
      ),
    );
  }
}
