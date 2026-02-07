import 'exercise.dart';

/// User's response to a single question or prompt
class UserResponse {
  final ExerciseType exerciseType;
  final int partIndex;
  final int questionIndex;
  final String question;
  final String response;
  final DateTime timestamp;
  final bool? isCorrect;
  final double? score;

  UserResponse({
    required this.exerciseType,
    required this.partIndex,
    required this.questionIndex,
    required this.question,
    required this.response,
    required this.timestamp,
    this.isCorrect,
    this.score,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseType': exerciseType.name,
      'partIndex': partIndex,
      'questionIndex': questionIndex,
      'question': question,
      'response': response,
      'timestamp': timestamp.toIso8601String(),
      'isCorrect': isCorrect,
      'score': score,
    };
  }
}
