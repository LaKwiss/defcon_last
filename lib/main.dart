import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          backgroundColor: Colors.black,
          initialCenter: LatLng(48.85795912675502, 2.344188416600133),
          initialZoom: 13.0,
          onTap: (tapPosition, point) {
            CircleMarker circle = CircleMarker(
              point: LatLng(48.85795912675502, 2.344188416600133),
              radius: 10000,
              useRadiusInMeter: true,
            );

            double distanceInMeters =
                const Distance().as(LengthUnit.Meter, circle.point, point);

            if (distanceInMeters <= circle.radius) {
              print('Tapped inside circle!');
            }
          },
          interactionOptions: InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.doubleTapZoom,
          ),
        ),
        children: [
          TileLayer(
            keepBuffer: 20,
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.defcon.app',
          ),
          Builder(
            builder: (context) {
              return CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(48.85795912675502, 2.344188416600133),
                    radius: 10000,
                    useRadiusInMeter: true,
                    color: Colors.blue.withAlpha(((0.5) * 255).round()),
                  ),
                ],
              );
            },
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(48.85795912675502, 2.344188416600133),
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
