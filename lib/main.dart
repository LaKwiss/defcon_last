import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'city.dart';
import 'city_notifier.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
        theme: ThemeData.dark(),
      );
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  static const initialPosition = LatLng(48.8579, 2.3441);
  late final mapController = MapController();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('City Map'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(cityProvider.notifier).fetchCities(),
            ),
          ],
        ),
        body: FlutterMap(
          mapController: mapController,
          options: MapOptions(
            backgroundColor: Colors.black,
            initialCenter: initialPosition,
            initialZoom: 13,
            onMapEvent: _handleMapEvent,
            onTap: _handleTapEvent,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            Consumer(
              builder: (_, ref, __) => ref.watch(cityProvider).when(
                    data: (cities) => CircleLayer(
                      circles: cities
                          .map((city) => CircleMarker(
                                point: city.latLng,
                                radius: 15,
                                color: Colors.red.withOpacity(0.5),
                                borderColor: Colors.red,
                                borderStrokeWidth: 1.5,
                                useRadiusInMeter: false,
                              ))
                          .toList(),
                    ),
                    loading: () => const CircleLayer<City>(circles: []),
                    error: (_, __) => const CircleLayer<City>(circles: []),
                  ),
            ),
          ],
        ),
      );

  void _handleMapEvent(MapEvent event) {
    if (event.camera.zoom < 6.0) {
      ref.read(cityProvider.notifier).updateVisibleCities(null);
      return;
    }
    ref
        .read(cityProvider.notifier)
        .updateVisibleCities(event.camera.visibleBounds);
  }

  void _handleTapEvent(TapPosition tapPosition, LatLng point) {
    log('Tapped at $point');

    final groupedCities = ref.read(cityProvider).value ?? [];
    // Convert radius to meters (1km = 1000m)
    final radiusInMeters = 2000.0;

    final nearbyCity = groupedCities.where((city) {
      final distanceInMeters = const Distance()(city.latLng, point);
      return distanceInMeters <= radiusInMeters;
    }).toList();

    if (nearbyCity.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(nearbyCity.length == 1
              ? nearbyCity.first.name
              : '${nearbyCity.length} villes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: nearbyCity
                .map((city) => Text('${city.name} (${city.population} hab.)'))
                .toList(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
