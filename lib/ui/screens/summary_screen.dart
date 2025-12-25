import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/engine/split_engine.dart';
import '../../domain/models/assignment.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/participant.dart';
import '../../domain/models/settlement.dart';
import '../../infra/share/whatsapp_share_service.dart';
import '../state/bill_state.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  static const routeName = '/summary';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(billDraftProvider);
    final bill = draft.toBill();
    final settlement = const SplitEngine().calculate(bill);
    final itemShares = _calculateItemShares(bill);

    return Scaffold(
      appBar: AppBar(title: const Text('Summary & Share')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            draft.merchantName ?? 'Receipt',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (final entry in settlement.participants)
            _ParticipantSummaryCard(
              participant: draft.participants
                  .firstWhere((p) => p.id == entry.participantId),
              entry: entry,
              currency: draft.currency,
              merchantName: draft.merchantName,
              itemShares: itemShares[entry.participantId] ?? const [],
              onShare: (message, phone) {
                WhatsappShareService().share(message: message, phone: phone);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      phone == null || phone.isEmpty
                          ? 'Message copied to clipboard.'
                          : 'Opening WhatsApp...',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Map<String, List<_ItemShare>> _calculateItemShares(Bill bill) {
    final assignmentsByItem = {
      for (final assignment in bill.assignments) assignment.itemId: assignment,
    };

    final result = <String, List<_ItemShare>>{
      for (final participant in bill.participants) participant.id: [],
    };

    for (final item in bill.items) {
      final assignment = assignmentsByItem[item.id];
      final allocations = _buildAllocations(assignment, bill.participants);
      for (final allocation in allocations) {
        final share = item.totalPrice * allocation.fraction;
        result[allocation.participantId]?.add(
          _ItemShare(name: item.name, amount: share),
        );
      }
    }

    return result;
  }

  List<ItemAllocation> _buildAllocations(
    Assignment? assignment,
    List<Participant> participants,
  ) {
    if (assignment == null) {
      final fraction = participants.isEmpty ? 0.0 : 1 / participants.length;
      return participants
          .map((participant) => ItemAllocation(
                participantId: participant.id,
                fraction: fraction,
              ))
          .toList();
    }

    switch (assignment.mode) {
      case SplitMode.single:
        return assignment.allocations;
      case SplitMode.selectedEqual:
        final count = assignment.allocations.length;
        if (count == 0) {
          return const [];
        }
        final fraction = 1 / count;
        return assignment.allocations
            .map((allocation) => ItemAllocation(
                  participantId: allocation.participantId,
                  fraction: fraction,
                ))
            .toList();
      case SplitMode.allEqual:
        final count = participants.length;
        if (count == 0) {
          return const [];
        }
        final fraction = 1 / count;
        return participants
            .map((participant) => ItemAllocation(
                  participantId: participant.id,
                  fraction: fraction,
                ))
            .toList();
      case SplitMode.customPercent:
        final totalFraction = assignment.allocations.fold<double>(
          0,
          (sum, allocation) => sum + allocation.fraction,
        );
        if (totalFraction == 0) {
          return const [];
        }
        return assignment.allocations
            .map((allocation) => ItemAllocation(
                  participantId: allocation.participantId,
                  fraction: allocation.fraction / totalFraction,
                ))
            .toList();
    }
  }
}

class _ItemShare {
  const _ItemShare({required this.name, required this.amount});

  final String name;
  final double amount;
}

class _ParticipantSummaryCard extends StatelessWidget {
  const _ParticipantSummaryCard({
    required this.participant,
    required this.entry,
    required this.currency,
    required this.merchantName,
    required this.itemShares,
    required this.onShare,
  });

  final Participant participant;
  final ParticipantSettlement entry;
  final String currency;
  final String? merchantName;
  final List<_ItemShare> itemShares;
  final void Function(String message, String? phone) onShare;

  @override
  Widget build(BuildContext context) {
    final message = _buildMessage();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(participant.name,
                style: Theme.of(context).textTheme.titleMedium),
            if (itemShares.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text('Assigned items:'),
                  for (final item in itemShares)
                    Text(
                      '- ${item.name}: $currency ${item.amount.toStringAsFixed(2)}',
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Text('Items: $currency ${entry.itemsSubtotal.toStringAsFixed(2)}'),
            Text('Tax: $currency ${entry.taxShare.toStringAsFixed(2)}'),
            Text(
              'Service: $currency ${entry.serviceShare.toStringAsFixed(2)}',
            ),
            const Divider(),
            Text(
              'Total owed: $currency ${entry.totalOwed.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => onShare(message, participant.phone),
              icon: const Icon(Icons.share),
              label: Text(
                participant.phone == null || participant.phone!.isEmpty
                    ? 'Copy message'
                    : 'Share via WhatsApp',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildMessage() {
    final buffer = StringBuffer();
    buffer.writeln('SplitSnap summary');
    if (merchantName != null && merchantName!.isNotEmpty) {
      buffer.writeln('Merchant: $merchantName');
    }
    buffer.writeln('Participant: ${participant.name}');
    if (itemShares.isNotEmpty) {
      buffer.writeln('Items:');
      for (final item in itemShares) {
        buffer.writeln('• ${item.name}: $currency ${item.amount.toStringAsFixed(2)}');
      }
    }
    buffer.writeln('Tax: $currency ${entry.taxShare.toStringAsFixed(2)}');
    buffer.writeln('Service: $currency ${entry.serviceShare.toStringAsFixed(2)}');
    buffer.writeln('Total owed: $currency ${entry.totalOwed.toStringAsFixed(2)}');
    buffer.writeln('Please review and press send in WhatsApp.');
    return buffer.toString();
  }
}
