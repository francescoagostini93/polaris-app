import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercise_provider.dart';
import '../providers/settings_provider.dart';
import '../models/exercise.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<ExerciseProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Risultati'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Score Card
                    _buildTotalScoreCard(theme, provider),

                    const SizedBox(height: 20),

                    // Individual Scores
                    Text(
                      'Punteggi per Esercizio',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...ExerciseType.values.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildScoreRow(
                          theme,
                          type,
                          provider.scores[type] ?? 0,
                          provider.getResponsesForType(type),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Session Info
                    Text(
                      'Dettagli Sessione',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      theme,
                      'Difficoltà',
                      '${provider.difficulty}/10',
                    ),
                    _buildDetailRow(
                      theme,
                      'Durata',
                      _formatDuration(provider.sessionResult?.duration ?? Duration.zero),
                    ),
                    _buildDetailRow(
                      theme,
                      'Risposte totali',
                      '${provider.responses.length}',
                    ),

                    const SizedBox(height: 20),

                    // Response Details
                    Text(
                      'Dettaglio Risposte',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...provider.responses.map((response) {
                      return _buildResponseDetail(theme, response);
                    }),
                  ],
                ),
              ),
            ),

            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Send Report Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: settings.isEmailConfigured
                          ? () => _sendReport(context, provider, settings)
                          : null,
                      icon: const Icon(Icons.email),
                      label: Text(
                        settings.isEmailConfigured
                            ? 'Invia Report a ${settings.email}'
                            : 'Configura email nelle impostazioni',
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // New Session Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        provider.reset();
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Torna alla Home'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalScoreCard(ThemeData theme, ExerciseProvider provider) {
    final score = provider.totalScore;
    final color = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Punteggio Totale',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getScoreMessage(score),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(
    ThemeData theme,
    ExerciseType type,
    double score,
    List responses,
  ) {
    final color = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _exerciseIcon(type, theme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _exerciseTypeName(type),
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '${responses.length} risposte',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          // Score bar
          SizedBox(
            width: 80,
            child: Column(
              children: [
                Text(
                  '${score.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseDetail(ThemeData theme, dynamic response) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: response.isCorrect == true
              ? Colors.green.withOpacity(0.3)
              : response.isCorrect == false
                  ? Colors.red.withOpacity(0.3)
                  : theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                response.isCorrect == true
                    ? Icons.check_circle
                    : response.isCorrect == false
                        ? Icons.cancel
                        : Icons.remove_circle_outline,
                size: 16,
                color: response.isCorrect == true
                    ? Colors.green
                    : response.isCorrect == false
                        ? Colors.red
                        : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                _exerciseTypeName(response.exerciseType),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (response.question.isNotEmpty)
            Text(
              response.question,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            'Risposta: ${response.response}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _exerciseIcon(ExerciseType type, ThemeData theme) {
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: theme.colorScheme.primary, size: 20),
    );
  }

  String _exerciseTypeName(ExerciseType type) {
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

  List getResponsesForType(ExerciseProvider provider, ExerciseType type) {
    return provider.responses.where((r) => r.exerciseType == type).toList();
  }

  String _getScoreMessage(double score) {
    if (score >= 90) return 'Eccellente!';
    if (score >= 80) return 'Ottimo lavoro!';
    if (score >= 70) return 'Buon risultato!';
    if (score >= 60) return 'Discreto, continua cosi!';
    if (score >= 50) return 'Puoi fare di meglio!';
    return 'Non arrenderti!';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  void _sendReport(
    BuildContext context,
    ExerciseProvider provider,
    SettingsProvider settings,
  ) async {
    final success = await provider.sendReport(settings.email);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Report inviato con successo!'
                : 'Errore nell\'invio del report. Verifica la configurazione email.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
