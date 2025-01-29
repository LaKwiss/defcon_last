enum CountryDoctrine {
  military('Militaire', 'Axé sur la force et la défense'),
  economic('Économique', 'Priorité au commerce et à la production'),
  technological('Technologique', 'Focus sur la recherche'),
  diplomatic('Diplomatique', 'Relations internationales'),
  industrial('Industriel', 'Production de masse'),
  agricultural('Agricole', 'Autosuffisance alimentaire'),
  religious('Religieux', 'Influence culturelle');

  /// Label en clair (ex. "Militaire", "Économique", etc.)
  final String label;

  /// Description plus détaillée de la doctrine.
  final String description;

  const CountryDoctrine(this.label, this.description);

  /// Récupère la doctrine à partir du champ `name` du JSON.
  /// `name` doit alors être "military", "economic", etc.
  factory CountryDoctrine.fromJson(Map<String, dynamic> json) {
    final doctrineName = json['name']?.toString().trim();
    if (doctrineName == null || doctrineName.isEmpty) {
      return CountryDoctrine.economic; // Valeur par défaut
    }
    return CountryDoctrine.values.firstWhere(
      (d) => d.name == doctrineName, // Compare au `name` interne de l'enum
      orElse: () => CountryDoctrine.economic,
    );
  }

  /// Sérialise la doctrine : on exporte `name` (technique),
  /// ainsi que le label et la description pour information.
  Map<String, dynamic> toJson() => {
        'name': name, // e.g. "military"
        'label': label, // e.g. "Militaire"
        'description': description,
        'resourceModifiers': resourceModifiers,
      };

  /// Modificateurs de ressources selon la doctrine.
  Map<String, double> get resourceModifiers {
    switch (this) {
      case CountryDoctrine.military:
        return {'metal': 1.2, 'workforce': 1.1, 'money': 0.8};
      case CountryDoctrine.economic:
        return {'money': 1.3, 'crates': 1.1, 'workforce': 0.9};
      case CountryDoctrine.technological:
        return {'rareResources': 1.2, 'money': 1.1, 'wheat': 0.9};
      case CountryDoctrine.diplomatic:
        return {'money': 1.2, 'workforce': 1.1, 'metal': 0.9};
      case CountryDoctrine.industrial:
        return {'metal': 1.2, 'oil': 1.2, 'wheat': 0.8};
      case CountryDoctrine.agricultural:
        return {'wheat': 1.3, 'workforce': 1.1, 'rareResources': 0.9};
      case CountryDoctrine.religious:
        return {'workforce': 1.2, 'money': 1.1, 'oil': 0.9};
    }
  }
}
