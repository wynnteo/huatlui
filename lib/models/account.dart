import 'enums.dart';

/// A broker / platform. Deliberately has no currency: one brokerage account
/// commonly holds SGD, USD and MYR instruments at once.
class Account {
  final String id;
  final String name;
  final BrokerType brokerType;
  final bool isActive;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.name,
    this.brokerType = BrokerType.brokerage,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'brokerType': brokerType.name,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String,
        brokerType: enumByName(BrokerType.values, j['brokerType'], BrokerType.brokerage),
        isActive: (j['isActive'] as bool?) ?? true,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
