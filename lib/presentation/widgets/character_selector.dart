import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

class CharacterSelector extends StatelessWidget {
  final String selectedCharacter;
  final bool isCustom;
  final TextEditingController customController;
  final ValueChanged<String> onSelected;
  final ValueChanged<bool> onCustomToggle;

  const CharacterSelector({
    super.key,
    required this.selectedCharacter,
    required this.isCustom,
    required this.customController,
    required this.onSelected,
    required this.onCustomToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...AppConstants.predefinedCharacters.map((name) {
              final isSelected = !isCustom && selectedCharacter == name;
              return ChoiceChip(
                label: Text(name),
                selected: isSelected,
                onSelected: (_) {
                  onSelected(name);
                  onCustomToggle(false);
                },
                selectedColor: AppColors.accent.withOpacity(0.3),
              );
            }),
            ChoiceChip(
              label: Text(isCustom && customController.text.isNotEmpty
                  ? customController.text
                  : 'Inny'),
              selected: isCustom,
              onSelected: (_) => onCustomToggle(true),
              selectedColor: AppColors.accent.withOpacity(0.3),
            ),
          ],
        ),
        if (isCustom) ...[
          const SizedBox(height: 12),
          TextField(
            controller: customController,
            decoration: const InputDecoration(
              labelText: 'Imię',
              hintText: 'Wpisz imię kurczaka',
            ),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ],
    );
  }
}
