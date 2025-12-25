import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/assignment.dart';
import '../../domain/models/bill.dart';
import '../../domain/models/bill_item.dart';
import '../../domain/models/participant.dart';
import '../../infra/ocr/receipt_parser.dart';

class BillDraftState {
  BillDraftState({
    required this.currency,
    required this.items,
    required this.participants,
    required this.assignments,
    required this.tax,
    required this.serviceCharge,
    required this.total,
    required this.subtotal,
    required this.merchantName,
    required this.overrideCharges,
    required this.chargeOverrides,
  });

  final String currency;
  final List<BillItem> items;
  final List<Participant> participants;
  final List<Assignment> assignments;
  final double tax;
  final double serviceCharge;
  final double total;
  final double? subtotal;
  final String? merchantName;
  final bool overrideCharges;
  final List<ParticipantChargeOverride> chargeOverrides;

  BillDraftState copyWith({
    String? currency,
    List<BillItem>? items,
    List<Participant>? participants,
    List<Assignment>? assignments,
    double? tax,
    double? serviceCharge,
    double? total,
    double? subtotal,
    String? merchantName,
    bool? overrideCharges,
    List<ParticipantChargeOverride>? chargeOverrides,
  }) {
    return BillDraftState(
      currency: currency ?? this.currency,
      items: items ?? this.items,
      participants: participants ?? this.participants,
      assignments: assignments ?? this.assignments,
      tax: tax ?? this.tax,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      total: total ?? this.total,
      subtotal: subtotal ?? this.subtotal,
      merchantName: merchantName ?? this.merchantName,
      overrideCharges: overrideCharges ?? this.overrideCharges,
      chargeOverrides: chargeOverrides ?? this.chargeOverrides,
    );
  }

  Bill toBill() {
    return Bill(
      currency: currency,
      items: items,
      participants: participants,
      assignments: assignments,
      tax: tax,
      serviceCharge: serviceCharge,
      total: total,
      subtotal: subtotal,
      merchantName: merchantName,
      overrideCharges: overrideCharges,
      chargeOverrides: chargeOverrides,
    );
  }

  factory BillDraftState.fromParse(ReceiptParseResult result) {
    return BillDraftState(
      currency: 'AED',
      items: result.items
          .map(
            (item) => BillItem(
              name: item.name,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
            ),
          )
          .toList(),
      participants: [],
      assignments: [],
      tax: result.tax ?? 0,
      serviceCharge: result.serviceCharge ?? 0,
      total: result.total ?? 0,
      subtotal: result.subtotal,
      merchantName: result.merchantName,
      overrideCharges: false,
      chargeOverrides: const [],
    );
  }

  factory BillDraftState.empty() {
    return BillDraftState(
      currency: 'AED',
      items: [],
      participants: [],
      assignments: [],
      tax: 0,
      serviceCharge: 0,
      total: 0,
      subtotal: null,
      merchantName: null,
      overrideCharges: false,
      chargeOverrides: const [],
    );
  }
}

class BillDraftNotifier extends StateNotifier<BillDraftState> {
  BillDraftNotifier() : super(BillDraftState.empty());

  void updateFromParse(ReceiptParseResult result) {
    state = BillDraftState.fromParse(result);
  }

  void updateMerchant(String value) {
    state = state.copyWith(merchantName: value);
  }

  void updateTotals({
    double? subtotal,
    double? tax,
    double? serviceCharge,
    double? total,
  }) {
    state = state.copyWith(
      subtotal: subtotal ?? state.subtotal,
      tax: tax ?? state.tax,
      serviceCharge: serviceCharge ?? state.serviceCharge,
      total: total ?? state.total,
    );
  }
}

final billDraftProvider =
    StateNotifierProvider<BillDraftNotifier, BillDraftState>(
  (ref) => BillDraftNotifier(),
);
