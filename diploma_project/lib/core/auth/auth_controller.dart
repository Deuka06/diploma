import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

String? dioErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final d = data['detail'];
    if (d is String) return d;
    if (d is List && d.isNotEmpty) {
      final first = d.first;
      if (first is Map && first['msg'] is String) return first['msg'] as String;
    }
  }
  return e.message ?? 'Ошибка сети';
}

class AuthController extends ChangeNotifier {
  AuthController() {
    _client = ApiClient(tokenGetter: () => _token);
    _bootstrap();
  }

  static const _kToken = 'medi_access_token';

  late final ApiClient _client;
  String? _token;
  bool _ready = false;
  /// null — профиль ещё не подгружали; иначе флаг с сервера.
  bool? _onboardingCompleted;

  ApiClient get client => _client;
  bool get isReady => _ready;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  /// Нужен онбординг (только для залогиненных с известным профилем).
  bool get needsOnboarding => isLoggedIn && _onboardingCompleted == false;

  Future<void> _bootstrap() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString(_kToken);
    _ready = true;
    notifyListeners();
    if (_token != null && _token!.isNotEmpty) {
      unawaited(refreshUserProfile());
    }
  }

  Future<void> _persist(String? token) async {
    final p = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await p.remove(_kToken);
      _onboardingCompleted = null;
    } else {
      await p.setString(_kToken, token);
    }
    _token = token;
    notifyListeners();
  }

  /// Загрузить `/users/me` (onboarding_completed и т.д.).
  Future<void> refreshUserProfile() async {
    if (!isLoggedIn) {
      _onboardingCompleted = null;
      notifyListeners();
      return;
    }
    try {
      final r = await _client.dio.get<Map<String, dynamic>>('/users/me');
      _onboardingCompleted = r.data?['onboarding_completed'] == true;
      notifyListeners();
    } catch (_) {
      _onboardingCompleted = true;
      notifyListeners();
    }
  }

  Future<String?> patchProfile(Map<String, dynamic> body) async {
    try {
      await _client.dio.patch<Map<String, dynamic>>('/users/me', data: body);
      await refreshUserProfile();
      return null;
    } on DioException catch (e) {
      return dioErrorMessage(e);
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final t = res.data?['access_token'] as String?;
      if (t == null) return 'Нет токена в ответе';
      await _persist(t);
      await refreshUserProfile();
      return null;
    } on DioException catch (e) {
      return dioErrorMessage(e);
    }
  }

  Future<String?> register(String email, String password, String? fullName) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        },
      );
      final t = res.data?['access_token'] as String?;
      if (t == null) return 'Нет токена в ответе';
      await _persist(t);
      await refreshUserProfile();
      return null;
    } on DioException catch (e) {
      return dioErrorMessage(e);
    }
  }

  Future<void> logout() => _persist(null);

  @override
  void dispose() {
    super.dispose();
  }
}
