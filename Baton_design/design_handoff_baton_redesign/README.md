# Handoff: Baton — Modern Dark UI Redesign

## Overview
Baton is a running/fitness app (Korean-language UI) with a gamified "avatar orb" and spot-collection mechanic. This handoff covers a **visual refresh** of 5 core screens: the brand's existing **orange accent palette is preserved**, while form language (shape, spacing, typography, components) is modernized into a refined dark UI.

The 5 screens:
1. **Live Run** (러닝) — live map with mock-runner control + start button
2. **Spot** (스팟) — list of visited spots with progress rings & reward badges
3. **My Room** (마이 룸) — avatar customization / cosmetics shop
4. **Activity** (활동) — stats dashboard with switchable Week/Month/Year chart
5. **Run Detail** (러닝 상세) — single run map + split breakdown

## About the Design Files
The files in this bundle are **design references created in HTML/CSS/JS** — prototypes showing intended look and behavior, **not production code to copy directly**. The task is to **recreate these designs in the target codebase's existing environment** (React Native, Flutter, SwiftUI, native iOS/Android, web, etc.) using its established patterns, component library, and conventions. If no environment exists yet, choose the most appropriate framework for a mobile-first app and implement the designs there.

All visuals (maps, charts, progress rings, avatar orb, icons) are drawn procedurally in SVG/CSS in the prototype. In production, replace these with the platform's real equivalents (actual map SDK, charting lib, icon set, 3D/gradient avatar asset) — match the *look*, don't port the SVG.

## Fidelity
**High-fidelity (hifi).** Final colors, typography, spacing, radii, and interactions are specified. Recreate the UI faithfully using the codebase's existing libraries and patterns. Exact hex values, type sizes, and spacing are listed under **Design Tokens**.

---

## Global Layout & Chrome

- **Device frame / status bar / dynamic island** in the prototype are presentation scaffolding only — do NOT implement; use the OS-native status bar.
- **Screen background:** `--screen #100D0B` (warm near-black). App-level body uses subtle radial warm glows over `--bg #0B0908` — optional.
- **Safe content padding:** 22px horizontal (`--pad`).
- **Scroll regions** hide scrollbars.

### Bottom Tab Bar (floating)
Appears on screens ① Live, ② Spot, ③ My Room (NOT on ④ Activity or ⑤ Detail, which are pushed/nested views with a back button).
- Floating pill, inset 14px left/right, 12px from bottom, height 74px
- Background `rgba(20,16,13,0.86)` + `backdrop-filter: blur(18px)`, 1px border `--line`, radius 30px, shadow `0 18px 40px -16px rgba(0,0,0,0.7)`
- 5 items, evenly distributed: **러닝 (Run) · 스팟 (Spot) · 소셜 (Social) · 마이 룸 (My Room) · 프로필 (Profile)**
- Icon 23px + label 10.5px/600. Inactive `--faint #685F57`; active `--accent #EC6E2C` (label 700).

---

## Screens / Views

### ① Live Run (러닝)
- **Purpose:** Live running view over a map; a "Mock Runner" dev control simulates movement (testing/sim feature).
- **Layout:** Full-bleed dark map fills the screen. A glass control card floats at the top; a runner puck + large start button stack near the bottom; tab bar (index 0 active) at the very bottom. A soft top-and-bottom vignette (`.run-haze`) overlays the map with a warm glow at bottom-center.
- **Components:**
  - **Mock Runner card** (top): glass card, bg `rgba(34,26,21,0.74)` + blur(20px), border `rgba(236,110,44,0.22)`, radius 24px, padding 18px.
    - Header row: 8px orange dot (glow), title "Mock Runner" 15.5px/800 in `--accent-bright #FF8C42`.
    - Subtext: "속도 3.33 m/s · 5'00" /km" 12.5px/600 `--muted`.
    - **Pace selector:** 4-up grid, gap 7px. Buttons "6'00 / 5'00 / 4'00 / 3'00", 14px/700, radius 13px, padding 11px. Inactive: 1px border `--line-2`, faint bg, `--muted` text. Active ("5'00"): bg `--accent`, text `#1a0e06`.
    - **Actions row** (gap 8px): primary "▶ 자동 이동" (auto-move) — flex:1, bg `--accent`, text `#1a0e06`, 15px/800, radius 15px, padding 14px, with play glyph. Secondary: 50px square, border `--line-2`, up-arrow icon.
  - **Live stack** (bottom, above tab bar ~116px): centered column, gap 26px.
    - **Runner puck:** 46px avatar orb with a 26px teardrop pin below it, sitting on a radial orange "ground glow" ellipse (210×96).
    - **Start FAB:** 66px circle, radial orange gradient (`--accent-bright → --accent → --accent-deep`), white play triangle, ring glow `0 0 0 8px rgba(236,110,44,0.14)` + drop shadow.

