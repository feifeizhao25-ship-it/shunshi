// Ultimate Home Page
// Based on Ultimate UI Structure v1.0

import 'package:flutter/material.dart';
import 'package:shunshi/design_system/ultimate_ui_components.dart';

class UltimateHomePage extends StatefulWidget {
  const UltimateHomePage({super.key});

  @override
  State<UltimateHomePage> createState() => _UltimateHomePageState();
}

class _UltimateHomePageState extends State<UltimateHomePage> {
  // User context (would come from provider)
  final int userAge = 30;
  final String userLifeStage = 'stress_stage'; // stress_stage, transition, stable, recovery
  
  // Sample data
  final String _greeting = '今天感觉怎么样？';
  final String _insight = '最近你下午容易疲惫，今天适合让身体慢一点。';
  final String _solarTerm = '立春';
  final String _solarSuggestion = '宜早睡早起，舒展身体';
  
  final List<String> _threeThings = [
    '早餐喝点温热的',
    '午后晒10分钟太阳',
    '晚上早点放下手机',
  ];
  
  final List<String> _quickQuestions = [
    '最近睡不好怎么办',
    '今天适合吃什么',
    '有没有适合放松的动作',
    '我有点累',
  ];
  
  bool _showFollowUp = true;
  
  // Age-based content priority
  List<Widget> _buildHomeContent() {
    switch (userLifeStage) {
      case 'stress_stage':
        return _buildStressStageContent();
      case 'transition_phase':
        return _buildTransitionContent();
      case 'stable_phase':
        return _buildStableContent();
      case 'recovery_phase':
        return _buildRecoveryContent();
      default:
        return _buildStressStageContent();
    }
  }
  
  List<Widget> _buildStressStageContent() {
    // 25-40岁：压力管理
    return [
      InsightCard(
        title: '📊 今日洞察',
        content: _insight,
        icon: Icons.insights,
        accentColor: ShunShiColors.warning,
      ),
      ThreeThingsCard(things: _threeThings),
      if (_showFollowUp)
        FollowUpCard(
          message: '上次我们聊到睡眠，最近有没有好一点？',
          onDismiss: () => setState(() => _showFollowUp = false),
        ),
      AIChatEntryCard(
        message: _greeting,
        onTap: () => _navigateToChat(),
      ),
      SolarTermCard(
        name: _solarTerm,
        suggestion: _solarSuggestion,
        onTap: () => _navigateToSolarTerm(),
      ),
    ];
  }
  
  List<Widget> _buildTransitionContent() {
    // 过渡期
    return [
      InsightCard(
        title: '📊 今日洞察',
        content: _insight,
      ),
      ThreeThingsCard(things: _threeThings),
      SolarTermCard(
        name: _solarTerm,
        suggestion: _solarSuggestion,
        onTap: () => _navigateToSolarTerm(),
      ),
      AIChatEntryCard(
        message: '想聊些什么？',
        onTap: () => _navigateToChat(),
      ),
    ];
  }
  
  List<Widget> _buildStableContent() {
    // 稳定期
    return [
      SolarTermCard(
        name: _solarTerm,
        suggestion: _solarSuggestion,
        onTap: () => _navigateToSolarTerm(),
      ),
      ThreeThingsCard(things: _threeThings),
      InsightCard(
        title: '📊 今日洞察',
        content: '今天状态不错，保持现在的节奏。',
      ),
    ];
  }
  
  List<Widget> _buildRecoveryContent() {
    // 恢复期 - 60+岁
    return [
      // 简化版首页，元素更少
      SolarTermCard(
        name: _solarTerm,
        suggestion: _solarSuggestion,
        onTap: () => _navigateToSolarTerm(),
      ),
      AIChatEntryCard(
        message: '想聊聊天吗？',
        onTap: () => _navigateToChat(),
      ),
      InsightCard(
        title: '💡 今日建议',
        content: '今天天气不错，适合出去走走。',
      ),
    ];
  }
  
  void _navigateToChat() {
    // Navigate to chat page
    print('Navigate to chat');
  }
  
  void _navigateToSolarTerm() {
    // Navigate to solar term page
    print('Navigate to solar term');
  }
  
  void _onQuickQuestion(String question) {
    print('Quick question: $question');
    _navigateToChat();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ShunShiColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Greeting Header
            SliverToBoxAdapter(
              child: GreetingHeader(
                greeting: _greeting,
                subtitle: '今天、立春后的第三天',
                age: userAge,
              ),
            ),
            
            // Main Content
            SliverList(
              delegate: SliverChildListDelegate(
                _buildHomeContent(),
              ),
            ),
            
            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== Usage Example ====================

/*
// In your main app:

import 'package:flutter/material.dart';
import 'design_system/ultimate_ui_components.dart';

void main() {
  runApp(const ShunShiApp());
}

class ShunShiApp extends StatelessWidget {
  const ShunShiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: ShunShiColors.primary,
        ),
      ),
      home: const UltimateHomePage(),
    );
  }
}
*/
