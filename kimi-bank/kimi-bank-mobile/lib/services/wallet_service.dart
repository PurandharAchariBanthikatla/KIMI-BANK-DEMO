import 'package:uuid/uuid.dart';
import 'api_client.dart';
import '../models/wallet_models.dart';

class WalletService {
  final _api = ApiClient.instance;
  final _uuid = const Uuid();

  Future<WalletBalance> getBalance() async {
    final res = await _api.get('/wallet/balance');
    return WalletBalance.fromJson(res);
  }

  Future<List<WalletTxn>> getStatement({int page = 0, int size = 20}) async {
    final res = await _api.get('/wallet/statement',
        query: {'page': '$page', 'size': '$size'});
    return (res as List).map((e) => WalletTxn.fromJson(e)).toList();
  }

  Future<WalletTxn> topUp(double amount, {String? remarks}) async {
    final res = await _api.post('/wallet/topup', {
      'amount': amount,
      'txnRef': 'TOPUP-${_uuid.v4()}',
      'remarks': remarks,
    });
    return WalletTxn.fromJson(res);
  }

  Future<WalletTxn> pay(double amount, String merchantId, {String? remarks}) async {
    final res = await _api.post('/wallet/pay', {
      'amount': amount,
      'merchantId': merchantId,
      'txnRef': 'PAY-${_uuid.v4()}',
      'remarks': remarks,
    });
    return WalletTxn.fromJson(res);
  }

  Future<void> transfer(double amount, String toUserId, {String? remarks}) async {
    await _api.post('/wallet/transfer', {
      'toUserId': toUserId,
      'amount': amount,
      'txnRef': 'XFER-${_uuid.v4()}',
      'remarks': remarks,
    });
  }
}
