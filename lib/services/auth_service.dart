import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/user_model.dart';

/// Auth service — handles login/register API calls
/// Falls back to demo mode when backend is unreachable
class AuthService {
  final String baseUrl;

  AuthService({String? baseUrl})
      : baseUrl = baseUrl ?? dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // --- Demo mode: bypass backend if using demo credentials ---
    if (_isDemoCredential(email, password)) {
      return _demoLogin(email);
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'token': data['token'] as String,
          'user': UserModel.fromJson(data['user'] as Map<String, dynamic>),
        };
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } on SocketException {
      throw Exception('Cannot connect to server. Please check your connection.');
    } on http.ClientException {
      throw Exception('Network error. Please try again.');
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
    String? nationalId,
    String? region,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'password': password,
              'firstName': firstName,
              'lastName': lastName,
              'phone': phone,
              'role': role.value,
              'nationalId': nationalId,
              'region': region,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        return {
          'token': data['token'] as String,
          'user': UserModel.fromJson(data['user'] as Map<String, dynamic>),
        };
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } on SocketException {
      // Demo fallback for development
      final user = UserModel(
        id: 'new-user-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        role: role,
        region: region,
        nationalId: nationalId,
        createdAt: DateTime.now(),
        isVerified: false,
        isActive: true,
      );
      return {'token': 'demo-token-${user.id}', 'user': user};
    }
  }

  bool _isDemoCredential(String email, String password) {
    const demoAccounts = {
      'citizen@kamer.cm': 'demo123',
      'officer@mindcaf.cm': 'demo123',
      'surveyor@kamer.cm': 'demo123',
    };
    return demoAccounts[email] == password;
  }

  Map<String, dynamic> _demoLogin(String email) {
    UserModel user;
    switch (email) {
      case 'officer@mindcaf.cm':
        user = DemoUsers.officer;
        break;
      case 'surveyor@kamer.cm':
        user = DemoUsers.surveyor;
        break;
      default:
        user = DemoUsers.citizen;
    }
    return {'token': 'demo-token-${user.id}', 'user': user};
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
