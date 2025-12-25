import 'package:flutter_test/flutter_test.dart';

import 'package:splitsnap/domain/engine/split_engine.dart';
import 'package:splitsnap/domain/models/assignment.dart';
import 'package:splitsnap/domain/models/bill.dart';
import 'package:splitsnap/domain/models/bill_item.dart';
import 'package:splitsnap/domain/models/participant.dart';

void main() {
  test('splits items equally and rounds remainder', () {
    final participants = [
      Participant(id: 'p1', name: 'A'),
      Participant(id: 'p2', name: 'B'),
      Participant(id: 'p3', name: 'C'),
    ];
    final items = [
      BillItem(id: 'i1', name: 'Pizza', quantity: 1, unitPrice: 30),
    ];
    final bill = Bill(
      currency: 'AED',
      items: items,
      participants: participants,
      assignments: [
        Assignment(itemId: 'i1', mode: SplitMode.allEqual, allocations: const []),
      ],
      tax: 0,
      serviceCharge: 0,
      total: 30,
    );

    final settlement = const SplitEngine().calculate(bill);
    final totals = settlement.participants.map((p) => p.totalOwed).toList();

    expect(totals.reduce((a, b) => a + b), 30);
    expect(totals.where((total) => total == 10.0).length, 3);
  });

  test('distributes rounding remainder across participants', () {
    final participants = [
      Participant(id: 'p1', name: 'A'),
      Participant(id: 'p2', name: 'B'),
    ];
    final items = [
      BillItem(id: 'i1', name: 'Coffee', quantity: 1, unitPrice: 10.01),
    ];
    final bill = Bill(
      currency: 'AED',
      items: items,
      participants: participants,
      assignments: [
        Assignment(itemId: 'i1', mode: SplitMode.allEqual, allocations: const []),
      ],
      tax: 0,
      serviceCharge: 0,
      total: 10.01,
    );

    final settlement = const SplitEngine().calculate(bill);
    final totals = settlement.participants.map((p) => p.totalOwed).toList();

    expect(totals.reduce((a, b) => a + b), 10.01);
    expect(totals.contains(5.01), true);
    expect(totals.contains(5.0), true);
  });

  test('uses override charges when enabled', () {
    final participants = [
      Participant(id: 'p1', name: 'A'),
      Participant(id: 'p2', name: 'B'),
    ];
    final items = [
      BillItem(id: 'i1', name: 'Meal', quantity: 1, unitPrice: 20),
    ];
    final bill = Bill(
      currency: 'AED',
      items: items,
      participants: participants,
      assignments: [
        Assignment(itemId: 'i1', mode: SplitMode.allEqual, allocations: const []),
      ],
      tax: 4,
      serviceCharge: 2,
      total: 26,
      overrideCharges: true,
      chargeOverrides: const [
        ParticipantChargeOverride(participantId: 'p1', tax: 1, service: 1),
        ParticipantChargeOverride(participantId: 'p2', tax: 3, service: 1),
      ],
    );

    final settlement = const SplitEngine().calculate(bill);
    final p1 = settlement.participants.firstWhere((p) => p.participantId == 'p1');
    final p2 = settlement.participants.firstWhere((p) => p.participantId == 'p2');

    expect(p1.taxShare, 1);
    expect(p2.taxShare, 3);
    expect(p1.serviceShare, 1);
    expect(p2.serviceShare, 1);
  });
}
