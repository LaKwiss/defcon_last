// ignore_for_file: deprecated_member_use

import 'dart:developer';

import 'package:defcon/city.dart';
import 'package:defcon/city_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

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
  static const int maxVisibleCities = 100;
  static const initialPosition = LatLng(48.8579, 2.3441);
  late final mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          interactionOptions: InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
          ),
        ),
        children: [
          _buildTileLayer(),
          _buildCircumference(),
          _buildCities(),
        ],
      ),
    );
  }

  Widget _buildTileLayer() => TileLayer(
        urlTemplate:
            'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.defcon.app',
        subdomains: const ['a', 'b', 'c'],
        maxZoom: 19,
      );

  Widget _buildCircumference() => CircleLayer(
        circles: [
          CircleMarker(
            point: initialPosition,
            radius: 10000,
            useRadiusInMeter: true,
            color: Colors.blue.withOpacity(0.2),
            borderColor: Colors.blue.withOpacity(0.7),
            borderStrokeWidth: 2,
          ),
        ],
      );

  Widget _buildCities() => Consumer(
        builder: (_, ref, __) => ref.watch(cityProvider).when(
              data: (cities) => CircleLayer(
                circles:
                    cities.take(maxVisibleCities).map(_cityToMarker).toList(),
              ),
              loading: () => const CircleLayer<City>(circles: []),
              error: (_, __) => const CircleLayer<City>(circles: []),
            ),
      );

  CircleMarker _cityToMarker(City city) => CircleMarker(
        point: city.latLng,
        radius: 15,
        color: Colors.red.withOpacity(0.5),
        borderColor: Colors.red,
        borderStrokeWidth: 1.5,
        useRadiusInMeter: false,
      );

  void _handleMapEvent(MapEvent event) {
    if (event.camera.zoom < 8.0) {
      ref.read(cityProvider.notifier).updateVisibleCities(null);
      return;
    }

    int numberOfVisibleCities = ref.read(cityProvider).when(
          data: (cities) => cities.length,
          loading: () => 0,
          error: (_, __) => 0,
        );

    log('Number of visible cities: $numberOfVisibleCities');

    final bounds = event.camera.visibleBounds;
    ref.read(cityProvider.notifier).updateVisibleCities(bounds);
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
