import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// YOLOv8 सर्विस से मिली घटना
class SecurityDetection {
  const SecurityDetection({
    required this.label,
    required this.confidence,
    this.clipUrl = '',
    this.photoUrl = '',
    this.alert = true,
  });

  final String label;
  final int confidence;
  final String clipUrl;
  final String photoUrl;
  final bool alert;

  static SecurityDetection fromJson(Map<String, dynamic> j) => SecurityDetection(
        label: (j['label'] as String?) ?? 'अनधिकृत प्रवेश',
        confidence: ((j['confidence'] as num?) ?? 90).toInt(),
        clipUrl: (j['clip_url'] as String?) ?? '',
        photoUrl: (j['photo_url'] as String?) ?? '',
        alert: (j['alert'] as bool?) ?? true,
      );
}

/// AI सुरक्षा API — POST {base}/detect  {cam: "03"}
///
/// `AppConfig.securityApiBaseUrl` खाली हो तो `null` लौटाता है और
/// स्क्रीन अपना डेमो सिमुलेशन चलाती है।
class SecurityApi {
  const SecurityApi._();

  static bool get isConfigured => AppConfig.hasSecurityApi;

  static Future<SecurityDetection?> detect({required String camId}) async {
    if (!isConfigured) return null;
    try {
      final res = await http
          .post(
            Uri.parse('${AppConfig.securityApiBaseUrl}/detect'),
            headers: {
              'Content-Type': 'application/json',
              if (AppConfig.securityApiKey.isNotEmpty)
                'Authorization': 'Bearer ${AppConfig.securityApiKey}',
            },
            body: jsonEncode({'cam': camId}),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) return null;
      final event = body['event'];
      if (event is! Map<String, dynamic>) return null;
      return SecurityDetection.fromJson(event);
    } catch (_) {
      // नेटवर्क/सर्वर गड़बड़ — डेमो सिमुलेशन पर लौटें
      return null;
    }
  }

  /// सर्वर को भेजने वाला नमूना body (दस्तावेज़ के लिए)
  static Map<String, dynamic> sampleRequest(String camId) => {'cam': camId};

  /// सर्वर से अपेक्षित जवाब का नमूना
  static Map<String, dynamic> get sampleResponse => {
        'event': {
          'label': 'अनधिकृत प्रवेश',
          'confidence': 97,
          'alert': true,
          'photo_url': 'https://ai.example.org/events/evd-1.jpg',
          'clip_url': 'https://ai.example.org/events/evd-1.mp4',
        }
      };
}
