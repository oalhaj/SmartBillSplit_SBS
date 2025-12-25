import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/bill_item.dart';
import '../state/bill_state.dart';
import 'participants_screen.dart';

class ReviewEditScreen extends ConsumerStatefulWidget {
  const ReviewEditScreen({super.key});

  static const routeName = '/review';

  @override
  ConsumerState<ReviewEditScreen> createState() => _ReviewEditScreenState();
}

class _ReviewEditScreenState extends ConsumerState<ReviewEditScreen> {
  late final TextEditingController _merchantController;
  late final TextEditingController _subtotalController;
  late final TextEditingController _taxController;
  late final TextEditingController _serviceController;
  late final TextEditingController _totalController;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(billDraftProvider);
    _merchantController =
        TextEditingController(text: draft.merchantName ?? '');
    _subtotalController = TextEditingController(
      text: draft.subtotal?.toStringAsFixed(2) ?? '',
    );
    _taxController = TextEditingController(
      text: draft.tax.toStringAsFixed(2),
    );
    _serviceController = TextEditingController(
      text: draft.serviceCharge.toStringAsFixed(2),
    );
    _totalController = TextEditingController(
      text: draft.total.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _subtotalController.dispose();
    _taxController.dispose();
    _serviceController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  double _parse(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  bool _isMismatch(List<BillItem> items) {
    final itemsTotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final expected = itemsTotal + _parse(_taxController) + _parse(_serviceController);
    final total = _parse(_totalController);
    return (expected - total).abs() > 0.01;
  }

  void _updateDraft() {
    ref.read(billDraftProvider.notifier).updateMerchant(
          _merchantController.text.trim(),
        );
    ref.read(billDraftProvider.notifier).updateTotals(
          subtotal: double.tryParse(_subtotalController.text.trim()),
          tax: _parse(_taxController),
          serviceCharge: _parse(_serviceController),
          total: _parse(_totalController),
        );
  }

  Future<void> _editItem(BillItem item) async {
    final nameController = TextEditingController(text: item.name);
    final qtyController = TextEditingController(text: item.quantity.toString());
    final priceController =
        TextEditingController(text: item.unitPrice.toStringAsFixed(2));
    final updated = await showDialog<BillItem>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Unit price'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedItem = item.copyWith(
                  name: nameController.text.trim(),
                  quantity: int.tryParse(qtyController.text.trim()) ?? item.quantity,
                  unitPrice:
                      double.tryParse(priceController.text.trim()) ?? item.unitPrice,
                );
                Navigator.pop(context, updatedItem);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updated != null) {
      final draft = ref.read(billDraftProvider);
      final updatedItems = draft.items
          .map((current) => current.id == item.id ? updated : current)
          .toList();
      ref.read(billDraftProvider.notifier).state = draft.copyWith(
            items: updatedItems,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(billDraftProvider);
    final mismatch = _isMismatch(draft.items);

    return Scaffold(
      appBar: AppBar(title: const Text('Review & Edit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (mismatch)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Items + tax + service do not match total. You can still continue.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          TextField(
            controller: _merchantController,
            decoration: const InputDecoration(labelText: 'Merchant name'),
            onChanged: (_) => _updateDraft(),
          ),
          const SizedBox(height: 16),
          Text(
            'Items',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final item in draft.items)
            Card(
              child: ListTile(
                title: Text(item.name),
                subtitle: Text(
                  '${item.quantity} x ${item.unitPrice.toStringAsFixed(2)} = ${item.totalPrice.toStringAsFixed(2)}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () => _editItem(item),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Totals',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextField(
            controller: _subtotalController,
            decoration: const InputDecoration(labelText: 'Subtotal (optional)'),
            keyboardType: TextInputType.number,
            onChanged: (_) => _updateDraft(),
          ),
          TextField(
            controller: _taxController,
            decoration: const InputDecoration(labelText: 'Tax'),
            keyboardType: TextInputType.number,
            onChanged: (_) => _updateDraft(),
          ),
          TextField(
            controller: _serviceController,
            decoration: const InputDecoration(labelText: 'Service charge'),
            keyboardType: TextInputType.number,
            onChanged: (_) => _updateDraft(),
          ),
          TextField(
            controller: _totalController,
            decoration: const InputDecoration(labelText: 'Total'),
            keyboardType: TextInputType.number,
            onChanged: (_) => _updateDraft(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _updateDraft();
          Navigator.pushNamed(context, ParticipantsScreen.routeName);
        },
        label: const Text('Participants'),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
