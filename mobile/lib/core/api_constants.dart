import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl {
    return dotenv.env['API_URL'] ?? "http://localhost:8000/api";
  }
}
