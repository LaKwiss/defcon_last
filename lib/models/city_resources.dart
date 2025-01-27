import 'package:equatable/equatable.dart';

class CityResources extends Equatable {
  final double oil;
  final double metal;
  final double crates;
  final double wheat;
  final double workforce;
  final double rareResources;
  final double money;

  const CityResources({
    this.oil = 0.0,
    this.metal = 0.0,
    this.crates = 0.0,
    this.wheat = 0.0,
    this.workforce = 0.0,
    this.rareResources = 0.0,
    this.money = 0.0,
  });

  @override
  List<Object> get props =>
      [oil, metal, crates, wheat, workforce, rareResources, money];

  CityResources copyWith({
    double? oil,
    double? metal,
    double? crates,
    double? wheat,
    double? workforce,
    double? rareResources,
    double? money,
  }) {
    return CityResources(
      oil: oil ?? this.oil,
      metal: metal ?? this.metal,
      crates: crates ?? this.crates,
      wheat: wheat ?? this.wheat,
      workforce: workforce ?? this.workforce,
      rareResources: rareResources ?? this.rareResources,
      money: money ?? this.money,
    );
  }

  CityResources operator +(CityResources other) => CityResources(
        oil: oil + other.oil,
        metal: metal + other.metal,
        crates: crates + other.crates,
        wheat: wheat + other.wheat,
        workforce: workforce + other.workforce,
        rareResources: rareResources + other.rareResources,
        money: money + other.money,
      );

  CityResources operator -(CityResources other) => CityResources(
        oil: oil - other.oil,
        metal: metal - other.metal,
        crates: crates - other.crates,
        wheat: wheat - other.wheat,
        workforce: workforce - other.workforce,
        rareResources: rareResources - other.rareResources,
        money: money - other.money,
      );

  CityResources operator *(double factor) => CityResources(
        oil: oil * factor,
        metal: metal * factor,
        crates: crates * factor,
        wheat: wheat * factor,
        workforce: workforce * factor,
        rareResources: rareResources * factor,
        money: money * factor,
      );

  factory CityResources.fromJson(Map<String, dynamic> json) {
    return CityResources(
      oil: json['oil']?.toDouble() ?? 0.0,
      metal: json['metal']?.toDouble() ?? 0.0,
      crates: json['crates']?.toDouble() ?? 0.0,
      wheat: json['wheat']?.toDouble() ?? 0.0,
      workforce: json['workforce']?.toDouble() ?? 0.0,
      rareResources: json['rareResources']?.toDouble() ?? 0.0,
      money: json['money']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'oil': oil,
        'metal': metal,
        'crates': crates,
        'wheat': wheat,
        'workforce': workforce,
        'rareResources': rareResources,
        'money': money,
      };
}
