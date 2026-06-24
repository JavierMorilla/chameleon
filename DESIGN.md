# Design

## Theme

Dark. Pure near-black background (`oklch(0.09 0.000 0)`), vivid saturated brand colors on top. The darkness is not "AMOLED aesthetic" — it's the physical scene: a party table at night, dark ambient, bright cards on top. The brand colors carry all the energy; the surface stays neutral.

Color strategy: **Full palette** — 3 named brand roles used deliberately. Party game UI needs high readability under bad lighting and quick legibility at a glance.

Brand mood phrase: *Brightly colored trivia cards scattered on a dark bar table — the fun lives in the cards, not the furniture.*

## Color

```css
:root {
  /* Brand seed: seed-037 — warm coral / burnt orange */
  /* Seed anchor: oklch(0.590 0.188 35.8) */

  /* Backgrounds */
  --color-bg:        oklch(0.09 0.000 0);       /* near-black, no hue tint */
  --color-surface:   oklch(0.14 0.000 0);       /* cards, panels */
  --color-surface-2: oklch(0.18 0.000 0);      /* elevated surfaces, modals */
  --color-border:    oklch(0.22 0.000 0);       /* dividers, input borders */

  /* Brand primary — coral/orange, party energy */
  --color-primary:   oklch(0.62 0.190 35.0);   /* warm coral — CTAs, active states */
  --color-primary-dim: oklch(0.50 0.150 35.0); /* pressed / disabled primary */

  /* Brand accent — electric yellow, second player */
  --color-accent:    oklch(0.82 0.175 88.0);   /* yellow-gold — badges, highlights, impostors */
  --color-accent-dim: oklch(0.70 0.130 88.0);  /* secondary accent states */

  /* Brand tertiary — electric teal, third player color (role reveal) */
  --color-tertiary:  oklch(0.65 0.155 195.0);  /* teal — confirmations, "you're safe" */

  /* Text */
  --color-ink:       oklch(0.95 0.000 0);       /* body text — ≥7:1 vs bg */
  --color-muted:     oklch(0.55 0.000 0);       /* secondary text — ≥3.5:1 vs bg */
  --color-on-primary: oklch(0.98 0.000 0);      /* text on primary fill */
  --color-on-accent:  oklch(0.10 0.000 0);      /* text on accent fill (pale, use dark) */
}
```

## Typography

