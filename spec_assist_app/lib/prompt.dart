import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatGPT {
  final String apiKey;
  final String modelEndpoint;

  ChatGPT(this.apiKey, this.modelEndpoint);

  Future<String> getResponse(String prompt) async {
    final response = await http.post(Uri.parse(modelEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
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

// class ChatScreen extends StatefulWidget {
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
// class _ChatScreenState extends State<ChatScreen> {
//   ChatGPT? _chatGPT;

//   @override
//   void initState() {
//     super.initState();
//     _chatGPT = ChatGPT("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", "https://api.openai.com/v1/engine/gpt-3.5/completions");
//   }

//   Future<void> _sendQuery(String query) async {
//     try {
//       String response = await _chatGPT!.getResponse(query);
//       // Do something with the response, such as displaying it in the UI
//     } catch (e) {
//       // Handle the error gracefully
//       print(e.toString());
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Build the UI for the chat screen
//   }
// }
