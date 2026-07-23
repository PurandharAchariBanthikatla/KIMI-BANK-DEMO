import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});
  final KimiTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final credit = transaction.isCredit;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: credit ? AppColors.success.withOpacity(0.12) : AppColors.danger.withOpacity(0.1),
        child: Icon(
          credit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          color: credit ? AppColors.success : AppColors.danger,
          size: 20,
        ),
      ),
      title: Text(
        transaction.narration?.isNotEmpty == true
            ? transaction.narration!
            : transaction.type.replaceAll('_', ' '),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${formatDate(transaction.createdAt)} · ${transaction.referenceId}',
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: Text(
        '${credit ? '+' : '-'}${formatRupees(transaction.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: credit ? AppColors.success : AppColors.textPrimary,
        ),
      ),
    );
  }
}
