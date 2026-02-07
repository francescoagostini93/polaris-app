import 'exercise.dart';
import 'user_response.dart';

/// Complete results from a cognitive exercise session
class SessionResult {
  final DateTime startTime;
  final DateTime? endTime;
  final int difficulty;
  final ExerciseSet exerciseSet;
  final List<UserResponse> responses;
  final Map<ExerciseType, double> scores;

  SessionResult({
    required this.startTime,
    this.endTime,
    required this.difficulty,
    required this.exerciseSet,
    required this.responses,
    required this.scores,
  });

  /// Total duration of the session
  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  /// Overall score (0-100)
  double get totalScore {
    if (scores.isEmpty) return 0;
    return scores.values.reduce((a, b) => a + b) / scores.length;
  }

  /// Get responses for a specific exercise type
  List<UserResponse> getResponsesForType(ExerciseType type) {
    return responses.where((r) => r.exerciseType == type).toList();
  }

  /// Generate email report content
  String generateReport() {
    final buffer = StringBuffer();

    buffer.writeln('REPORT SESSIONE ESERCIZI COGNITIVI');
    buffer.writeln('=' * 40);
    buffer.writeln();
    buffer.writeln('Data: ${_formatDate(startTime)}');
    buffer.writeln('Difficoltà: $difficulty/10');
    buffer.writeln('Durata: ${_formatDuration(duration)}');
    buffer.writeln();

    // Memory exercise
    buffer.writeln('ESERCIZIO 1 - MEMORIA');
    buffer.writeln('-' * 30);
    _writeMemorySection(buffer);
    buffer.writeln();

    // Attention exercise
    buffer.writeln('ESERCIZIO 2 - ATTENZIONE');
    buffer.writeln('-' * 30);
    _writeAttentionSection(buffer);
    buffer.writeln();

    // Fluency exercise
    buffer.writeln('ESERCIZIO 3 - FLUENZA VERBALE');
    buffer.writeln('-' * 30);
    _writeFluencySection(buffer);
    buffer.writeln();

    // Numbers exercise
    buffer.writeln('ESERCIZIO 4 - LISTE NUMERICHE');
    buffer.writeln('-' * 30);
    _writeNumbersSection(buffer);
    buffer.writeln();

    // Total score
    buffer.writeln('=' * 40);
    buffer.writeln('PUNTEGGIO TOTALE: ${totalScore.toStringAsFixed(1)}/100');
    buffer.writeln();
    buffer.writeln('Punteggi per esercizio:');
    for (final entry in scores.entries) {
      buffer.writeln('  - ${_exerciseTypeName(entry.key)}: ${entry.value.toStringAsFixed(1)}');
    }

    return buffer.toString();
  }

  void _writeMemorySection(StringBuffer buffer) {
    final memoryResponses = getResponsesForType(ExerciseType.memory);
    for (int i = 0; i < exerciseSet.memoryArticles.length; i++) {
      final article = exerciseSet.memoryArticles[i];
      buffer.writeln('\nArticolo ${i + 1}: ${article.title}');
      buffer.writeln(article.content);
      buffer.writeln('\nDomande e Risposte:');

      final articleResponses = memoryResponses.where((r) => r.partIndex == i).toList();
      for (int j = 0; j < article.questions.length; j++) {
        final response = articleResponses.length > j ? articleResponses[j] : null;
        buffer.writeln('  ${j + 1}. ${article.questions[j]}');
        buffer.writeln('     Risposta: ${response?.response ?? "Non risposto"}');
      }
    }
    buffer.writeln('\nPunteggio Memoria: ${scores[ExerciseType.memory]?.toStringAsFixed(1) ?? "N/A"}');
  }

  void _writeAttentionSection(StringBuffer buffer) {
    final attentionResponses = getResponsesForType(ExerciseType.attention);
    for (int i = 0; i < exerciseSet.attentionParts.length; i++) {
      buffer.writeln('\nParte ${i + 1}:');
      for (final word in exerciseSet.attentionParts[i]) {
        buffer.writeln('  ${word.hiddenString}');
        buffer.writeln('  (Parola nascosta: ${word.word})');
      }
      final partResponses = attentionResponses.where((r) => r.partIndex == i).toList();
      buffer.writeln('  Risposte utente: ${partResponses.map((r) => r.response).join(", ")}');
    }
    buffer.writeln('\nPunteggio Attenzione: ${scores[ExerciseType.attention]?.toStringAsFixed(1) ?? "N/A"}');
  }

  void _writeFluencySection(StringBuffer buffer) {
    final fluencyResponses = getResponsesForType(ExerciseType.fluency);
    for (int i = 0; i < exerciseSet.fluencyParts.length; i++) {
      final part = exerciseSet.fluencyParts[i];
      buffer.writeln('\nParte ${i + 1} (${part.type}): ${part.instruction}');
      buffer.writeln('  Target: ${part.target}');
      final partResponses = fluencyResponses.where((r) => r.partIndex == i).toList();
      buffer.writeln('  Parole generate: ${partResponses.map((r) => r.response).join(", ")}');
    }
    buffer.writeln('\nPunteggio Fluenza: ${scores[ExerciseType.fluency]?.toStringAsFixed(1) ?? "N/A"}');
  }

  void _writeNumbersSection(StringBuffer buffer) {
    final numberResponses = getResponsesForType(ExerciseType.numbers);
    for (int i = 0; i < exerciseSet.numberParts.length; i++) {
      buffer.writeln('\nParte ${i + 1}:');
      for (int j = 0; j < exerciseSet.numberParts[i].length; j++) {
        final seq = exerciseSet.numberParts[i][j];
        buffer.writeln('  Sequenza: ${seq.displayString}');
        final response = numberResponses.firstWhere(
          (r) => r.partIndex == i && r.questionIndex == j,
          orElse: () => UserResponse(
            exerciseType: ExerciseType.numbers,
            partIndex: i,
            questionIndex: j,
            question: '',
            response: 'Non risposto',
            timestamp: DateTime.now(),
          ),
        );
        buffer.writeln('  Risposta: ${response.response}');
      }
    }
    buffer.writeln('\nPunteggio Numeri: ${scores[ExerciseType.numbers]?.toStringAsFixed(1) ?? "N/A"}');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes}m ${seconds}s';
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
}
