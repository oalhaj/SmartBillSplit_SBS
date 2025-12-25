import '../models/assignment.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/participant.dart';
import '../models/settlement.dart';

double roundToCents(double value) {
  return (value * 100).round() / 100;
}

class SplitEngine {
  const SplitEngine();

  Settlement calculate(Bill bill) {
    final participants = bill.participants;
    final itemTotals = _calculateItemTotals(
      bill.items,
      participants,
      bill.assignments,
    );
    final chargeShares = bill.overrideCharges
        ? _overrideCharges(participants, bill)
        : _proportionalCharges(participants, bill, itemTotals);

    final settlements = <ParticipantSettlement>[];
    var unroundedSum = 0.0;
    for (final participant in participants) {
      final itemsSubtotal = itemTotals[participant.id] ?? 0.0;
      final taxShare = chargeShares[participant.id]?.tax ?? 0.0;
      final serviceShare = chargeShares[participant.id]?.service ?? 0.0;
      final total = itemsSubtotal + taxShare + serviceShare;
      unroundedSum += total;
      settlements.add(
        ParticipantSettlement(
          participantId: participant.id,
          itemsSubtotal: itemsSubtotal,
          taxShare: taxShare,
          serviceShare: serviceShare,
          totalOwed: total,
        ),
      );
    }

    final rounded = _applyRounding(settlements, bill.total);
    return Settlement(participants: rounded, unroundedTotal: unroundedSum);
  }

  Map<String, double> _calculateItemTotals(
    List<BillItem> items,
    List<Participant> participants,
    List<Assignment> assignments,
  ) {
    final totals = <String, double>{
      for (final participant in participants) participant.id: 0,
    };
    final assignmentByItem = {
      for (final assignment in assignments) assignment.itemId: assignment,
    };

    for (final item in items) {
      final assignment = assignmentByItem[item.id];
      final allocations = _buildAllocations(assignment, participants);
      if (allocations.isEmpty) {
        continue;
      }
      for (final allocation in allocations) {
        totals.update(
          allocation.participantId,
          (value) => value + item.totalPrice * allocation.fraction,
          ifAbsent: () => item.totalPrice * allocation.fraction,
        );
      }
    }

    return totals;
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

  Map<String, ParticipantChargeOverride> _overrideCharges(
    List<Participant> participants,
    Bill bill,
  ) {
    final overrides = {
      for (final override in bill.chargeOverrides)
        override.participantId: override,
    };
    return {
      for (final participant in participants)
        participant.id: overrides[participant.id] ??
            ParticipantChargeOverride(
              participantId: participant.id,
              tax: 0,
              service: 0,
            ),
    };
  }

  Map<String, ParticipantChargeOverride> _proportionalCharges(
    List<Participant> participants,
    Bill bill,
    Map<String, double> itemTotals,
  ) {
    final totalItems = itemTotals.values.fold(0.0, (sum, value) => sum + value);
    final result = <String, ParticipantChargeOverride>{};
    for (final participant in participants) {
      final itemsSubtotal = itemTotals[participant.id] ?? 0.0;
      final fraction = totalItems == 0
          ? (participants.isEmpty ? 0.0 : 1 / participants.length)
          : itemsSubtotal / totalItems;
      result[participant.id] = ParticipantChargeOverride(
        participantId: participant.id,
        tax: bill.tax * fraction,
        service: bill.serviceCharge * fraction,
      );
    }
    return result;
  }

  List<ParticipantSettlement> _applyRounding(
    List<ParticipantSettlement> settlements,
    double targetTotal,
  ) {
    final rounded = settlements
        .map(
          (entry) => ParticipantSettlement(
            participantId: entry.participantId,
            itemsSubtotal: roundToCents(entry.itemsSubtotal),
            taxShare: roundToCents(entry.taxShare),
            serviceShare: roundToCents(entry.serviceShare),
            totalOwed: roundToCents(entry.totalOwed),
          ),
        )
        .toList();

    final roundedSum = rounded.fold<double>(
      0,
      (sum, entry) => sum + entry.totalOwed,
    );
    var remainderCents = ((targetTotal - roundedSum) * 100).round();

    if (remainderCents == 0 || rounded.isEmpty) {
      return rounded;
    }

    final direction = remainderCents > 0 ? 1 : -1;
    remainderCents = remainderCents.abs();

    for (var i = 0; i < remainderCents; i++) {
      final index = i % rounded.length;
      final entry = rounded[index];
      rounded[index] = ParticipantSettlement(
        participantId: entry.participantId,
        itemsSubtotal: entry.itemsSubtotal,
        taxShare: entry.taxShare,
        serviceShare: entry.serviceShare,
        totalOwed: roundToCents(entry.totalOwed + 0.01 * direction),
      );
    }

    return rounded;
  }
}
