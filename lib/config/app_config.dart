import 'api_keys.dart' as keys;

/// Application configuration constants
class AppConfig {
  // Gemini API Configuration
  static const String geminiApiKey = keys.geminiApiKey;
  static const String generationModel = 'gemini-2.0-flash';
  static const String liveModel = 'gemini-2.0-flash';

  // Default settings
  static const int defaultDifficulty = 5;
  static const String defaultLanguage = 'Italian';
  static const double defaultTtsSpeed = 0.5;

  // Exercise configuration
  static const int partsPerExercise = 3;
  static const int wordsPerAttentionPart = 5;
  static const int sequencesPerNumberPart = 6;

  // Article length per difficulty level
  static const Map<int, int> articleLengthPerLevel = {
    1: 100, 2: 150, 3: 200, 4: 250, 5: 300,
    6: 350, 7: 400, 8: 450, 9: 500, 10: 550,
  };

  // Questions per article per difficulty level
  static const Map<int, int> questionsPerLevel = {
    1: 2, 2: 3, 3: 3, 4: 4, 5: 4,
    6: 5, 7: 5, 8: 6, 9: 6, 10: 7,
  };

  // Word length for attention exercise per level
  static const Map<int, int> wordLengthPerLevel = {
    1: 4, 2: 5, 3: 6, 4: 7, 5: 8,
    6: 9, 7: 10, 8: 12, 9: 14, 10: 16,
  };

  // Memory span (number of digits) per level
  static const Map<int, List<int>> spanPerLevel = {
    1: [3, 4], 2: [4, 5], 3: [4, 5, 6], 4: [5, 6], 5: [5, 6, 7],
    6: [6, 7, 8], 7: [6, 7, 8], 8: [7, 8, 9], 9: [8, 9, 10], 10: [9, 10, 11],
  };
}
