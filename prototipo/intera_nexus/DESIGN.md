# Design System Document: Academic Mastery & Connection

## 1. Overview & Creative North Star: "The Digital Curator"

This design system is built to transform academic networking from a noisy social feed into a focused, high-end editorial experience. Our Creative North Star is **"The Digital Curator."** 

Unlike traditional social platforms that rely on "vanity metrics" (likes, view counts) and rigid grids, this system prioritizes **intellectual breathing room**. We move beyond the "template" look by utilizing intentional asymmetry, varying typographic scales, and layered surfaces. The goal is to make the user feel like they are navigating a premium academic journal or a high-end architectural portfolio—calm, professional, and mastery-oriented.

### Creative Principles:
*   **Asymmetry as Intent:** Avoid perfectly centered blocks. Offset text and imagery to create a sense of movement and sophisticated editorial design.
*   **Data Dignity:** In compliance with LGPD and our "no vanity" rule, we prioritize qualitative connections over quantitative noise. No "10k followers" labels; only "Collaborador" or "Especialista."
*   **Silent UI:** The interface should disappear, leaving only the content and the connections.

---

## 2. Colors & Surface Philosophy

The palette is a sophisticated blend of cool neutrals and a singular, deep Indigo accent. We use color not just for decoration, but to define the physical architecture of the app.

### The "No-Line" Rule
**Explicit Instruction:** Do not use 1px solid borders to separate sections. Sectioning must be achieved through background color shifts. For example, a profile bio (`surface-container-low`) should sit on the main page background (`surface`) without a stroke.

### Surface Hierarchy & Nesting
We treat the UI as a series of stacked, fine-paper layers. 
*   **Base:** `surface` (#fbf8fc)
*   **Secondary Level:** `surface-container-low` (#f5f2f8) for secondary groupings.
*   **Interactive Level:** `surface-container-highest` (#e3e1ec) for active cards or headers.

### The "Glass & Gradient" Rule
To elevate the "out-of-the-box" feel, floating elements (like Navigation Bars or Quick Action Modals) must use **Glassmorphism**.
*   **Token:** `surface-container-lowest` (#ffffff) at 80% opacity with a 20px Backdrop Blur.
*   **Signature Textures:** Main CTAs (e.g., "Publicar Pesquisa") should use a subtle linear gradient: `primary` (#4355b9) to `primary-dim` (#3649ac) at a 135° angle.

---

## 3. Typography: Editorial Authority

We pair **Manrope** for high-impact display moments with **Inter** for functional clarity. This contrast signals the difference between "Inspiration" (Headlines) and "Information" (Body).

*   **Display (Manrope):** Use for "Boas-vindas" or "Novas Conexões." Large, bold, and airy.
*   **Body (Inter):** Optimized for long-form academic abstracts. Use `body-md` for standard text to maintain a high-density, professional feel.
*   **The pt-BR Nuance:** Brazilian Portuguese often results in longer word strings than English. Always allow for 1.5x line-height (`leading-relaxed`) to prevent dense "walls of text."

**Hierarchy Example:**
*   `headline-lg`: **Descubra novos horizontes.** (Manrope, 2rem)
*   `body-md`: Explore publicações e colabore com pesquisadores de todo o Brasil. (Inter, 0.875rem)

---

## 4. Elevation & Depth: Tonal Layering

Traditional drop shadows are too "heavy" for a minimalist academic tool. We achieve depth through the **Layering Principle**.

### Ambient Shadows
When an element must float (e.g., a floating action button), use an ultra-diffused shadow:
*   **Shadow Color:** `on-surface` (#31323a) at 4% opacity.
*   **Blur:** 24px | **Y-Offset:** 8px.

### The "Ghost Border" Fallback
If a border is required for accessibility in input fields, use a **Ghost Border**:
*   **Token:** `outline-variant` (#b2b1bb) at **15% opacity**. Never use 100% opaque borders.

---

## 5. Components

### Buttons (Botões)
*   **Primary:** Gradient (`primary` to `primary-dim`), White text, `lg` (1rem) roundedness. No shadow.
*   **Secondary:** `surface-container-highest` background with `on-surface` text.
*   **States:** On `pressed`, shift the background to `primary-fixed-dim`.

### Cards & Lists (Cards e Listas)
*   **Constraint:** Forbid divider lines.
*   **Implementation:** Use a `spacing-4` (1rem) vertical gap and a subtle background shift to `surface-container-low` for the card body. 
*   **Content:** Place the researcher's name in `title-md` and their institution in `label-md` with `secondary` (#5e5e67) color.

### Input Fields (Campos de Entrada)
*   **Style:** Minimalist underline or "Ghost Border." 
*   **Focus State:** The label slides up and changes to `on-primary-container` (#3648ac).
*   **LGPD Hint:** Every input field that collects personal data must include a `label-sm` helper text in `secondary` color: *"Seus dados estão protegidos sob a LGPD."*

### Chips (Categorias)
*   **Filter Chips:** `surface-container-high` with 9999px (full) roundedness. When selected, use `primary-container` background with `on-primary-container` text.

### Connection Indicators (Sem Métricas de Vaidade)
Instead of "500+ conexões", use "Conectado via [Instituição]" or "Interesses em comum: [Tópico]".

---

## 6. Do's and Don'ts

### Do
*   **Do** use `surface-container-lowest` for the main content area to make it feel like "pure paper."
*   **Do** prioritize white space (vão livre) over decorative elements. If in doubt, add `spacing-8`.
*   **Do** ensure all calls to action are in clear pt-BR (e.g., use "Solicitar Colaboração" instead of "Conectar").

### Don't
*   **Don't** use 100% black (#000000). Use `inverse-surface` (#0e0e11) for deep contrast.
*   **Don't** use standard "Success Green" or "Warning Yellow" unless absolutely necessary for system errors. Prefer tonal shifts.
*   **Don't** use icons without labels. In an academic context, clarity is mastery.
*   **Don't** use sharp 90-degree corners. Always use a minimum of `DEFAULT` (0.5rem) to keep the "Soft Minimalism" tone.