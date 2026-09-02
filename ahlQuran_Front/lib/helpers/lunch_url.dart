import 'package:url_launcher/url_launcher.dart';

void launchURL(String url) async {
  Uri uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    throw 'Impossible d\'ouvrir l\'URL : $url';
  }
}
