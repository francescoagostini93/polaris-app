import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import '../models/user_response.dart';
import '../models/session_result.dart';
import '../services/gemini_service.dart';
import '../services/gemini_live_service.dart';
import '../services/speech_service.dart';
import '../services/email_service.dart';

/// State of the exercise session
enum SessionState {
  idle,
  greeting,
  waitingReady,
  askingDifficulty,
  generating,
  runningMemory,
  runningAttention,
  runningFluency,
  runningNumbers,
  evaluating,
  completed,
  error,
}

/// Manages the exercise session state and flow
class ExerciseProvider extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final GeminiLiveService _liveService = GeminiLiveService();
  final SpeechService _speechService = SpeechService();
  final EmailService _emailService = EmailService();

  SessionState _state = SessionState.idle;
  int _difficulty = 5;
  ExerciseSet? _exercises;
  final List<UserResponse> _responses = [];
  final Map<ExerciseType, double> _scores = {};
  DateTime? _sessionStart;
  DateTime? _sessionEnd;
  String _currentMessage = '';
  String _userTranscript = '';
  bool _isListening = false;
  bool _isSpeaking = false;
  int _currentPart = 0;
  int _currentQuestion = 0;
  ExerciseType? _currentExerciseType;
  String _errorMessage = '';
  int _highlightStart = -1;
  int _highlightEnd = -1;
  String _spokenText = ''; // the cleaned text being spoken

  // Getters
  SessionState get state => _state;
  int get difficulty => _difficulty;
  ExerciseSet? get exercises => _exercises;
  List<UserResponse> get responses => List.unmodifiable(_responses);
  Map<ExerciseType, double> get scores => Map.unmodifiable(_scores);
  String get currentMessage => _currentMessage;
  String get userTranscript => _userTranscript;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  int get currentPart => _currentPart;
  int get currentQuestion => _currentQuestion;
  ExerciseType? get currentExerciseType => _currentExerciseType;
  String get errorMessage => _errorMessage;
  SpeechService get speechService => _speechService;
  int get highlightStart => _highlightStart;
  int get highlightEnd => _highlightEnd;
  String get spokenText => _spokenText;

  /// Get responses for a specific exercise type
  List<UserResponse> getResponsesForType(ExerciseType type) {
    return _responses.where((r) => r.exerciseType == type).toList();
  }

  double get totalScore {
    if (_scores.isEmpty) return 0;
    return _scores.values.reduce((a, b) => a + b) / _scores.length;
  }

  int get totalExercises => 4;
  int get currentExerciseIndex {
    switch (_currentExerciseType) {
      case ExerciseType.memory:
        return 0;
      case ExerciseType.attention:
        return 1;
      case ExerciseType.fluency:
        return 2;
      case ExerciseType.numbers:
        return 3;
      default:
        return 0;
    }
  }

  double get progress => (currentExerciseIndex + 1) / totalExercises;

  SessionResult? get sessionResult {
    if (_exercises == null) return null;
    return SessionResult(
      startTime: _sessionStart ?? DateTime.now(),
      endTime: _sessionEnd,
      difficulty: _difficulty,
      exerciseSet: _exercises!,
      responses: _responses,
      scores: _scores,
    );
  }

  /// Initialize speech service
  Future<void> init() async {
    await _speechService.initialize();

    _speechService.onListeningStarted = () {
      _isListening = true;
      notifyListeners();
    };
    _speechService.onListeningStopped = () {
      _isListening = false;
      notifyListeners();
    };
    _speechService.onSpeakingStarted = () {
      _isSpeaking = true;
      _spokenText = SpeechService.cleanForSpeech(_currentMessage);
      _highlightStart = -1;
      _highlightEnd = -1;
      notifyListeners();
    };
    _speechService.onSpeakingStopped = () {
      _isSpeaking = false;
      _highlightStart = -1;
      _highlightEnd = -1;
      notifyListeners();
    };
    _speechService.onPartialResult = (text) {
      _userTranscript = text;
      notifyListeners();
    };
    _speechService.onSpeechProgress = (start, end) {
      _highlightStart = start;
      _highlightEnd = end;
      notifyListeners();
    };
  }

  /// Start a new session with gender setting
  Future<void> startSession({String gender = 'maschio'}) async {
    _state = SessionState.greeting;
    _responses.clear();
    _scores.clear();
    _sessionStart = DateTime.now();
    _sessionEnd = null;
    _currentPart = 0;
    _currentQuestion = 0;
    _errorMessage = '';
    notifyListeners();

    // Set gender for correct Italian forms
    _liveService.setGender(gender);

    try {
      // Greet user and ask if ready
      final greeting = await _liveService.greet();
      _currentMessage = greeting;
      notifyListeners();
      await _speechService.speak(greeting);

      // Wait for user to say they're ready
      _state = SessionState.waitingReady;
      notifyListeners();

      final readyResponse = await _speechService.listen(timeout: const Duration(seconds: 15));
      _userTranscript = readyResponse;
      notifyListeners();

      // Now ask for difficulty
      _state = SessionState.askingDifficulty;
      notifyListeners();

      final diffQuestion = await _liveService.askDifficulty();
      _currentMessage = diffQuestion;
      notifyListeners();
      await _speechService.speak(diffQuestion);

      // Listen for difficulty
      final diffText = await _speechService.listen(timeout: const Duration(seconds: 15));
      _userTranscript = diffText;
      notifyListeners();

      // Parse difficulty
      _difficulty = _parseDifficulty(diffText);

      // Confirm difficulty
      final confirmation = await _liveService.setDifficulty(_difficulty);
      _currentMessage = confirmation;
      notifyListeners();
      await _speechService.speak(confirmation);

      // Generate exercises
      _state = SessionState.generating;
      _currentMessage = 'Sto generando gli esercizi...';
      notifyListeners();

      _exercises = await _geminiService.generateExercises(_difficulty);

      // Run all 4 exercises in sequence
      await _runMemoryExercise();
      await _runAttentionExercise();
      await _runFluencyExercise();
      await _runNumbersExercise();

      // Complete session
      _sessionEnd = DateTime.now();
      _state = SessionState.completed;
      final completion = await _liveService.completeSession(totalScore);
      _currentMessage = completion;
      notifyListeners();
      await _speechService.speak(completion);

      _liveService.endSession();
    } catch (e) {
      _state = SessionState.error;
      _errorMessage = e.toString();
      _currentMessage = 'Si è verificato un errore: $_errorMessage';
      notifyListeners();
    }
  }

  // ==================== Memory Exercise ====================

  Future<void> _runMemoryExercise() async {
    _state = SessionState.runningMemory;
    _currentExerciseType = ExerciseType.memory;
    _currentPart = 0;
    _currentQuestion = 0;
    notifyListeners();

    final transition = await _liveService.introduceExercise(
      'Memoria',
      'Ti leggerò degli articoli. Ascolta con attenzione, poi ti farò delle domande su ciascuno.',
    );
    _currentMessage = transition;
    notifyListeners();
    await _speechService.speak(transition);

    int totalCorrect = 0;
    int totalQuestions = 0;

    for (int i = 0; i < (_exercises?.memoryArticles.length ?? 0); i++) {
      _currentPart = i;
      final article = _exercises!.memoryArticles[i];

      // Read article
      final intro = await _liveService.presentContent(
        'Articolo ${i + 1}: ${article.title}\n\n${article.content}',
      );
      _currentMessage = intro;
      notifyListeners();
      await _speechService.speak(intro);

      // Ask questions
      for (int j = 0; j < article.questions.length; j++) {
        _currentQuestion = j;
        notifyListeners();

        final questionText = await _liveService.askQuestion(article.questions[j]);
        _currentMessage = questionText;
        notifyListeners();
        await _speechService.speak(questionText);

        // Listen for answer
        final answer = await _speechService.listen(timeout: const Duration(seconds: 20));
        _userTranscript = answer;
        notifyListeners();

        // Evaluate
        final eval = await _liveService.evaluateAndFeedback(
          question: article.questions[j],
          userResponse: answer,
          context: article.content,
        );

        final isCorrect = eval['isCorrect'] == true;
        if (isCorrect) totalCorrect++;
        totalQuestions++;

        _responses.add(UserResponse(
          exerciseType: ExerciseType.memory,
          partIndex: i,
          questionIndex: j,
          question: article.questions[j],
          response: answer,
          timestamp: DateTime.now(),
          isCorrect: isCorrect,
          score: (eval['score'] as num?)?.toDouble(),
        ));

        // Speak feedback
        final feedback = eval['feedback'] as String? ?? '';
        if (feedback.isNotEmpty) {
          _currentMessage = feedback;
          notifyListeners();
          await _speechService.speak(feedback);
        }
      }
    }

    _scores[ExerciseType.memory] =
        totalQuestions > 0 ? (totalCorrect / totalQuestions * 100) : 0;
  }

  // ==================== Attention Exercise ====================

  Future<void> _runAttentionExercise() async {
    _state = SessionState.runningAttention;
    _currentExerciseType = ExerciseType.attention;
    _currentPart = 0;
    _currentQuestion = 0;
    notifyListeners();

    final transition = await _liveService.transitionToNext('Attenzione');
    _currentMessage = transition;
    notifyListeners();
    await _speechService.speak(transition);

    final intro = await _liveService.introduceExercise(
      'Attenzione',
      'Ti presenterò delle sequenze di lettere e numeri. Dovrai trovare la parola nascosta tra i numeri.',
    );
    _currentMessage = intro;
    notifyListeners();
    await _speechService.speak(intro);

    int totalCorrect = 0;
    int totalWords = 0;

    for (int i = 0; i < (_exercises?.attentionParts.length ?? 0); i++) {
      _currentPart = i;
      final part = _exercises!.attentionParts[i];

      final partIntro = 'Parte ${i + 1}. Trova le parole nascoste:';
      _currentMessage = partIntro;
      notifyListeners();
      await _speechService.speak(partIntro);

      for (int j = 0; j < part.length; j++) {
        _currentQuestion = j;
        final word = part[j];
        notifyListeners();

        // Read the hidden string character by character (1 char/second)
        _currentMessage = word.hiddenString;
        notifyListeners();
        await _speechService.speak('Sequenza:');
        await _speechService.speakCharByChar(word.hiddenString);
        await _speechService.speak('Quale parola è nascosta?');

        final answer = await _speechService.listen(timeout: const Duration(seconds: 15));
        _userTranscript = answer;
        notifyListeners();

        final isCorrect = answer.trim().toUpperCase() == word.word.toUpperCase();
        if (isCorrect) totalCorrect++;
        totalWords++;

        _responses.add(UserResponse(
          exerciseType: ExerciseType.attention,
          partIndex: i,
          questionIndex: j,
          question: word.hiddenString,
          response: answer,
          timestamp: DateTime.now(),
          isCorrect: isCorrect,
          score: isCorrect ? 100 : 0,
        ));

        if (isCorrect) {
          await _speechService.speak('Corretto!');
        } else {
          await _speechService.speak('La parola era ${word.word}.');
        }
      }
    }

    _scores[ExerciseType.attention] =
        totalWords > 0 ? (totalCorrect / totalWords * 100) : 0;
  }

  // ==================== Fluency Exercise ====================

  Future<void> _runFluencyExercise() async {
    _state = SessionState.runningFluency;
    _currentExerciseType = ExerciseType.fluency;
    _currentPart = 0;
    _currentQuestion = 0;
    notifyListeners();

    final transition = await _liveService.transitionToNext('Fluenza Verbale');
    _currentMessage = transition;
    notifyListeners();
    await _speechService.speak(transition);

    double totalWordCount = 0;

    for (int i = 0; i < (_exercises?.fluencyParts.length ?? 0); i++) {
      _currentPart = i;
      final part = _exercises!.fluencyParts[i];
      notifyListeners();

      final instruction = await _liveService.presentContent(
        '${part.instruction}\nTarget: ${part.target}\nHai 60 secondi.',
      );
      _currentMessage = instruction;
      notifyListeners();
      await _speechService.speak(instruction);

      // Listen continuously for 60 seconds, restarting after pauses
      final answer = await _speechService.listenContinuous(
        totalDuration: const Duration(seconds: 60),
      );
      _userTranscript = answer;
      notifyListeners();

      // Count words
      final words = answer.split(RegExp(r'[\s,;.]+'))
          .where((w) => w.trim().isNotEmpty)
          .toList();
      final wordCount = words.length.toDouble();
      totalWordCount += wordCount;

      _responses.add(UserResponse(
        exerciseType: ExerciseType.fluency,
        partIndex: i,
        questionIndex: 0,
        question: '${part.instruction} (${part.target})',
        response: answer,
        timestamp: DateTime.now(),
        score: wordCount,
      ));

      _currentMessage = 'Hai detto ${words.length} parole.';
      notifyListeners();
      await _speechService.speak('Hai detto ${words.length} parole. Bene!');
    }

    // Score: assume 10 words per round is good performance at difficulty level
    final expectedWords = _difficulty * 3.0;
    final avgWords = totalWordCount / (_exercises?.fluencyParts.length ?? 1);
    _scores[ExerciseType.fluency] = (avgWords / expectedWords * 100).clamp(0, 100);
  }

  // ==================== Numbers Exercise ====================

  Future<void> _runNumbersExercise() async {
    _state = SessionState.runningNumbers;
    _currentExerciseType = ExerciseType.numbers;
    _currentPart = 0;
    _currentQuestion = 0;
    notifyListeners();

    final transition = await _liveService.transitionToNext('Liste Numeriche');
    _currentMessage = transition;
    notifyListeners();
    await _speechService.speak(transition);

    final intro = await _liveService.introduceExercise(
      'Liste Numeriche',
      'Ti leggerò delle sequenze di numeri. Dovrai ripeterle nello stesso ordine.',
    );
    _currentMessage = intro;
    notifyListeners();
    await _speechService.speak(intro);

    int totalCorrect = 0;
    int totalSequences = 0;

    for (int i = 0; i < (_exercises?.numberParts.length ?? 0); i++) {
      _currentPart = i;
      final part = _exercises!.numberParts[i];

      _currentMessage = 'Parte ${i + 1}';
      notifyListeners();
      await _speechService.speak('Parte ${i + 1}. Ascolta e ripeti.');

      for (int j = 0; j < part.length; j++) {
        _currentQuestion = j;
        final seq = part[j];
        notifyListeners();

        // Read digits slowly
        final digitsStr = seq.digits.join('... ');
        _currentMessage = seq.displayString;
        notifyListeners();
        await _speechService.speak(digitsStr);

        // Small pause then listen
        await Future.delayed(const Duration(milliseconds: 500));
        final answer = await _speechService.listen(timeout: const Duration(seconds: 15));
        _userTranscript = answer;
        notifyListeners();

        // Parse user's numbers
        final userDigits = _parseNumbers(answer);
        final isCorrect = _compareSequences(seq.digits, userDigits);
        if (isCorrect) totalCorrect++;
        totalSequences++;

        _responses.add(UserResponse(
          exerciseType: ExerciseType.numbers,
          partIndex: i,
          questionIndex: j,
          question: seq.displayString,
          response: answer,
          timestamp: DateTime.now(),
          isCorrect: isCorrect,
          score: isCorrect ? 100 : 0,
        ));

        if (isCorrect) {
          await _speechService.speak('Esatto!');
        } else {
          await _speechService.speak(
            'La sequenza corretta era: ${seq.digits.join(', ')}',
          );
        }
      }
    }

    _scores[ExerciseType.numbers] =
        totalSequences > 0 ? (totalCorrect / totalSequences * 100) : 0;
  }

  // ==================== Utility Methods ====================

  int _parseDifficulty(String text) {
    final numbers = RegExp(r'\d+').allMatches(text);
    if (numbers.isNotEmpty) {
      final num = int.tryParse(numbers.first.group(0)!) ?? _difficulty;
      return num.clamp(1, 10);
    }

    // Map Italian number words
    final wordMap = {
      'uno': 1, 'due': 2, 'tre': 3, 'quattro': 4, 'cinque': 5,
      'sei': 6, 'sette': 7, 'otto': 8, 'nove': 9, 'dieci': 10,
    };

    final lower = text.toLowerCase().trim();
    for (final entry in wordMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }

    return _difficulty;
  }

  List<int> _parseNumbers(String text) {
    final numbers = <int>[];
    final matches = RegExp(r'\d+').allMatches(text);
    for (final match in matches) {
      final digits = match.group(0)!;
      // If the number has multiple digits, split them
      for (final d in digits.split('')) {
        final n = int.tryParse(d);
        if (n != null) numbers.add(n);
      }
    }

    // Also try Italian words
    if (numbers.isEmpty) {
      final wordMap = {
        'zero': 0, 'uno': 1, 'due': 2, 'tre': 3, 'quattro': 4,
        'cinque': 5, 'sei': 6, 'sette': 7, 'otto': 8, 'nove': 9,
      };
      final words = text.toLowerCase().split(RegExp(r'[\s,;.]+'));
      for (final word in words) {
        final trimmed = word.trim();
        if (wordMap.containsKey(trimmed)) {
          numbers.add(wordMap[trimmed]!);
        }
      }
    }

    return numbers;
  }

  bool _compareSequences(List<int> expected, List<int> actual) {
    if (expected.length != actual.length) return false;
    for (int i = 0; i < expected.length; i++) {
      if (expected[i] != actual[i]) return false;
    }
    return true;
  }

  /// Send report via email
  Future<bool> sendReport(String email) async {
    final result = sessionResult;
    if (result == null) return false;
    return _emailService.sendReport(
      result: result,
      recipientEmail: email,
    );
  }

  /// Reset session
  void reset() {
    _state = SessionState.idle;
    _exercises = null;
    _responses.clear();
    _scores.clear();
    _currentMessage = '';
    _userTranscript = '';
    _currentPart = 0;
    _currentQuestion = 0;
    _currentExerciseType = null;
    _errorMessage = '';
    _highlightStart = -1;
    _highlightEnd = -1;
    _spokenText = '';
    _liveService.endSession();
    notifyListeners();
  }

  @override
  void dispose() {
    _speechService.dispose();
    super.dispose();
  }
}
