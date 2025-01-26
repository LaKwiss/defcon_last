import 'package:defcon/city.dart';
import 'package:defcon/city_repository.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class CityNotifier extends AsyncNotifier<List<City>> {
  List<City> _allCities = [];
  List<City> _visibleCities = [];

  @override
  Future<List<City>> build() async {
    await fetchCities();
    return _visibleCities;
  }

  int get cityLength => _allCities.length;

  Future<void> fetchCities() async {
    try {
      state = const AsyncValue.loading();
      _allCities = await CityRepository.fetchCities();
      _visibleCities = _allCities;
      state = AsyncValue.data(_visibleCities);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateVisibleCities(LatLngBounds? bounds) {
    if (bounds == null) {
      state = AsyncValue.data(List.empty());
    } else {
      state = AsyncValue.data(
          _allCities.where((city) => bounds.contains(city.latLng)).toList());
    }
  }

  bool isInRange(LatLng point, City city) {
    return const Distance().as(LengthUnit.Meter, city.latLng, point) <=
        city.width;
  }
}

final cityProvider = AsyncNotifierProvider<CityNotifier, List<City>>(
  () => CityNotifier(),
);
