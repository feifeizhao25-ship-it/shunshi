/// Welcome to SEASONS — Reference: welcome_to_seasons
/// Onboarding: hemisphere detection + get started
///
/// Structure:
/// 1. Brand logo + welcome text
/// 2. Hemisphere auto-detect
/// 3. Manual hemisphere selector
/// 4. Get Started CTA
/// 5. Terms notice
library;

import 'package:flutter/material.dart';
import '../../../design_system/theme.dart';
import '../../../core/theme/app_localizations.dart';
import '../../../core/network/api_singleton.dart';

class WelcomeToSeasonsPage extends StatefulWidget {
  const WelcomeToSeasonsPage({super.key});

  @override
  State<WelcomeToSeasonsPage> createState() => _WelcomeToSeasonsPageState();
}

class _WelcomeToSeasonsPageState extends State<WelcomeToSeasonsPage> {
  bool _isNorthern = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? ShunShiColors.darkBackground : ShunShiColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Brand ──
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: ShunShiColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text('🌿', style: const TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Welcome to SEASONS.',
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w700,
                  color: ShunShiColors.textPrimary,
                  fontFamily: ShunShiTypography.serifFamily,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Let's find your rhythm.",
                style: TextStyle(
                  fontSize: 17, color: ShunShiColors.textSecondary,
                  fontFamily: ShunShiTypography.sansFamily,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Align your wellness with nature's wisdom.\nBased on your location and unique body type.",
                style: TextStyle(
                  fontSize: 14, color: ShunShiColors.textTertiary,
                  fontFamily: ShunShiTypography.sansFamily, height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // ── Hemisphere Detection ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ShunShiColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  Icon(Icons.location_on, size: 20, color: ShunShiColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        _isNorthern ? 'Northern Hemisphere detected' : 'Southern Hemisphere detected',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600,
                          color: ShunShiColors.primary, fontFamily: ShunShiTypography.sansFamily,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Based on your current IP',
                        style: TextStyle(
                          fontSize: 12, color: ShunShiColors.textTertiary,
                          fontFamily: ShunShiTypography.sansFamily,
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 12),

              // ── Manual Select ──
              Text(AppLocalizations.of(context).t('welcome_or_select_manually'), style: TextStyle(
                fontSize: 13, color: ShunShiColors.textTertiary, fontFamily: ShunShiTypography.sansFamily,
              )),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isNorthern = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _isNorthern ? ShunShiColors.primary : ShunShiColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(children: [
                          Icon(Icons.north_east, size: 24,
                            color: _isNorthern ? Colors.white : ShunShiColors.textTertiary,
                          ),
                          const SizedBox(height: 4),
                          Text(AppLocalizations.of(context).t('welcome_northern'), style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: _isNorthern ? Colors.white : ShunShiColors.textSecondary,
                            fontFamily: ShunShiTypography.sansFamily,
                          )),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isNorthern = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: !_isNorthern ? ShunShiColors.primary : ShunShiColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(children: [
                          Icon(Icons.south_east, size: 24,
                            color: !_isNorthern ? Colors.white : ShunShiColors.textTertiary,
                          ),
                          const SizedBox(height: 4),
                          Text(AppLocalizations.of(context).t('welcome_southern'), style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: !_isNorthern ? Colors.white : ShunShiColors.textSecondary,
                            fontFamily: ShunShiTypography.sansFamily,
                          )),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ── Get Started CTA ──
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ShunShiColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppLocalizations.of(context).t('get_started'), style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, fontFamily: ShunShiTypography.sansFamily,
                  )),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'By continuing, you agree to our Seasonal Living Principles and Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11, color: ShunShiColors.textTertiary,
                  fontFamily: ShunShiTypography.sansFamily, height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
