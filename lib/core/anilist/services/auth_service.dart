import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class AniListAuthService {
  static String get clientId => dotenv.env['ANILIST_CLIENT_ID'] ?? '';
  static String get clientSecret => dotenv.env['ANILIST_CLIENT_SECRET'] ?? '';
  static const String redirectUri = 'shonenx://callback';

  // روابط AniList للأوث فقط
  static const String authUrl = 'https://anilist.co/api/v2/oauth/authorize';
  static const String tokenUrl = 'https://anilist.co/api/v2/oauth/token';

  // روابط APIs الأساسية والاحتياطية
  static String get primaryApi => dotenv.env['API_URL'] ?? 'https://api.jikan.moe/v4';
  static String get backupApi => dotenv.env['BACKUP_API_URL'] ?? 'https://kitsu.io/api/edge';

  // ✅ تسجيل الدخول عبر AniList OAuth
  Future<String?> authenticate() async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: '$authUrl?client_id=$clientId&redirect_uri=$redirectUri&response_type=code',
        callbackUrlScheme: 'shonenx',
        options: const FlutterWebAuth2Options(),
      );

      final code = Uri.parse(result).queryParameters['code'];
      return code;
    } catch (e) {
      debugPrint('❌ خطأ أثناء عملية تسجيل الدخول: $e');
      return null;
    }
  }

  // ✅ الحصول على Access Token
  Future<String?> getAccessToken(String code) async {
    try {
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "grant_type": "authorization_code",
          "client_id": clientId,
          "client_secret": clientSecret,
          "redirect_uri": redirectUri,
          "code": code,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'];
      } else {
        debugPrint('⚠️ فشل في جلب Access Token: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ خطأ أثناء جلب Access Token: $e');
      return null;
    }
  }

  // ✅ التحقق من API الأساسي والاحتياطي
  Future<String> getWorkingApi() async {
    try {
      final response = await http.get(Uri.parse(primaryApi));
      if (response.statusCode == 200) {
        debugPrint("✅ API الأساسي شغال: $primaryApi");
        return primaryApi;
      } else {
        debugPrint("⚠️ API الأساسي فشل: $primaryApi");
        debugPrint("🔄 التجربة مع API الاحتياطي...");
        return backupApi;
      }
    } catch (_) {
      debugPrint("⚠️ API الأساسي متعطل، التبديل إلى API الاحتياطي");
      return backupApi;
    }
  }
}
