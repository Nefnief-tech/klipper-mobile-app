# Design: Dashboard Redesign, Real-time Updates, Pull-to-Refresh

**Date:** 2026-02-23
**Status:** Approved

---

## 1. Dashboard Redesign

### Layout
- Replace current ListView with GridView (2 columns on phone, 3+ on tablet)
- Each printer card shows:
  - Printer name
  - Status badge (printing/paused/idle/offline/error)
  - Thumbnail background (when printing)
  - Animated circular progress indicator
  - Current temps (nozzle/bed)
  - Current file name (if printing)
- Add quick stats header: "X printing, Y idle, Z offline"

### Bottom Navigation
- 4 tabs: Dashboard, Printers, Spools, Settings
- Use `IndexedStack` for state preservation between tabs
- Smooth transitions with fade/slide animations

---

## 2. Real-time Visual Feedback

### Animated Elements
- Circular progress ring on printer cards (animated fill)
- Pulsing glow effect when printer is heating (nozzle < target)
- Pulsing status indicator for "printing" state

### Auto-refresh
- Provider timer: refresh every 5 seconds
- Temperature history: keep last 60 readings for mini-graphs
- WebSocket-ready architecture (future enhancement)

---

## 3. Pull-to-Refresh

### Implementation
- Wrap all lists with `RefreshIndicator`
- Add "Last updated: X seconds ago" timestamp in app bar
- Apply to:
  - Printer list on Dashboard
  - Files list in Printer Detail
  - Spool list (Spoolman)
  - Print history

---

## Architecture Changes

### New Files
- `lib/screens/home_screen.dart` - Main container with BottomNavigationBar
- `lib/widgets/quick_stats.dart` - Stats header widget
- `lib/widgets/printer_grid.dart` - Grid layout for printers

### Modified Files
- `lib/main.dart` - Use HomeScreen instead of DashboardScreen
- `lib/screens/dashboard_screen.dart` - Rename to DashboardTab
- `lib/widgets/printer_card.dart` - Add circular progress, animations

### Navigation Structure
```
HomeScreen (BottomNavigationBar)
├── DashboardTab (index 0)
│   └── QuickStats + PrinterGrid
├── PrintersTab (index 1)
│   └── ListView of all printers
├── SpoolsTab (index 2)
│   └── Spoolman inventory
└── SettingsTab (index 3)
    └── App settings
```

---

## Success Criteria
- [ ] Grid layout displays correctly on phone/tablet
- [ ] Bottom navigation switches tabs without losing state
- [ ] Pull-to-refresh triggers data reload on all lists
- [ ] Circular progress animation is smooth (60fps)
- [ ] Heating indicator pulses when nozzle < target temp
- [ ] Last updated timestamp shows correctly
