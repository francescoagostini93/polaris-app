import 'package:flutter/material.dart';
import '../models/exercise.dart';

/// Card displaying exercise type info
class ExerciseCard extends StatelessWidget {
  final ExerciseType type;
  final bool isActive;
  final bool isCompleted;
  final double? score;

  const ExerciseCard({
    super.key,
    required this.type,
    this.isActive = false,
    this.isCompleted = false,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primaryContainer
            : isCompleted
                ? theme.colorScheme.secondaryContainer.withOpacity(0.5)
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary
              : isCompleted
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.outline.withOpacity(0.3),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          _buildIcon(theme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Text(
                  _typeDescription,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted && score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _scoreColor(score!),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${score!.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          else if (isCompleted)
            Icon(Icons.check_circle, color: theme.colorScheme.secondary)
          else if (isActive)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    IconData icon;
    switch (type) {
      case ExerciseType.memory:
        icon = Icons.psychology;
        break;
      case ExerciseType.attention:
        icon = Icons.visibility;
        break;
      case ExerciseType.fluency:
        icon = Icons.record_voice_over;
        break;
      case ExerciseType.numbers:
        icon = Icons.pin;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: isActive ? Colors.white : theme.colorScheme.primary,
        size: 22,
      ),
    );
  }

  String get _typeName {
    switch (type) {
      case ExerciseType.memory:
        return 'Memoria';
      case ExerciseType.attention:
        return 'Attenzione';
      case ExerciseType.fluency:
        return 'Fluenza Verbale';
      case ExerciseType.numbers:
        return 'Liste Numeriche';
    }
  }

  String get _typeDescription {
    switch (type) {
      case ExerciseType.memory:
        return 'Leggi e rispondi a domande';
      case ExerciseType.attention:
        return 'Trova parole nascoste';
      case ExerciseType.fluency:
        return 'Genera parole per categoria';
      case ExerciseType.numbers:
        return 'Ripeti sequenze numeriche';
    }
  }

  Color _scoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
