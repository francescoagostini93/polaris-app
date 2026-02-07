import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/exercise_provider.dart';
import '../providers/settings_provider.dart';
import '../models/exercise.dart';
import '../widgets/voice_button.dart';
import '../widgets/exercise_card.dart';
import '../widgets/progress_indicator.dart';
import 'results_screen.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late ExerciseProvider _provider;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _highlightKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _provider = context.read<ExerciseProvider>();
    // Keep screen on during session
    WakelockPlus.enable();
    _startSession();
  }

  Future<void> _startSession() async {
    await _provider.init();
    _provider.addListener(_onStateChange);
    final gender = context.read<SettingsProvider>().gender;
    _provider.startSession(gender: gender);
  }

  void _onStateChange() {
    if (_provider.state == SessionState.completed) {
      // Navigate to results after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ResultsScreen()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onStateChange);
    _scrollController.dispose();
    // Allow screen to turn off again
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessione'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(context),
        ),
      ),
      body: Consumer<ExerciseProvider>(
        builder: (context, provider, _) {
          return SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: SessionProgressIndicator(
                    currentType: provider.currentExerciseType,
                    scores: provider.scores,
                  ),
                ),

                // Exercise cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildExerciseCards(provider),
                ),

                const Divider(height: 1),

                // Main content area
                Expanded(
                  child: _buildContent(theme, provider),
                ),

                // Voice interaction area
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
                      // User transcript
                      if (provider.userTranscript.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  provider.userTranscript,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Voice button
                      VoiceButton(
                        isListening: provider.isListening,
                        isSpeaking: provider.isSpeaking,
                        onTap: provider.isListening
                            ? () => provider.speechService.stopListening()
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseCards(ExerciseProvider provider) {
    return Column(
      children: ExerciseType.values.map((type) {
        final isActive = provider.currentExerciseType == type;
        final isCompleted = provider.scores.containsKey(type);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: ExerciseCard(
            type: type,
            isActive: isActive,
            isCompleted: isCompleted,
            score: provider.scores[type],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContent(ThemeData theme, ExerciseProvider provider) {
    switch (provider.state) {
      case SessionState.idle:
        return const Center(child: Text('Preparazione...'));

      case SessionState.greeting:
      case SessionState.waitingReady:
      case SessionState.askingDifficulty:
        return _buildMessageArea(theme, provider, Icons.waving_hand);

      case SessionState.generating:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Generazione esercizi...',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Difficoltà: ${provider.difficulty}/10',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );

      case SessionState.runningMemory:
      case SessionState.runningAttention:
      case SessionState.runningFluency:
      case SessionState.runningNumbers:
        return _buildMessageArea(theme, provider, Icons.smart_toy);

      case SessionState.evaluating:
        return const Center(child: CircularProgressIndicator());

      case SessionState.completed:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Sessione completata!',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Punteggio: ${provider.totalScore.toStringAsFixed(0)}%',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case SessionState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Errore',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.errorMessage,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    provider.reset();
                    _startSession();
                  },
                  child: const Text('Riprova'),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildMessageArea(ThemeData theme, ExerciseProvider provider, IconData icon) {
    // Auto-scroll when highlight changes
    if (provider.isSpeaking && provider.highlightEnd > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoScrollToHighlight();
      });
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI message bubble
          if (provider.currentMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHighlightedText(theme, provider),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build text with word-by-word highlighting during TTS
  Widget _buildHighlightedText(ThemeData theme, ExerciseProvider provider) {
    final text = provider.spokenText;
    final start = provider.highlightStart;
    final end = provider.highlightEnd;

    // If not speaking or no highlight data, show plain text
    if (!provider.isSpeaking || start < 0 || end < 0 || text.isEmpty) {
      return Text(
        provider.currentMessage,
        style: theme.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.6),
      );
    }

    // Clamp offsets to text length
    final safeStart = start.clamp(0, text.length);
    final safeEnd = end.clamp(0, text.length);

    return RichText(
      key: _highlightKey,
      text: TextSpan(
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: 18,
          height: 1.6,
          color: theme.colorScheme.onSurface,
        ),
        children: [
          // Text before highlight
          if (safeStart > 0)
            TextSpan(text: text.substring(0, safeStart)),
          // Highlighted word
          if (safeEnd > safeStart)
            TextSpan(
              text: text.substring(safeStart, safeEnd),
              style: TextStyle(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.3),
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          // Text after highlight
          if (safeEnd < text.length)
            TextSpan(
              text: text.substring(safeEnd),
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
        ],
      ),
    );
  }

  void _autoScrollToHighlight() {
    if (!_scrollController.hasClients) return;
    final provider = _provider;
    if (provider.spokenText.isEmpty || provider.highlightEnd < 0) return;

    // Estimate scroll position based on progress through text
    final progress = provider.highlightEnd / provider.spokenText.length;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetScroll = (progress * maxScroll).clamp(0.0, maxScroll);

    if ((targetScroll - _scrollController.offset).abs() > 30) {
      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Interrompere sessione?'),
        content: const Text(
          'Se esci ora perderai i progressi della sessione corrente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continua'),
          ),
          TextButton(
            onPressed: () {
              _provider.reset();
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Esci'),
          ),
        ],
      ),
    );
  }
}