**Google Fonts pairing:**
- **Display / Game headings**: [Syne](https://fonts.google.com/specimen/Syne) — geometric, bold personality, wide range of weights. Used for word reveals, role cards, game state headings.
- **Body / UI**: [DM Sans](https://fonts.google.com/specimen/DM+Sans) — humanist, highly legible at small sizes, friendly without being childish.

Contrast axis: geometric display + humanist body. Neither is a serif, but they diverge strongly on personality and proportion.

```css
@import url('https://fonts.googleapis.com/css2?family=Syne:wght@700;800&family=DM+Sans:ital,opsz,wght@0,9..40,400;0,9..40,500;0,9..40,600;1,9..40,400&display=swap');

:root {
  --font-display: 'Syne', system-ui, sans-serif;
  --font-body:    'DM Sans', system-ui, sans-serif;

  /* Scale */
  --text-xs:   0.75rem;   /* 12px — labels */
  --text-sm:   0.875rem;  /* 14px — secondary UI */
  --text-base: 1rem;      /* 16px — body */
  --text-lg:   1.125rem;  /* 18px — emphasized body */
  --text-xl:   1.25rem;   /* 20px — section headings */
  --text-2xl:  1.5rem;    /* 24px — card titles */
  --text-3xl:  1.875rem;  /* 30px — word reveal */
  --text-4xl:  clamp(2.25rem, 6vw, 3rem); /* game role display */
  --text-hero: clamp(3rem, 10vw, 5.5rem); /* splash / impostor reveal */

  /* Weight */
  --weight-regular: 400;
  --weight-medium:  500;
  --weight-semibold: 600;
  --weight-bold:    700;
  --weight-extrabold: 800;

  /* Tracking */
  --tracking-tight:  -0.03em;  /* display headings (floor: -0.04em) */
  --tracking-normal: 0em;
  --tracking-wide:   0.08em;   /* all-caps labels only */

  /* Leading */
  --leading-tight:  1.1;
  --leading-snug:   1.25;
  --leading-normal: 1.5;
}
```

## Spacing & Layout

Mobile-first. The game is played on mobile in portrait mode; tablet is a secondary landscape view for the host.

```css
:root {
  --space-1:  0.25rem;   /* 4px */
  --space-2:  0.5rem;    /* 8px */
  --space-3:  0.75rem;   /* 12px */
  --space-4:  1rem;      /* 16px */
  --space-5:  1.25rem;   /* 20px */
  --space-6:  1.5rem;    /* 24px */
  --space-8:  2rem;      /* 32px */
  --space-10: 2.5rem;    /* 40px */
  --space-12: 3rem;      /* 48px */
  --space-16: 4rem;      /* 64px */
  --space-20: 5rem;      /* 80px */

  /* Layout */
  --max-content: 28rem;  /* 448px — single-column game flow */
  --page-pad:    var(--space-5); /* horizontal page padding */
  --section-gap: var(--space-10);
}
```

## Border Radius

```css
:root {
  --radius-sm:   6px;   /* inputs, small buttons */
  --radius-md:   10px;  /* cards, panels */
  --radius-lg:   16px;  /* role cards, modals */
  --radius-pill: 9999px; /* tags, badges only */
}
```

## Shadows & Elevation

```css
:root {
  /* Subtle depth without ghost-card pattern (no border + large shadow) */
  --shadow-sm:  0 1px 3px oklch(0 0 0 / 0.30);
  --shadow-md:  0 4px 12px oklch(0 0 0 / 0.40);
  --shadow-lg:  0 8px 24px oklch(0 0 0 / 0.50);

  /* Brand glow — used sparingly on impostor reveal, role badge */
  --glow-primary: 0 0 24px oklch(0.62 0.190 35.0 / 0.45);
  --glow-accent:  0 0 24px oklch(0.82 0.175 88.0 / 0.40);
}
```

## Motion

Energetic and physical. Animations are short (150–300ms), elastic on reveals, instant on navigation taps.

```css
:root {
  /* Durations */
  --duration-instant: 80ms;
  --duration-fast:    150ms;
  --duration-base:    220ms;
  --duration-slow:    300ms;
  --duration-reveal:  500ms;   /* role card flip only */

  /* Easings */
  --ease-out-quart:  cubic-bezier(0.25, 1, 0.5, 1);
  --ease-out-expo:   cubic-bezier(0.16, 1, 0.3, 1);
  --ease-spring:     cubic-bezier(0.34, 1.56, 0.64, 1);  /* elastic — tap feedback */
  --ease-in-out:     cubic-bezier(0.4, 0, 0.2, 1);
}

/* Tap feedback — universal across all interactive elements */
@media (hover: none) {
  [data-interactive]:active {
    transform: scale(0.96);
    transition: transform var(--duration-instant) var(--ease-spring);
  }
}

/* Reduced motion overrides */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

## Components

### Button — Primary

Large tap target (min 52px height), coral fill, white text.

```css
.btn-primary {
  background: var(--color-primary);
  color: var(--color-on-primary);
  font-family: var(--font-body);
  font-weight: var(--weight-semibold);
  font-size: var(--text-lg);
  border-radius: var(--radius-sm);
  padding: var(--space-4) var(--space-6);
  min-height: 52px;
  width: 100%;
  border: none;
  cursor: pointer;
  transition: background var(--duration-fast) var(--ease-out-quart),
              transform var(--duration-instant) var(--ease-spring);
}
.btn-primary:active { transform: scale(0.97); }
.btn-primary:disabled { background: var(--color-primary-dim); }
```

### Role Card

Full-screen card shown to each player when roles are distributed. High drama, large type.

```css
.role-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  padding: var(--space-8);
  text-align: center;
  /* Impostor variant adds --glow-primary */
}
.role-card__label {
  font-family: var(--font-body);
  font-size: var(--text-sm);
  font-weight: var(--weight-medium);
  color: var(--color-muted);
  text-transform: uppercase;
  letter-spacing: var(--tracking-wide);
}
.role-card__word {
  font-family: var(--font-display);
  font-size: var(--text-hero);
  font-weight: var(--weight-extrabold);
  letter-spacing: var(--tracking-tight);
  color: var(--color-ink);
  text-wrap: balance;
}
```

### Badge / Pill

For player counts, role tags, game state.

```css
.badge {
  font-family: var(--font-body);
  font-size: var(--text-xs);
  font-weight: var(--weight-semibold);
  padding: var(--space-1) var(--space-3);
  border-radius: var(--radius-pill);
  display: inline-flex;
  align-items: center;
}
.badge--accent {
  background: var(--color-accent);
  color: var(--color-on-accent);
}
.badge--primary {
  background: var(--color-primary);
  color: var(--color-on-primary);
}
```

## Z-Index Scale

```css
:root {
  --z-base:    0;
  --z-raised:  10;   /* cards in play */
  --z-sticky:  100;  /* sticky header/footer */
  --z-overlay: 200;  /* backdrop */
  --z-modal:   300;  /* modals, bottom sheets */
  --z-toast:   400;  /* toast notifications */
  --z-tooltip: 500;  /* tooltips */
}
```
