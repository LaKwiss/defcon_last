import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/city.dart';

/// ---------------------------------------------------------------------------
///                         PROVIDERS
/// ---------------------------------------------------------------------------

/// Provider (StateProvider) pour mémoriser la position x,y de la fenêtre.
/// Ici, c'est un seul layout global, sans paramètre cityId.
final globalLayoutConfigProvider = StateProvider<Map<String, double>>((ref) {
  return {
    'x': 20.0,
    'y': 20.0,
  };
});

/// Provider (StateNotifier) pour l'ordre des cartes dans chaque onglet.
/// Un seul ordre global, non spécifique à une ville.
final globalCardOrderProvider =
    StateNotifierProvider<GlobalCardOrderNotifier, Map<String, List<String>>>(
  (ref) => GlobalCardOrderNotifier(),
);

/// Ce StateNotifier gère un Map<onglet, listeDeCartId> pour l'ordre des cartes.
/// Les changements sont enregistrés dans SharedPreferences via `_saveOrder()`.
class GlobalCardOrderNotifier extends StateNotifier<Map<String, List<String>>> {
  GlobalCardOrderNotifier() : super({}) {
    _loadInitialOrder();
  }

  /// Monte la carte d'un cran dans l'onglet [tabKey].
  void moveCardUp(String tabKey, String cardId) {
    final currentOrder = [...?state[tabKey]];
    final index = currentOrder.indexOf(cardId);
    if (index > 0) {
      currentOrder.removeAt(index);
      currentOrder.insert(index - 1, cardId);
      state = {...state, tabKey: currentOrder};
      _saveOrder();
    }
  }

  /// Descend la carte d'un cran dans l'onglet [tabKey].
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

  /// Charge l'ordre initial depuis SharedPreferences (clé "global_card_order"),
  /// ou définit un ordre par défaut si non trouvé.
  Future<void> _loadInitialOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('global_card_order');
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
          'upgrade_options',
        ],
        'trade': ['active_offers', 'trade_history', 'market_analysis'],
        'development': ['development_projects', 'resource_requirements'],
      };
    }
  }

  /// Sauvegarde l'ordre actuel dans SharedPreferences, clé "global_card_order".
  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_card_order', json.encode(state));
  }
}

/// Provider pour gérer le mode édition (sélection de carte, etc.).
/// Pas spécifique à une ville, mais vous pouvez le laisser paramétré si besoin.
final editModeProvider = StateProvider<EditModeState>(
  (ref) => const EditModeState(isEditing: false),
);

/// ---------------------------------------------------------------------------
///                         CLASSES ET WIDGETS
/// ---------------------------------------------------------------------------

/// État d'édition : [isEditing] + [selectedCardId].
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

/// Widget "EditableCard" pour entourer le contenu d'une carte.
/// Affiche des boutons (ex. flèches) en mode édition si besoin.
class EditableCard extends StatelessWidget {
  final String cardId;
  final Widget child;
  final bool isEditing;
  final VoidCallback? onSelect;
  final Widget additionalButtons;

