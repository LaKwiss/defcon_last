import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/city.dart';
import 'package:intl/intl.dart';

class CityView extends ConsumerStatefulWidget {
  final City city;
  const CityView({super.key, required this.city});

  @override
  ConsumerState<CityView> createState() => _CityViewState();
}

class _CityViewState extends ConsumerState<CityView> {
  static const double _defaultWidth = 300;
  static const double _defaultHeight = 500;
  final NumberFormat _numberFormat = NumberFormat.decimalPattern();

  Offset _position = const Offset(20, 20);
  bool _isDragging = false;

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
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        child: GestureDetector(
          onPanStart: (_) => setState(() => _isDragging = true),
          onPanEnd: (_) => setState(() => _isDragging = false),
          onPanUpdate: (details) => setState(() {
            _position = Offset(
              (_position.dx + details.delta.dx)
                  .clamp(0, screenSize.width - width),
              (_position.dy + details.delta.dy)
                  .clamp(0, screenSize.height - height),
            );
          }),
          child: AnimatedOpacity(
            opacity: _isDragging ? 0.9 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCountryInfo(),
                          _buildDivider(),
                          _buildResourcesInfo(),
                          _buildDivider(),
                          _buildFactories(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(vertical: 8),
        color: Theme.of(context).dividerColor,
      );

  Widget _buildHeader(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).appBarTheme.backgroundColor,
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
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: 'Fermer',
              onPressed: () => Navigator.of(context).pop(),
              splashRadius: 20,
            ),
          ],
        ),
      );

  Widget _buildCountryInfo() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
                Icons.flag, 'Pays:', widget.city.country?.name ?? 'N/A'),
            const SizedBox(height: 6),
            _buildInfoRow(
              Icons.people,
              'Population:',
              _numberFormat.format(widget.city.population),
            ),
            if (widget.city.country?.doctrine != null) ...[
              const SizedBox(height: 6),
              _buildInfoRow(
                Icons.account_balance,
                'Doctrine:',
                widget.city.country!.doctrine.name,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 4),
                child: Text(
                  widget.city.country!.doctrine.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.8),
                      ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildInfoRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon,
              size: 16,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.8)),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _buildResourcesInfo() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PRODUCTION',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                    color: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.color
                        ?.withOpacity(0.8),
                  ),
            ),
            const SizedBox(height: 12),
            ..._buildResourceRows(),
          ],
        ),
      );

  List<Widget> _buildResourceRows() {
    final resources = [
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
    ];

    return resources
        .map((res) => _buildResourceRow(
              res['icon'] as IconData,
              res['label'] as String,
              res['value'] as double,
            ))
        .toList();
  }

  Widget _buildResourceRow(IconData icon, String label, double value) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
            const SizedBox(width: 12),
            Expanded(
                child:
                    Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            Text(
              value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: value > 0
                        ? Colors.greenAccent.shade400
                        : value < 0
                            ? Colors.redAccent.shade400
                            : null,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      );

  Widget _buildFactories(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONSTRUCTION D\'USINES',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.2,
                    color: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.color
                        ?.withOpacity(0.8),
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFactoryButton(context, 'Pétrole', Icons.oil_barrel),
                _buildFactoryButton(context, 'Métal', Icons.factory),
                _buildFactoryButton(context, 'Blé', Icons.grass),
                _buildFactoryButton(context, 'Rare', Icons.diamond),
              ],
            ),
          ],
        ),
      );

  Widget _buildFactoryButton(
          BuildContext context, String name, IconData icon) =>
      Tooltip(
        message: 'Construire une usine de $name',
        child: ElevatedButton.icon(
          onPressed: () => _showNotImplemented(context),
          icon: Icon(icon, size: 18),
          label: Text(name),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );

  void _showNotImplemented(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fonctionnalité en cours de développement'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
