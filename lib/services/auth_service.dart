import '../models/session_user.dart';
import 'api_client.dart';

sealed class LoginOutcome {}

class LoginSession extends LoginOutcome {
  LoginSession({required this.accessToken, required this.user});

  final String accessToken;
  final SessionUser user;
}

class LoginOtpRequired extends LoginOutcome {
  LoginOtpRequired(this.challenge);

  final OtpChallenge challenge;
}

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<LoginOutcome> loginWithPassword(String email, String password) async {
    final data = await _api.request<dynamic>(
      '/api/v1/auth/login',
      method: 'POST',
      body: {'email': email.trim(), 'password': password},
      auth: false,
      fallbackError: 'Invalid email or password.',
    );

    if (data is! Map<String, dynamic>) {
      throw ApiError(0, 'Unexpected login response.');
    }

    if (_isOtpRequired(data)) {
      return LoginOtpRequired(_readOtpChallenge(data));
    }

    final token = '${data['access_token'] ?? ''}';
    final userRaw = data['user'];
    if (token.isEmpty || userRaw is! Map<String, dynamic>) {
      throw ApiError(0, 'Unexpected login response.');
    }
    return LoginSession(
      accessToken: token,
      user: SessionUser.fromApi(userRaw),
    );
  }

  Future<LoginSession> verifyLoginOtp(String challengeToken, String code) async {
    final data = await _api.request<Map<String, dynamic>>(
      '/api/v1/auth/verify-otp',
      method: 'POST',
      body: {'challengeToken': challengeToken, 'code': code.trim()},
      auth: false,
      fallbackError: 'Incorrect code. Try again.',
    );
    final token =
        '${data['access_token'] ?? data['accessToken'] ?? ''}'.trim();
    final userRaw = data['user'];
    if (token.isEmpty || userRaw is! Map<String, dynamic>) {
      throw ApiError(0, 'Sign-in incomplete. Try again.');
    }
    return LoginSession(
      accessToken: token,
      user: SessionUser.fromApi(userRaw),
    );
  }

  Future<OtpChallenge> resendLoginOtp(String challengeToken) async {
    final data = await _api.request<Map<String, dynamic>>(
      '/api/v1/auth/resend-otp',
      method: 'POST',
      body: {'challengeToken': challengeToken},
      auth: false,
      fallbackError: 'Could not resend code.',
    );
    return OtpChallenge(
      challengeToken: challengeToken,
      emailHint: '${data['emailHint'] ?? data['email_hint'] ?? ''}',
      otpExpiresIn:
          (data['otpExpiresIn'] as num?)?.toInt() ??
          (data['otp_expires_in'] as num?)?.toInt() ??
          600,
      message: '${data['message'] ?? 'Code sent'}',
    );
  }

  bool _isOtpRequired(Map<String, dynamic> row) {
    if (row['status'] == 'otp_required') return true;
    final token = row['challengeToken'] ?? row['challenge_token'];
    final access = row['access_token'];
    return token is String && token.isNotEmpty && access == null;
  }

  OtpChallenge _readOtpChallenge(Map<String, dynamic> data) {
    return OtpChallenge(
      challengeToken:
          '${data['challengeToken'] ?? data['challenge_token'] ?? ''}',
      emailHint: '${data['emailHint'] ?? data['email_hint'] ?? ''}',
      otpExpiresIn:
          (data['otpExpiresIn'] as num?)?.toInt() ??
          (data['otp_expires_in'] as num?)?.toInt() ??
          600,
      mustChangePassword:
          data['mustChangePassword'] == true ||
          data['must_change_password'] == true,
      message:
          '${data['message'] ?? 'We sent a verification code to your email'}',
    );
  }
}
