import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';
import '../models/exercise.dart';

/// Service for generating cognitive exercises using Gemini API
class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: AppConfig.generationModel,
      apiKey: AppConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        maxOutputTokens: 8000,
      ),
    );
  }

  /// Generate a complete set of exercises for the given difficulty level
  Future<ExerciseSet> generateExercises(int difficulty) async {
    final prompt = _buildGenerationPrompt(difficulty);

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '';

    // Extract JSON from response
    final jsonStr = _extractJson(text);
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;

    return ExerciseSet.fromJson(json, difficulty);
  }

  /// Evaluate a user's response for correctness
  Future<Map<String, dynamic>> evaluateResponse({
    required ExerciseType exerciseType,
    required String question,
    required String userResponse,
    required String correctAnswer,
  }) async {
    final prompt = '''
Valuta la seguente risposta dell'utente.

Tipo esercizio: ${exerciseType.name}
Domanda/Consegna: $question
Risposta corretta: $correctAnswer
Risposta utente: $userResponse

Rispondi SOLO con un JSON nel formato:
{
  "isCorrect": true/false,
  "score": 0-100,
  "feedback": "breve feedback in italiano"
}
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '{}';
    final jsonStr = _extractJson(text);

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {'isCorrect': false, 'score': 0, 'feedback': 'Errore nella valutazione'};
    }
  }

  String _buildGenerationPrompt(int difficulty) {
    final articleLength = AppConfig.articleLengthPerLevel[difficulty] ?? 300;
    final questionsCount = AppConfig.questionsPerLevel[difficulty] ?? 4;
    final wordLength = AppConfig.wordLengthPerLevel[difficulty] ?? 8;
    final spans = AppConfig.spanPerLevel[difficulty] ?? [5, 6, 7];

    return '''
Genera un set completo di esercizi di stimolazione cognitiva in ITALIANO per difficoltà $difficulty/10.

Rispondi ESCLUSIVAMENTE con un JSON valido nel seguente formato (nessun testo prima o dopo):

{
  "memory": [
    {
      "title": "Titolo articolo 1",
      "content": "Testo dell'articolo di circa $articleLength parole con dettagli specifici (nomi, date, luoghi, numeri)...",
      "questions": ["Domanda 1?", "Domanda 2?", ...]
    },
    {
      "title": "Titolo articolo 2",
      "content": "...",
      "questions": [...]
    },
    {
      "title": "Titolo articolo 3",
      "content": "...",
      "questions": [...]
    }
  ],
  "attention": [
    [
      {"word": "PAROLA1", "hidden_string": "3M7P2A5R1O8L4A6"},
      {"word": "PAROLA2", "hidden_string": "..."},
      {"word": "PAROLA3", "hidden_string": "..."},
      {"word": "PAROLA4", "hidden_string": "..."},
      {"word": "PAROLA5", "hidden_string": "..."}
    ],
    [...],
    [...]
  ],
  "fluency": [
    {
      "type": "phonemic",
      "instruction": "Elenca il maggior numero di parole che iniziano con...",
      "target": "CA"
    },
    {
      "type": "semantic",
      "instruction": "Elenca il maggior numero di...",
      "target": "animali"
    },
    {
      "type": "alternating",
      "instruction": "Alterna parole che iniziano con... e...",
      "target": "MA/PA"
    }
  ],
  "numbers": [
    [
      {"digits": [4, 7, 2, 9, 1]},
      {"digits": [8, 3, 6, 2, 5]},
      {"digits": [...]},
      {"digits": [...]},
      {"digits": [...]},
      {"digits": [...]}
    ],
    [...],
    [...]
  ]
}

REQUISITI:
- MEMORIA: 3 articoli di circa $articleLength parole ciascuno, con $questionsCount domande per articolo
- ATTENZIONE: 3 parti con 5 parole nascoste ciascuna, parole lunghe max $wordLength lettere
- FLUENZA: 3 parti (fonemica, semantica, alternata) con difficoltà appropriata al livello
- NUMERI: 3 parti con 6 sequenze ciascuna, lunghezza sequenze da ${spans.join(' a ')} cifre
- Tutte le parole nascoste devono essere intervallate da numeri casuali
- La difficoltà delle sillabe e categorie deve essere appropriata al livello $difficulty
''';
  }

  /// Validate which words from a list belong to a semantic category
  /// Returns the list of valid words.
  Future<List<String>> validateSemanticWords(
    List<String> words,
    String category,
  ) async {
    if (words.isEmpty) return [];

    final prompt = '''
Verifica quali delle seguenti parole appartengono alla categoria "$category".
Parole: ${words.join(', ')}

Rispondi SOLO con un JSON nel formato:
{"valid": ["parola1", "parola2"], "invalid": ["parola3"]}
Non aggiungere altro testo.
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '{}';
    final jsonStr = _extractJson(text);

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return List<String>.from(json['valid'] ?? []);
    } catch (e) {
      // If parsing fails, assume all words are valid (don't penalize for API issues)
      return words;
    }
  }

  String _extractJson(String text) {
    // Try to find JSON between curly braces
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');

    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }

    return text;
  }
}
