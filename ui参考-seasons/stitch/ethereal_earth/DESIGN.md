# Design System Specification: A Study in Seasonal Transition

This document defines the visual language and structural principles for a "Calm Lifestyle" experience. It is designed to move beyond the rigid, mechanical grids of traditional apps, opting instead for an editorial, "high-end boutique" feel that balances the wisdom of nature with modern digital clarity.

---

### 1. Creative North Star: "The Digital Sanctuary"
The Creative North Star for this system is **The Digital Sanctuary**. Unlike standard utility apps that prioritize speed and high-density information, this system prioritizes *rhythm and breath*. 

We break the "template" look through **Intentional Asymmetry**. Imagery should often bleed off the edge of the screen or sit offset from text blocks. We use a high-contrast typography scale to create an editorial hierarchy—large, "wise" serif headlines paired with diminutive, functional sans-serif labels. The goal is to make the user feel like they are turning the pages of a premium linen-bound journal.

---

### 2. Color & Surface Philosophy
The palette is rooted in the earth: Sage (`primary`), Terracotta (`secondary`), and Cream (`background`). 

#### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders for sectioning. Boundaries must be defined solely through background color shifts or tonal transitions.
- To separate a header from a body, transition from `surface` to `surface-container-low`.
- To highlight a feature, use a `surface-container-high` block against the `background`.

#### Surface Hierarchy & Nesting
Treat the UI as physical layers of fine paper.
- **Base Layer:** `surface` (#fbf9f5).
- **Secondary Layer:** `surface-container-low` (#f5f3ef) for subtle grouping.
- **Interactive Layer:** `surface-container-highest` (#e4e2de) for cards or elements that require immediate attention.

#### The "Glass & Gradient" Rule
To prevent a "flat" or "cheap" appearance, use **Glassmorphism** for floating elements (like bottom navigation bars or sticky headers). Use a semi-transparent `surface` color with a `backdrop-blur` of 20px. 
*Signature Texture:* Apply a subtle linear gradient to main CTAs, transitioning from `primary` (#56642b) to `primary-container` (#8a9a5b) at a 45-degree angle to give the Sage green a botanical depth.

---

### 3. Typography: Wisdom & Clarity
We employ a "dual-voice" typographic strategy.

*   **The Voice of Wisdom (Noto Serif):** Used for `display` and `headline` levels. This font conveys heritage and calm. It should be given significant leading (1.4x+) to allow the words to breathe.
*   **The Voice of Clarity (Manrope):** Used for `title`, `body`, and `label` levels. This is a highly legible sans-serif that ensures the "sophisticated" brand doesn't sacrifice usability.

**Key Scales:**
- **Display Large:** `notoSerif`, 3.5rem — For moments of inspiration.
- **Headline Medium:** `notoSerif`, 1.75rem — For section headers.
- **Body Large:** `manrope`, 1rem — For long-form editorial content.
- **Label Medium:** `manrope`, 0.75rem — For utility and metadata.

---

### 4. Elevation & Depth
In this system, depth is organic, not synthetic.

*   **Tonal Layering:** Instead of shadows, stack `surface-container-lowest` cards on a `surface-container-low` background. This creates a "soft lift" that feels natural to the eye.
*   **Ambient Shadows:** Where a floating effect is vital (e.g., a modal or a primary FAB), use a custom shadow: `0 20px 40px rgba(27, 28, 26, 0.05)`. Notice the use of the `on-surface` color (#1b1c1a) at a very low opacity to mimic natural light.
*   **The Ghost Border:** If accessibility requires a container boundary, use `outline-variant` (#c6c8b8) at **15% opacity**. Never use 100% opaque borders.

---

### 5. Components

#### Buttons
- **Primary:** Rounded `xl` (1.5rem). Background is the Sage gradient (`primary` to `primary-container`). Text is `on-primary` (White).
- **Secondary:** Rounded `xl`. Background is `secondary-fixed` (Terracotta mist). Text is `on-secondary-container`.
- **Tertiary:** No background. `title-sm` typography in `primary`.

#### Cards & Lists
- **Rule:** Forbid the use of divider lines.
- **Cards:** Use `xl` (1.5rem) or `lg` (1rem) corner radius. Use `surface-container-low` backgrounds to distinguish from the main page.
- **Spacing:** Use the `Spacing Scale 8` (2.75rem) between list items to prevent a cluttered "utility" feel.

#### Input Fields
- **Style:** Minimalist. No bottom border. Instead, use a `surface-container-high` background with an `xl` corner radius. 
- **Focus:** Transition the background to `surface-container-highest` and add a `Ghost Border` of `primary` at 20% opacity.

#### Imagery (The "Organic" Component)
All imagery must use `xl` (1.5rem) corner radius. To enhance the "Modern meets Nature" feel, try to overlap images slightly over text containers using negative margins from the spacing scale (e.g., `-spacing-10`).

---

### 6. Do’s and Don’ts

#### Do
- **Do** use whitespace as a functional element. If in doubt, add more space (use `spacing-16` or `spacing-20`).
- **Do** use "Editorial Offsets"—shift text 1.4rem (`spacing-4`) to the right of its containing image to break the grid.
- **Do** use Terracotta (`secondary`) sparingly as an accent to draw the eye to "warm" interactions (like 'Save' or 'Favorite').

#### Don't
- **Don’t** use 90-degree corners. Everything in nature is curved; everything in this system should be at least `md` (0.75rem) or `xl` (1.5rem).
- **Don’t** use pure black for text. Always use `on-surface` (#1b1c1a) for a softer, more sophisticated charcoal finish.
- **Don’t** use standard "drop shadows." If a layer doesn't feel separated enough, use a different `surface-container` token first.