import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Auth state
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
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      token: clearUser ? null : (token ?? this.token),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Auth state notifier
class AuthNotifier extends AsyncNotifier<AuthState> {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  final _secureStorage = const FlutterSecureStorage();

  @override
  Future<AuthState> build() async {
    return _loadPersistedAuth();
  }

  Future<AuthState> _loadPersistedAuth() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (token != null && userJson != null) {
        final user = UserModel.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
        return AuthState(user: user, token: token);
      }
    } catch (e) {
      // Clear corrupt data
      await _clearStorage();
    }
    return const AuthState();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.login(email: email, password: password);

      await _persistAuth(result['token'] as String, result['user'] as UserModel);

      state = AsyncValue.data(AuthState(
        user: result['user'] as UserModel,
        token: result['token'] as String,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
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
    state = const AsyncValue.loading();

    try {
      final authService = ref.read(authServiceProvider);
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

      state = AsyncValue.data(AuthState(
        user: result['user'] as UserModel,
        token: result['token'] as String,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _clearStorage();
    state = const AsyncValue.data(AuthState());
  }

  Future<void> _persistAuth(String token, UserModel user) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearStorage() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

 UserModel? get currentUser => state.value?.user;
  String? get currentToken => state.value?.token;
  UserRole? get currentRole => state.value?.user?.role;
}

/// Auth providers
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).value?.user;
});

final currentRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(currentUserProvider)?.role;
});

final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.token;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).value?.isAuthenticated ?? false;
});
