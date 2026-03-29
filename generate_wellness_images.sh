#!/bin/bash
# Generate wellness images using fal.ai imagen3
# Replaces mismatched stock images with AI-generated content-matched images

FAL_KEY="b4694091-bbfc-4c3d-92fd-37187e74bc58:29f281ced5b472e8880779f1b651e9e8"
OUT_DIR="$HOME/Documents/Shunshi/android-cn/assets/images/wellness"

mkdir -p "$OUT_DIR"

generate_image() {
  local name="$1"
  local prompt="$2"
  local outfile="$OUT_DIR/$name"
  
  echo "Generating: $name"
  echo "  Prompt: $prompt"
  
  local response
  response=$(curl -s -H "Authorization: Key $FAL_KEY" \
    -H "Content-Type: application/json" \
    "https://fal.run/fal-ai/imagen3" \
    -X POST \
    -d "{\"prompt\": $(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$prompt"), \"image_size\": \"landscape_4_3\"}")
  
  # Extract URL from JSON response
  local url
  url=$(echo "$response" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['images'][0]['url'])" 2>/dev/null)
  
  if [ -n "$url" ]; then
    curl -sL -o "$outfile" "$url"
    echo "  Saved: $outfile ($(du -h "$outfile" | cut -f1))"
  else
    echo "  FAILED: $response"
  fi
  
  echo ""
  sleep 2  # Rate limit courtesy
}

echo "=== Shunshi Wellness Image Generation ==="
echo "Model: fal.ai imagen3"
echo "Output: $OUT_DIR"
echo ""

# ── Food (食疗) ──

generate_image "food_yam_porridge.jpg" \
  "A warm bowl of Chinese yam porridge (山药粥) in a white ceramic bowl on a wooden table. The porridge is creamy white with visible yam chunks. A few red dates (红枣) are scattered on top. Soft warm lighting, top-down food photography, minimalist style, Chinese wellness aesthetic. Clean background with a bamboo mat underneath."

generate_image "food_lotus_soup.jpg" \
  "A delicate bowl of snow fungus and lotus seed soup (银耳莲子羹) in a white porcelain bowl. The soup is slightly translucent with gelatinous snow fungus, plump lotus seeds, and goji berries floating. Warm soft lighting, top-down food photography, Chinese wellness aesthetic. Steam rising gently, elegant presentation on a wooden table."

generate_image "food_red_bean_porridge.jpg" \
  "A comforting bowl of red bean and coix seed porridge (红豆薏米粥) in a rustic ceramic bowl. The porridge shows reddish-brown beans and white coix grains in a creamy base. Warm inviting lighting, close-up food photography, Chinese wellness aesthetic. Wooden table background with a linen napkin."

# ── Tea (茶饮) ──

generate_image "tea_goji_chrysanthemum.jpg" \
  "A glass cup of goji berry and chrysanthemum tea (枸杞菊花茶) on a wooden tea tray. The clear golden tea has several bright orange goji berries and white chrysanthemum flowers floating. Soft natural light from the side, warm tones. Chinese tea ceremony aesthetic, minimalist composition with a small tea spoon beside the cup."

generate_image "tea_rose.jpg" \
  "A clear glass cup of rose petal tea (玫瑰花茶) on a clean white saucer. Dried rose petals unfurl in warm water creating a soft pink hue. Soft warm lighting, elegant presentation. Chinese wellness aesthetic with a single fresh rose bud beside the cup. Minimalist, serene mood."

generate_image "tea_hawthorn.jpg" \
  "A ceramic cup of hawthorn and tangerine peel tea (山楂陈皮茶) with a warm amber-red color. Sliced dried hawthorn berries and curled orange peel visible in the tea. Steam rising gently. Warm lighting on a wooden table. Chinese wellness aesthetic, traditional tea culture mood."

generate_image "tea_longan.jpg" \
  "A white ceramic bowl of longan and red date tea (桂圆红枣茶) with whole brown longan fruits and red dates floating. The tea has a rich warm brown color. Warm golden lighting, Chinese wellness aesthetic. Bamboo mat background, a pair of wooden chopsticks resting beside the bowl."

# ── Exercise (运动) ──

generate_image "exercise_baduanjin.jpg" \
  "A serene woman in loose white cotton clothing practicing Ba Duan Jin (八段锦) qigong in a bamboo grove at dawn. She is in the '双手托天理三焦' (holding up the sky) pose, arms raised above her head. Soft morning light filtering through bamboo. Misty atmosphere, Chinese wellness aesthetic. Full body view, graceful posture."

generate_image "exercise_morning_stretch.jpg" \
  "A person doing gentle morning stretching exercises on a yoga mat by a window with soft sunrise light. Arms extended upward in a full body stretch, wearing light comfortable clothing. Warm golden morning light, clean minimalist room with a plant in the corner. Serene, calming atmosphere, Chinese wellness lifestyle aesthetic."

generate_image "exercise_sleep_relax.jpg" \
  "A peaceful scene of a person meditating in lotus position on a cushion before bedtime. Soft blue-grey ambient lighting, closed eyes, relaxed shoulders. A small candle flickers nearby. The room has a zen minimalist aesthetic with a jade plant. Calming, restful mood suitable for sleep preparation."

# ── Emotion/Sleep ──

generate_image "emotion_meditation.jpg" \
  "A tranquil meditation scene in a traditional Chinese garden pavilion. A person sits calmly in meditation posture on a wooden platform, surrounded by bamboo and a small koi pond. Soft diffused light, morning mist. Zen Buddhist aesthetic, peaceful and contemplative mood. Misty mountains visible in the background."

generate_image "sleep_quality.jpg" \
  "A cozy bedroom scene at night showing a neatly made bed with soft white linens and a light green comforter. A small jade pillow and a cup of herbal tea on the nightstand. Moonlight streaming through thin curtains. Soft blue-silver tones. Serene, restful Chinese wellness aesthetic promoting good sleep quality."

echo "=== Generation Complete ==="
echo "Generated images in: $OUT_DIR"
ls -la "$OUT_DIR"
