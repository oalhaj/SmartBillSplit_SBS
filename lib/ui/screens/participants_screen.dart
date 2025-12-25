import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../domain/models/participant.dart';
import '../../infra/contacts/contacts_service.dart';
import '../state/bill_state.dart';
import 'assign_screen.dart';

class ParticipantsScreen extends ConsumerStatefulWidget {
  const ParticipantsScreen({super.key});

  static const routeName = '/participants';

  @override
  ConsumerState<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends ConsumerState<ParticipantsScreen> {
  final _contactsService = ContactsService();
  bool _loadingContacts = false;

  Future<void> _addManual() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final created = await showDialog<Participant>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add participant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
              keyboardType: TextInputType.phone,
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
              final name = nameController.text.trim();
              if (name.isEmpty) {
                return;
              }
              Navigator.pop(
                context,
                Participant(name: name, phone: phoneController.text.trim()),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (created != null) {
      final draft = ref.read(billDraftProvider);
      final updated = [...draft.participants, created];
      if (updated.length == 1) {
        updated[0] = updated[0].copyWith(isPayer: true);
      }
      ref.read(billDraftProvider.notifier).state =
          draft.copyWith(participants: updated);
    }
  }

  Future<void> _pickFromContacts() async {
    setState(() {
      _loadingContacts = true;
    });
    final contacts = await _contactsService.fetchContacts();
    if (!mounted) {
      return;
    }
    setState(() {
      _loadingContacts = false;
    });
    if (contacts.isEmpty) {
      return;
    }

    final selected = await showModalBottomSheet<Contact>(
      context: context,
      builder: (context) {
        return ListView(
          children: [
            const ListTile(title: Text('Select contact')),
            for (final contact in contacts)
              ListTile(
                title: Text(contact.displayName),
                subtitle: Text(contact.phones.firstOrNull?.number ?? ''),
                onTap: () => Navigator.pop(context, contact),
              ),
          ],
        );
      },
    );

    if (selected != null) {
      final phone = selected.phones.firstOrNull?.number;
      final draft = ref.read(billDraftProvider);
      final updated = [
        ...draft.participants,
        Participant(name: selected.displayName, phone: phone),
      ];
      if (updated.length == 1) {
        updated[0] = updated[0].copyWith(isPayer: true);
      }
      ref.read(billDraftProvider.notifier).state =
          draft.copyWith(participants: updated);
    }
  }

  void _setPayer(String id) {
    final draft = ref.read(billDraftProvider);
    final updated = draft.participants
        .map((participant) =>
            participant.copyWith(isPayer: participant.id == id))
        .toList();
    ref.read(billDraftProvider.notifier).state =
        draft.copyWith(participants: updated);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(billDraftProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Participants')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Select a payer (defaults to first participant).'),
          const SizedBox(height: 16),
          if (draft.participants.isEmpty)
            const Text('Add someone to start splitting.'),
          for (final participant in draft.participants)
            RadioListTile<String>(
              title: Text(participant.name),
              subtitle: Text(participant.phone ?? 'No phone'),
              value: participant.id,
              groupValue: draft.participants
                  .firstWhere((p) => p.isPayer, orElse: () => participant)
                  .id,
              onChanged: (value) {
                if (value != null) {
                  _setPayer(value);
                }
              },
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _loadingContacts ? null : _pickFromContacts,
                icon: const Icon(Icons.contacts),
                label: Text(_loadingContacts ? 'Loading...' : 'From contacts'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _addManual,
                icon: const Icon(Icons.person_add),
                label: const Text('Manual'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: draft.participants.isEmpty
            ? null
            : () => Navigator.pushNamed(context, AssignScreen.routeName),
        label: const Text('Assign items'),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }
}

extension _PhoneExtension on List<Phone> {
  Phone? get firstOrNull => isEmpty ? null : first;
}