### ② Spot (스팟)
- **Purpose:** Browse spots the user has physically visited; each grants EXP and points.
- **Layout:** Scroll view. Eyebrow "SPOT" + title "내가 방문한 스팟" (28px/800). Vertical list of spot cards, gap 16px. Tab bar index 1 active.
- **Spot card** (`--card` bg, 1px `--line`, radius 26px, padding 18px):
  - **Main row** (align top, gap 13px):
    - Icon tile 44px, radius 13px, bg `--accent-soft`, pin icon `--accent-bright`.
    - Info (flex): title 15.5px/700 (Korean, may wrap to 2 lines, `word-break: keep-all`); meta "마지막 방문 · 2026.06.08" 12.5px/500 `--faint`.
    - **Progress ring** 50px: SVG donut, track `rgba(255,255,255,0.10)` 3px, fill `--accent` 3px round cap, `stroke-dasharray: <p> 100`. Center label below = duration (e.g. "00:20:33") 11.5px/800 `--accent`, tabular-nums.
  - **Foot row** (top border `--line`, padding-top 14px, gap 8px): reward badges (pill, 12.5px/700, nowrap):
    - EXP badge: bg `--accent-soft`, text `--accent-bright`, bolt icon, e.g. "+15 EXP". A `.dim` variant (0 EXP): bg `rgba(255,255,255,0.05)`, `--muted`.
    - Points badge: bg `--gold-soft`, text `--gold #E0A437`, coin icon, e.g. "50 P".
- Sample data: 3 cards — 구서동 중앙천로 산책로 (ring 100%, +15 EXP / 50 P) · 구서역 GS 편의점 (78%, +0 EXP dim / 100 P) · 구서역 1번 출구 광장 (55%, +5 EXP / 10 P).

### ③ My Room (마이 룸)
- **Purpose:** View/equip avatar cosmetics (core colors, aura, titles, inventory) and enter the shop.
- **Layout:** Scroll view. Title "마이 룸" 30px/800. Centered avatar orb, equipped-title block, shop banner, category segmented control, swatch grid. Tab bar index 3 active.
- **Components:**
  - **Avatar orb:** 138px sphere — radial gradient highlight to orange to deep-orange with inset shadows (see `.orb` token). The brand's hero element.
  - **Equipped title block:** centered. Label "EQUIPPED TITLE" 11px/800 letter-spaced uppercase `--faint`. Badge "스피드 킹" — pill, 16px/700, blue text `#aebfff`, bg `--blue-soft`, border `rgba(120,145,255,0.4)`. (Blue is intentional — titles use a cool accent vs the orange core.)
  - **Shop banner:** full-width row, orange gradient (`--accent → #d9622a → --accent-deep`), radius 20px, padding 15px, shadow. 44px icon tile (white 18% overlay) + "Baton Shop" 16px/800 white + "GET EXCLUSIVE ITEMS" 11.5px/600 uppercase 85% white + chevron.
  - **Segmented control** (`.seg`): pill container `--card`, padding 5px. Tabs "Core Colors / Aura / Titles / Inventory" 11.5px/700, nowrap. Active tab: bg `--accent`, text `#160d06`, radius pill.
  - **Swatch grid:** 4 columns, gap 15px. Circular swatches (aspect 1:1).
    - Selected: filled color + ring `0 0 0 3px var(--screen), 0 0 0 5px #fff` + white check.
    - Unlocked: solid color (e.g. blue `#3A57D6`).
    - Locked: bg `--card-2`, lock icon `--faint`.

### ④ Activity (활동)
- **Purpose:** Stats dashboard summarizing runs over a selectable period, plus recent activity list. **No tab bar** — top app bar with back button.
- **Layout:** Scroll view. Top bar (back · "Baton" brand 21px/800 `--accent` · bell). Period segmented control. Period label row. Stats card. "Recent Activities" section list.
- **Components:**
  - **Period segmented control** (`.seg`): "Week / Month / Year". Default active = **Month**. **Interactive** — see Interactions.
  - **Period label row** (`.month-row`): 22px/800 text + chevron-down. Value depends on period: Week→"Jun 2 – 8", Month→"June 2026", Year→"2026".
  - **Stats card** (`--card`, radius 26px, padding 22px):
    - "KILOMETERS" eyebrow 11px/800 uppercase `--faint`.
    - Big number e.g. "6.3" 56px/800 with "km" unit 22px/700 `--muted`.
    - **Stat trio** (3 cols, 1px dividers): Runs / Avg Pace / Time. Value 19px/800, label 11.5px/600 `--faint`.
    - **Bar chart** (see below).
  - **Recent Activities** list (gap 13px). **Activity card** (`--card`, radius 26px, padding 12px, align center, gap 11px):
    - 50px route thumbnail (rounded 14px mini-map with route line + green start / red end dots).
    - Info (flex): top row = title 14px/700 (single line, ellipsis) + date 11px/600 `--faint`; stats row = "0.21 km  3'40" pace  0:00:46 time" — values 13.5px/800, units 9.5px/700 uppercase `--faint`.
    - Chevron `--faint`.

