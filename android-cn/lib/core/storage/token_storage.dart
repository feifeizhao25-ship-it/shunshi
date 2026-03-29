// Token Storage Service
// Securely stores authentication tokens

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiryKey = 'token_expiry';
  
  final FlutterSecureStorage _storage;
  
  TokenStorage() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Save tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    if (expiresAt != null) {
      await _storage.write(
        key: _tokenExpiryKey,
        value: expiresAt.toIso8601String(),
      );
    }
  }
  
  // Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }
  
  // Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
  
  // Check if token is expired
  Future<bool> isTokenExpired() async {
    final expiryStr = await _storage.read(key: _tokenExpiryKey);
    if (expiryStr == null) return true;
    
    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) return true;
    
    return DateTime.now().isAfter(expiry);
  }
  
  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token == null) return false;
    
    final expired = await isTokenExpired();
    return !expired;
  }
  
  // Clear all tokens (logout)
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
  }
  
  // Refresh token
  Future<bool> refreshToken(Future<Map<String, String>> Function(String) refreshFn) async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;
    
    try {
      final newTokens = await refreshFn(refreshToken);
      await saveTokens(
        accessToken: newTokens['access'] ?? '',
        refreshToken: newTokens['refresh'] ?? refreshToken,
      );
      return true;
    } catch (e) {
      await clearTokens();
      return false;
    }
  }
}

// Global instance
final tokenStorage = TokenStorage();
