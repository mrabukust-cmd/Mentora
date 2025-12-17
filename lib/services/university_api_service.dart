import 'dart:convert';
import 'package:http/http.dart' as http;

class UniversityApiService {
  static Future<List<String>> fetchUniversities(String country) async {
    final url =
        Uri.parse("http://universities.hipolabs.com/search?country=$country");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => e['name'].toString()).toList();
    } else {
      throw Exception("Failed to load universities");
    }
  }
}