#### Activity Bar Chart (the key interactive piece)
A categorical bar chart that re-renders when the period changes. Bars are laid out in **equal-width flex columns** (NOT absolute positioning), each column centers a bar whose height = `value / max` (%). Empty/zero days render a 4%-tall faint stub (`rgba(255,255,255,0.07)`). Bars: max-width 16px, radius `6px 6px 2px 2px`, vertical orange gradient, height transition `.42s cubic-bezier(.2,.8,.2,1)`. Chart area height 96px, bottom border `--line`. Axis row below: equal-width centered labels 10px/600 `--faint`; the "highlighted" index uses `--accent` 800.

Three datasets (axis labels in English per spec):

| Period | Axis | Bars (km) | Highlighted | Stats shown |
|---|---|---|---|---|
| **Week** | Mon, Tue, Wed, Thu, Fri, Sat, Sun | 1.2, 0, 2.1, 0.8, 0, 3.4, 1.0 | Sat | 8.5 km · 5 Runs · 5'10" · 0:44:02 · label "Jun 2 – 8" |
| **Month** | W1, W2, W3, W4, W5 (weekly sections; thin dividers between columns) | 1.1, 4.2, 0.5, 0.3, 0.2 | W2 | 6.3 km · 17 Runs · 4'58" · 0:31:17 · label "June 2026" |
| **Year** | Jan … Dec | 4.2, 6.1, 9.4, 12.2, 14.8, 6.3, 0×6 | May | 92.4 km · 140 Runs · 5'04" · 7:38:11 · label "2026" |

The Month view shows **weekly sections** (W1–W5) with a faint 1px divider after each column. Week view shows **Mon–Sun**. Year view shows **Jan–Dec**.

### ⑤ Run Detail (러닝 상세)
- **Purpose:** Detail of a single run — route map + key stats + km splits. **No tab bar** — floating back button over the map.
- **Layout:** Top ~46% is the route map (with floating back button top-left, "Google" attribution bottom-left). Below: scroll body with a stats card and KM Splits section.
- **Components:**
  - **Map header:** dark procedural map with route line (orange 5.5px), green start dot + red end dot (both ringed in bg color).
  - **Floating back button:** 42px, radius 14px, bg `rgba(20,16,13,0.7)` + blur, 1px `--line`.
  - **Detail stats card** (`--card`, radius 26px, padding 20px, 3 cols + dividers): each col = small accent icon (ruler/timer/gauge) + value 21px/800 + uppercase label 10.5px/700 `--faint`. Values: 0.21 KM · 0:00:46 TIME · 3'40" PACE.
  - **KM Splits:** section header "KM SPLITS" 12px/800 uppercase `--faint`. Split row (bottom border `--line`): left = 9px orange dot + "+0.21 km" 15px/700; right = "3'40"" 16px/800 `--accent` + "/km" 12px/600 `--muted`.

---

## Interactions & Behavior
- **Period switcher (Activity ④):** Tapping Week/Month/Year updates, in one pass: (1) active segment styling, (2) period label text, (3) all 4 stat values (km, runs, pace, time), (4) the bar chart bars + axis labels + highlighted index + section dividers (Month only). Bars animate height via CSS transition (~0.42s). Default state = Month.
- **My Room category tabs ③:** segmented control switches the swatch grid content (Core Colors / Aura / Titles / Inventory). Prototype only wires visual selection of the active tab; production should swap grid contents per category.
- **Swatch selection ③:** tapping an unlocked swatch selects it (ring + check); locked swatches are non-interactive (would route to shop/unlock flow).
- **Pace selector ①:** single-select segmented buttons (sets mock runner pace).
- **Live start FAB ①:** begins/stops a run session.
- **Activity/Detail back buttons:** pop navigation.
- **Reduced motion:** keep content visible; only the bar-height transition is motion — safe to disable.

