/*
SEASONS Design System
Calm, natural, minimal, premium

Export all design system components
*/

// Colors
export 'colors.dart';

// Typography
export 'typography.dart';

// Theme
export 'theme.dart';

// Components
export 'components.dart';

// Animations
export 'animations.dart';

// ============== Quick Access ==============

/*
Usage:

import 'package:seasons/design_system/design_system.dart';

// Use colors
Colors.skyBlue
Colors.warmSand

// Use theme
MaterialApp(
  theme: SeasonsTheme.lightTheme,
  darkTheme: SeasonsTheme.darkTheme,
)

// Use components
SoftButton(text: 'Get Started', onPressed: () {})
SoftCard(child: Text('Content'))
CalmInput(hintText: 'Enter your name')
QuoteCard(quote: '...')

// Use animations
FadeIn(child: Text('Hello'))
BreathingCircle(child: Icon(Icons.self_improvement))
*/
