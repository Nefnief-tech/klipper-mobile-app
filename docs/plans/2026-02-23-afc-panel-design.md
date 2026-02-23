# AFC Panel Design - Material 3 Expressive

**Date:** 2026-02-23  
**Project:** Farm Manager Flutter App  
**Feature:** AFC (Automatic Filament Changer) Panel Revamp

---

## Overview

Revamp the AFC panel in the Flutter app with Material 3 expressive design, horizontal card layout, and enhanced visual feedback for filament lane management.

## Design Direction

- **Design Style:** Material 3 Expressive (dark theme, clean, rounded)
- **Layout:** Horizontal Cards (scrollable lane cards)
- **Enhancements:** Status animations, glow effects, color-coded states

---

## Layout Structure

```
┌─────────────────────────────────────────────────────────┐
│  🔄 BOX TURTLE AFC           [Status Badge]  [Refresh] │
├─────────────────────────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │
│  │  LANE 1 │ │  LANE 2 │ │  LANE 3 │ │  LANE 4 │  ...  │
│  │  🟢     │ │  🟡     │ │  ⚪     │ │  🔴     │       │
│  │ PLA     │ │ PETG    │ │  TPU    │ │ ABS     │       │
│  │ [Load]  │ │[Unload] │ │ [Load]  │ │[Load]   │       │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘       │
├─────────────────────────────────────────────────────────┤
│  ⚡ Quick Actions                                        │
│  [Eject] [Cut] [Brush] [Poop] [Park] [Calibrate]       │
│  💡 [LED On] [LED Off]                                  │
└─────────────────────────────────────────────────────────┘
```

---

## Visual Design Specs

| Element | Style |
|---------|-------|
| **Cards** | Rounded corners (20px), gradient backgrounds, elevation shadows |
| **Status Colors** | 🟢 Green (loaded/active), 🟡 Yellow (loading/unloading), ⚪ Gray (empty), 🔴 Red (error) |
| **Active Lane** | Glowing border effect, pulsing animation |
| **Loading State** | Shimmer animation on transitioning lanes |
| **Actions** | Rounded chip buttons with icons, grouped by category |

---

## Components

### 1. Lane Card (120x140px)
- Color swatch circle with glow (when active)
- Lane number + name
- Material label
- Status indicator dot
- Load/Unload button

### 2. Quick Action Chips
- Icon + label format
- Grouped: Main | LED | System
- Haptic feedback on tap

### 3. Status Badge
- Rounded pill showing AFC status
- Color-coded (ready=green, busy=yellow, error=red)

---

## Interactions

| Action | Behavior |
|--------|----------|
| Tap lane | Opens detail modal |
| Long press | Quick load/unload |
| Pull down | Refresh AFC status |
| Swipe actions | Eject, Cut, Brush |

---

## Existing Features to Preserve

1. ✅ Lane editing (material, color)
2. ✅ SpoolMan integration
3. ✅ All AFC actions (eject, cut, brush, poop, park, calibrate, etc.)
4. ✅ LED on/off controls
5. ✅ Status refresh

---

## New Features to Add

1. ✨ Enhanced visual status indicators
2. ✨ Loading/unloading animations
3. ✨ Glow effects for active lane
4. ✨ Material 3 expressive styling
5. ✨ Better quick action chips
6. ✨ Color-coded status badge
