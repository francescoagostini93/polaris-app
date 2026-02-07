import 'package:flutter/material.dart';
import '../models/exercise.dart';

/// Visual progress indicator for the exercise session
class SessionProgressIndicator extends StatelessWidget {
  final ExerciseType? currentType;
  final Map<ExerciseType, double> scores;

  const SessionProgressIndicator({
    super.key,
    this.currentType,
    required this.scores,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final types = ExerciseType.values;

    return Row(
      children: List.generate(types.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final prevType = types[index ~/ 2];
          final isCompleted = scores.containsKey(prevType);
          return Expanded(
            child: Container(
              height: 3,
              color: isCompleted
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.2),
            ),
          );
        }

        final type = types[index ~/ 2];
        final isActive = type == currentType;
        final isCompleted = scores.containsKey(type);

        return _buildDot(theme, type, isActive, isCompleted);
      }),
    );
  }

  Widget _buildDot(ThemeData theme, ExerciseType type, bool isActive, bool isCompleted) {
    final size = isActive ? 36.0 : 28.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isCompleted
            ? theme.colorScheme.primary
            : isActive
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '${ExerciseType.values.indexOf(type) + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
      ),
    );
  }
}
