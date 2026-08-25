import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/engines/farm_resource.dart';
import '../domain/models/farm/farm_state.dart';
import '../domain/models/farm/farm_tier.dart';

class FarmResourceBar extends StatelessWidget {
  const FarmResourceBar({
    super.key,
    required this.balances,
    required this.onApply,
    this.highlight,
    this.busy = false,
  });

  final UserResourceBalances balances;
  final FarmResourceType? highlight;
  final bool busy;
  final ValueChanged<FarmResourceType> onApply;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ResourceChip(
            icon: Icons.water_drop_outlined,
            label: '물',
            balance: balances.waterBalance,
            emphasized: highlight == FarmResourceType.water,
            enabled: !busy && balances.waterBalance > 0,
            onTap: () => onApply(FarmResourceType.water),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ResourceChip(
            icon: Icons.grass_outlined,
            label: '사료',
            balance: balances.feedBalance,
            emphasized: highlight == FarmResourceType.feed,
            enabled: !busy && balances.feedBalance > 0,
            onTap: () => onApply(FarmResourceType.feed),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ResourceChip(
            icon: Icons.auto_awesome_outlined,
            label: '영양제',
            balance: balances.nutrientBalance,
            emphasized: highlight == FarmResourceType.nutrient,
            enabled: !busy && balances.nutrientBalance > 0,
            onTap: () => onApply(FarmResourceType.nutrient),
          ),
        ),
      ],
    );
  }
}

class _ResourceChip extends StatelessWidget {
  const _ResourceChip({
    required this.icon,
    required this.label,
    required this.balance,
    required this.onTap,
    required this.enabled,
    required this.emphasized,
  });

  final IconData icon;
  final String label;
  final int balance;
  final VoidCallback onTap;
  final bool enabled;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final fg = enabled
        ? (emphasized ? BalmiColors.potato : BalmiColors.ink)
        : BalmiColors.sub;
    final bg = enabled
        ? (emphasized ? BalmiColors.potato.withValues(alpha: 0.12) : BalmiColors.mist)
        : BalmiColors.line.withValues(alpha: 0.5);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: fg),
              const SizedBox(height: 4),
              Text(
                label,
                style: BalmiTheme.body(size: 12, weight: FontWeight.w800, color: fg),
              ),
              Text(
                '$balance',
                style: BalmiTheme.num(size: 14, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
