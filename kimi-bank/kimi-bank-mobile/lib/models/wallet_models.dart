class WalletBalance {
  final String walletId;
  final double balance;
  final String currency;
  final String status;

  WalletBalance({
    required this.walletId,
    required this.balance,
    required this.currency,
    required this.status,
  });

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      walletId: json['walletId'],
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'],
      status: json['status'],
    );
  }
}

class WalletTxn {
  final String id;
  final String type;
  final double amount;
  final double balanceAfter;
  final String? category;
  final String? counterparty;
  final String status;
  final DateTime createdAt;

  WalletTxn({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    this.category,
    this.counterparty,
    required this.status,
    required this.createdAt,
  });

  factory WalletTxn.fromJson(Map<String, dynamic> json) {
    return WalletTxn(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      category: json['category'],
      counterparty: json['counterparty'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
