import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/city.dart';
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

  void updateVisibleCities(LatLngBounds? bounds, {int? minPopulation}) {
    if (bounds == null) {
      // Si les limites ne sont pas définies, réinitialiser la liste des villes visibles
      state = AsyncValue.data(List.empty());
      return;
    }

    // Filtrer les villes en fonction des limites et de la population minimale
    final filteredCities = _allCities.where((city) {
      final withinBounds = bounds.contains(city.latLng);
      final meetsPopulationCriteria =
          minPopulation == null || city.population >= minPopulation;
      return withinBounds && meetsPopulationCriteria;
    }).toList();

    // Mettre à jour l'état avec les villes filtrées
    state = AsyncValue.data(filteredCities);
  }
}

final cityProvider = AsyncNotifierProvider<CityNotifier, List<City>>(
  () => CityNotifier(),
);
