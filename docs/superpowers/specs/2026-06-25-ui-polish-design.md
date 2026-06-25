---
name: ui-polish
description: Evolutionary UI/UX polish for FeedbackHub — one signature light/dark theme, a single unified glass-surface primitive, and color/typography/rhythm discipline applied across existing screens. No new features or layout changes.
status: backlog
created: 2026-06-25T18:25:23Z
updated: 2026-06-25T18:25:23Z
---

# FeedbackHub UI Polish — Design Spec

## Summary

Lift the existing FeedbackHub UI from "competent but flat" to polished, without
changing the information architecture, features, or layouts. This is an
**evolutionary refinement**: keep the DaisyUI + glassmorphism direction, but make it
consistent and intentional through a single design-token foundation that components
are migrated onto.

The work is **pure visual refinement**. No routes, models, controllers, or business
logic change.

## Current State (observed on the running app)

Captured from the live dev server (`localhost:3006`, DaisyUI 5.5.19, default
`corporate` theme, seed-only data so most screens show empty states):

1. **Content surfaces read as flat.** `MetricCardComponent` and others apply the
   `.glass-card` class, but its glass tokens were only ever tuned for the navbar's
   per-theme overrides. On `corporate` (near-white `base-100` on near-white
   `base-200`) the translucency and shadow are imperceptible, so cards look like flat
   rectangles. The navbar floats; everything below sits dead-flat. This split is the
   single biggest "unfinished" signal.

2. **One surface idea, hand-rolled three ways.**
   - `.glass-card` CSS class — `MetricCardComponent`, `LoginComponent`.
   - Inline `bg-base-100/80 backdrop-blur-md ...` — `Feedback::CardComponent`
     (`app/views/components/feedback/card_component.rb:11`).
   - Plain `bg-base-100` / `bg-base-200` — hub tabs, collapses, modals, popovers.

3. **Loud semantic colors on a muted canvas.** Solid saturated priority badges
   (red/yellow/green pills in `MetricCardComponent` and `Feedback::CardComponent`) and
   the pink/red flash `Alert` are the highest-contrast elements on screen, pulling the
   eye to the wrong places (e.g. the "0" metric values).

4. **Generic type and loose rhythm.** Default system font, large bold headings, wide
   dead vertical space, and bare centered-text empty states
   (`Hub::IndexComponent#render_empty_state`, feedback/articles empty states).

5. **Fragile chrome.** The flash toast (`Shared::FlashComponent`, `toast-top
   toast-end`) clips off the right edge at a 1440px viewport; it fits at 1280px. The
   positioning is marginal and needs constraining.

## Goals

- A single, consistent depth/glass language across all surfaces.
- One signature **light** theme and one signature **dark** theme, each with glass
  tokens tuned to actually register.
- Disciplined color: saturated accent reserved for primary actions; semantic colors
  rendered as soft tonal treatments.
- Tighter typographic hierarchy and vertical rhythm; polished empty states.
- A token foundation that prevents future drift — new components inherit the look.

## Non-Goals

- No new features, screens, or navigation/IA changes.
- No layout restructuring (grids, tabs, and page composition stay as they are).
- No component-library swap (stay on Phlex + PhlexyUI + DaisyUI).
- No model/controller/route/logic changes.
- No data-dependent work that requires seeding realistic feedback (refinement is
  validated on both empty and populated states, but seeding is out of scope).

## Approach: token layer, then sweep

A single design-token foundation is established first, then components are migrated
onto it in priority order. Hand-tuning screens individually is explicitly rejected —
it re-introduces the exact inconsistency this spec exists to remove.

### A. Theme foundation — one light, one dark

Replace the four shipped themes (`light, dark, corporate, business`) with **two
custom DaisyUI 5 themes**: `fh-light` and `fh-dark`.

