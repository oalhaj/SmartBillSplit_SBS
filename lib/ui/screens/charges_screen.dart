import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/bill.dart';
import '../state/bill_state.dart';
import 'summary_screen.dart';

class ChargesScreen extends ConsumerStatefulWidget {
  const ChargesScreen({super.key});

  static const routeName = '/charges';

  @override
  ConsumerState<ChargesScreen> createState() => _ChargesScreenState();
}

class _ChargesScreenState extends ConsumerState<ChargesScreen> {
  final Map<String, TextEditingController> _taxControllers = {};
  final Map<String, TextEditingController> _serviceControllers = {};

  @override
  void dispose() {
    for (final controller in _taxControllers.values) {
      controller.dispose();
    }
    for (final controller in _serviceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final draft = ref.read(billDraftProvider);
    if (!draft.overrideCharges) {
      Navigator.pushNamed(context, SummaryScreen.routeName);
      return;
    }
    final overrides = draft.participants.map((participant) {
      final tax =
          double.tryParse(_taxControllers[participant.id]?.text ?? '') ?? 0;
      final service =
          double.tryParse(_serviceControllers[participant.id]?.text ?? '') ?? 0;
      return ParticipantChargeOverride(
        participantId: participant.id,
        tax: tax,
        service: service,
      );
    }).toList();
    ref.read(billDraftProvider.notifier).state =
        draft.copyWith(chargeOverrides: overrides);
    Navigator.pushNamed(context, SummaryScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(billDraftProvider);

    for (final participant in draft.participants) {
      _taxControllers.putIfAbsent(
        participant.id,
        () => TextEditingController(text: '0.00'),
      );
      _serviceControllers.putIfAbsent(
        participant.id,
        () => TextEditingController(text: '0.00'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Charges')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Override tax/service splits'),
            subtitle: const Text(
              'Default is proportional based on assigned items.',
            ),
            value: draft.overrideCharges,
            onChanged: (value) {
              ref.read(billDraftProvider.notifier).state =
                  draft.copyWith(overrideCharges: value);
            },
          ),
          if (draft.overrideCharges)
            ...draft.participants.map(
              (participant) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(participant.name),
                      TextField(
                        controller: _taxControllers[participant.id],
                        decoration: const InputDecoration(labelText: 'Tax share'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: _serviceControllers[participant.id],
                        decoration:
                            const InputDecoration(labelText: 'Service share'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        label: const Text('Summary'),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }
}
