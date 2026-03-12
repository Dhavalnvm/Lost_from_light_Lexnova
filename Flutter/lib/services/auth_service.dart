import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey   = 'auth_token';
  static const String _userIdKey  = 'user_id';
  static const String _nameKey    = 'user_name';
  static const String _emailKey   = 'user_email';

  String?      _token;
  UserProfile? _currentUser;

  String?      get token       => _token;
  UserProfile? get currentUser => _currentUser;

  /// Returns true only when a token exists AND it has not expired.
  bool get isLoggedIn {
    if (_token == null || _token!.isEmpty) return false;
    return !_isTokenExpired(_token!);
  }

  // ── JWT expiry check (no external package needed) ────────────────────────────
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Base64url → Base64 padding
      String payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2: payload += '=='; break;
        case 3: payload += '=';  break;
      }

      final decoded = utf8.decode(base64Decode(payload));
      final map     = jsonDecode(decoded) as Map<String, dynamic>;
      final exp     = map['exp'] as int?;
      if (exp == null) return false; // no exp claim → treat as valid

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true; // malformed token → treat as expired
    }
  }

  Future<void> saveAuth(AuthResponse auth) async {
    _token = auth.token;
    _currentUser = UserProfile(
      userId:         auth.userId,
      name:           auth.name,
      email:          auth.email,
      documentsCount: 0,
      createdAt:      '',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey,  auth.token);
    await prefs.setString(_userIdKey, auth.userId);
    await prefs.setString(_nameKey,   auth.name);
    await prefs.setString(_emailKey,  auth.email);
  }

  /// Loads persisted auth. Clears storage and returns false if the token has expired.
  Future<bool> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return false;

    if (_isTokenExpired(token)) {
      // Token exists but is expired — clear everything
      await _clearPrefs(prefs);
      return false;
    }

    _token = token;
    _currentUser = UserProfile(
      userId:         prefs.getString(_userIdKey) ?? '',
      name:           prefs.getString(_nameKey)   ?? '',
      email:          prefs.getString(_emailKey)  ?? '',
      documentsCount: 0,
      createdAt:      '',
    );
    return true;
  }

  Future<void> logout() async {
    _token       = null;
    _currentUser = null;
    final prefs  = await SharedPreferences.getInstance();
    await _clearPrefs(prefs);
  }

  Future<void> _clearPrefs(SharedPreferences prefs) async {
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
  }
}