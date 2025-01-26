import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class City extends Equatable {
  final String name;
  final LatLng latLng;
  final int population;
  final int width;

  const City({
    required this.name,
    required this.latLng,
    required this.population,
    required this.width,
  });

  @override
  List<Object?> get props => [name, latLng, population, width];

  @override
  bool get stringify => true;

  City copyWith({
    String? name,
    LatLng? latLng,
    int? population,
    int? width,
  }) {
    return City(
      name: name ?? this.name,
      latLng: latLng ?? this.latLng,
      population: population ?? this.population,
      width: width ?? this.width,
    );
  }

  Marker get marker {
    return Marker(
      width: width.toDouble(),
      height: width.toDouble(),
      point: latLng,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['asciiname'],
      latLng:
          LatLng((json['latitude']).toDouble(), (json['longitude']).toDouble()),
      population: json['population'],
      width: json['width'] ?? 100,
    );
  }
}
