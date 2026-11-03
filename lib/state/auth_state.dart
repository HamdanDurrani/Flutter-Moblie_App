import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

sealed class AuthLoginResult {}

class AuthLoginOk extends AuthLoginResult {
  AuthLoginOk(this.user);
  final SessionUser user;
}

class AuthLoginNeedsOtp extends AuthLoginResult {
  AuthLoginNeedsOtp(this.challenge);
  final OtpChallenge challenge;
}

class AuthLoginFailed extends AuthLoginResult {
  AuthLoginFailed(this.error);
  final String error;
}

class AuthState extends ChangeNotifier {
  AuthState() : api = ApiClient() {
    _auth = AuthService(api);
  }

  final ApiClient api;
  late final AuthService _auth;

  SessionUser? user;
  bool loading = true;
  String? pendingToken;

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(kStorageSessionKey);
      final token = prefs.getString(kStorageTokenKey);
      if (raw != null && token != null && token.isNotEmpty) {
        api.setAccessToken(token);
        user = SessionUser.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } else {
        api.setAccessToken(null);
        user = null;
      }
    } catch (_) {
      api.setAccessToken(null);
      user = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<AuthLoginResult> login(String email, String password) async {
    try {
      final result = await _auth.loginWithPassword(email, password);
      switch (result) {
        case LoginOtpRequired(:final challenge):
          pendingToken = null;
          if (challenge.challengeToken.isEmpty) {
            return AuthLoginFailed('Could not start email verification.');
          }
          return AuthLoginNeedsOtp(challenge);
        case LoginSession(:final accessToken, :final user):
          pendingToken = accessToken;
          return AuthLoginOk(user);
      }
    } on ApiError catch (err) {
      if (err.status == 401) {
        return AuthLoginFailed('Invalid email or password.');
      }
      return AuthLoginFailed(err.detail);
    } catch (_) {
      return AuthLoginFailed(
        'Could not reach the server. Check that the API is running.',
      );
    }
  }

  Future<AuthLoginResult> verifyOtp(String challengeToken, String code) async {
    try {
      final session = await _auth.verifyLoginOtp(challengeToken, code);
      pendingToken = session.accessToken;
      return AuthLoginOk(session.user);
    } on ApiError catch (err) {
      return AuthLoginFailed(err.detail);
    } catch (_) {
      return AuthLoginFailed('Incorrect code. Try again.');
    }
  }

  Future<OtpChallenge?> resendOtp(String challengeToken) async {
    try {
      return await _auth.resendLoginOtp(challengeToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> activateSession(SessionUser session, {String? accessToken}) async {
    final token = (accessToken ?? pendingToken)?.trim();
    if (token == null || token.isEmpty) {
      throw ApiError(0, 'Missing access token.');
    }
    api.setAccessToken(token);
    user = session;
    pendingToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kStorageSessionKey, jsonEncode(session.toJson()));
    await prefs.setString(kStorageTokenKey, token);
    notifyListeners();
  }

  Future<void> logout() async {
    api.setAccessToken(null);
    pendingToken = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kStorageSessionKey);
    await prefs.remove(kStorageTokenKey);
    notifyListeners();
  }
}
