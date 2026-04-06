import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class QuantityToggle extends StatefulWidget {
  final int quantity;
  final bool isEnabled;
  final ValueChanged<int> onConfirm;

  const QuantityToggle({
    super.key,
    required this.quantity,
    required this.isEnabled,
    required this.onConfirm,
  });

  @override
  State<QuantityToggle> createState() => _QuantityToggleState();
}

class _QuantityToggleState extends State<QuantityToggle> {
  late int _localQuantity;

  @override
  void initState() {
    super.initState();
    _localQuantity = widget.quantity;
  }

  @override
  void didUpdateWidget(covariant QuantityToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity) {
      _localQuantity = widget.quantity;
    }
  }

  void _changeQuantity(int newQty) {
    setState(() {
      _localQuantity = newQty;
    });
  }

  void _confirm() {
    if (_localQuantity != widget.quantity) {
      widget.onConfirm(_localQuantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isChanged = _localQuantity != widget.quantity;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: widget.isEnabled
              ? theme.colorScheme.onSurface
              : theme.dividerColor,
          onPressed: widget.isEnabled && _localQuantity > 1
              ? () => _changeQuantity(_localQuantity - 1)
              : null,
          splashRadius: 18,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: widget.isEnabled
                ? theme.colorScheme.surface
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Text(
            _localQuantity.toString(),
            style: (theme.textTheme.bodyLarge ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: widget.isEnabled
                  ? theme.textTheme.bodyLarge?.color
                  : theme.textTheme.bodySmall?.color,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          color: widget.isEnabled
              ? theme.colorScheme.onSurface
              : theme.dividerColor,
          onPressed: widget.isEnabled
              ? () => _changeQuantity(_localQuantity + 1)
              : null,
          splashRadius: 18,
        ),
        if (widget.isEnabled && isChanged)
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: IconButton(
              icon: const Icon(Icons.check_circle),
              color: AppColors.success,
              onPressed: _confirm,
              splashRadius: 18,
              tooltip: 'Confirm quantity',
            ),
          ),
      ],
    );
  }
}
