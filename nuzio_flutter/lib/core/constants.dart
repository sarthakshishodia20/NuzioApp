import 'package:flutter/foundation.dart' show kIsWeb;

// Base API URL
// Web (Chrome): localhost
// Android emulator: 10.0.2.2 (maps to host machine localhost)
// Physical device: your LAN IP e.g. 192.168.1.x
const String kBaseUrl = kIsWeb
    ? 'http://localhost:3000/api'
    : 'https://nuzio-api-sarthak.loca.lt/api';
