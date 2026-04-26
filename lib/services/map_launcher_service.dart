import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncherService {
  const MapLauncherService();

  static const MethodChannel _channel = MethodChannel('postcard_actions');

  Future<void> openGoogleMaps({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched) {
      throw Exception('無法開啟 Google Maps。');
    }
  }

  Future<void> openBlueMap({required double lat, required double lng}) async {
    if (kIsWeb) {
      throw Exception('藍色地圖只支援 Android。');
    }

    try {
      await _channel.invokeMethod('openBlueMap', {'lat': lat, 'lng': lng});
    } on PlatformException catch (error) {
      throw Exception(error.message ?? '無法開啟藍色地圖。');
    }
  }
}
