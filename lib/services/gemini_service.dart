import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyCGvJWMOOJFghObRuepJCjbpM-pTs0u6fo';

  // Future<String> getFarmingAdvice(
  //   List<Map<String, dynamic>> weatherData,
  // ) async {
  //   try {
  //     final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

  //     // Construct the prompt
  //     StringBuffer prompt = StringBuffer();
  //     prompt.writeln(
  //       "You are an expert agricultural advisor. Based on the following weather forecast for the next 4 days, provide specific farming advice.",
  //     );
  //     prompt.writeln(
  //       "Focus on irrigation, pest control, and sowing/harvesting.",
  //     );
  //     prompt.writeln("Keep it concise and actionable for a farmer.");
  //     prompt.writeln("\nForecast Data:");

  //     for (var day in weatherData) {
  //       prompt.writeln(
  //         "- ${day['date']}: Temp ${day['temp']}°C, Humidity ${day['humidity']}%, Pressure ${day['pressure']}hPa, Wind ${day['windSpeed']}m/s (${day['windDeg']}°), ${day['description']}",
  //       );
  //     }

  //     final content = [Content.text(prompt.toString())];
  //     final response = await model.generateContent(content);

  //     if (response.text != null && response.text!.isNotEmpty) {
  //       return response.text!;
  //     } else {
  //       return "No advice available at the moment.";
  //     }
  //   } catch (e) {
  //     print('Gemini Service Error: $e');
  //     throw Exception('AI Error: $e');
  //   }
  // }
  
  Future<String> getFarmingAdvice(
    List<Map<String, dynamic>> weatherData,
  ) async {
      try {
        // 1. Setup the System Instruction separately
        final systemInstruction = Content.system(
          "You are an expert agricultural advisor. Focus on irrigation, pest control, and sowing/harvesting. "
          "Keep it concise and actionable. Do not provide any additional information. Remove all the symbols from the text. And make all titles appear in bold. The text will be given to a farmer so make it sound simple and include some more text covering some details. Do not include any other text apart from the information. Just give the advice and don't give any other data accuracy or logical check. Just start from the advice. "
        );

        // 2. Initialize the model with the systemInstruction parameter
        final model = GenerativeModel(
          model: 'gemini-3-flash-preview', // Try 'models/gemini-1.5-flash' if 'gemini-1.5-flash' fails
          apiKey: _apiKey,
          systemInstruction: systemInstruction,
        );

        // 3. Construct ONLY the data for the prompt
        StringBuffer dataBuffer = StringBuffer();
        dataBuffer.writeln("Forecast Data:");
        for (var day in weatherData) {
          dataBuffer.writeln(
            "- ${day['date']}: Temp ${day['temp']}°C, Humidity ${day['humidity']}%, ${day['description']}",
          );
        }

        final content = [Content.text(dataBuffer.toString())];
        final response = await model.generateContent(content);

        return response.text ?? "No advice available.";
      } catch (e) {
        // As requested, I'm pointing out that catching 'Exception' 
        // might hide specific network errors. Use 'print' for debugging!
        print('Gemini Service Error: $e');
        throw Exception('AI Error: $e');
      }
    }


}
