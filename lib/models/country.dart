import 'package:defcon/models/doctrine.dart';
import 'package:equatable/equatable.dart';

class Country extends Equatable {
  final String name;
  final String code;
  final String capital;
  final int population;
  final String continent;
  final List<String> neighbours;
  final CountryDoctrine doctrine;

  const Country({
    required this.name,
    required this.code,
    required this.capital,
    required this.population,
    required this.continent,
    required this.neighbours,
    required this.doctrine,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'],
      code: json['code'],
      capital: json['capital'],
      population: json['population'],
      continent: json['continent'],
      neighbours: (json['neighbours'] as String).split(','),
      doctrine: CountryDoctrine.fromJson(json['doctrine']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'capital': capital,
        'population': population,
        'continent': continent,
        'neighbours': neighbours.join(','),
        'doctrine': doctrine.toJson(),
      };

  @override
  List<Object> get props => [
        name,
        code,
        capital,
        population,
        continent,
        neighbours,
        doctrine,
      ];

  static const Country onError = Country(
    name: '',
    code: 'code',
    capital: 'capital',
    population: 100,
    continent: 'continent',
    neighbours: ['neighbours'],
    doctrine: CountryDoctrine.diplomatic,
  );

  static const none = Country(
      name: 'none',
      code: 'none',
      capital: 'none',
      population: 0,
      continent: 'non',
      neighbours: [''],
      doctrine: CountryDoctrine.agricultural);
}
