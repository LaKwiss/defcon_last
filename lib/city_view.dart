import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/city.dart';

/// ---------------------------------------------------------------------------
///                          PROVIDERS
/// ---------------------------------------------------------------------------

/// Provider pour gérer l'état d'édition et la carte sélectionnée.
final editModeProvider = StateProvider.family<EditModeState, String>(
  (ref, cityId) => EditModeState(isEditing: false, selectedCardId: null),
);

/// Provider pour la configuration du layout (positionnement x, y).
final cityLayoutConfigProvider =
    StateProvider.family<Map<String, dynamic>, String>(
  (ref, cityId) => {
    'x': 20.0,
    'y': 20.0,
  },
);

/// ---------------------------------------------------------------------------
///  Provider et StateNotifier pour gérer l'ordre (Z-ordre) des cartes dans
///  chaque onglet, par exemple pour la vue "overview", "production", etc.
/// ---------------------------------------------------------------------------

/// Provider pour l'ordre des cartes (layout vertical) dans chaque onglet.
/// La clé du Map correspond à l'onglet ("overview", "production", etc.),
/// et la valeur est la liste ordonnée des cardId.
final cityCardOrderProvider = StateNotifierProvider.family<
    CityCardOrderNotifier, Map<String, List<String>>, String>(
  (ref, cityId) => CityCardOrderNotifier(cityId),
);

/// StateNotifier qui gère l'ordre des cartes.
/// On charge/sauvegarde dans SharedPreferences pour persister cet ordre.
class CityCardOrderNotifier extends StateNotifier<Map<String, List<String>>> {
  final String cityId;

  /// Constructeur : on initialise l'état en chargeant l'ordre depuis
  /// les préférences, ou en définissant un ordre par défaut.
  CityCardOrderNotifier(this.cityId) : super({}) {
    _loadInitialOrder();
  }

  /// Monte la carte d'un cran dans l'onglet donné [tabKey].
  void moveCardUp(String tabKey, String cardId) {
    final currentOrder = [...?state[tabKey]]; // copie défensive
    final index = currentOrder.indexOf(cardId);
    if (index > 0) {
      currentOrder.removeAt(index);
      currentOrder.insert(index - 1, cardId);
      state = {...state, tabKey: currentOrder};
      _saveOrder();
    }
  }

  /// Descend la carte d'un cran dans l'onglet donné [tabKey].
  void moveCardDown(String tabKey, String cardId) {
    final currentOrder = [...?state[tabKey]];
    final index = currentOrder.indexOf(cardId);
    if (index >= 0 && index < currentOrder.length - 1) {
      currentOrder.removeAt(index);
      currentOrder.insert(index + 1, cardId);
      state = {...state, tabKey: currentOrder};
      _saveOrder();
    }
  }

  /// Charge l'ordre initial depuis les SharedPreferences,
  /// ou utilise un ordre par défaut si non trouvé.
  Future<void> _loadInitialOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('card_order_$cityId');
    if (stored != null) {
      final Map<String, dynamic> decoded = json.decode(stored);
      final result = decoded.map((key, value) => MapEntry(
            key,
            (value as List).map((e) => e.toString()).toList(),
          ));
      state = result;
    } else {
      // Ordre par défaut : ajustez selon vos besoins
      state = {
        'overview': ['city_info', 'quick_stats', 'recent_activity'],
        'production': [
          'resources_overview',
          'production_trends',
          'production_efficiency',
          'upgrade_options'
        ],
        'trade': ['active_offers', 'trade_history', 'market_analysis'],
        'development': ['development_projects', 'resource_requirements'],
      };
    }
  }

  /// Sauvegarde l'ordre actuel des cartes dans les SharedPreferences.
  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('card_order_$cityId', json.encode(state));
  }
}

/// ---------------------------------------------------------------------------
///                         CLASSES ET WIDGETS
/// ---------------------------------------------------------------------------

/// Classe représentant l'état d'édition : [isEditing] + [selectedCardId].
class EditModeState {
  final bool isEditing;
  final String? selectedCardId;

  const EditModeState({
    required this.isEditing,
    this.selectedCardId,
  });

  EditModeState copyWith({
    bool? isEditing,
    String? selectedCardId,
  }) {
    return EditModeState(
      isEditing: isEditing ?? this.isEditing,
      selectedCardId: selectedCardId ?? this.selectedCardId,
    );
  }
}

