# TinyWins Theme System QA Checklist

**Deliverable D - QA and Testing**
**Date:** December 2024

---

## 1. Automated Tests

### 1.1 Contrast Tests (TokenTests.swift)

- [ ] `testTextContrastMeetsWCAGAA()` - All text/background combinations pass
- [ ] `testAvatarInitialsContrast()` - All child colors have readable initials
- [ ] `testSemanticColorContrast()` - Positive/challenge/error states readable
- [ ] `testLightModeResolution()` - Light mode tokens resolve correctly
- [ ] `testDarkModeResolution()` - Dark mode tokens resolve correctly
- [ ] `testThemePackDifferentiation()` - Different themes have different accents
- [ ] `testButtonTokenDerivation()` - Button tokens match semantic source
- [ ] `testCardTokenDerivation()` - Card tokens match semantic source
- [ ] `testLuminanceCalculation()` - Color luminance values accurate
- [ ] `testContrastRatioCalculation()` - Contrast ratios calculated correctly

### 1.2 Run Tests

```bash
# Run all token tests
xcodebuild test -scheme TinyWins -only-testing:TinyWinsTests/TokenTests

# Run with code coverage
xcodebuild test -scheme TinyWins -only-testing:TinyWinsTests/TokenTests -enableCodeCoverage YES
```

---

## 2. Manual Visual QA

### 2.1 Light Mode Checklist

For each theme (Classic, Ocean, Sunset, Forest, Midnight, Aurora, Rosegold, Lavender, Mint, Slate, Champagne, Nordic):

**TodayView:**
- [ ] Navigation bar readable
- [ ] Greeting text clearly visible
- [ ] Child picker chips have sufficient contrast
- [ ] Add Moment button text visible
- [ ] Focus row text readable
- [ ] Today's Activity section headers visible
- [ ] Event cards have clear borders

**KidView:**
- [ ] Avatar initials readable on ALL child colors (Blue, Green, Orange, Purple, Pink, Teal, Coral, Yellow)
- [ ] Child name clearly visible
- [ ] Progress ring numbers readable
- [ ] Star counter visible
- [ ] Theme picker icon visible
- [ ] Close button visible

**InsightsView:**
- [ ] Tab labels readable
- [ ] Insight cards have clear text
- [ ] Child selector chips visible
- [ ] Chart labels readable
- [ ] Streak indicators clear

**SettingsView:**
- [ ] All menu items readable
- [ ] Section headers visible
- [ ] Toggle states clear
- [ ] Destructive actions (red) visible

### 2.2 Dark Mode Checklist

Repeat ALL items from 2.1 in dark mode.

**Additional Dark Mode Checks:**
- [ ] No white text on light backgrounds
- [ ] Surfaces are distinguishable from app background
- [ ] Borders visible but not harsh
- [ ] Accent colors are not washed out
- [ ] Error states still visible

### 2.3 Child Color Edge Cases

Test avatar with EACH child color in BOTH light and dark mode:

| Color | Light Initials | Dark Initials | Badge BG Light | Badge BG Dark |
|-------|---------------|---------------|----------------|---------------|
| Blue | [ ] Pass | [ ] Pass | [ ] Pass | [ ] Pass |
| Green | [ ] Pass | [ ] Pass | [ ] Pass | [ ] Pass |
| Orange | [ ] Pass | [ ] Pass | [ ] Pass | [ ] Pass |
| Purple | [ ] Pass | [ ] Pass | [ ] Pass | [ ] Pass |
| Pink | [ ] Pass | [ ] Pass | [ ] Pass | [ ] Pass |
| Teal | [ ] Pass | [ ] Pass | [ ] Pass | [ ] Pass |
| Coral | [ ] Pass | [ ] Pass | [ ] Pass | [ ] Pass |
| Yellow | [ ] Pass | [ ] Pass | [ ] Pass | [ ] Pass |

---

## 3. Accessibility QA

