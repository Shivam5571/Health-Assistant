import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://healthfly-backend-1.onrender.com";

  static Future<Map<String, dynamic>> getRecommendation({
    required int age,
    required double height,
    required double weight,
    required String goal,
    required String condition,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/recommend"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "age": age,
        "height": height,
        "weight": weight,
        "goal": goal,
        "condition": condition,
      }),
    );

    return jsonDecode(response.body);
  }


static Future<List<dynamic>> checkIngredients(String text) async {
  try {
    final uri = Uri.parse("http://127.0.0.1:8000/check-ingredients");

    final response = await http.post(
      uri,
      headers: const {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "ingredients": text
            .split(",")
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      }),
    );

    // 🔥 HARD DEBUG (DON'T REMOVE)
    print("STATUS CODE => ${response.statusCode}");
    print("RAW BODY => ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("HTTP ${response.statusCode}");
    }

    final decoded = jsonDecode(response.body);

    if (decoded == null || decoded["results"] == null) {
      throw Exception("Invalid response format");
    }

    return decoded["results"] as List<dynamic>;
  } catch (e) {
    print("CHECK INGREDIENT ERROR => $e");
    rethrow;
  }
}


static Future<String> chat(String message) async {
  try {
    final response = await http.post(
      Uri.parse("$baseUrl/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // ✅ safety check
      if (decoded != null && decoded["reply"] != null) {
        return decoded["reply"].toString();
      } else {
        return "AI did not return a response.";
      }
    } else {
      return "AI service error (${response.statusCode}).";
    }
  } catch (e) {
    return "AI is currently unavailable.";
  }
}



}


