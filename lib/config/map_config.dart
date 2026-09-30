import 'package:flutter_dotenv/flutter_dotenv.dart';

const _compileTimeOpenRouteServiceApiKey = String.fromEnvironment(
  'OPENROUTESERVICE_API_KEY',
);

String get openRouteServiceApiKey {
  try {
    final value = dotenv.maybeGet('OPENROUTESERVICE_API_KEY')?.trim() ?? '';
    return value.isNotEmpty ? value : _compileTimeOpenRouteServiceApiKey;
  } catch (_) {
    return _compileTimeOpenRouteServiceApiKey;
  }
}

const openStreetMapTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const mapUserAgentPackageName = 'vn.xanhsm.ridebooking.app';
