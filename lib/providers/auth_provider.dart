import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

// Simple auth state – not AsyncNotifier
class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null && token != null;

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  final _secureStorage = const FlutterSecureStorage();

  AuthNotifier() : super(const AuthState()) {
    _loadPersistedAuth();
  }

  Future<void> _loadPersistedAuth() async {
    if (kIsWeb) return;

    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (token != null && userJson != null) {
        final user = UserModel.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
        state = state.copyWith(user: user, token: token);
      }
    } catch (e) {
      await _clearStorage();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authService = AuthService();
      final result = await authService.login(email: email, password: password);

      await _persistAuth(result['token'] as String, result['user'] as UserModel);
      state = state.copyWith(
        user: result['user'] as UserModel,
        token: result['token'] as String,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
    String? nationalId,
    String? region,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final authService = AuthService();
      final result = await authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        role: role,
        nationalId: nationalId,
        region: region,
      );

      await _persistAuth(result['token'] as String, result['user'] as UserModel);
      state = state.copyWith(
        user: result['user'] as UserModel,
        token: result['token'] as String,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _clearStorage();
    state = const AuthState();
  }

  Future<void> _persistAuth(String token, UserModel user) async {
    if (kIsWeb) return;
    await _secureStorage.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearStorage() async {
    if (kIsWeb) return;
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}

// Change provider to StateNotifierProvider
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).user;
});

final currentRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});