## State Management
- `activityPeriod`: `'week' | 'month' | 'year'` → drives label, 4 stats, and chart dataset (③ default `'month'`).
- `roomCategory`: `'core' | 'aura' | 'titles' | 'inventory'` → drives swatch grid.
- `selectedSwatch` / equipped cosmetic id.
- `mockPace`: selected pace button.
- `runSessionActive`: boolean for the start FAB.
- Real app also needs: live GPS/location stream (①⑤), visited-spots list with progress + rewards (②), per-period aggregated run stats (④), single-run splits (⑤).

## Design Tokens

### Colors
```
/* surfaces — warm near-black */
--bg:        #0B0908
--screen:    #100D0B
--card:      #1B1714
--card-2:    #241F1A
--card-3:    #2C2620
--line:      rgba(255,246,238,0.07)
--line-2:    rgba(255,246,238,0.12)

/* brand — orange (PRESERVED, do not change) */
--accent:        #EC6E2C
--accent-bright: #FF8C42
--accent-deep:   #C8551C
--accent-soft:   rgba(236,110,44,0.14)
--accent-glow:   rgba(236,110,44,0.45)

/* support */
--gold:      #E0A437   --gold-soft: rgba(224,164,55,0.16)
--green:     #36C26B   (route start dot)
--red:       #E8503A   (route end dot)
--blue:      #3A57D6   --blue-soft: rgba(58,87,214,0.16)  (titles)

/* text */
--text:   #F8F3ED
--muted:  #9D938A
--faint:  #685F57
```

### Typography
- Font family: **Pretendard** (Korean + Latin), fallback Apple SD Gothic Neo / Noto Sans KR / system sans.
- Scale used: 56 (hero stat) · 30 (page title) · 22 (period label / unit) · 21 (brand / detail stat) · 19 (stat trio) · 16–16.5 (titles/badges) · 15–15.5 (body/list titles) · 13.5–14 (compact values) · 12–12.5 (meta/badges) · 11–11.5 (labels) · 10–10.5 (axis/units) · 9.5 (micro units).
- Weights: 800 (display/titles/active), 700 (values/labels), 600 (meta), 500 (subtle meta).
- Eyebrows/labels: uppercase, letter-spacing ~0.18–0.22em.
- Numbers: tabular-nums where they tick (timers, durations).

### Spacing / Radius / Shadow
- Content padding: 22px horizontal.
- Radius: cards 26px (`--r-card`), inner controls 13–24px, pills/segments 999px, FAB/orbs 50%.
- Card list gaps: 13–16px.
- Key shadows: card depth `0 18px 40px -16px rgba(0,0,0,0.7)`; orange FAB `0 0 0 8px rgba(236,110,44,0.14), 0 14px 34px -8px var(--accent-glow)`; orb `inset -10px -16px 34px rgba(90,30,5,0.55), inset 8px 10px 26px rgba(255,220,180,0.35), 0 24px 60px -18px var(--accent-glow)`.

## Assets
No external image assets — everything is procedural in the prototype:
- **Maps** — replace with the platform's map SDK (Google Maps / MapKit / Mapbox) styled dark.
- **Charts** — replace with the codebase's charting solution or a simple flex-bar implementation matching the spec above.
- **Progress rings, avatar orb, route thumbnails** — recreate with native drawing / gradients / a charting or SVG lib.
- **Icons** — prototype uses custom 24px stroke icons (run, spot/pin, social, home, profile, bolt, coin, shop, chevron, check, lock, back, bell, ruler, timer, gauge, play, up-arrow). Map these to the codebase's existing icon set.
- **Avatar orb** — in production this is presumably a richer 3D/gradient character asset; the gradient sphere is a stand-in.

## Files
In this bundle:
- `Baton - UI Redesign.html` — all 5 screens, self-contained (inline JS for icons/maps/charts/build + interactive period switcher).
- `baton.css` — full design-token + component stylesheet (the source of truth for all values above).
- `screenshots/` — rendered reference images of each screen:
  - `01-live-run.png` · `02-spot.png` · `03-my-room.png` · `05-run-detail.png`
  - `04-activity-month.png` (default) · `04-activity-week.png` · `04-activity-year.png` (the three chart/period states of the Activity screen)

The HTML renders all 5 phones side-by-side on one canvas for reference. Each screen's markup lives in a `<template id="scr-…">` block; the build script clones each into a phone frame. The chart/period logic is in the `window.MAPS.chartData` / `renderChart` + the `[data-period-seg]` click wiring at the bottom of the inline script.
