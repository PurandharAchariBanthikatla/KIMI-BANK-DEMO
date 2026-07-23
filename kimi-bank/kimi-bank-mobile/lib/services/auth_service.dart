import 'api_client.dart';

class AuthService {
  final _api = ApiClient.instance;

  Future<String?> requestOtp(String phoneNumber, String purpose) async {
    final res = await _api.post('/auth/otp/request',
        {'phoneNumber': phoneNumber, 'purpose': purpose}, auth: false);
    // devOtp is only ever non-null when the backend is running in dev mode.
    return res['devOtp'] as String?;
  }

  Future<void> signup({
    required String fullName,
    required String phoneNumber,
    required String otp,
  }) async {
    final res = await _api.post(
      '/auth/signup?otp=$otp',
      {'fullName': fullName, 'phoneNumber': phoneNumber},
      auth: false,
    );
    await _api.saveTokens(access: res['accessToken'], refresh: res['refreshToken']);
  }

  Future<void> setMpin(String mpin) async {
    await _api.post('/auth/mpin/set', {'mpin': mpin});
  }

  Future<void> login({required String phoneNumber, required String mpin}) async {
    final res = await _api.post(
      '/auth/login',
      {'phoneNumber': phoneNumber, 'mpin': mpin},
      auth: false,
    );
    await _api.saveTokens(access: res['accessToken'], refresh: res['refreshToken']);
  }

  Future<void> logout() async {
    await _api.clearTokens();
  }

  Future<bool> get isLoggedIn => _api.isLoggedIn;
}
