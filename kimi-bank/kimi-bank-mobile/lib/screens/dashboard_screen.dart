import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/wallet_service.dart';
import '../models/wallet_models.dart';
import '../theme/app_theme.dart';
import 'topup_screen.dart';
import 'pay_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _walletService = WalletService();
  WalletBalance? _balance;
  List<WalletTxn> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _walletService.getBalance(),
        _walletService.getStatement(size: 10),
      ]);
      setState(() {
        _balance = results[0] as WalletBalance;
        _transactions = results[1] as List<WalletTxn>;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KIMI BANK'), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _BalanceCard(
                    balance: _balance?.balance ?? 0,
                    currencyFormat: _currency,
                    onTopUp: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TopUpScreen()),
                      );
                      _load();
                    },
                    onPay: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PayScreen()),
                      );
                      _load();
                    },
                  ),
                  const SizedBox(height: 28),
                  Text('Recent activity', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (_transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('No transactions yet',
                          style: Theme.of(context).textTheme.bodySmall),
                    )
                  else
                    ..._transactions.map((t) => _TxnTile(txn: t, currencyFormat: _currency)),
                ],
              ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final NumberFormat currencyFormat;
  final VoidCallback onTopUp;
  final VoidCallback onPay;

  const _BalanceCard({
    required this.balance,
    required this.currencyFormat,
    required this.onTopUp,
    required this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wallet balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            currencyFormat.format(balance),
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size.fromHeight(46),
                  ),
                  onPressed: onTopUp,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add money'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  onPressed: onPay,
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Pay'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final WalletTxn txn;
  final NumberFormat currencyFormat;

  const _TxnTile({required this.txn, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.type == 'CREDIT';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCredit ? AppColors.success.withOpacity(0.1) : AppColors.danger.withOpacity(0.1),
          child: Icon(
            isCredit ? Icons.south_west : Icons.north_east,
            color: isCredit ? AppColors.success : AppColors.danger,
            size: 18,
          ),
        ),
        title: Text(txn.category ?? txn.type),
        subtitle: Text(
          txn.counterparty != null ? 'To/from: ${txn.counterparty}' : txn.status,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'}${currencyFormat.format(txn.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isCredit ? AppColors.success : AppColors.danger,
          ),
        ),
      ),
    );
  }
}
