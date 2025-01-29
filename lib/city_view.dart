import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/city.dart';

// Provider pour gérer l'état d'édition et la carte sélectionnée
final editModeProvider = StateProvider.family<EditModeState, String>(
    (ref, cityId) => EditModeState(isEditing: false, selectedCardId: null));

// Provider pour la configuration du layout
final cityLayoutConfigProvider =
    StateProvider.family<Map<String, dynamic>, String>(
  (ref, cityId) => {
    'x': 20.0,
    'y': 20.0,
  },
);

// Classe pour représenter l'état d'édition
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

// Widget personnalisé pour les cartes éditables
class EditableCard extends StatelessWidget {
  final String cardId;
  final Widget child;
  final bool isEditing;
  final bool isSelected;
  final VoidCallback? onSelect;

  const EditableCard({
    super.key,
    required this.cardId,
    required this.child,
    required this.isEditing,
    required this.isSelected,
    this.onSelect,
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
            child,
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
          ],
        ),
      ),
    );
  }
}

class CityView extends ConsumerStatefulWidget {
  final City city;
  const CityView({super.key, required this.city});

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

  void _toggleEditMode() {
    final editMode = ref.read(editModeProvider(widget.city.name));
    ref.read(editModeProvider(widget.city.name).notifier).state = EditModeState(
      isEditing: !editMode.isEditing,
      selectedCardId: null,
    );
  }

  void _selectCard(String cardId) {
    final editMode = ref.read(editModeProvider(widget.city.name));
    ref.read(editModeProvider(widget.city.name).notifier).state =
        editMode.copyWith(
      selectedCardId: editMode.selectedCardId == cardId ? null : cardId,
    );
  }

  Widget _wrapInEditableCard(String cardId, Widget child) {
    final editMode = ref.watch(editModeProvider(widget.city.name));
    return EditableCard(
      cardId: cardId,
      isEditing: editMode.isEditing,
      isSelected: editMode.selectedCardId == cardId,
      onSelect: () => _selectCard(cardId),
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
                      _buildDevelopmentProjects(),
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

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildCityInfo(),
            _buildQuickStats(),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

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
    );
  }

  Widget _buildProductionTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildResourcesOverview(),
            _buildProductionTrends(),
            _buildProductionEfficiency(),
            _buildUpgradeOptions(),
          ],
        ),
      ),
    );
  }

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
    );
  }

  Widget _buildTradeTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildActiveOffers(),
            _buildTradeHistory(),
            _buildMarketAnalysis(),
          ],
        ),
      ),
    );
  }

  /// Cartes "Commerce"
  Widget _buildActiveOffers() {
    return Card(
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
    );
  }

  Widget _buildTradeHistory() {
    return Card(
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
    );
  }

  Widget _buildMarketAnalysis() {
    return Card(
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
    );
  }

  /// Cartes "Développement"
  Widget _buildUpgradeOptions() {
    return Card(
      key: const ValueKey('upgrade_options'),
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
    );
  }

  Widget _buildDevelopmentProjects() {
    return Card(
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
    );
  }

  Widget _buildResourceRequirements() {
    return Card(
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
    );
  }

  /// Liste des ressources de la ville sous forme de Rows (Production tab)
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

  /// Liste des ressources pour l'onglet "Vue d'ensemble" (grille)
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
              Text(
                label,
              ),
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

  /// Tableau descriptif des ressources
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
          'icon':
              Icons.diamond, // Si l'icône n'existe pas, utilisez autre chose
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
