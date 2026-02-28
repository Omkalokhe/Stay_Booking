import 'package:url_launcher/url_launcher.dart';

Future<void> openMap({required String fullAddress}) async {
  final normalizedAddress = fullAddress.trim();
  if (normalizedAddress.isEmpty) {
    throw const FormatException('Address is unavailable.');
  }

  final mapsUri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(normalizedAddress)}',
  );

  final canOpen = await canLaunchUrl(mapsUri);
  if (!canOpen) {
    throw Exception('No app available to open Google Maps.');
  }

  final didLaunch = await launchUrl(
    mapsUri,
    mode: LaunchMode.externalApplication,
  );
  if (!didLaunch) {
    throw Exception('Failed to launch Google Maps.');
  }
}
