import 'dart:convert';
import 'package:http/http.dart' as http;
import 'keys.dart';

class ChatGPT {
  final String modelEndpoint = 'https://api.openai.com/v1/completions';

  Future<String> getResponse(String prompt) async {
    final response = await http.post(Uri.parse(modelEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $API_KEY',
        },
        body: jsonEncode({
          'model': 'text-davinci-003',
          'prompt': prompt,
          'max_tokens': 64,
          'temperature': 0.5,
          // 'n': 1,
          // 'stop': ['\n']
        }));

    if (response.statusCode == 200) {
      Map<String, dynamic> responseBody = jsonDecode(response.body);
      // print(response.body);
      List<String> choices = responseBody['choices'][0]['text'].split("\n");
      print(choices[2]);
      return choices[2];
    } else {
      throw Exception('Failed to load response: ${response.statusCode}');
    }
  }
}
