import 'package:uuid/uuid.dart';

import 'assignment.dart';
import 'bill_item.dart';
import 'participant.dart';

class ParticipantChargeOverride {
  const ParticipantChargeOverride({
    required this.participantId,
    required this.tax,
    required this.service,
  });

  final String participantId;
  final double tax;
  final double service;

  Map<String, dynamic> toJson() => {
        'participantId': participantId,
        'tax': tax,
        'service': service,
      };

  factory ParticipantChargeOverride.fromJson(Map<String, dynamic> json) {
    return ParticipantChargeOverride(
      participantId: json['participantId'] as String? ?? '',
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      service: (json['service'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Bill {
  Bill({
    String? id,
    required this.currency,
    required this.items,
    required this.participants,
    required this.assignments,
    required this.total,
    this.merchantName,
    this.subtotal,
    this.tax = 0,
    this.serviceCharge = 0,
    this.overrideCharges = false,
    this.chargeOverrides = const [],
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String currency;
  final String? merchantName;
  final double? subtotal;
  final double tax;
  final double serviceCharge;
  final double total;
  final List<BillItem> items;
  final List<Participant> participants;
  final List<Assignment> assignments;
  final bool overrideCharges;
  final List<ParticipantChargeOverride> chargeOverrides;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'currency': currency,
        'merchantName': merchantName,
        'subtotal': subtotal,
        'tax': tax,
        'serviceCharge': serviceCharge,
        'total': total,
        'items': items.map((item) => item.toJson()).toList(),
        'participants': participants.map((p) => p.toJson()).toList(),
        'assignments': assignments.map((a) => a.toJson()).toList(),
        'overrideCharges': overrideCharges,
        'chargeOverrides': chargeOverrides.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String?,
      currency: json['currency'] as String? ?? 'AED',
      merchantName: json['merchantName'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((entry) => BillItem.fromJson(entry as Map<String, dynamic>))
          .toList(),
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((entry) => Participant.fromJson(entry as Map<String, dynamic>))
          .toList(),
      assignments: (json['assignments'] as List<dynamic>? ?? [])
          .map((entry) => Assignment.fromJson(entry as Map<String, dynamic>))
          .toList(),
      overrideCharges: json['overrideCharges'] as bool? ?? false,
      chargeOverrides: (json['chargeOverrides'] as List<dynamic>? ?? [])
          .map((entry) =>
              ParticipantChargeOverride.fromJson(entry as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
