import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _emailController;
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _emailController = TextEditingController(text: settings.email);
    _apiKeyController = TextEditingController(text: settings.apiKey);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          _buildSectionTitle(theme, 'Tema'),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('Auto'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('Chiaro'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('Scuro'),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (modes) {
              settings.setThemeMode(modes.first);
            },
          ),

          const SizedBox(height: 24),

          // Email Section
          _buildSectionTitle(theme, 'Email Report'),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Indirizzo email',
              hintText: 'email@esempio.com',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (value) => settings.setEmail(value.trim()),
          ),
          const SizedBox(height: 4),
          Text(
            'I report delle sessioni verranno inviati a questo indirizzo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),

          const SizedBox(height: 24),

          // Gender Section
          _buildSectionTitle(theme, 'Genere'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: settings.gender,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'maschio', child: Text('Maschio')),
                  DropdownMenuItem(value: 'femmina', child: Text('Femmina')),
                ],
                onChanged: (value) {
                  if (value != null) settings.setGender(value);
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'L\'assistente si rivolger\u00e0 a te con il genere corretto',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),

          const SizedBox(height: 24),

          // Difficulty Section
          _buildSectionTitle(theme, 'Difficolt\u00e0 Predefinita'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Livello'),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${settings.defaultDifficulty}/10',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: settings.defaultDifficulty.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: settings.defaultDifficulty.toString(),
                  onChanged: (value) {
                    settings.setDefaultDifficulty(value.round());
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Facile',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      'Difficile',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // TTS Speed Section
          _buildSectionTitle(theme, 'Velocit\u00e0 Voce'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Velocit\u00e0 TTS'),
                    Text(
                      '${(settings.ttsSpeed * 100).round()}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Slider(
                  value: settings.ttsSpeed,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(settings.ttsSpeed * 100).round()}%',
                  onChanged: (value) {
                    settings.setTtsSpeed(value);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lenta',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      'Veloce',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Language Section
          _buildSectionTitle(theme, 'Lingua'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: settings.language,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 'Italian', child: Text('Italiano')),
                  DropdownMenuItem(value: 'English', child: Text('English')),
                ],
                onChanged: (value) {
                  if (value != null) settings.setLanguage(value);
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          // API Key Section
          _buildSectionTitle(theme, 'Chiave API Gemini'),
          const SizedBox(height: 8),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'AIza...',
              prefixIcon: const Icon(Icons.key),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
            onChanged: (value) => settings.setApiKey(value.trim()),
          ),
          const SizedBox(height: 4),
          Text(
            'Necessaria per utilizzare i servizi Gemini',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
