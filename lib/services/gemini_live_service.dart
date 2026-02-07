import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/app_config.dart';

/// Service for live conversational interaction with Gemini
/// Used to guide the user through the exercise session
class GeminiLiveService {
  late GenerativeModel _model;
  ChatSession? _chat;
  String _gender = 'maschio';

  GeminiLiveService() {
    _initModel();
  }

  void _initModel() {
    _model = GenerativeModel(
      model: AppConfig.liveModel,
      apiKey: AppConfig.geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 2000,
      ),
      systemInstruction: Content.text(_buildSystemPrompt()),
    );
  }

  /// Set user gender and reinitialize model with updated prompt
  void setGender(String gender) {
    _gender = gender;
    _initModel();
  }

  String _buildSystemPrompt() {
    final genderInfo = _gender == 'femmina'
        ? 'L\'utente è una donna. Rivolgiti a lei al femminile (es. "sei pronta", "brava", "benvenuta").'
        : 'L\'utente è un uomo. Rivolgiti a lui al maschile (es. "sei pronto", "bravo", "benvenuto").';

    return '''
Sei un assistente cognitivo professionale e gentile che guida gli utenti attraverso esercizi di stimolazione cognitiva.

$genderInfo

REGOLA FONDAMENTALE: Le tue risposte vengono lette ad alta voce da un sintetizzatore vocale (TTS).
Quindi OGNI tua risposta deve contenere ESCLUSIVAMENTE il testo da pronunciare ad alta voce.
NON includere MAI:
- Istruzioni interne, note tra parentesi, commenti meta-testuali
- Prefissi come "Ecco:", "Risposta:", "Testo da leggere:"
- Formattazione markdown (asterischi, underscore, cancelletti)
- Testo che non sia destinato ad essere letto all'utente

Il tuo ruolo:
1. Accogliere l'utente con calore e professionalità
2. Guidare l'utente attraverso 4 esercizi: Memoria, Attenzione, Fluenza Verbale, Liste Numeriche
3. Leggere i contenuti degli esercizi in modo chiaro
4. Fornire feedback incoraggiante

Stile:
- Parla SEMPRE in italiano
- Sii paziente e incoraggiante
- Risposte brevi e dirette (massimo 2-3 frasi per messaggio)
- Non rivelare le risposte prima che l'utente risponda
- Usa SEMPRE il genere corretto come indicato sopra
- Niente formattazione, solo testo parlato naturale
''';
  }

  /// Start a new chat session
  void startSession() {
    _chat = _model.startChat();
  }

  /// Send a message and get a response
  Future<String> sendMessage(String message) async {
    if (_chat == null) {
      startSession();
    }

    final response = await _chat!.sendMessage(Content.text(message));
    return response.text ?? '';
  }

  /// Initialize session with greeting (greet only, no difficulty question)
  Future<String> greet() async {
    startSession();
    return await sendMessage(
      'L\'utente ha appena aperto l\'app per una sessione di esercizi cognitivi. '
      'Salutalo brevemente e chiedigli se è pronto per iniziare. '
      'NON chiedere ancora il livello di difficoltà. Sii breve, massimo 2 frasi.',
    );
  }

  /// Inform Gemini about the difficulty and prepare for exercises
  Future<String> setDifficulty(int difficulty) async {
    return await sendMessage(
      'Il livello di difficoltà impostato è $difficulty su 10. '
      'Comunica all\'utente il livello e digli che stai preparando gli esercizi. '
      'Massimo 2 frasi.',
    );
  }

  /// Introduce an exercise
  Future<String> introduceExercise(String exerciseType, String instructions) async {
    return await sendMessage(
      '[ISTRUZIONE INTERNA - non leggere questa riga] '
      'Presenta brevemente l\'esercizio di $exerciseType e spiega queste regole all\'utente: '
      '$instructions. '
      'Rispondi solo con il testo da dire ad alta voce, senza prefissi o commenti.',
    );
  }

  /// Present exercise content to the user
  Future<String> presentContent(String content) async {
    return await sendMessage(
      '[ISTRUZIONE INTERNA - non leggere questa riga] '
      'Leggi ad alta voce il seguente contenuto all\'utente. '
      'Rispondi SOLO con il contenuto da leggere, senza aggiungere prefissi, commenti o istruzioni.\n\n'
      '$content',
    );
  }

  /// Ask a question to the user
  Future<String> askQuestion(String question) async {
    return await sendMessage(
      '[ISTRUZIONE INTERNA] Poni questa domanda all\'utente. '
      'Rispondi solo con la domanda formulata in modo naturale: $question',
    );
  }

  /// Evaluate user response and provide feedback
  Future<Map<String, dynamic>> evaluateAndFeedback({
    required String question,
    required String userResponse,
    required String context,
  }) async {
    final response = await sendMessage(
      'L\'utente ha risposto "$userResponse" alla domanda "$question". '
      'Contesto dell\'esercizio: $context\n\n'
      'Valuta la risposta e rispondi con questo formato JSON:\n'
      '{"isCorrect": true/false, "score": 0-100, "feedback": "il tuo feedback breve"}\n'
      'Rispondi SOLO con il JSON.',
    );

    try {
      final jsonStr = _extractJson(response);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return {
        'isCorrect': false,
        'score': 0,
        'feedback': response,
      };
    }
  }

  /// Transition between exercises
  Future<String> transitionToNext(String nextExercise) async {
    return await sendMessage(
      'L\'esercizio precedente è terminato. '
      'Fai un breve commento incoraggiante e introduci il prossimo esercizio: $nextExercise. '
      'Sii breve, massimo 2-3 frasi.',
    );
  }

  /// Session completion
  Future<String> completeSession(double totalScore) async {
    return await sendMessage(
      'La sessione è terminata. Il punteggio totale è ${totalScore.toStringAsFixed(1)}/100. '
      'Fai un breve riassunto e congratulati con l\'utente. '
      'Suggerisci di consultare il report dettagliato. Sii breve.',
    );
  }

  /// End the session
  void endSession() {
    _chat = null;
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return '{}';
  }
}
