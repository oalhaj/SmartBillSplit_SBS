import 'package:uuid/uuid.dart';

class Participant {
  Participant({
    String? id,
    required this.name,
    this.phone,
    this.isPayer = false,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String name;
  final String? phone;
  final bool isPayer;

  Participant copyWith({
    String? id,
    String? name,
    String? phone,
    bool? isPayer,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isPayer: isPayer ?? this.isPayer,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'isPayer': isPayer,
      };

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      isPayer: json['isPayer'] as bool? ?? false,
    );
  }
}
