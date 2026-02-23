# Dashboard Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement dashboard redesign with grid layout, bottom navigation, real-time animations, and pull-to-refresh

**Architecture:** Create HomeScreen with BottomNavigationBar using IndexedStack for state preservation. Convert printer list to grid with animated cards. Add RefreshIndicator to all lists.

**Tech Stack:** Flutter, Material 3, IndexedStack, RefreshIndicator, AnimatedBuilder

---

## Task 1: Create QuickStats Widget

**Files:**
- Create: `lib/widgets/quick_stats.dart`

**Step 1: Create the QuickStats widget**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/printer.dart';

class QuickStats extends StatelessWidget {
  final List<Printer> printers;

  const QuickStats({super.key, required this.printers});

  @override
  Widget build(BuildContext context) {
    final printing = printers.where((p) => p.status == 'printing').length;
    final idle = printers.where((p) => p.status == 'idle').length;
    final offline = printers.where((p) => p.status == 'offline').length;
    final paused = printers.where((p) => p.status == 'paused').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem('PRINTING', printing, Theme.of(context).colorScheme.secondary),
          _StatItem('PAUSED', paused, Colors.orange),
          _StatItem('IDLE', idle, Colors.green),
          _StatItem('OFFLINE', offline, Colors.grey),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatItem(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count', style: GoogleFonts.anton(fontSize: 24, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/widgets/quick_stats.dart
git commit -m "feat: add QuickStats widget for dashboard"
```

---

## Task 2: Create PrinterGrid Widget

**Files:**
- Create: `lib/widgets/printer_grid.dart`

**Step 1: Create the PrinterGrid widget**

```dart
import 'package:flutter/material.dart';
import '../models/printer.dart';
import 'printer_card.dart';

class PrinterGrid extends StatelessWidget {
  final List<Printer> printers;

  const PrinterGrid({super.key, required this.printers});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: printers.length,
      itemBuilder: (context, index) => PrinterCard(printer: printers[index]),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/widgets/printer_grid.dart
git commit -m "feat: add PrinterGrid widget"
```

---

## Task 3: Update PrinterCard with Circular Progress and Animations

**Files:**
- Modify: `lib/widgets/printer_card.dart`

**Step 1: Add circular progress and heating animation**

Replace the progress display section (around line 138-156) with:

```dart
if (printer.status == 'printing' || printer.status == 'paused') ...[
  // Animated circular progress
  Center(
    child: SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 8,
              backgroundColor: Colors.white10,
              color: Colors.white10,
            ),
          ),
          // Progress ring
          SizedBox(
            width: 120,
            height: 120,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: printer.progress / 100),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  backgroundColor: Colors.transparent,
                  color: statusColor,
                );
              },
            ),
          ),
          // Percentage text
          Text(
            "${printer.progress}%",
            style: GoogleFonts.anton(fontSize: 32, color: Colors.white),
          ),
        ],
      ),
    ),
  ),
] else ...[
  // Heating indicator - pulse when nozzle is heating
  if (printer.nozzleTemp < printer.targetNozzle && printer.targetNozzle > 0)
    _HeatingIndicator(nozzleTemp: printer.nozzleTemp, targetTemp: printer.targetNozzle)
  else
    const SizedBox(height: 80),
```

**Step 2: Add _HeatingIndicator widget at bottom of file**

```dart
class _HeatingIndicator extends StatefulWidget {
  final double nozzleTemp;
  final double targetTemp;

  const _HeatingIndicator({required this.nozzleTemp, required this.targetTemp});

  @override
  State<_HeatingIndicator> createState() => _HeatingIndicatorState();
}

class _HeatingIndicatorState extends State<_HeatingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(_animation.value * 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.whatshot, color: Colors.orange.withOpacity(_animation.value), size: 32),
                const SizedBox(height: 8),
                Text(
                  "HEATING ${widget.nozzleTemp.round()}° → ${widget.targetTemp.round()}°",
                  style: TextStyle(fontSize: 10, color: Colors.orange.withOpacity(_animation.value)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

**Step 3: Commit**

```bash
git add lib/widgets/printer_card.dart
git commit -m "feat: add circular progress and heating animation to PrinterCard"
```

---

## Task 4: Create HomeScreen with Bottom Navigation

**Files:**
- Create: `lib/screens/home_screen.dart`

**Step 1: Create HomeScreen**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/printer_provider.dart';
import '../widgets/quick_stats.dart';
import '../widgets/printer_grid.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime? _lastUpdated;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          _buildPrinters(),
          _buildSpools(),
          _buildSettings(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.print_outlined),
            selectedIcon: Icon(Icons.print),
            label: 'Printers',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Spools',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Consumer<PrinterProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.refresh();
            setState(() => _lastUpdated = DateTime.now());
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("FARM\nMANAGER", style: Theme.of(context).textTheme.displayLarge),
                          if (_lastUpdated != null)
                            Text(
                              "Updated ${_formatTime(_lastUpdated!)}",
                              style: TextStyle(fontSize: 10, color: Colors.white24),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      QuickStats(printers: provider.printers),
                    ],
                  ),
                ),
              ),
              SliverFillRemaining(
                child: provider.printers.isEmpty
                    ? Center(child: Text("NO PRINTERS", style: GoogleFonts.anton(fontSize: 24, color: Colors.white24)))
                    : PrinterGrid(printers: provider.printers),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrinters() {
    return Consumer<PrinterProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.refresh();
            setState(() => _lastUpdated = DateTime.now());
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.printers.length,
            itemBuilder: (context, index) {
              final printer = provider.printers[index];
              return ListTile(
                title: Text(printer.name.toUpperCase()),
                subtitle: Text(printer.status.toUpperCase()),
                trailing: Text("${printer.progress}%"),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DashboardScreen(printerId: printer.id),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSpools() {
    return Consumer<PrinterProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.fetchAllSpools();
            setState(() => _lastUpdated = DateTime.now());
          },
          child: FutureBuilder(
            future: provider.fetchAllSpools(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final spools = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: spools.length,
                itemBuilder: (context, index) {
                  final spool = spools[index];
                  return ListTile(
                    title: Text(spool.name),
                    subtitle: Text("${spool.vendor} ${spool.material}"),
                    trailing: Text("${spool.remainingWeight.round()}g"),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSettings() {
    return const Center(child: Text("Settings coming soon"));
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return "${diff.inSeconds}s ago";
    return "${diff.inMinutes}m ago";
  }
}
```

**Step 2: Commit**

```bash
git add lib/screens/home_screen.dart
git commit -m "feat: add HomeScreen with bottom navigation"
```

---

## Task 5: Update Main.dart to Use HomeScreen

**Files:**
- Modify: `lib/main.dart:98`

**Step 1: Change DashboardScreen to HomeScreen**

Replace:
```dart
home: const DashboardScreen(),
```
With:
```dart
home: const HomeScreen(),
```

Also add import:
```dart
import 'screens/home_screen.dart';
```

**Step 2: Commit**

```bash
git add lib/main.dart
git commit -m "feat: use HomeScreen as main entry point"
```

---

## Task 6: Verify Build

**Step 1: Build the app**

```bash
cd /media/games/farm-manager
flutter build apk --debug
```

Expected: Build succeeds with no errors

**Step 2: Commit**

```bash
git commit -m "chore: verify build passes"
```

---

## Plan complete

Save this plan to `docs/plans/2026-02-23-dashboard-implementation-plan.md`