### 3.1 VoiceOver Testing

- [ ] All interactive elements have accessibility labels
- [ ] Color information is not the ONLY way information is conveyed
- [ ] Focus order is logical
- [ ] Custom actions work correctly

### 3.2 Dynamic Type

Test with each text size (Settings > Accessibility > Display & Text Size > Larger Text):

| Size | TodayView | KidView | InsightsView | Settings |
|------|-----------|---------|--------------|----------|
| xSmall | [ ] | [ ] | [ ] | [ ] |
| Small | [ ] | [ ] | [ ] | [ ] |
| Medium (default) | [ ] | [ ] | [ ] | [ ] |
| Large | [ ] | [ ] | [ ] | [ ] |
| xLarge | [ ] | [ ] | [ ] | [ ] |
| xxLarge | [ ] | [ ] | [ ] | [ ] |
| xxxLarge | [ ] | [ ] | [ ] | [ ] |
| AX1 | [ ] | [ ] | [ ] | [ ] |
| AX5 | [ ] | [ ] | [ ] | [ ] |

### 3.3 Reduced Motion

- [ ] Animations respect `UIAccessibility.isReduceMotionEnabled`
- [ ] No essential information conveyed only through animation

### 3.4 Color Blind Testing

Use Xcode Accessibility Inspector or simulator filters:

- [ ] Protanopia (red-blind) - Content distinguishable
- [ ] Deuteranopia (green-blind) - Content distinguishable
- [ ] Tritanopia (blue-blind) - Content distinguishable

---

## 4. Theme Switching Tests

### 4.1 Real-Time Updates

- [ ] Changing theme in Settings immediately updates all visible UI
- [ ] No flashing or jarring transitions
- [ ] State is preserved during theme change

### 4.2 Persistence

- [ ] Theme preference persists after app restart
- [ ] Theme preference syncs with iCloud (if applicable)
- [ ] Default theme works correctly on fresh install

### 4.3 System Theme Tracking

- [ ] "System" theme follows iOS dark/light mode
- [ ] Changing iOS appearance updates app appearance
- [ ] No delay when switching system appearance

---

## 5. Edge Cases

### 5.1 Memory/Performance

- [ ] No memory leaks when switching themes repeatedly
- [ ] No UI lag during theme changes
- [ ] Token resolution is cached appropriately

### 5.2 Background/Foreground

- [ ] Theme persists when app goes to background
- [ ] Theme updates correctly when returning from background
- [ ] System appearance changes apply when returning to foreground

### 5.3 Sheets and Modals

- [ ] Sheets use correct theme colors
- [ ] Alerts use correct theme colors
- [ ] Action sheets have readable text

---

## 6. Regression Prevention

### 6.1 Snapshot Tests (Recommended)

Create snapshot tests for critical views in all theme x appearance combinations:

```swift
func testTodayViewSnapshots() {
    for theme in ThemePack.allCases {
        for appearance in [Appearance.light, .dark] {
            let view = TodayView().withDesignTokens(DesignTokens(appearance: appearance, themePack: theme))
            assertSnapshot(matching: view, as: .image, named: "\(appearance)-\(theme)")
        }
    }
}
```

### 6.2 CI Integration

Add to CI pipeline:
- [ ] Token contrast tests run on every PR
- [ ] Snapshot tests run on every PR
- [ ] Visual diff review required for snapshot changes

---

## 7. Sign-Off

| Area | Tester | Date | Status |
|------|--------|------|--------|
| Automated Tests | | | |
| Light Mode Visual | | | |
| Dark Mode Visual | | | |
| Child Colors | | | |
| Accessibility | | | |
| Theme Switching | | | |
| Edge Cases | | | |

**Final Approval:**
- [ ] All checklist items pass
- [ ] No critical contrast failures
- [ ] No accessibility blockers
- [ ] Performance acceptable

---

**Signed off by:** ___________________ **Date:** ___________
