import 'package:flutter/material.dart';
import '../../widgets/seasons_visual.dart';

/// Photo cards shown under the first assistant greeting, so a new conversation
/// starts from something to tap instead of an empty screen.
class ChatTopic {
  const ChatTopic(this.label, this.prompt, this.asset);
  final String label;
  final String prompt;
  final String asset;
}

const kChatTopics = <ChatTopic>[
  ChatTopic('Sleep better', 'Help me sleep better tonight', 'assets/images/wellness/sleep_pillow_moon.jpg'),
  ChatTopic('Seasonal food', 'What should I eat this season?', 'assets/images/wellness/food_spring_salad.jpg'),
  ChatTopic('Calm my mind', 'I feel stressed. How can I calm down?', 'assets/images/wellness/emotion_meditation_bowl.jpg'),
  ChatTopic('Gentle movement', 'Suggest a gentle morning routine', 'assets/images/wellness/exercise_morning_stretch.jpg'),
  ChatTopic('Herbal teas', 'Which herbal teas suit me now?', 'assets/images/wellness/tea_chamomile.jpg'),
];

class ChatTopicCards extends StatelessWidget {
  const ChatTopicCards({super.key, required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(left: 2, bottom: 10),
          child: Text('Or start with a topic',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5B6B5F))),
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kChatTopics.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final t = kChatTopics[i];
              return Semantics(
                button: true,
                label: t.label,
                child: GestureDetector(
                  key: ValueKey('chat_topic_$i'),
                  onTap: () => onPick(t.prompt),
                  child: SizedBox(
                    width: 112,
                    child: Stack(fit: StackFit.expand, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(t.asset, fit: BoxFit.cover, cacheWidth: 320),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0xB3102A1B)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 9,
                        child: Text(t.label,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, height: 1.2)),
                      ),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
