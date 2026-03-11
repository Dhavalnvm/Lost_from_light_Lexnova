import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';

  // In-memory cache
  String? _token;
  UserProfile? _currentUser;

  String? get token => _token;
  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<void> saveAuth(AuthResponse auth) async {
    _token = auth.token;
    _currentUser = UserProfile(
      userId: auth.userId,
      name: auth.name,
      email: auth.email,
      documentsCount: 0,
      createdAt: '',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, auth.token);
    await prefs.setString(_userIdKey, auth.userId);
    await prefs.setString(_nameKey, auth.name);
    await prefs.setString(_emailKey, auth.email);
  }

  Future<bool> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return false;
    _token = token;
    _currentUser = UserProfile(
      userId: prefs.getString(_userIdKey) ?? '',
      name: prefs.getString(_nameKey) ?? '',
      email: prefs.getString(_emailKey) ?? '',
      documentsCount: 0,
      createdAt: '',
    );
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
  }
}