- Defined via DaisyUI 5 theme config in `app/assets/tailwind/application.css`
  (`@plugin "daisyui/theme" { ... }` blocks, or the `@plugin "daisyui"` theme list
  plus custom theme blocks — confirm exact DaisyUI 5.5 syntax during implementation).
- `fh-light` derives from the current clean neutral light look (keep it familiar) but
  with a slightly warmer/deeper `base-200` canvas so elevated surfaces have something
  to lift off of.
- `fh-dark` derives from the current `dark` theme (the dark login card already reads
  well).
- **Primary color:** one signature blue used consistently in both themes (resolves
  today's blue-in-light / indigo-in-dark drift). Refined, slightly richer than the
  default DaisyUI blue. Exact hex chosen during implementation against both themes.
- Semantic ramps (success/warning/error/info) kept but consumed through the soft
  tonal treatment in section D, not as solid fills.

Consequences for existing code:
- `Shared::ThemeToggleComponent` (`THEMES = %w[light dark corporate business]`) becomes
  a **light/dark toggle** over `fh-light` / `fh-dark` (a simple two-state switch, not a
  four-item dropdown menu).
- `theme_controller.js` default changes from `"corporate"` to `"fh-light"`; preserve
  the localStorage persistence behavior. Add a one-time migration so existing stored
  values (`corporate`/`business`/`light`/`dark`) map to `fh-light`/`fh-dark`.
- `ApplicationLayout` hardcodes `data: { theme: "corporate" }` on `<html>`
  (`application_layout.rb:17`) — change the SSR default to `fh-light` so first paint
  matches before the Stimulus controller runs.

### B. One surface primitive

Introduce a single surface system in `application.css`, replacing `.glass-card` and
the inline `bg-base-100/80 backdrop-blur-md` usage:

- `.surface` — the default elevated content surface: token-driven translucent
  background, refined 1px border, soft shadow. **No `backdrop-filter`.** Used for
  dashboard cards, feedback cards, list items, panels, the hub tab/collapse bodies.
- `.surface-overlay` — chrome and overlays: everything in `.surface` **plus**
  `backdrop-filter: blur(...) saturate(...)`. Used for the navbar, modal boxes,
  dropdown menus, and popovers — surfaces that frame moving content underneath.
- `.surface-raised` — hover/active elevation modifier (slightly stronger shadow +
  subtle translate), replacing the ad-hoc `hover:shadow-xl` on feedback cards.

All values come from CSS custom properties defined per theme:

```
--surface-bg
--surface-border
--surface-shadow
--surface-shadow-raised
--overlay-blur        /* used only by .surface-overlay */
```

`.glass-card`, `.navbar-glass`, and `.glass-card` per-theme overrides in
`application.css` are removed and re-expressed through these tokens.

### C. Glass with discipline (performance-aware)

The rule: **chrome floats with real blur; content uses the glass *look* without the
blur cost.**

- `backdrop-filter` blur is applied **only** via `.surface-overlay` (navbar, modals,
  dropdowns, popovers) — a small, bounded number of instances.
- Content surfaces (`.surface`) get translucency + border + shadow that read as subtle
  glass but carry **no per-element blur**. This keeps a dense feedback grid
  (`grid-cols-1 md:grid-cols-2 lg:grid-cols-3`, potentially dozens of cards) fast.
  `backdrop-blur` is expensive per instance and would jank a busy board.

Still one cohesive glass identity; the expensive part is reserved for where it counts.

### D. Color discipline

- **Priority / status indicators:** replace solid saturated badges with soft tonal
  treatment — tinted background + readable foreground in the matching semantic hue
  (e.g. a low-saturation error-tinted chip with strong-contrast text), not a solid
  fill. Applies to `MetricCardComponent` (`metric_card_component.rb:16`) and
  `Feedback::CardComponent#priority_modifier`.
- **Flash alerts:** same soft tonal treatment via the surface/token system so the
  toast no longer dominates the page.
- **Saturated primary** reserved for genuine primary actions (Submit buttons).
- Define the tonal treatment once (utility classes or a small set of tokens) so all
  semantic-colored elements share it.

### E. Typography & vertical rhythm

- Adopt a refined font stack with **Inter** as the primary face (system-ui fallback),
  self-hosted via the asset pipeline. If self-hosting adds meaningful complexity,
  fall back to a tightened system stack — the type *scale and rhythm* changes below
  matter more than the specific face.
- Establish a deliberate type scale (heading sizes, weights, letter-spacing on large
  headings, body/label sizes) applied through a small set of utility conventions.
- Tighten vertical rhythm: reduce the loose empty-space padding on page headers and
  card bodies to a consistent spacing scale.

### F. Empty states & chrome fixes

- Upgrade bare centered-text empty states to a consistent pattern: a muted icon, a
  short headline, supporting text, and the existing primary action. Create one shared
  empty-state component/partial and use it in `Hub::IndexComponent`, feedback,
  articles, and updates index components (replacing each ad-hoc `render_empty_state`).
- Constrain the flash toast (`Shared::FlashComponent`) so it cannot overflow the
  viewport at any width (max-width + safe inset). Verify at 1280, 1440, and a narrow
  mobile width.

## Component Sweep Plan (priority order)

Foundation lands first, then screens in traffic order. Each step migrates components
onto `.surface` / tokens and removes the old class usage.

1. **Foundation** — `application.css` (themes, tokens, surface system, type scale),
   `theme_controller.js`, `ThemeToggleComponent`, `ApplicationLayout` SSR theme + nav
   re-expressed via `.surface-overlay`.
2. **Dashboard** — `Dashboard::MetricCardComponent`, `IndexComponent`,
   `ActivityFeedComponent`, `ActivityItemComponent`.
3. **Feedback** — `Feedback::CardComponent` (drop inline glass → `.surface` +
   `.surface-raised`), `IndexComponent`, `SuccessComponent`,
   `Hub::SubmissionModalComponent` (→ `.surface-overlay`), `Hub::IndexComponent`
   (tabs/collapses/empty state).
4. **Forms & auth** — `Feedback::FormComponent`, `Sessions::LoginComponent`,
   shared form-field styling.
5. **Remaining** — articles, updates, tools, search results, admin
   (template/user list + form components). Most inherit automatically once on
   `.surface`; touch only where a component hand-rolls surface/color styling.
6. **Shared chrome** — `Shared::FlashComponent` toast fix, any popover styling.

## Testing & Verification

- **Visual verification** is the acceptance test. Use the headless browser (gstack
  `browse`) to screenshot each migrated screen in **both `fh-light` and `fh-dark`** at
  desktop (1440, 1280) and mobile (375) widths, before/after each sweep step.
- Verify the dense-grid performance assumption: confirm no `backdrop-filter` is
  applied to `.surface` (content) elements; blur is `.surface-overlay`-only.
- Console must be clean (no new JS errors) after theme-controller changes; verify the
  localStorage migration maps old theme values correctly.
- Existing test suite must stay green (`rails test`). Phlex component tests that assert
  on the removed `glass-card` / inline classes are updated to the new class names.
- Confirm the flash toast does not clip at 1280/1440/375.

## Risks & Mitigations

- **`backdrop-filter` jank on dense boards** → mitigated by the chrome-only blur rule
  (section C); enforced in review.
- **Theme migration breaks stored preferences** → explicit localStorage value mapping
  in `theme_controller.js`.
- **Self-hosted Inter adds build complexity** → fall back to a tightened system stack;
  the scale/rhythm changes are the load-bearing part.
- **Sweep drift** (a component left on old classes) → the foundation removes
  `.glass-card`/inline variants outright, so any straggler fails visibly and is caught.

## Out of Scope

New features, IA/layout/navigation changes, library swaps, data seeding, and any
model/controller/route/logic change. Multi-theme support beyond one light + one dark.
