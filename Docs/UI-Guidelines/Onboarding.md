# Onboarding UI Guidelines (Sticky Button + Backgrounds)

## 1) Ownership (single source of truth)

**OnboardingScaffold owns:**
- Page background (`PiggyGradients.background`)
- Sticky button block (primary + optional Skip)
- Safe-area spacing (top and bottom)
- Optional bottom scrim fade

**Individual screens own:**
- Content only (cards, lists, illustrations, text)
- No backgrounds, no local sticky buttons, no safe-area insets

**DO NOT:** add `PiggyGradients.background`, `safeAreaInset`, or another sticky button inside a screen.

---

## 2) When to use the bottom scrim

**Turn `showScrim: true` when the screen content is long/scrollable and may appear behind the sticky button:**
- `ArtistSelectionView` (grids/lists)
- `GoalSetupView` (reorderable lists)  
- `OnboardingStepView` (any tall content)

**Keep `showScrim: false` for short/hero pages:**
- `WelcomeView`
- `PermissionExplainerView`
- `OnboardingInsightView` (Aha)
- `OnboardingBridgeView` (Success)
- `OnboardingIntroCardsView` (short cards)

**Rule of thumb:** If a user can scroll to the bottom and content sits under the button, scrim = ON.

---

## 3) Safe-area & spacing rules

- **Top:** handled by Scaffold. No manual `.padding(.top, …)` to dodge the status bar/Dynamic Island.
- **Bottom:** handled by Scaffold. No local `.padding(.bottom, …)` or `.safeAreaInset(edge: .bottom, …)`.
- **Button spacing** above the home indicator is dynamic and already applied.

---

## 4) Background rules

- Project-wide gradient lives only in `OnboardingScaffold`.
- Screen backgrounds must be transparent (let the scaffold show through).
- If a screen needs decorative layers (e.g., sparkles, hero images), place them above content and keep them transparent (no full-screen fills).

---

## 5) Title & progress placement

- Titles and progress dots/bars are provided by `OnboardingContainer` (when used) or embedded in content if needed.
- Do not add extra top bars with their own safe-area logic—use the provided top bar components.

---

## 6) Definition of Done (per screen)

**Uses `OnboardingScaffold` with:**
- `title: <button label>`
- `canProceed: <bool>`
- `showScrim: <true|false>` (per rules above)

**No `PiggyGradients.background` inside the screen.**
**No `.safeAreaInset` or local sticky buttons inside the screen.**
**Builds with no seams:** scroll to bottom → scrim appears only where expected; background is seamless; button spacing is consistent.

---

## 7) Quick audit (copy-paste search checklist)

**Search the file you're editing and remove lines if found:**
- `PiggyGradients.background`
- `.safeAreaInset(edge: .bottom`
- `.safeAreaInset(edge: .top`
- `OnboardingStickyButton` (legacy)
- Manual `.padding(.bottom, 120+)` to "make space for button"

**Then ensure the scaffold call includes:**
- `showScrim: true` (if long/scrollable) or `false` (if short/hero)

---

## 8) Figma handoff notes (for designers)

- Provide a "with scrim" variant (subtle fade behind button) and a "no scrim" variant for each onboarding template.
- Keep hero art centered; avoid asymmetric shadows/rotations that make the layout feel off-center.
- Screen backgrounds in Figma = transparent artboard; gradient belongs to the Scaffold.

---

## 9) PR checklist (paste into PR template)

- [ ] Screen uses `OnboardingScaffold` (not custom sticky button)
- [ ] `showScrim` is set correctly (ON for long lists/grids, OFF for hero/short)
- [ ] No local `PiggyGradients.background` in the screen
- [ ] No local `.safeAreaInset` or manual bottom padding "to fit button"
- [ ] Visual QA on device: no white seams, bottom spacing looks consistent, titles not clipped

---

## 10) Common pitfalls (and fixes)

- **White/gray band at bottom** → A local `.safeAreaInset` or background is still present. Remove it; scaffold handles both.
- **Content looks off-center** → Check decorative rotations/shadows (they can create visual drift). Keep rotation minimal or symmetric.
- **Button overlaps content** → Turn `showScrim: true` on that screen's scaffold.

---

## Current Implementation Status ✅

**Confirmed Clean Architecture:**
- **OnboardingScaffold:** Single gradient source with `.safeAreaPadding(.top, 20)` (transparent)
- **ArtistSelectionView:** `showScrim: true` ✅, no redundant background ✅
- **GoalSetupView:** `showScrim: true` ✅, no redundant background ✅  
- **OnboardingStepView:** `showScrim: true` ✅, no redundant background ✅
- **All other onboarding views:** Clean, no redundant backgrounds ✅

**Build Status:** ✅ Successful compilation
**Simulator Status:** ✅ Fresh build deployed