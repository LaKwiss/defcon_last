import 'dart:developer';
import 'package:defcon/models/city_resources.dart';
import 'package:dio/dio.dart';
import 'models/city.dart';
import 'models/country.dart';

class CityRepository {
  static final _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000/api',
    ),
  );

  static Future<List<City>> fetchCities() async {
    try {
      final response = await _dio.get<List<dynamic>>('/cities');
      return _handleCitiesResponse(response);
    } catch (e, stack) {
      _handleError('Fetch cities failed', e, stack);
      rethrow;
    }
  }

  static Future<City> fetchCityByName(String name, {int index = 0}) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/cities/exact/$name/$index');
      return City.fromJson(response.data!);
    } catch (e, stack) {
      _handleError('Fetch city by name failed', e, stack);
      rethrow;
    }
  }

  static Future<List<City>> fetchCitiesByCountry(String countryCode,
      {int? minPopulation}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/cities/country/$countryCode',
        queryParameters:
            minPopulation != null ? {'minPopulation': minPopulation} : null,
      );
      return _handleCitiesResponse(response);
    } catch (e, stack) {
      _handleError('Fetch cities by country failed', e, stack);
      rethrow;
    }
  }

  static Future<Country> fetchCountry(String code) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/countries/$code');
      return Country.fromJson(response.data!);
    } catch (e, stack) {
      _handleError('Fetch country failed', e, stack);
      rethrow;
    }
  }

  static Future<CityResources> fetchCountryResources(String code) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/countries/$code/resources');
      return CityResources.fromJson(response.data!);
    } catch (e, stack) {
      _handleError('Fetch country resources failed', e, stack);
      rethrow;
    }
  }

  static Future<List<Country>> fetchNeighbours(String code) async {
    try {
      final response =
          await _dio.get<List<dynamic>>('/countries/$code/neighbours');
      return response.data!
          .map((json) => Country.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      _handleError('Fetch neighbours failed', e, stack);
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchContinentResources(
      String code) async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/resources/continent/$code');
      return response.data!;
    } catch (e, stack) {
      _handleError('Fetch continent resources failed', e, stack);
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchTopCountries(String resource,
      {int limit = 10}) async {
    try {
      final response =
          await _dio.get<List<dynamic>>('/countries/top/$resource/$limit');
      return response.data!.cast<Map<String, dynamic>>();
    } catch (e, stack) {
      _handleError('Fetch top countries failed', e, stack);
      rethrow;
    }
  }

  static List<City> _handleCitiesResponse(Response<List<dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Empty response',
      );
    }
    return data.map((json) {
      if (json != null) {
        City city = City.fromJson(json);
        return city;
      } else {
        throw Exception('One city is null');
      }
    }).toList();
  }

  static void _handleError(String message, Object error, StackTrace stack) {
    log(message, error: error, stackTrace: stack);
  }
}
