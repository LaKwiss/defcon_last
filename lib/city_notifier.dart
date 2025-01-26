import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'city.dart';
import 'city_repository.dart';

class CityNotifier extends AsyncNotifier<List<City>> {
  List<City> _allCities = [];
  List<City> _visibleCities = [];

  @override
  Future<List<City>> build() async {
    await fetchCities();
    return _visibleCities;
  }

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
      return;
    }

    state = AsyncValue.data(
        _allCities.where((city) => bounds.contains(city.latLng)).toList());
  }
}

final cityProvider = AsyncNotifierProvider<CityNotifier, List<City>>(
  () => CityNotifier(),
);
