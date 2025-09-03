import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

class AnimeApiClient {
  static String get _primaryApi =>
      dotenv.env['API_URL'] ?? 'https://api.jikan.moe/v4';
  static String get _backupApi =>
      dotenv.env['BACKUP_API_URL'] ?? 'https://kitsu.io/api/edge';

  /// يختار الـ API شغال (Jikan أو Kitsu)
  static Future<String> _getWorkingApi() async {
    try {
      final response = await http.get(Uri.parse(_primaryApi));
      if (response.statusCode == 200) {
        debugPrint("✅ API الأساسي شغال: $_primaryApi");
        return _primaryApi;
      } else {
        debugPrint("⚠️ API الأساسي فشل → التجربة مع الاحتياطي...");
        return _backupApi;
      }
    } catch (_) {
      debugPrint("⚠️ API الأساسي متعطل → التحويل إلى الاحتياطي");
      return _backupApi;
    }
  }

  /// دالة عامة لجلب البيانات من API مع Fallback تلقائي
  static Future<Map<String, dynamic>> fetchData(String endpoint,
      {Map<String, String>? params}) async {
    final baseUrl = await _getWorkingApi();
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: params);
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            '❌ فشل في جلب البيانات من $baseUrl: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في الاتصال بالـ API: $e');
      rethrow;
    }
  }
}
