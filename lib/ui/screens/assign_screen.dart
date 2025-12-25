import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/assignment.dart';
import '../../domain/models/bill_item.dart';
import '../../domain/models/participant.dart';
import '../state/bill_state.dart';
import 'charges_screen.dart';

class AssignScreen extends ConsumerStatefulWidget {
  const AssignScreen({super.key});

  static const routeName = '/assign';

  @override
  ConsumerState<AssignScreen> createState() => _AssignScreenState();
}

class _AssignScreenState extends ConsumerState<AssignScreen> {
  late Map<String, Assignment> _draftAssignments;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(billDraftProvider);
    _draftAssignments = {
      for (final assignment in draft.assignments) assignment.itemId: assignment,
    };
  }

  void _applyQuickSplitAll(List<BillItem> items) {
    setState(() {
      _draftAssignments = {
        for (final item in items)
          item.id: Assignment(
            itemId: item.id,
            mode: SplitMode.allEqual,
            allocations: const [],
          ),
      };
    });
  }

  void _clearAssignments() {
    setState(() {
      _draftAssignments = {};
    });
  }

  Assignment _assignmentForItem(BillItem item) {
    return _draftAssignments[item.id] ??
        Assignment(
          itemId: item.id,
          mode: SplitMode.allEqual,
          allocations: const [],
        );
  }

  void _save() {
    final draft = ref.read(billDraftProvider);
    ref.read(billDraftProvider.notifier).state =
        draft.copyWith(assignments: _draftAssignments.values.toList());
    Navigator.pushNamed(context, ChargesScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(billDraftProvider);
    final items = draft.items;
    final participants = draft.participants;

    return Scaffold(
      appBar: AppBar(title: const Text('Assign items')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _applyQuickSplitAll(items),
                child: const Text('Split everything equally'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _clearAssignments,
                child: const Text('Clear all assignments'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in items)
            _AssignmentCard(
              item: item,
              participants: participants,
              assignment: _assignmentForItem(item),
              onChanged: (assignment) {
                setState(() {
                  _draftAssignments[item.id] = assignment;
                });
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        label: const Text('Charges'),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }
}

class _AssignmentCard extends StatefulWidget {
  const _AssignmentCard({
    required this.item,
    required this.participants,
    required this.assignment,
    required this.onChanged,
  });

  final BillItem item;
  final List<Participant> participants;
  final Assignment assignment;
  final ValueChanged<Assignment> onChanged;

  @override
  State<_AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<_AssignmentCard> {
  late SplitMode _mode;
  late Set<String> _selectedParticipants;

  @override
  void initState() {
    super.initState();
    _mode = widget.assignment.mode;
    _selectedParticipants = widget.assignment.allocations
        .map((allocation) => allocation.participantId)
        .toSet();
  }

  void _update() {
    final allocations = _selectedParticipants
        .map((id) => ItemAllocation(participantId: id, fraction: 1))
        .toList();
    widget.onChanged(
      Assignment(itemId: widget.item.id, mode: _mode, allocations: allocations),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item.name,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButton<SplitMode>(
              value: _mode,
              items: SplitMode.values
                  .map(
                    (mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(_labelForMode(mode)),
                    ),
                  )
                  .toList(),
              onChanged: (mode) {
                if (mode == null) {
                  return;
                }
                setState(() {
                  _mode = mode;
                });
                _update();
              },
            ),
            if (_mode == SplitMode.single || _mode == SplitMode.selectedEqual)
              Wrap(
                spacing: 8,
                children: [
                  for (final participant in widget.participants)
                    FilterChip(
                      label: Text(participant.name),
                      selected:
                          _selectedParticipants.contains(participant.id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedParticipants.add(participant.id);
                          } else {
                            _selectedParticipants.remove(participant.id);
                          }
                        });
                        _update();
                      },
                    ),
                ],
              ),
            if (_mode == SplitMode.customPercent)
              Text(
                'Custom % split is available in advanced mode. Use edit screen to fine-tune.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  String _labelForMode(SplitMode mode) {
    switch (mode) {
      case SplitMode.single:
        return 'Assign to one participant';
      case SplitMode.selectedEqual:
        return 'Split equally among selected';
      case SplitMode.allEqual:
        return 'Split equally among all';
      case SplitMode.customPercent:
        return 'Custom % split';
    }
  }
}
