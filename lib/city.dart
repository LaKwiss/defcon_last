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
    final latLng = json['latLng'] as Map<String, dynamic>;
    return City(
      name: json['name'] as String,
      latLng: LatLng(
          (latLng['lat'] is int)
              ? (latLng['lat'] as int).toDouble()
              : latLng['lat'] as double,
          (latLng['lng'] is int)
              ? (latLng['lng'] as int).toDouble()
              : latLng['lng'] as double),
      population: json['population'] as int,
      width: json['width'] as int,
    );
  }
}
