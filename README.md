# Handoff: Expense Tracker — Mobile App

## Overview
A dark-themed personal expense tracking app for iOS (375×812pt). Two screens: a dashboard with animated spend widgets, and an add-expense entry flow. The design is minimal and luxury-leaning — pitch black surfaces, Cormorant Garamond serif typography, gold (#C9A84C) as the single accent.

## About the Design Files
The files in this bundle are **HTML design references** — prototypes showing intended look and behaviour, not production code to copy directly. Recreate these designs in your target codebase (React Native, SwiftUI, Flutter, etc.) using its established patterns and libraries. Match the visual output pixel-for-pixel where possible.

## Fidelity
**High-fidelity.** Pixel-precise colors, typography, spacing, and interaction animations. Recreate the UI exactly as shown using your codebase's component and navigation patterns.

---

## Screens

### Screen 1 — Dashboard (`Expense Tracker Hi-Fi.dc.html`)

**Purpose:** At-a-glance view of today's spending vs budget, weekly trend, and monthly budget calendar.

**Layout:** Single column, full-screen. Safe-area-aware. Vertical scroll is NOT expected — all content fits in one screen.

#### Header
- Padding: 16pt top, 22pt horizontal
- Left: "Good morning," caption (13pt, #555, regular) + user's first name (26pt, weight 600, #F0EDE8)
- Right: notification bell button (40×40pt, #0D0D0D bg, 12pt border-radius) + avatar circle (40×40pt, gold border 1.5pt rgba(201,168,76,0.35), initials in gold 16pt weight 600)

#### Budget Widget (Card 1)
- Margin: 14pt top, 22pt sides
- Background: #0D0D0D, border: 1pt #1C1C1C, border-radius: 22pt
- Padding: 22pt
- Shadow: `0 4px 32px rgba(0,0,0,0.6), inset 0 1px 0 rgba(255,255,255,0.04), 0 0 50px rgba(201,168,76,0.07)`
- Row 1: "SPENT TODAY" label (10pt, #C9A84C, uppercase, letter-spacing 2.5pt, weight 500) + "Budget ₹X,XXX" (11pt, #3A3830, right-aligned)
- Row 2: ₹ prefix (24pt, weight 300, rgba(201,168,76,0.5)) + spend amount (54pt, weight 300, #C9A84C, letter-spacing -2pt) — **counter-animates from 0 on mount, ease-out cubic, 1600ms**
- Row 3: "of ₹X,XXX budget" (12pt, #3A3830) + status text with arrow (12pt, green #4CAF82 if under, red #E05555 if over)
- Progress bar: 3pt height, #1A1A1A track, gold fill `linear-gradient(to right, #8A6A28, #C9A84C)`, **animates width from 0% to actual % on mount**
- Bar footer: "XX% used" (11pt, #333) left + "XX days left" (11pt, #333) right

#### Weekly Graph (Card 2)
- Same card styling minus gold glow shadow
- Header: "THIS WEEK" (10pt, gold, uppercase, 2.5pt spacing) + "Jun 2026" (11pt, #3A3830)
- SVG line chart, 295×70pt
  - Y-axis: 0 = budget amount (top), full height = ₹0 (bottom)
  - Budget reference line: dashed gold, 0.6pt, 30% opacity
  - Gradient fill under line: gold → transparent
  - Past days: solid gold line 2pt, **stroke-dasharray animated on mount, 1400ms**
  - Today's dot: 5pt radius gold fill + pulsing ring animation (scale 1→2.4, opacity 0.7→0, 2s infinite)
  - Future days: dashed gray line + hollow dots (#2A2828 stroke)
- Day labels row: M T W T F S S (11pt, past=#666, today=#C9A84C weight 600, future=#2A2828)

#### Budget Calendar (Card 3)
- Fills remaining vertical space (`flex: 1`)
- Same card styling
- Header: "Month Year" (15pt, weight 600, #F0EDE8) + "X over budget" (12pt, #E05555) + ‹ › nav arrows (16pt, #333/#777)
- Day headers: M T W T F S S (10pt, #333, weight 500)
- Grid: 7 columns × 5 rows, 2pt gap, cells 26pt height, 6pt border-radius
  - Normal day: transparent bg, #8A8680 text, 12pt, weight 400
  - Over-budget day: `rgba(224,85,85,0.12)` bg, #E05555 text, weight 600
  - Today: `rgba(201,168,76,0.18)` bg, `1.5pt solid rgba(201,168,76,0.45)` outline, #C9A84C text, weight 600
  - Empty cell: transparent
- Legend: 7pt color dot + 10pt label (#444) for "Over budget" and "Today"

#### Bottom Navigation
- Height: 84pt, background: #000, top border: 1pt #141414
- 5 items: Home | Stats | FAB | History | You
- Inactive icon stroke: #2A2828, inactive label: 10pt #2A2828
- Active (Home): icon + label in #C9A84C, weight 500
- FAB: 56pt circle, #C9A84C bg, white + icon (SVG 22pt), margin-top: -28pt (floats above bar), border: 3pt solid #000, shadow: `0 0 20px rgba(201,168,76,0.35), 0 4px 16px rgba(0,0,0,0.5)`

#### Home Indicator
- 30pt height, #000 bg
- Pill: 134×5pt, `rgba(255,255,255,0.18)`, border-radius 3pt

---

### Screen 2 — Add Expense (`Expense Tracker Hi-Fi.dc.html`)

**Purpose:** Entry form for logging a new expense. No bottom tab bar (modal flow).

**Layout:** Full screen, fixed. Bottom numpad always visible.

#### Header Row
- Padding: 14pt top, 22pt sides
- Back button: 40×40pt, #0D0D0D, 12pt radius, chevron-left SVG (#888)
- Title: "New Expense" (17pt, weight 600, #F0EDE8, centered)
- Save button: 40×40pt, `rgba(201,168,76,0.1)` bg, `rgba(201,168,76,0.25)` border, checkmark SVG (#C9A84C)

#### Amount Display
- "ENTER AMOUNT" label: 10pt, #333, uppercase, 2.5pt spacing
- ₹ prefix: 28pt weight 300, rgba(201,168,76,0.4)
- Amount: 64pt weight 300, #C9A84C, letter-spacing -2pt — starts at "0"
- Blinking cursor: 3×52pt bar, #C9A84C, blink animation 1.1s infinite
- Underline: 1pt gold gradient divider
- Context: "Today's budget: ₹X,XXX · Used: ₹X,XXX" (11pt, #2A2828)

#### Category Grid
- Label: "CATEGORY" (10pt, #333, uppercase, 2.5pt spacing)
- 6 buttons in 3-column flex-wrap, 10pt gap
- Each button: `calc(33.3% - 7pt)` wide, #0D0D0D bg, 1pt #1C1C1C border, 16pt radius, 14pt padding, column flex
  - Color dot circle: 34×34pt, category-tinted bg + border, 10pt inner dot
  - Label: 12pt, #666
- Categories + colors:
  - Food → #E8855A
  - Travel → #5A9BE8
  - Shopping → #9B5AE8
  - Bills → #E85A5A
  - Health → #5AE89B
  - Other → #C9A84C

#### Form Fields
- Description: #0D0D0D bg, 1pt #1C1C1C border, 14pt radius, 14pt padding, edit icon (#333), placeholder "Description (optional)" (14pt, #2A2828)
- Date: same styling, calendar icon + "Today, Jun 18 2026" (14pt, #F0EDE8) + "Change" (12pt, #333) right

#### Save Button
- Full width, #C9A84C bg, 16pt radius, 52pt height
- "Save Expense" (16pt, weight 600, #000, 0.5pt spacing)
- Shadow: `0 8px 28px rgba(201,168,76,0.25)`

#### Numpad
- Fills remaining height (flex:1)
- 3×4 grid, 8pt gap
- Keys: 1–9, ., 0, ⌫
- Each key: #0D0D0D bg, 1pt #141414 border, 12pt radius, 22pt font weight 300, #F0EDE8

---

## Interactions & Animations

| Element | Animation | Duration | Easing | Trigger |
|---|---|---|---|---|
| Cards | `slideUp` (opacity 0→1, translateY 18→0) | 500ms | ease-out | on mount, staggered: 0ms / 120ms / 240ms / 360ms |
| Budget number | Counter 0 → spend amount | 1600ms | ease-out cubic | 500ms after mount |
| Progress bar | width 0% → actual% | 1600ms (via counter state) | linear (CSS transition 80ms) | driven by counter |
| Graph line | stroke-dashoffset 320→0 | 1400ms | ease-out | 900ms delay |
| Graph dots | `slideUp` | 300ms each | ease-out | staggered 1.0s–1.3s |
| Today pulse ring | scale 1→2.4, opacity 0.7→0 | 2s | ease-out | infinite, 1.5s delay |
| Cursor blink | opacity 1→0→1 | 1.1s | ease-in-out | infinite |

---

## State Management

### Dashboard
- `spent`: number — current value in counter animation (state)
- `budget`: number — from user settings / props
- Derived: `remaining`, `pct`, `isOver`, `statusText`

### Add Expense
- `amount`: string — numpad input
- `selectedCategory`: string | null
- `description`: string
- `date`: Date — defaults to today

---

## Design Tokens

### Colors
| Token | Value | Usage |
|---|---|---|
| `bg-black` | `#000000` | Phone background |
| `bg-surface` | `#0D0D0D` | Cards |
| `bg-surface-2` | `#141414` | Nav border, numpad keys |
| `border-subtle` | `#1C1C1C` | Card borders |
| `gold` | `#C9A84C` | Primary accent |
| `gold-dim` | `rgba(201,168,76,0.4)` | ₹ prefix, decorative |
| `gold-glow` | `rgba(201,168,76,0.07)` | Budget card ambient shadow |
| `text-primary` | `#F0EDE8` | Main text |
| `text-secondary` | `#8A8680` | Calendar days |
| `text-muted` | `#555` | Labels, subtitles |
| `text-ghost` | `#333` | Least important text |
| `text-dark` | `#2A2828` | Future days, placeholders |
| `green` | `#4CAF82` | Under-budget status |
| `red` | `#E05555` | Over-budget status |

### Typography (Cormorant Garamond — all weights)
| Role | Size | Weight | Color | Notes |
|---|---|---|---|---|
| Display number | 54–64pt | 300 | gold | letter-spacing -2pt |
| Screen title | 26pt | 600 | #F0EDE8 | |
| Card heading | 10pt | 500 | gold | uppercase, 2.5pt spacing |
| Body | 14pt | 400 | #F0EDE8 | |
| Label | 12–13pt | 400 | #555–#8A8680 | |
| Micro | 10–11pt | 400–500 | #333–#444 | |
| Nav label | 10pt | 400/500 | #2A2828 / #C9A84C | inactive / active |

### Spacing
- Screen horizontal padding: 22pt
- Card gap: 14pt
- Card border-radius: 22pt
- Card internal padding: 18–22pt
- Section label spacing: 10–12pt below

### Shadows (dark-mode style)
| Element | Shadow |
|---|---|
| Cards | `0 4px 32px rgba(0,0,0,.6), inset 0 1px 0 rgba(255,255,255,.04)` |
| Budget card extra | `+ 0 0 50px rgba(201,168,76,.07)` |
| FAB | `0 0 20px rgba(201,168,76,.35), 0 4px 16px rgba(0,0,0,.5)` |
| Save button | `0 8px 28px rgba(201,168,76,.25)` |
| Phone bezel | `0 0 0 10px #0D0C0A, 0 0 0 11px rgba(255,255,255,.05), 0 50px 120px rgba(0,0,0,.95)` |

---

## Assets
- **Font:** Cormorant Garamond (Google Fonts) — weights 300, 400, 500, 600, italic 300/400
- **Icons:** Inline SVG, 24×24 viewBox, 1.5pt stroke, round linecaps. No icon library required — see source HTML for path data.
- **No images** used in the design.

---

## Files
| File | Description |
|---|---|
| `Expense Tracker Hi-Fi.dc.html` | Full hi-fi design reference — open in any browser |
| `Expense Tracker.dc.html` | Wireframe reference (direction A, kept for layout context) |
| `README.md` | This document |

---

## Notes for Developer
1. The HTML files are self-contained and open directly in any modern browser. Open `Expense Tracker Hi-Fi.dc.html` to see live animations.
2. The Tweaks panel (top-right gear icon) lets you change `userName`, `spentAmount`, and `budgetAmount` to test different states.
3. The counter animation is driven by `requestAnimationFrame` — implement equivalently in your target platform (e.g. `Animated.timing` in React Native, `withTiming` in Reanimated, `withAnimation` in SwiftUI).
4. The graph is a static SVG mockup with hardcoded sample data — replace with real weekly data from your backend, maintaining the same visual encoding (gold = actual, gray dashed = future, budget reference line).
5. Calendar over-budget days should be computed from historical transaction data.
