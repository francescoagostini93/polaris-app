import 'package:flutter/material.dart';

/// Animated microphone button for voice interaction
class VoiceButton extends StatelessWidget {
  final bool isListening;
  final bool isSpeaking;
  final VoidCallback? onTap;
  final double size;

  const VoiceButton({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    this.onTap,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color bgColor;
    IconData icon;
    String label;

    if (isSpeaking) {
      bgColor = theme.colorScheme.secondary;
      icon = Icons.volume_up;
      label = 'In ascolto...';
    } else if (isListening) {
      bgColor = Colors.red;
      icon = Icons.mic;
      label = 'Parla ora...';
    } else {
      bgColor = theme.colorScheme.primary;
      icon = Icons.mic_none;
      label = 'Tocca per parlare';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                if (isListening)
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                else if (isSpeaking)
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
