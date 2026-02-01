import 'package:url_launcher/url_launcher.dart';

class ContactUtils {
  static Future<void> callNumber(String? number) async {
    if (number == null || number.isEmpty) return;
    final Uri uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> openWhatsApp(String? number, {String? message}) async {
    if (number == null || number.isEmpty) return;
    
    // Remove non-numeric characters except for leading +
    String formattedNumber = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (!formattedNumber.startsWith('+') && formattedNumber.isNotEmpty) {
      // Default to Saudi Arabia if no country code? User mentioned Riyadh.
      // Let's assume the number might need a country code if it doesn't have one.
      if (formattedNumber.length == 9 && formattedNumber.startsWith('5')) {
        formattedNumber = '+966$formattedNumber';
      } else if (formattedNumber.length == 10 && formattedNumber.startsWith('05')) {
        formattedNumber = '+966${formattedNumber.substring(1)}';
      }
    }

    String urlString = 'https://wa.me/$formattedNumber';
    if (message != null && message.isNotEmpty) {
      urlString += '?text=${Uri.encodeComponent(message)}';
    }

    final Uri uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
