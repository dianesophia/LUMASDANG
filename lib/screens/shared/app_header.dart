import 'package:flutter/material.dart';
import 'package:lumasdang/screens/settingsPages/main_Settings.dart';

class AppHeader extends StatelessWidget {
  /// Optional title — defaults to 'Lumasdang'.
  final String title;

  /// Optional leading icon — defaults to [Icons.local_hospital_outlined].
  final IconData leadingIcon;

  /// Set to `false` to hide the settings gear button.
  final bool showSettings;

  /// Provide a custom trailing widget instead of the settings button.
  final Widget? trailingWidget;

  /// Set to `false` to hide the gradient divider at the bottom.
  final bool showDivider;

  const AppHeader({
    super.key,
    this.title = 'Lumasdang',
    this.leadingIcon = Icons.local_hospital_outlined,
    this.showSettings = true,
    this.trailingWidget,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              // Leading icon bubble
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 1.2,
                  ),
                ),
                child: Icon(leadingIcon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),

              // Trailing — custom widget OR settings button
              if (trailingWidget != null)
                trailingWidget!
              else if (showSettings)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MainSettings()),
                    ),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(Icons.settings_outlined,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
            ],
          ),

          if (showDivider) ...[
            const SizedBox(height: 14),
            Container(
              height: 1,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}