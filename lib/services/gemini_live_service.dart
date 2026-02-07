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
Sei un assistente cognitivo professionale e gentile che guida gli utenti attraverso esercizi di stimolazione cognitiva. Parla SEMPRE in italiano.

$genderInfo

Il tuo ruolo:
1. Accogliere l'utente con calore e professionalità
2. Guidare l'utente attraverso 4 esercizi in sequenza: Memoria, Attenzione, Fluenza Verbale, Liste Numeriche
3. Leggere le istruzioni e i contenuti degli esercizi
4. Raccogliere le risposte dell'utente
5. Fornire feedback incoraggiante
6. Valutare le risposte e assegnare un punteggio

Regole:
- Sii paziente e incoraggiante
- Dai istruzioni chiare e concise
- Non rivelare le risposte prima che l'utente risponda
- Adatta il tuo tono alla situazione (più serio durante l'esercizio, più rilassato tra un esercizio e l'altro)
- Rispondi sempre in italiano
- Mantieni le risposte brevi e dirette per l'interazione vocale
- Usa SEMPRE il genere corretto come indicato sopra
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

  /// Ask for difficulty level
  Future<String> askDifficulty() async {
    return await sendMessage(
      'L\'utente è pronto. Ora chiedigli a che livello di difficoltà vuole giocare, da 1 a 10. '
      'Sii breve, massimo 1-2 frasi.',
    );
  }

  /// Inform Gemini about the difficulty chosen and prepare for exercises
  Future<String> setDifficulty(int difficulty) async {
    return await sendMessage(
      'L\'utente ha scelto difficoltà $difficulty. '
      'Conferma la scelta e digli che stai preparando gli esercizi. '
      'Sii breve, massimo 2 frasi.',
    );
  }

  /// Introduce an exercise
  Future<String> introduceExercise(String exerciseType, String instructions) async {
    return await sendMessage(
      'Ora presenta all\'utente l\'esercizio di $exerciseType. '
      'Ecco le istruzioni da comunicare:\n$instructions\n\n'
      'Leggi le istruzioni in modo chiaro e conciso. Non aggiungere troppo testo.',
    );
  }

  /// Present exercise content to the user
  Future<String> presentContent(String content) async {
    return await sendMessage(
      'Leggi all\'utente il seguente contenuto dell\'esercizio:\n\n$content\n\n'
      'Leggilo chiaramente. Poi chiedi all\'utente di rispondere.',
    );
  }

  /// Ask a question to the user
  Future<String> askQuestion(String question) async {
    return await sendMessage(
      'Fai la seguente domanda all\'utente:\n"$question"\n'
      'Poni la domanda in modo chiaro e attendi la risposta.',
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