  const EditableCard({
    Key? key,
    required this.cardId,
    required this.child,
    required this.isEditing,
    this.onSelect,
    this.additionalButtons = const SizedBox.shrink(),
  }) : super(key: key);

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
        ),
        child: Stack(
          children: [
            /// Contenu principal
            Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),

            /// Boutons additionnels (ex. flèches)
            if (isEditing)
              Positioned(
                top: 16,
                right: 16,
                child: additionalButtons,
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget principal pour afficher la "CityView" (fenêtre draggable).
/// Ici, la position et l'ordre des cartes sont identiques pour TOUTES les villes.
class CityView extends ConsumerStatefulWidget {
  final City city;

  const CityView({Key? key, required this.city}) : super(key: key);

  @override
  ConsumerState<CityView> createState() => _CityViewState();
}

class _CityViewState extends ConsumerState<CityView>
    with TickerProviderStateMixin {
  static const double _defaultWidth = 450;
  static const double _defaultHeight = 600;

  final NumberFormat _numberFormat = NumberFormat.decimalPattern();
  late TabController _tabController;

  Offset _position = const Offset(20, 20);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadLayout();
  }

  /// Charge la position (globale) depuis SharedPreferences (clé "global_layout").
  Future<void> _loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final layoutData = prefs.getString('global_layout');
    // Position par défaut (20,20) si on ne trouve rien
    double defaultX = 20.0;
    double defaultY = 20.0;

    if (layoutData != null) {
      final map = json.decode(layoutData) as Map<String, dynamic>;
      defaultX = map['x'] as double? ?? 20.0;
      defaultY = map['y'] as double? ?? 20.0;
    }

    setState(() {
      _position = Offset(defaultX, defaultY);
    });

    // On met aussi à jour le globalLayoutConfigProvider (en mémoire)
    ref.read(globalLayoutConfigProvider.notifier).state = {
      'x': defaultX,
      'y': defaultY,
    };
  }

  /// Sauvegarde la position globale dans SharedPreferences (clé "global_layout").
  Future<void> _saveLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'x': _position.dx,
      'y': _position.dy,
    };
    await prefs.setString('global_layout', json.encode(map));

    // Mise à jour du provider global en mémoire
    ref.read(globalLayoutConfigProvider.notifier).state = {
      'x': _position.dx,
      'y': _position.dy,
    };
  }

  void _toggleEditMode() {
    final editMode = ref.read(editModeProvider);
    ref.read(editModeProvider.notifier).state = EditModeState(
      isEditing: !editMode.isEditing,
    );
  }

  void _selectCard(String cardId) {
    final editMode = ref.read(editModeProvider);
    final newCardId = (editMode.selectedCardId == cardId) ? null : cardId;
    ref.read(editModeProvider.notifier).state =
        editMode.copyWith(selectedCardId: newCardId);
  }

  /// Enveloppe [child] dans un [EditableCard] et ajoute les boutons de réorg.
  /// [tabKey] précise dans quel onglet se trouve la carte.
  Widget _wrapInEditableCard(
    String cardId,
    Widget child, {
    required String tabKey,
  }) {
    final editMode = ref.watch(editModeProvider);

    return EditableCard(
      cardId: cardId,
      isEditing: editMode.isEditing,
      onSelect: () => _selectCard(cardId),
      additionalButtons: editMode.isEditing
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  onPressed: () {
                    ref
                        .read(globalCardOrderProvider.notifier)
                        .moveCardUp(tabKey, cardId);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  onPressed: () {
                    ref
                        .read(globalCardOrderProvider.notifier)
                        .moveCardDown(tabKey, cardId);
                  },
                ),
              ],
            )
          : const SizedBox.shrink(),
      child: child,
    );
  }

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
    final width =
        screenSize.width > 400 ? _defaultWidth : screenSize.width * 0.8;
    final height =
        screenSize.height > 600 ? _defaultHeight : screenSize.height * 0.8;

    // On "clamp" pour éviter que la fenêtre ne sorte de l'écran
    final clampedX = _position.dx.clamp(0, screenSize.width - width).toDouble();
    final clampedY =
        _position.dy.clamp(0, screenSize.height - height).toDouble();
    final effectivePosition = Offset(clampedX, clampedY);

    return Positioned(
      left: effectivePosition.dx,
      top: effectivePosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
          });
        },
        onPanEnd: (_) => _saveLayout(),
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

  Widget _buildHeader() {
    final editMode = ref.watch(editModeProvider);

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
            onPressed: () {
              if (editMode.isEditing) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Fermer la fenêtre ?'),
                      content: const Text(
                          'Voulez-vous vraiment quitter le mode édition ?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            _toggleEditMode();
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Oui'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Non'),
                        ),
                      ],
                    );
                  },
                );
              } else {
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      dragStartBehavior: DragStartBehavior.start,
      tabs: const [
        Tab(text: 'Vue d\'ensemble'),
        Tab(text: 'Production'),
        Tab(text: 'Commerce'),
        Tab(text: 'Développement'),
      ],
    );
  }

  /// On récupère l'ordre global des cartes pour chaque onglet depuis
  /// [globalCardOrderProvider]. Cela s'applique à TOUTES les villes.
  Widget _buildOverviewTab() {
    final orderMap = ref.watch(globalCardOrderProvider);
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

  Widget _buildProductionTab() {
    final orderMap = ref.watch(globalCardOrderProvider);
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

  Widget _buildTradeTab() {
    final orderMap = ref.watch(globalCardOrderProvider);
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

  Widget _buildDevelopmentTab() {
    final orderMap = ref.watch(globalCardOrderProvider);
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
  ///                          CARTES "OVERVIEW"
  /// -------------------------------------------------------------------------
  Widget _buildCityInfo() {
    return _wrapInEditableCard(
      'city_info',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('INFORMATIONS',
                  style: Theme.of(context).textTheme.labelMedium),
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

  Widget _buildQuickStats() {
    return _wrapInEditableCard(
      'quick_stats',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STATISTIQUES',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 12),
              _buildResourcesGrid(),
            ],
          ),
        ),
      ),
      tabKey: 'overview',
    );
  }

  Widget _buildRecentActivity() {
    return _wrapInEditableCard(
      'recent_activity',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ACTIVITÉ RÉCENTE',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 12),
              const Center(child: Text('Historique des activités à venir')),
            ],
          ),
        ),
      ),
      tabKey: 'overview',
    );
  }

  /// -------------------------------------------------------------------------
  ///                         CARTES "PRODUCTION"
  /// -------------------------------------------------------------------------
  Widget _buildResourcesOverview() {
    return _wrapInEditableCard(
      'resources_overview',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PRODUCTION',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 12),
              _buildResourcesList(),
            ],
          ),
        ),
      ),
      tabKey: 'production',
    );
  }

  Widget _buildProductionTrends() {
    return _wrapInEditableCard(
      'production_trends',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TENDANCES', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 12),
              const Center(child: Text('Graphiques de tendances à venir')),
            ],
          ),
        ),
      ),
      tabKey: 'production',
    );
  }

  Widget _buildProductionEfficiency() {
    return _wrapInEditableCard(
      'production_efficiency',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EFFICACITÉ',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 12),
              const Center(child: Text('Métriques d\'efficacité à venir')),
            ],
          ),
        ),
      ),
      tabKey: 'production',
    );
  }

  Widget _buildUpgradeOptions() {
    return _wrapInEditableCard(
      'upgrade_options',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AMÉLIORATIONS POSSIBLES',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 12),
              const Center(child: Text('Options d\'amélioration à venir')),
            ],
          ),
        ),
      ),
      tabKey: 'production',
    );
  }

  /// -------------------------------------------------------------------------
  ///                         CARTES "COMMERCE"
  /// -------------------------------------------------------------------------
  Widget _buildActiveOffers() {
    return _wrapInEditableCard(
      'active_offers',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OFFRES ACTIVES',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 12),
              const Center(child: Text('Liste des offres à venir')),
            ],
          ),
        ),
      ),
      tabKey: 'trade',
    );
  }

  Widget _buildTradeHistory() {
    return _wrapInEditableCard(
      'trade_history',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HISTORIQUE',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 12),
              const Center(child: Text('Historique des échanges à venir')),
            ],
          ),
        ),
      ),
      tabKey: 'trade',
    );
  }

  Widget _buildMarketAnalysis() {
    return _wrapInEditableCard(
      'market_analysis',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ANALYSE DU MARCHÉ',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 12),
              const Center(child: Text('Analyse des prix à venir')),
            ],
          ),
        ),
      ),
      tabKey: 'trade',
    );
  }

  /// -------------------------------------------------------------------------
  ///                      CARTES "DÉVELOPPEMENT"
  /// -------------------------------------------------------------------------
  Widget _buildDevelopmentProjects() {
    return _wrapInEditableCard(
      'development_projects',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PROJETS EN COURS',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 12),
              const Center(child: Text('Liste des projets à venir')),
            ],
          ),
        ),
      ),
      tabKey: 'development',
    );
  }

  Widget _buildResourceRequirements() {
    return _wrapInEditableCard(
      'resource_requirements',
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RESSOURCES NÉCESSAIRES',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 12),
              const Center(child: Text('Besoins en ressources à venir')),
            ],
          ),
        ),
      ),
      tabKey: 'development',
    );
  }

  /// -------------------------------------------------------------------------
  ///                          LISTE DE RESSOURCES
  /// -------------------------------------------------------------------------
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
          'value': '${widget.city.resources.crates}/h'
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

  Widget _buildResourcesList() {
    return Column(
      children: _resourcesList
          .where((res) => (res['value'] as double) > 0)
          .map((res) => _buildResourceRow(
                res['icon'] as IconData,
                res['label'] as String,
                res['value'] as double,
              ))
          .toList(),
    );
  }

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
