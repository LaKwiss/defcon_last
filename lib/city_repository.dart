import 'dart:developer';
import 'package:dio/dio.dart';
import 'city.dart';

class CityRepository {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  static Future<List<City>> fetchCities() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/cities');
      final data = response.data;

      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Empty response',
        );
      }

      return data
          .map((json) => City.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      log('Fetch failed', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
