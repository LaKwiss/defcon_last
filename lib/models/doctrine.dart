enum CountryDoctrine {
  military('Militaire', 'Axé sur la force et la défense'),
  economic('Économique', 'Priorité au commerce et à la production'),
  technological('Technologique', 'Focus sur la recherche'),
  diplomatic('Diplomatique', 'Relations internationales'),
  industrial('Industriel', 'Production de masse'),
  agricultural('Agricole', 'Autosuffisance alimentaire'),
  religious('Religieux', 'Influence culturelle');

  final String name;
  final String description;

  const CountryDoctrine(this.name, this.description);

  factory CountryDoctrine.fromJson(Map<String, dynamic> json) {
    return CountryDoctrine.values.firstWhere((d) => d.name == json['name'],
        orElse: () => CountryDoctrine.economic);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'resourceModifiers': resourceModifiers,
      };

  Map<String, double> get resourceModifiers {
    switch (this) {
      case military:
        return {'metal': 1.2, 'workforce': 1.1, 'money': 0.8};
      case economic:
        return {'money': 1.3, 'crates': 1.1, 'workforce': 0.9};
      case technological:
        return {'rareResources': 1.2, 'money': 1.1, 'wheat': 0.9};
      case diplomatic:
        return {'money': 1.2, 'workforce': 1.1, 'metal': 0.9};
      case industrial:
        return {'metal': 1.2, 'oil': 1.2, 'wheat': 0.8};
      case agricultural:
        return {'wheat': 1.3, 'workforce': 1.1, 'rareResources': 0.9};
      case religious:
        return {'workforce': 1.2, 'money': 1.1, 'oil': 0.9};
    }
  }
}
