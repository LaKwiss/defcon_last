import 'package:defcon/city_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'models/city.dart';
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
                    data: (cities) => MarkerLayer(
                      markers: cities
                          .map((city) => Marker(
                                point: city.latLng,
                                width: 30,
                                height: 30,
                                child: GestureDetector(
                                  onTap: () => _handleTapEvent(city),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    loading: () => const MarkerLayer(markers: []),
                    error: (_, __) => const MarkerLayer(markers: []),
                  ),
            ),
          ],
        ),
      );

  void _handleMapEvent(MapEvent event) {
    ref
        .read(cityProvider.notifier)
        .updateVisibleCities(event.camera.visibleBounds, minPopulation: 400000);
  }

  void _handleTapEvent(City city) {
    showDialog(
      context: context,
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.black38),
              ),
            ),
            CityView(city: city),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}
