"""
顺时国际版 — TCM 文化故事讲述
为国际用户讲述 TCM 的文化背景、历史渊源和养生智慧。
"""

from fastapi import APIRouter, Query, HTTPException
from typing import Optional
from datetime import datetime

router = APIRouter(prefix="/api/v1/stories", tags=["cultural_tcm_stories"])

# ─────────────────────────────────────────────────────────────────────────────
# TCM 文化故事数据库
# ─────────────────────────────────────────────────────────────────────────────

CULTURAL_STORIES = {
    "winter_solstice_kitchen": {
        "id": "winter_solstice_kitchen",
        "title": "Winter Solstice and the Emperor's Kitchen",
        "category": "solar_term",
        "related_tcm_element": ["winter", "kidney", "yang_qi"],
        "period": "Zhou Dynasty (周朝)",
        "length_words": 380,
        "story_text": """
During the Zhou Dynasty, the imperial kitchen was not merely a place to prepare food, but a sacred space where
culinary art met medical wisdom. Every winter solstice (冬至), the emperor's physicians and cooks gathered together
to craft special meals designed to preserve the emperor's yang qi (阳气) through the darkest and coldest time of year.

The ancient text 'Records of the Zhou Rites' (周礼) describes how the imperial chef would select warming ingredients—
root vegetables, ginger, and mutton—to create broths that would sustain the court through winter. These were not
random choices. The physicians understood that winter was the season when the body's warmth retreats inward, and
external cold could easily invade if yang qi was weak.

One legend tells of an elderly palace physician who noticed the emperor growing weak despite expensive tonics. The
wise doctor prescribed something simple: a daily bowl of ginger-date congee, taken with regularity and mindfulness.
Within weeks, the emperor's vigor returned. The lesson: consistency and alignment with seasonal rhythms matter more
than exotic ingredients.

The winter solstice meal became an annual ritual, not for luxury, but for survival. This ancient practice reflects
the deepest principle of Chinese medicine—that we are not separate from nature, but inseparable from its cycles.
        """,
        "moral_lesson": "True wellness comes from alignment with natural cycles and consistent small practices, not from luxury or excess.",
        "modern_relevance": "In our modern world of heating, artificial light, and abundant food year-round, we have lost the seasonal wisdom. Returning to winter solstice practices reminds us to slow down and build reserves during cold months.",
        "related_wellness_tip": "During winter, prioritize warming, nourishing foods taken regularly. Establish a bedtime ritual and honor the season's call to rest.",
    },
    "qingming_ancestral": {
        "id": "qingming_ancestral",
        "title": "The Legend of Qingming: Spring Awakening and Ancestral Connection",
        "category": "solar_term",
        "related_tcm_element": ["spring", "liver", "qi_circulation"],
        "period": "Han Dynasty (汉朝)",
        "length_words": 350,
        "story_text": """
Qingming (清明), the pure brightness festival, arrives in early April when the weather becomes clear and the
earth awakens. Ancient tradition says this is when the boundary between the living and ancestral worlds grows thin,
and we honor those who came before.

The festival arose during the Han Dynasty, when wise ancestors observed that spring fever and grief often arose
together. The liver, in Chinese medicine, governs the smooth flow of qi (气) and is the organ of springtime. Yet grief,
unresolved loss, and stagnation can block liver qi, causing irritability, depression, and physical tension.

The Qingming ritual—visiting tombs, tending graves, leaving offerings of food and flowers—serves as an emotional
catharsis. Families walk in nature, move their bodies, express emotion, and reconnect with lineage. These actions
naturally move qi. The food offerings (especially bitter and sour herbs, which support liver function) were not mere
ceremony, but medicine.

One story tells of a daughter who had never grieved her father's passing, burying her feelings instead. She developed
chronic headaches and menstrual pain. A wise physician told her, "Your liver is locked. Go to his tomb and cry."
When she finally wept by his grave, her symptoms eased within days. The physician understood what modern psychology
would later confirm: suppressed emotion stores in the body as pain.
        """,
        "moral_lesson": "Acknowledging grief and honoring connection—to ancestors and to our own emotions—is essential for physical and spiritual health.",
        "modern_relevance": "We tend to suppress grief in modern culture, believing it a weakness. Yet TCM and modern psychology both show that emotional expression is crucial for health. The Qingming practice of grieving openly and collectively was brilliant preventive medicine.",
        "related_wellness_tip": "In spring, allow yourself to move and feel. Practice grieving, forgiving, and letting go. Support your liver with sour and bitter herbs. Take forest walks.",
    },
    "ginger_legend": {
        "id": "ginger_legend",
        "title": "How Ginger Became China's Most Beloved Spice",
        "category": "ingredient",
        "related_tcm_element": ["warming", "digestion", "yang_qi", "vomiting"],
        "period": "Song Dynasty (宋朝)",
        "length_words": 320,
        "story_text": """
Ginger grows wild in Southeast Asia, but it was a Song Dynasty merchant named Chen who brought it to prominence
in Chinese culture. Chen traveled the maritime Silk Road, a perilous three-month journey by sea plagued by sickness,
spoilage, and despair among crews.

Chen noticed that sailors who chewed raw ginger rarely suffered from nausea and sea sickness. Their digestion remained
sound even on tossing waves and questionable food. When a fellow merchant fell deathly ill with dysentery, Chen
prepared ginger soup—warming, slightly sweet, pungent. The man recovered. Chen realized ginger was not just a flavor
enhancer, but a guardian of health during difficult times.

Upon his return to Song court, Chen presented ginger not merely as a commodity, but as a medicine worthy of imperial
attention. The emperor's physicians studied it. They confirmed its warming nature, its ability to harmonize the stomach,
and its power to help the body expel cold and dampness. Ginger was elevated from common spice to essential medicine.

From that point forward, ginger became synonymous with Chinese wellness. Every household kept dried ginger. Every
herbal formula included it. And every sailor who braved the seas carried ginger with him, trusting in its ancient protection.
        """,
        "moral_lesson": "The most powerful medicines often grow around us. Observation of how plants serve life in practical moments often reveals their deepest gifts.",
        "modern_relevance": "Ginger remains one of the most scientifically validated herbs for nausea, digestion, and inflammation. The ancient wisdom has been proven by modern research.",
        "related_wellness_tip": "Keep ginger tea on hand for digestive upset, cold onset, or nausea. A small piece of fresh ginger before meals aids digestion and warms the stomach.",
    },
    "li_shizhen_compendium": {
        "id": "li_shizhen_compendium",
        "title": "Li Shizhen and the 27-Year Journey of the Compendium",
        "category": "physician",
        "related_tcm_element": ["herbal_medicine", "research", "dedication"],
        "period": "Ming Dynasty (明朝, 1518-1593)",
        "length_words": 400,
        "story_text": """
Li Shizhen was born into a family of physicians during the Ming Dynasty. His father was a renowned doctor, yet young Li
initially resisted the calling. He studied for the civil exams, hoping for bureaucratic prestige. But after passing the
imperial exam, he found official life hollow. At 38, he returned to medicine.

Li became obsessed with a question: the existing herbal texts were full of errors and omissions. Some herbs were described
incorrectly. Some were missing entirely. He resolved to create the definitive herbal compendium. His family thought him mad.

For 27 years, Li Shizhen traveled through mountains and villages, observing plants directly, tasting herbs himself, consulting
with hunters, miners, and common people. He conducted careful experiments, recording not just classical theory but practical
observation. He examined 1,892 substances and wrote 1.9 million words—a lifetime of meticulous documentation.

When Li was 61, his Compendium of Materia Medica (本草纲目) was finally published. It became the most authoritative herbal
text of the Chinese medical tradition, so comprehensive that subsequent herbalists added little. Li had sacrificed wealth,
comfort, and family time for complete accuracy and truth. His dedication set the standard for all medicine that followed.

The story teaches that genuine healing comes not from ego or ambition, but from love of truth and service to those who will
come after.
        """,
        "moral_lesson": "True contribution to healing requires decades of humble observation, willingness to test assumptions, and dedication to accuracy over recognition.",
        "modern_relevance": "Li Shizhen's methodology—direct observation, experimentation, documentation—mirrors modern scientific method. He was a scientist before the term existed.",
        "related_wellness_tip": "Study the herbs you use. Learn where they grow, what they look like, how they taste. Direct knowledge deepens effect.",
    },
    "bian_que_diagnosis": {
        "id": "bian_que_diagnosis",
        "title": "Bian Que's Miraculous Diagnosis: The Power of Listening",
        "category": "physician",
        "related_tcm_element": ["diagnosis", "observation", "deep_listening"],
        "period": "Warring States (战国, 475-221 BCE)",
        "length_words": 330,
        "story_text": """
Bian Que (扁鹊) was legendary in ancient China for diagnoses so accurate they seemed supernatural. He lived during the
Warring States period and traveled between kingdoms, healing rulers and peasants alike. One tale illustrates his genius.

The Duke of an important state fell gravely ill. His fever raged, his mind wandered, and the finest physicians could not
awaken him. In desperation, the Duke's advisors sent for Bian Que.

Upon arrival, Bian Que did not rush to prescribe. He sat in silence by the Duke's bed for hours, merely observing and listening.
He watched how the servant poured water—how her hands trembled suggesting her fear. He heard the Duke's breathing—rapid, then
slow, then held. He smelled the quality of the breath and sweat. He noticed the color of the lips and ears. Only after this
deep observation did he feel the pulse.

Bian Que then told the Duke's family that the Duke would recover without special herbs or bloodletting. He prescribed rest,
gentle warming broths, and the presence of trusted loved ones. He made the family understand that the Duke's illness was not
a foreign invader but an imbalance arising from unchecked grief after the loss of his beloved. The Duke needed emotional healing
as much as medical treatment.

Within days, as predicted, the Duke returned to himself. Those watching understood that Bian Que's power lay not in exotic
knowledge but in the depth of his listening and observation.
        """,
        "moral_lesson": "Healing begins with deep listening and observation. Every person carries their diagnosis in their presence, if we are quiet enough to perceive it.",
        "modern_relevance": "Modern medicine often rushes to tests and treatments. The humbling truth of Bian Que's story is that careful observation and human presence are irreplaceable.",
        "related_wellness_tip": "When seeking help for health issues, find a practitioner who listens more than they speak. Trust the quiet observers.",
    },
    "lotus_white_lady": {
        "id": "lotus_white_lady",
        "title": "The Lotus Root and the White Lady: A Story of Transformation",
        "category": "ingredient",
        "related_tcm_element": ["cooling", "digestion", "beauty", "transformation"],
        "period": "Tang Dynasty (唐朝)",
        "length_words": 380,
        "story_text": """
In a Tang Dynasty village, a young woman was tormented by acne and heat-related skin problems. Her complexion was
mottled and inflamed. She became a recluse, believing herself unlovely.

An old herbalist took pity on her and explained that her skin reflected internal heat and damp-heat accumulation. "Your
body is struggling to cool itself," the herbalist said. "Lotus root can help."

The girl began eating fresh lotus root daily—sliced into cool salads, cooked into gentle soups, sometimes candied for dessert.
Lotus root is one of the few foods considered cooling and cleansing in TCM. It clears heat from the blood and calms
inflammation. Slowly, almost imperceptibly, her complexion changed. The redness faded. The skin cleared. Within months,
the transformed girl emerged—clear-skinned, bright-eyed, luminous.

The local people began to whisper that she must be the White Lady—a celestial being known for her pale, perfect complexion.
The girl's simple beauty, enhanced by clarity from within, seemed almost otherworldly. The label amused her. But the truth
was simpler: she had learned to work with her body's nature rather than against it.

This tale became a parable about patience and alignment. True transformation takes time and requires understanding our
internal nature, not fighting it with harsh treatments.
        """,
        "moral_lesson": "True beauty comes from internal clarity and balance. Transformation happens gradually when we align our choices with our constitution.",
        "modern_relevance": "Modern skincare emphasizes strong actives and surface treatments. The ancient understanding was different: clear skin reflects a clear body and balanced digestion.",
        "related_wellness_tip": "If your skin is inflamed or acne-prone, include cooling foods like lotus root, bitter greens, and mung beans. Address heat internally, not just topically.",
    },
    "zusanli_farmer": {
        "id": "zusanli_farmer",
        "title": "The Acupoint Discovered by a Farmer: How Zusanli Became the Point of Longevity",
        "category": "acupoint",
        "related_tcm_element": ["acupuncture", "vitality", "digestion"],
        "period": "Post-Han Dynasty",
        "length_words": 360,
        "story_text": """
Zusanli (足三里), "Leg Third Mile," is one of the most famous acupoints in Chinese medicine. Legend traces its discovery
not to imperial physicians, but to a farmer.

A farmer worked his fields from dawn to dusk. His life was physically demanding—his body should have worn out quickly.
Yet remarkably, this farmer remained vigorous into old age. Neighbors marveled at his strength, his clear mind, his
undiminished appetite.

When the farmer was very old, a traveling physician asked the secret of his health. The farmer laughed. "No secret. Every
evening, I sit by the fire and massage a tender point on my leg—just below the knee. It has always felt good, like waking
up tired muscles. I do it without thinking."

The physician examined the point and realized the farmer had accidentally discovered one of the most powerful acupoints on
the body. This point, Zusanli (Stomach 36), governs digestive function, strengthens immunity, and tonifies qi generally.
The farmer's regular stimulation of this point—through massage, the friction of his work, and likely traditional moxibustion—
had been his longevity medicine all along.

From this encounter, Zusanli's reputation grew. Ancient physicians confirmed that needling or moxaing this point strengthened
the foundation of health. It became known as the "Point of Longevity" and the "Point of Three Miles"—supposedly allowing a
weary traveler to walk three more miles. It is one of the most frequently used points in acupuncture to this day.
        """,
        "moral_lesson": "The most powerful healing practices are often simple and accessible. The body knows what it needs; sometimes we just need to listen and respond consistently.",
        "modern_relevance": "Scientific studies have verified that stimulation of Zusanli enhances immune function, improves digestion, and increases longevity markers. Ancient wisdom meets modern validation.",
        "related_wellness_tip": "Learn to find and massage Zusanli (found below the knee, in the depression when your leg is bent 90 degrees). Regular gentle massage or moxibustion here supports long-term vitality.",
    },
    "emperor_shennong_tea": {
        "id": "emperor_shennong_tea",
        "title": "Emperor Shennong and the First Cup of Tea",
        "category": "tea",
        "related_tcm_element": ["tea_culture", "detoxification", "cultivation"],
        "period": "Legendary (传说中)",
        "length_words": 350,
        "story_text": """
Emperor Shennong (神农) is a mythical figure in Chinese history, credited with discovering agriculture and medicine.
According to legend, he possessed an unusual gift: his body was transparent, and he could see the effect of herbs as
they moved through his stomach and organs.

Using this ability, Shennong tested countless plants, experiencing their effects directly. He documented which healed,
which poisoned, and which balanced the body. His dedication was absolute—he was poisoned countless times, learning from
each near-fatal experiment.

One day, as Shennong rested from his labors, a leaf from a wild tea plant drifted into his pot of boiling water. He drank
the resulting brew and immediately felt a profound clarity. The leaves, he discovered, had the power to awaken the mind,
settle the spirit, and counteract certain poisons. He had found not just another herb, but a philosophy of cultivation.

Shennong declared that tea was the perfect drink for a scholar and healer—something to accompany contemplation, something
to clear the mind and support longevity. From that mythical beginning, tea became central to Chinese culture, paired with
medicine, philosophy, and daily ritual.

The lesson of Shennong is that the greatest teacher is direct experience, and that the greatest discoveries often come
when we slow down enough to notice what nature offers us.
        """,
        "moral_lesson": "Direct observation and willingness to experience consequences leads to wisdom that no theory alone can provide. Mindful consumption reveals medicine.",
        "modern_relevance": "Tea science has validated what Shennong discovered: tea is rich in antioxidants, supports cognitive function, and contributes to longevity.",
        "related_wellness_tip": "Make tea a daily practice, not just a beverage. Use it as a moment for pause, clarity, and contemplation. Different teas offer different benefits.",
    },
    "cinnamon_silk_road": {
        "id": "cinnamon_silk_road",
        "title": "How Cinnamon Traveled the Silk Road: Trade Routes as Healing Routes",
        "category": "silk_road",
        "related_tcm_element": ["warming", "circulation", "trade", "cultural_exchange"],
        "period": "Tang to Ming Dynasty (唐至明朝)",
        "length_words": 380,
        "story_text": """
Cinnamon is native to Sri Lanka and Southeast Asia. For centuries, its value was so high that it was traded weight-for-weight
with silver. The question was: how to bring this precious substance safely across deserts, mountains, and hostile lands to
wealthy markets in the Middle East, Europe, and China?

The Silk Road was not purely a trade route—it was a living ecosystem of merchants, monks, explorers, and healers. Along
the way, precious goods were exchanged not just for profit, but because their healing power was recognized across cultures.

Cinnamon traveled westward and, more importantly, was embraced wholeheartedly by Chinese medicine. Physicians discovered
that cinnamon bark was warming, invigorating the digestive fire and improving circulation. It moved qi and blood. It warmed
the kidneys. It was particularly valuable in cold climates where yang qi easily became depleted.

But the Silk Road brought more than cinnamon. It brought ideas, philosophies, and medical knowledge. Chinese physicians learned
from Persian healers. Arab physicians learned from Indian Ayurveda. The very route of spice trade became a route of medical
knowledge exchange.

One Tang Dynasty physician documented that cinnamon combined with other spices brought from the Silk Road created powerful
formulas unknown in earlier eras. The age of exploration was also an age of medicinal expansion. Cinnamon was not just a flavor
enhancer—it was a bridge between cultures.
        """,
        "moral_lesson": "Healing knowledge spreads through genuine exchange and mutual respect. The most powerful medicines often come from integration of different traditions.",
        "modern_relevance": "Modern TCM herbalism is enriched by integration with Ayurveda, functional medicine, and nutrition science. Just as the Silk Road brought new herbs and knowledge, cross-cultural medicine strengthens us all.",
        "related_wellness_tip": "Cinnamon is warming and beneficial for circulation and digestion, especially in cold seasons. A pinch in tea or food supports healthy qi and warmth.",
    },
    "white_peony_root": {
        "id": "white_peony_root",
        "title": "The White Peony Root and the Scholar's Trembling Hands",
        "category": "ingredient",
        "related_tcm_element": ["blood_nourishment", "anxiety", "creativity"],
        "period": "Song Dynasty (宋朝)",
        "length_words": 320,
        "story_text": """
A renowned scholar in the Song Dynasty began to suffer a peculiar affliction: his hands trembled uncontrollably. As a
calligrapher and painter, steady hands were essential to his art. The trembling grew worse with stress, rendering him unable
to create.

Western physicians of his day would have offered little. But a Chinese physician examined him deeply and said, "Your blood is
insufficient to nourish your hands and settle your spirit. The trembling is your body's cry for nourishment."

The physician prescribed white peony root (白芍), a pale, sweet herb that nourishes blood and softens the Liver's rigid tension.
In TCM, tremors often result from Yin or blood deficiency, or from Liver qi stagnation—both conditions that white peony root
addresses beautifully.

The scholar took white peony root in a gentle decoction daily. Within weeks, the trembling subsided. More remarkably, his
creative output flourished. His calligraphy became more fluid, his paintings more inspired. The herb had restored not just
physical steadiness, but spiritual flow.

The scholar spent his final years teaching that true stability comes not from rigid control, but from nourishment and flow.
The white peony had taught him this.
        """,
        "moral_lesson": "Trembling, anxiety, and rigidity often reflect insufficient nourishment. Gentleness and adequate self-care restore not just physical but creative function.",
        "modern_relevance": "Modern stress medicine recognizes that tremors, anxiety, and creative blocks often reflect nutrient insufficiency and autonomic dysregulation—conditions that nourishing herbs address.",
        "related_wellness_tip": "If you experience tremors, anxiety, or creative block, ensure adequate blood and yin nourishment. White peony root, dates, and dark leafy greens support this.",
    },
    "cordyceps_mountain": {
        "id": "cordyceps_mountain",
        "title": "The Cordyceps Legend: Fungus of the Mountains",
        "category": "ingredient",
        "related_tcm_element": ["yang_qi", "stamina", "high_altitude"],
        "period": "Tibetan and Ming records",
        "length_words": 340,
        "story_text": """
High in the Tibetan plateau, at altitudes where few plants survive, grows cordyceps (冬虫夏草)—a rare fungus that is part
caterpillar, part mushroom. Cordyceps are found only in specific high-altitude regions, making them precious beyond measure.

The story goes that Tibetan herders discovered cordyceps' properties through necessity. Living at extreme altitude with thin air,
cold climate, and physical demands, these herders experienced fatigue that ordinary tonics could not touch. They noticed that
cordyceps, when consumed, provided extraordinary stamina and resilience. Herds that grazed on pastures where cordyceps naturally
grew were healthier, more robust, more able to endure the harsh climate.

Traditional knowledge holds that cordyceps bridges yin and yang—it is fungal (yin in nature) but grows from an insect (yang).
This unique combination makes it powerfully tonifying without being overstimulating. It strengthens qi without creating heat.
It supports both lung and kidney function, precious in high-altitude environments where oxygen is scarce.

The cordyceps became so valued that Tibetan herders developed careful practices of harvesting—never taking all plants, always
leaving seeds for future growth. This sustainable practice has kept cordyceps viable for centuries.

In modern TCM, cordyceps remain one of the most expensive and highly valued tonics, used to support fatigue, strengthen
stamina, and support longevity in those who must endure demanding conditions.
        """,
        "moral_lesson": "The most valuable medicines are often found in the most difficult environments, adapting to extreme conditions. We can learn resilience by studying nature's adaptations.",
        "modern_relevance": "Modern research validates that cordyceps enhance mitochondrial ATP production and oxygen utilization—explaining the ancient wisdom about stamina and altitude adaptation.",
        "related_wellness_tip": "If you face demanding conditions or chronic fatigue, consider cordyceps as a premium tonic. It is expensive, but a small amount goes a long way.",
    },
    "rehmannia_root_legend": {
        "id": "rehmannia_root_legend",
        "title": "Rehmannia Root and the Return of Vitality",
        "category": "ingredient",
        "related_tcm_element": ["kidney_yin", "aging", "vitality_restoration"],
        "period": "Ming Dynasty (明朝)",
        "length_words": 300,
        "story_text": """
In the Ming Dynasty, there lived a noblewoman who, by her fifties, had aged dramatically. Her hair whitened, her skin withered,
her energy depleted. She had lived a life of excess—overwork, stress, and insufficient rest. Her beauty and vitality seemed
permanently lost.

Desperation led her to a Daoist hermit known for impossible healings. After examining her, the hermit prescribed rehmannia root
(熟地黄)—a dark, sweet herb that nourishes the deepest yin resources of the body.

"Your essence is depleted," the hermit explained. "Decades of excess without nourishment have left your yin dry and withered.
Rehmannia is the premier restorer of yin essence. But it requires patience—true restoration takes years, not weeks."

The noblewoman committed herself. She took rehmannia daily, lived modestly, rested adequately, and meditated. Within months,
her energy stabilized. Within a year, her hair began to darken. Within three years, her complexion transformed. By her sixties,
she seemed fifty again. More importantly, she had found peace.

The story teaches that aging is not irreversible—but restoration requires commitment to nourishment and patience. Rehmannia
became legendary as the herb that can turn back time, not through magic, but through deep nutritional support and wise living.
        """,
        "moral_lesson": "True restoration takes time, commitment, and patience. Quick fixes are less effective than sustained nourishment and wise lifestyle.",
        "modern_relevance": "Telomerase research shows that consistent stress reduction and nourishing practices can slow and partially reverse aging markers.",
        "related_wellness_tip": "To support aging gracefully, include yin-nourishing herbs like rehmannia, goji, and sesame. Prioritize rest and stress reduction.",
    },
}


