import 'package:flutter/material.dart';

class FilterChipSelector<T> extends StatelessWidget {
  const FilterChipSelector({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelectionChanged,
    required this.labelBuilder,
  });

  final List<T> options;
  final T selectedValue;
  final ValueChanged<T> onSelectionChanged;
  final String Function(T) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return FilterChip(
          selected: isSelected,
          label: Text(labelBuilder(option)),
          onSelected: (selected) {
            if (selected) {
              onSelectionChanged(option);
            }
          },
          selectedColor: Theme.of(context).colorScheme.secondaryContainer,
          checkmarkColor: Theme.of(context).colorScheme.onSecondaryContainer,
          labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
        );
      }).toList(),
    );
  }
}
