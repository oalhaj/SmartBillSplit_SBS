enum SplitMode {
  single,
  selectedEqual,
  allEqual,
  customPercent,
}

class ItemAllocation {
  const ItemAllocation({
    required this.participantId,
    required this.fraction,
  });

  final String participantId;
  final double fraction;

  Map<String, dynamic> toJson() => {
        'participantId': participantId,
        'fraction': fraction,
      };

  factory ItemAllocation.fromJson(Map<String, dynamic> json) {
    return ItemAllocation(
      participantId: json['participantId'] as String? ?? '',
      fraction: (json['fraction'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Assignment {
  const Assignment({
    required this.itemId,
    required this.mode,
    required this.allocations,
  });

  final String itemId;
  final SplitMode mode;
  final List<ItemAllocation> allocations;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'mode': mode.name,
        'allocations': allocations.map((a) => a.toJson()).toList(),
      };

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      itemId: json['itemId'] as String? ?? '',
      mode: SplitMode.values.firstWhere(
        (mode) => mode.name == json['mode'],
        orElse: () => SplitMode.allEqual,
      ),
      allocations: (json['allocations'] as List<dynamic>? ?? [])
          .map((entry) => ItemAllocation.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }
}
