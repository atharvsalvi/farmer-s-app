import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // TODO: Replace with actual OpenWeatherMap API Key
  static const String _apiKey = '1a016acee81dd5d6d86ccbb801a2a71d';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  Future<Map<String, dynamic>> getForecast(double lat, double lon) async {
    final url = Uri.parse(
      '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Weather Service Error: $e');
      throw Exception('Failed to connect to weather service');
    }
  }

  Future<List<Map<String, dynamic>>> getNext4DaysForecast(
    double lat,
    double lon,
  ) async {
    final data = await getForecast(lat, lon);
    final List<dynamic> list = data['list'];

    // Filter to get one reading per day (e.g., at 12:00 PM) for the next 4 days
    // OpenWeatherMap returns data every 3 hours.

    List<Map<String, dynamic>> dailyForecast = [];
    String currentDay = '';

    for (var item in list) {
      String dateText = item['dt_txt']; // "2022-08-30 15:00:00"
      String day = dateText.split(' ')[0];

      if (day != currentDay && dailyForecast.length < 4) {
        // Prefer noon data if available, or just the first one of the day
        if (dateText.contains('12:00:00') || currentDay == '') {
          dailyForecast.add({
            'date': day,
            'temp': item['main']['temp'],
            'humidity': item['main']['humidity'],
            'pressure': item['main']['pressure'],
            'windSpeed': item['wind']['speed'],
            'windDeg': item['wind']['deg'],
            'description': item['weather'][0]['description'],
          });
          currentDay = day;
        }
      }
    }

    return dailyForecast;
  }
}
