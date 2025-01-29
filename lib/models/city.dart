import 'package:defcon/models/city_resources.dart';
import 'package:defcon/models/country.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class City extends Equatable {
  final String name;
  final LatLng latLng;
  final int population;
  final int width;
  final Country country;
  final CityResources resources;

  const City({
    required this.name,
    required this.latLng,
    required this.population,
    required this.width,
    required this.country,
    required this.resources,
  });

  @override
  List<Object> get props =>
      [name, latLng, population, width, country, resources];

  factory City.fromJson(Map<String, dynamic> json) => City(
        name: json['asciiname'],
        latLng: LatLng(
            json['latLng']['lat'].toDouble(), json['latLng']['lng'].toDouble()),
        population: json['population'],
        width: json['width'] ?? 100,
        country: json['country'] != null
            ? Country.fromJson(json['country'] as Map<String, dynamic>)
            : Country.none,
        resources:
            CityResources.fromJson(json['resources'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'asciiname': name,
        'latLng': {
          'lat': latLng.latitude,
          'lng': latLng.longitude,
        },
        'population': population,
        'width': width,
        'country': country.toJson(),
        'resources': resources.toJson(),
      };

  City copyWith({
    String? name,
    LatLng? latLng,
    int? population,
    int? width,
    Country? country,
    CityResources? resources,
  }) =>
      City(
        name: name ?? this.name,
        latLng: latLng ?? this.latLng,
        population: population ?? this.population,
        width: width ?? this.width,
        country: country ?? this.country,
        resources: resources ?? this.resources,
      );

  @override
  bool? get stringify => true;
}
