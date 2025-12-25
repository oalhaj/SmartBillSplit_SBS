import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsappShareService {
  Future<bool> share({required String message, String? phone}) async {
    if (phone == null || phone.isEmpty) {
      await Clipboard.setData(ClipboardData(text: message));
      return false;
    }
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
