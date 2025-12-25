class ParticipantSettlement {
  const ParticipantSettlement({
    required this.participantId,
    required this.itemsSubtotal,
    required this.taxShare,
    required this.serviceShare,
    required this.totalOwed,
  });

  final String participantId;
  final double itemsSubtotal;
  final double taxShare;
  final double serviceShare;
  final double totalOwed;
}

class Settlement {
  const Settlement({
    required this.participants,
    required this.unroundedTotal,
  });

  final List<ParticipantSettlement> participants;
  final double unroundedTotal;
}
