```markdown
# Design System Documentation: The Living Ink-Wash

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Digital Scroll."** Unlike traditional apps that feel like a collection of rigid boxes, this system is designed to feel like a continuous, organic journey—an evolving ink-wash painting that breathes with the user. 

We are moving away from the "industrial" feel of modern tech and toward a **"New Chinese" Editorial aesthetic**. This is achieved through intentional asymmetry, vast negative space, and a rejection of hard structural lines. The interface doesn't just present data; it provides "warm companionship." The layout should feel like a premium lifestyle magazine: high-contrast typography scales, overlapping elements that break the grid, and a seasonal soul that shifts color based on the 24 Solar Terms.

---

## 2. Colors & Tonal Atmosphere
The palette is rooted in nature, using deep botanical greens and sun-dried earth tones.

*   **Primary (Ink Green - `#144227`):** The grounding force. Used for moments of authority and primary actions.
*   **Secondary (Warm Apricot - `#74593c`):** The "human" element. Used for cards and supportive elements that need to feel approachable.
*   **Surface (Elegant White - `#fdf9f4`):** Our canvas. It provides the "breathing room" essential to the minimalist aesthetic.
*   **Tertiary (Light Gold - `#4c3605`):** Reserved for the "Membership" and "Premium" experience—use sparingly to maintain its value.

### The "No-Line" Rule
To achieve a high-end editorial feel, **1px solid borders are strictly prohibited** for sectioning. We define boundaries through:
1.  **Background Color Shifts:** A `surface_container_low` (`#f7f3ee`) section sitting on a `surface` background creates a natural, soft edge.
2.  **Vertical Whitespace:** Use the Spacing Scale (specifically `12` / `4rem` or `16` / `5.5rem`) to separate thoughts rather than lines.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers of fine paper. 
*   **Base:** `surface` (`#fdf9f4`)
*   **Sectioning:** `surface_container_low` (`#f7f3ee`)
*   **Prominence:** Use `surface_container_lowest` (`#ffffff`) for cards to create a subtle "lift" against the off-white background.

### The Glass & Gradient Rule
For floating AI modules or temporary overlays, use **Glassmorphism**. Apply a backdrop-blur (12px–20px) to a semi-transparent `surface_container` color. For main CTAs, use a subtle linear gradient from `primary` (`#144227`) to `primary_container` (`#2d5a3d`) to give the button a "rounded," three-dimensional ink-drop quality.

---

## 3. Typography: The Editorial Voice
We contrast the heritage of the Serif with the modern efficiency of the Sans.

*   **Display & Headlines (Source Han Serif / `notoSerif`):** This is the "Voice of Wisdom." Use `display-lg` (3.5rem) for seasonal greetings and `headline-md` for wellness insights. Encourage **intentional asymmetry**—left-align headlines with a wide right margin to allow the layout to "breathe."
*   **Body & Labels (Source Han Sans / `manrope`):** This is the "Voice of the Friend." Use `body-lg` (1rem) for most content to ensure high readability and a "non-preachy" feel. 
*   **Letter Spacing:** For `label-md` and `label-sm`, increase letter-spacing by 0.05rem to mimic high-end print kerning.

---

## 4. Elevation & Depth
In this system, depth is felt, not seen. We avoid the "drop shadow" look of the early 2010s.

*   **The Layering Principle:** Stacking is our primary tool. A `surface_container_highest` card on a `surface_container_low` background provides enough contrast to signify hierarchy without a single shadow.
*   **Ambient Shadows:** When an element must float (e.g., a bottom sheet or a floating action button), use a shadow with a `24px` blur and `4%` opacity, tinted with the `on_surface` (`#1c1c19`) color. It should look like a soft glow of light, not a dark smudge.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility in input fields, use `outline_variant` (`#c1c9c0`) at **20% opacity**. It should be barely perceptible.

---

## 5. Components

### Buttons
*   **Primary:** Solid `primary` (`#144227`) with `on_primary` (`#ffffff`) text. Use `rounded-lg` (`0.5rem`)—not fully pill-shaped—to maintain a modern, architectural feel.
*   **Secondary:** `secondary_container` (`#ffd9b4`) with `on_secondary_container` (`#795d40`). This feels warmer and less urgent.
*   **Tertiary:** No background. `primary` text with a subtle `3.5` (1.2rem) padding to maintain a large hit state.

### Cards & Lists
*   **No Dividers:** Lists should never use horizontal lines. Use a `1.5` (0.5rem) or `2` (0.7rem) gap between items.
*   **Layered Cards:** Cards should use `surface_container_lowest` (`#ffffff`) and no border. 
*   **The Seasonal Tag:** A specialized chip using the current "Solar Term" color to tag content as "Spring" or "Autumn" appropriate.

### Input Fields
*   **Style:** Minimalist. No bottom line or box. Use a `surface_container` background with `rounded-md` (`0.375rem`).
*   **Focus State:** Transition the background to `surface_bright` and add a "Ghost Border" of `primary` at 30% opacity.

### AI Companion Module
*   A specialized container using **Glassmorphism**. 
*   **Background:** `surface_container_low` at 80% opacity with a `20px` backdrop blur.
*   **Interaction:** When the AI "speaks," use a subtle pulse animation using the `tertiary_fixed_dim` (`#e4c285`) color.

---

## 6. Do's and Don'ts

### Do:
*   **Embrace the Void:** Use the `20` (7rem) and `24` (8.5rem) spacing tokens for top-level page margins. Space is luxury.
*   **Layer Tones:** Use `surface_container` tiers to create hierarchy.
*   **Use Low-Saturation Photography:** Ensure all imagery has a slightly lowered "Ink-wash" saturation to match the `#6B7B7D` text tone.

### Don't:
*   **No Hard Grids:** Avoid perfectly symmetrical "bento box" layouts. Offset your images or text to create visual interest.
*   **No Medical Jargon:** Even in the UI (e.g., error messages), keep the voice gentle. Instead of "Invalid Input," use "Let's try that again."
*   **No 100% Opaque Borders:** Never use the `outline` token at 100% opacity. It breaks the "New Chinese" softness.
*   **No Pure Black:** Always use `on_surface` (`#1c1c19`) or `on_background` for text. Pure black is too harsh for this "Warm Companionship" brand.

---
**Director's Final Note:** 
Remember, you are not building a dashboard; you are curate-ing a sanctuary. Every pixel should feel intentional, quiet, and meaningful. If the screen feels "busy," remove an element. If it feels "flat," add a layer—not a line.```