/// Widget "EditableCard" qui entoure l'UI d'une carte. Permet de gérer :
/// - l'affichage d'un encadré spécial en mode édition.
/// - l'affichage de boutons additionnels (ex. flèches Haut/Bas) en mode édition.
class EditableCard extends StatelessWidget {
  /// L'identifiant unique de la carte (ex.: "city_info").
  final String cardId;

  /// Le contenu enfant de la carte.
  final Widget child;

  /// Indique si on est en mode édition.
  final bool isEditing;

  /// Indique si la carte est sélectionnée (par ex. pour la surbrillance).
  final bool isSelected;

  /// Callback quand on sélectionne la carte (en mode édition).
  final VoidCallback? onSelect;

  /// Boutons supplémentaires à afficher en overlay (ex. flèches Haut/Bas).
  final Widget additionalButtons;

  const EditableCard({
    super.key,
    required this.cardId,
    required this.child,
    required this.isEditing,
    required this.isSelected,
    this.onSelect,
    this.additionalButtons = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEditing ? onSelect : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: isEditing
              ? Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.withOpacity(0.5),
                  width: isSelected ? 2 : 1,
                )
              : null,
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              )
          ],
        ),
        child: Stack(
          children: [
            /// Contenu principal de la carte.
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),

            /// Icône de sélection (check/radio) en mode édition, en haut à droite.
            if (isEditing)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  size: 20,
                ),
              ),

            /// Boutons supplémentaires (ex.: flèches Haut/Bas) en haut à gauche.
            if (isEditing)
              Positioned(
                top: 8,
                left: 8,
                child: additionalButtons,
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget principal pour l'affichage d'une ville.
/// On y gère :
/// - Le positionnement draggable de la vue (layout),
/// - Le multi-onglet (TabBar),
/// - Le mode édition (sélection de cartes, reordering, etc.),
/// - L'affichage des différents "blocks" de carte.
class CityView extends ConsumerStatefulWidget {
  final City city;

  const CityView({super.key, required this.city});

  @override
  ConsumerState<CityView> createState() => _CityViewState();
}

class _CityViewState extends ConsumerState<CityView>
    with TickerProviderStateMixin {
  /// Dimensions par défaut de la fenêtre.
  static const double _defaultWidth = 450;
  static const double _defaultHeight = 600;

  /// Permet le formatage des nombres (ex.: 2 345).
  final NumberFormat _numberFormat = NumberFormat.decimalPattern();

  /// Contrôleur pour notre TabBar (4 onglets).
  late TabController _tabController;

  /// Position (x, y) de la fenêtre draggable.
  Offset _position = const Offset(20, 20);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLayout();
  }

  /// Charge la position x,y depuis les SharedPreferences.
  Future<void> _loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutData = prefs.getString('city_layout_${widget.city.name}');
    if (layoutData != null) {
      final layout = json.decode(layoutData) as Map<String, dynamic>;
      ref.read(cityLayoutConfigProvider(widget.city.name).notifier).state =
          layout;

      setState(() {
        final x = layout['x'] as double? ?? 20.0;
        final y = layout['y'] as double? ?? 20.0;
        _position = Offset(x, y);
      });
    }
  }

  /// Sauvegarde la position x,y de la fenêtre dans les SharedPreferences.
  Future<void> _saveLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layout =
        ref.read(cityLayoutConfigProvider(widget.city.name).notifier).state;
    final updatedLayout = {
      ...layout,
      'x': _position.dx,
      'y': _position.dy,
    };

    await prefs.setString(
      'city_layout_${widget.city.name}',
      json.encode(updatedLayout),
    );

    ref.read(cityLayoutConfigProvider(widget.city.name).notifier).state =
        updatedLayout;
  }

  /// Bascule le mode édition (on/off).
  void _toggleEditMode() {
    final editMode = ref.read(editModeProvider(widget.city.name));
    ref.read(editModeProvider(widget.city.name).notifier).state = EditModeState(
      isEditing: !editMode.isEditing,
      selectedCardId: null,
    );
  }

  /// Sélectionne/désélectionne une carte [cardId].
  void _selectCard(String cardId) {
    final editMode = ref.read(editModeProvider(widget.city.name));
    ref.read(editModeProvider(widget.city.name).notifier).state =
        editMode.copyWith(
      selectedCardId: editMode.selectedCardId == cardId ? null : cardId,
    );
  }

  /// Enveloppe [child] dans un EditableCard, en gérant notamment :
  /// - la sélection/désélection,
  /// - les flèches de réorganisation.
  ///
  /// [tabKey] : l'onglet dans lequel se trouve cette carte
  ///            (ex: "overview", "production"...).
  Widget _wrapInEditableCard(
    String cardId,
    Widget child, {
    required String tabKey,
  }) {
    final editMode = ref.watch(editModeProvider(widget.city.name));

    return EditableCard(
      cardId: cardId,
      isEditing: editMode.isEditing,
      isSelected: editMode.selectedCardId == cardId,
      onSelect: () => _selectCard(cardId),

      /// On crée deux boutons flèche haut/bas qui appellent le Notifier
      /// pour réorganiser la liste.
      additionalButtons: editMode.isEditing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  onPressed: () {
                    ref
                        .read(cityCardOrderProvider(widget.city.name).notifier)
                        .moveCardUp(tabKey, cardId);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  onPressed: () {
                    ref
                        .read(cityCardOrderProvider(widget.city.name).notifier)
                        .moveCardDown(tabKey, cardId);
                  },
                ),
              ],
            )
          : const SizedBox.shrink(),

      child: child,
    );
  }

  /// Détermine un label "type de ville" en fonction des ressources.
  String get _cityType {
    final res = widget.city.resources;
    if (res.warBonds > 500) return 'Financière';
    if (res.workforce > 2000) return 'Administrative';
    if (res.oil > 2000) return 'Pétrolière';
    if (res.metal > 2000) return 'Métallurgique';
    if (res.crates > 2000) return 'Logistique';
    if (res.wheat > 2000) return 'Agricole';
    if (res.rareResources > 2000) return 'Technologique';
    return 'Standard';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    /// Ajuste la largeur/hauteur à la taille de l'écran.
    final width =
        screenSize.width > 400 ? _defaultWidth : screenSize.width * 0.8;
    final height =
        screenSize.height > 600 ? _defaultHeight : screenSize.height * 0.8;

    return Positioned(
      left: _position.dx.clamp(0, screenSize.width - width),
      top: _position.dy.clamp(0, screenSize.height - height),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onPanEnd: (details) {
          _saveLayout();
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildHeader(),
                _buildTabs(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildProductionTab(),
                      _buildTradeTab(),
                      _buildDevelopmentTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bar d'en-tête avec le nom de la ville, le bouton d'édition et de fermeture.
  Widget _buildHeader() {
    final editMode = ref.watch(editModeProvider(widget.city.name));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor ?? Colors.blueGrey,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.city.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          IconButton(
            icon: Icon(
              editMode.isEditing ? Icons.check : Icons.edit,
              size: 20,
            ),
            onPressed: _toggleEditMode,
            tooltip:
                editMode.isEditing ? 'Terminer l\'édition' : 'Mode édition',
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }

  /// TabBar (4 onglets) : Vue d'ensemble, Production, Commerce, Développement.
  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabs: const [
        Tab(text: 'Vue d\'ensemble'),
        Tab(text: 'Production'),
        Tab(text: 'Commerce'),
        Tab(text: 'Développement'),
      ],
    );
  }

  /// Onglet "Vue d'ensemble" : on construit les cartes dans l'ordre défini
  /// dans le provider [cityCardOrderProvider] pour la clé "overview".
  Widget _buildOverviewTab() {
    /// On récupère la liste des cardId pour l'onglet "overview".
    final orderMap = ref.watch(cityCardOrderProvider(widget.city.name));
    final cardsOrder = orderMap['overview'] ?? [];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: cardsOrder.map((cardId) {
            switch (cardId) {
              case 'city_info':
                return _buildCityInfo();
              case 'quick_stats':
                return _buildQuickStats();
              case 'recent_activity':
                return _buildRecentActivity();
              default:
                return const SizedBox.shrink();
            }
          }).toList(),
        ),
      ),
    );
  }

  /// Onglet "Production" : même logique, avec la clé "production".
  Widget _buildProductionTab() {
    final orderMap = ref.watch(cityCardOrderProvider(widget.city.name));
    final cardsOrder = orderMap['production'] ?? [];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: cardsOrder.map((cardId) {
            switch (cardId) {
              case 'resources_overview':
                return _buildResourcesOverview();
              case 'production_trends':
                return _buildProductionTrends();
              case 'production_efficiency':
                return _buildProductionEfficiency();
              case 'upgrade_options':
                return _buildUpgradeOptions();
              default:
                return const SizedBox.shrink();
            }
          }).toList(),
        ),
      ),
    );
  }

  /// Onglet "Commerce" : même logique, avec la clé "trade".
  Widget _buildTradeTab() {
    final orderMap = ref.watch(cityCardOrderProvider(widget.city.name));
    final cardsOrder = orderMap['trade'] ?? [];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: cardsOrder.map((cardId) {
            switch (cardId) {
              case 'active_offers':
                return _buildActiveOffers();
              case 'trade_history':
                return _buildTradeHistory();
              case 'market_analysis':
                return _buildMarketAnalysis();
              default:
                return const SizedBox.shrink();
            }
          }).toList(),
        ),
      ),
    );
  }

  /// Onglet "Développement" : même logique, avec la clé "development".
  Widget _buildDevelopmentTab() {
    final orderMap = ref.watch(cityCardOrderProvider(widget.city.name));
    final cardsOrder = orderMap['development'] ?? [];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: cardsOrder.map((cardId) {
            switch (cardId) {
              case 'development_projects':
                return _buildDevelopmentProjects();
              case 'resource_requirements':
                return _buildResourceRequirements();
              default:
                return const SizedBox.shrink();
            }
          }).toList(),
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  ///                        CARTES DE L'ONGLET "OVERVIEW"
  /// -------------------------------------------------------------------------

  /// Carte "INFORMATIONS" de la ville.
  Widget _buildCityInfo() {
    return _wrapInEditableCard(
      'city_info',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INFORMATIONS',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.location_city, 'Type', _cityType),
              _buildInfoRow(Icons.flag, 'Pays', widget.city.country.name),
              _buildInfoRow(
                Icons.people,
                'Population',
                _numberFormat.format(widget.city.population),
              ),
              _buildInfoRow(
                Icons.account_balance,
                'Doctrine',
                widget.city.country.doctrine.name,
              ),
            ],
          ),
        ),
      ),
      tabKey: 'overview',
    );
  }

  /// Carte "STATISTIQUES" avec une grille rapide de ressources.
  Widget _buildQuickStats() {
    return _wrapInEditableCard(
      'quick_stats',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATISTIQUES',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              _buildResourcesGrid(),
            ],
          ),
        ),
      ),
      tabKey: 'overview',
    );
  }

  /// Carte "ACTIVITÉ RÉCENTE".
  Widget _buildRecentActivity() {
    return _wrapInEditableCard(
      'recent_activity',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACTIVITÉ RÉCENTE',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Historique des activités à venir'),
              ),
            ],
          ),
        ),
      ),
      tabKey: 'overview',
    );
  }

  /// -------------------------------------------------------------------------
  ///                      CARTES DE L'ONGLET "PRODUCTION"
  /// -------------------------------------------------------------------------

  /// Carte "PRODUCTION" : aperçu des ressources produites.
  Widget _buildResourcesOverview() {
    return _wrapInEditableCard(
      'resources_overview',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRODUCTION',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              _buildResourcesList(),
            ],
          ),
        ),
      ),
      tabKey: 'production',
    );
  }

  /// Carte "TENDANCES" (graphiques de production).
  Widget _buildProductionTrends() {
    return _wrapInEditableCard(
      'production_trends',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TENDANCES',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Graphiques de tendances à venir'),
              ),
            ],
          ),
        ),
      ),
      tabKey: 'production',
    );
  }

  /// Carte "EFFICACITÉ" (métriques).
  Widget _buildProductionEfficiency() {
    return _wrapInEditableCard(
      'production_efficiency',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EFFICACITÉ',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Métriques d\'efficacité à venir'),
              ),
            ],
          ),
        ),
      ),
      tabKey: 'production',
    );
  }

  /// Carte "AMÉLIORATIONS POSSIBLES".
  Widget _buildUpgradeOptions() {
    return _wrapInEditableCard(
      'upgrade_options',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AMÉLIORATIONS POSSIBLES',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Options d\'amélioration à venir'),
              ),
            ],
          ),
        ),
      ),
      tabKey: 'production',
    );
  }

  /// -------------------------------------------------------------------------
  ///                        CARTES DE L'ONGLET "COMMERCE"
  /// -------------------------------------------------------------------------

  /// Carte "OFFRES ACTIVES".
  Widget _buildActiveOffers() {
    return _wrapInEditableCard(
      'active_offers',
      Card(
        key: const ValueKey('active_offers'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OFFRES ACTIVES',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Liste des offres à venir'),
              ),
            ],
          ),
        ),
      ),
      tabKey: 'trade',
    );
  }

  /// Carte "HISTORIQUE".
  Widget _buildTradeHistory() {
    return _wrapInEditableCard(
      'trade_history',
      Card(
        key: const ValueKey('trade_history'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HISTORIQUE',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Historique des échanges à venir'),
              ),
            ],
          ),
        ),
      ),
      tabKey: 'trade',
    );
  }

  /// Carte "ANALYSE DU MARCHÉ".
  Widget _buildMarketAnalysis() {
    return _wrapInEditableCard(
      'market_analysis',
      Card(
        key: const ValueKey('market_analysis'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANALYSE DU MARCHÉ',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Analyse des prix à venir'),
              ),
            ],
          ),
        ),
      ),
      tabKey: 'trade',
    );
  }

  /// -------------------------------------------------------------------------
  ///                   CARTES DE L'ONGLET "DÉVELOPPEMENT"
  /// -------------------------------------------------------------------------

  /// Carte "PROJETS EN COURS".
  Widget _buildDevelopmentProjects() {
    return _wrapInEditableCard(
      'development_projects',
      Card(
        key: const ValueKey('development_projects'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PROJETS EN COURS',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Liste des projets à venir'),
              ),
            ],
          ),
        ),
      ),
      tabKey: 'development',
    );
  }

  /// Carte "RESSOURCES NÉCESSAIRES" (pour projets, etc.).
  Widget _buildResourceRequirements() {
    return _wrapInEditableCard(
      'resource_requirements',
      Card(
        key: const ValueKey('resource_requirements'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RESSOURCES NÉCESSAIRES',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Besoins en ressources à venir'),
              ),
            ],
          ),
        ),
      ),
      tabKey: 'development',
    );
  }

  /// -------------------------------------------------------------------------
  ///                   MÉTHODES PRATIQUES (RESOURCE LIST, etc.)
  /// -------------------------------------------------------------------------

  /// Retourne la liste des ressources à afficher.
  List<Map<String, dynamic>> get _resourcesList => [
        {
          'icon': Icons.oil_barrel,
          'label': 'Pétrole',
          'value': widget.city.resources.oil
        },
        {
          'icon': Icons.construction,
          'label': 'Métal',
          'value': widget.city.resources.metal
        },
        {
          'icon': Icons.shopping_cart,
          'label': 'Caisse',
          'value': widget.city.resources.crates
        },
        {
          'icon': Icons.grass,
          'label': 'Blé',
          'value': widget.city.resources.wheat
        },
        {
          'icon': Icons.engineering,
          'label': 'Main d\'œuvre',
          'value': widget.city.resources.workforce
        },
        {
          'icon': Icons.diamond,
          'label': 'Ressources rares',
          'value': widget.city.resources.rareResources
        },
        {
          'icon': Icons.attach_money,
          'label': 'Argent',
          'value': widget.city.resources.money
        },
        {
          'icon': Icons.military_tech,
          'label': 'Obligations de guerre',
          'value': widget.city.resources.warBonds
        },
      ];

  /// Construit une grille (2 colonnes) avec les ressources présentes.
  Widget _buildResourcesGrid() {
    final filtered =
        _resourcesList.where((res) => (res['value'] as double) > 0).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _buildResourceGridItem(
          item['icon'] as IconData,
          item['label'] as String,
          item['value'] as double,
        );
      },
    );
  }

  /// Construction d'un "item" de ressource dans la grille.
  Widget _buildResourceGridItem(IconData icon, String label, double value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 4),
              Text(label),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _numberFormat.format(value),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Construit une liste de ressources (verticale) pour la production.
  Widget _buildResourcesList() {
    return Column(
      children: _resourcesList
          .where((res) => (res['value'] as double) > 0)
          .map(
            (res) => _buildResourceRow(
              res['icon'] as IconData,
              res['label'] as String,
              res['value'] as double,
            ),
          )
          .toList(),
    );
  }

  /// Construit une "row" de ressource, avec icône, label et valeur.
  Widget _buildResourceRow(IconData icon, String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            _numberFormat.format(value),
            style: TextStyle(
              color: value > 0 ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construit une row d'information pour l'encart "INFORMATIONS" (ex.: Type: Standard).
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text('$label:'),
          const SizedBox(width: 4),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Simple message de placeholder pour fonctionnalité non-implémentée.
  void _showNotImplemented() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité en développement'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