# ─────────────────────────────────────────────────────────────────────────────
# 辅助函数
# ─────────────────────────────────────────────────────────────────────────────

def _get_daily_story_id() -> str:
    """基于当前日期返回一个一致的故事 ID。"""
    day_of_year = datetime.now().timetuple().tm_yday
    story_ids = list(CULTURAL_STORIES.keys())
    return story_ids[day_of_year % len(story_ids)]


# ─────────────────────────────────────────────────────────────────────────────
# 端点
# ─────────────────────────────────────────────────────────────────────────────

@router.get("/", summary="故事列表")
async def get_stories(
    category: Optional[str] = Query(None, description="分类过滤：solar_term, ingredient, physician, acupoint, tea, silk_road"),
    season: Optional[str] = Query(None, description="季节过滤：spring, summer, autumn, winter"),
):
    """返回 TCM 文化故事列表。"""
    results = []

    for story_id, story_data in CULTURAL_STORIES.items():
        # 分类过滤
        if category and story_data["category"] != category:
            continue

        # 季节过滤（通过 related_tcm_element）
        if season:
            if season not in story_data.get("related_tcm_element", []):
                continue

        results.append({
            "id": story_data["id"],
            "title": story_data["title"],
            "category": story_data["category"],
            "period": story_data["period"],
            "length_words": story_data["length_words"],
            "moral_lesson": story_data["moral_lesson"],
        })

    return {
        "success": True,
        "data": {
            "total_stories": len(results),
            "stories": results,
        },
    }


