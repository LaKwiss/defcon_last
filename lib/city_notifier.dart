import 'package:defcon/city.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class CityNotifier extends AsyncNotifier {
  @override
  Future<List<City>> build() => getAllCities();

  Future<List<City>> getAllCities() async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      City(
        name: 'Paris',
        latLng: LatLng(48.85795912675502, 2.344188416600133),
        population: 2140526,
        width: 10000,
      ),
      City(
        name: 'London',
        latLng: LatLng(51.5074, -0.1278),
        population: 8982000,
        width: 10000,
      ),
      City(
        name: 'New York',
        latLng: LatLng(40.7128, -74.0060),
        population: 8336817,
        width: 10000,
      ),
      City(
        name: 'Tokyo',
        latLng: LatLng(35.6895, 139.6917),
        population: 9273000,
        width: 10000,
      ),
    ];
  }
}