@router.get("/{story_id}", summary="完整故事")
async def get_story_detail(story_id: str):
    """返回某个故事的完整内容。"""
    if story_id not in CULTURAL_STORIES:
        raise HTTPException(status_code=404, detail="故事不存在")

    story = CULTURAL_STORIES[story_id]
    return {
        "success": True,
        "data": story,
    }


@router.get("/daily", summary="今日精选故事")
async def get_daily_story():
    """返回基于今日日期的精选故事。每天相同。"""
    story_id = _get_daily_story_id()
    story = CULTURAL_STORIES[story_id]

    return {
        "success": True,
        "data": {
            "date": datetime.now().strftime("%Y-%m-%d"),
            "daily_featured_story": story,
            "tip": "返回同一天的多次调用将返回相同的故事。",
        },
    }


@router.get("/category/{category}", summary="按分类查看")
async def get_stories_by_category(category: str):
    """返回某个分类下的所有故事。"""
    valid_categories = ["solar_term", "ingredient", "physician", "acupoint", "tea", "silk_road"]
    if category not in valid_categories:
        raise HTTPException(status_code=400, detail=f"分类无效。有效分类：{', '.join(valid_categories)}")

    results = []
    for story_id, story_data in CULTURAL_STORIES.items():
        if story_data["category"] == category:
            results.append({
                "id": story_data["id"],
                "title": story_data["title"],
                "period": story_data["period"],
                "length_words": story_data["length_words"],
                "moral_lesson": story_data["moral_lesson"],
            })

    return {
        "success": True,
        "data": {
            "category": category,
            "total_in_category": len(results),
            "stories": results,
        },
    }


@router.get("/related/{tcm_element}", summary="相关故事")
async def get_related_stories(tcm_element: str):
    """返回与某个 TCM 元素相关的所有故事。"""
    tcm_element_lower = tcm_element.lower()
    results = []

    for story_id, story_data in CULTURAL_STORIES.items():
        related = story_data.get("related_tcm_element", [])
        if any(tcm_element_lower in str(e).lower() for e in related):
            results.append({
                "id": story_data["id"],
                "title": story_data["title"],
                "category": story_data["category"],
                "moral_lesson": story_data["moral_lesson"],
            })

    if not results:
        return {
            "success": True,
            "data": {
                "tcm_element": tcm_element,
                "found": False,
                "stories": [],
                "message": "没有与该元素相关的故事。",
            },
        }

    return {
        "success": True,
        "data": {
            "tcm_element": tcm_element,
            "found": True,
            "total_related": len(results),
            "stories": results,
        },
    }
