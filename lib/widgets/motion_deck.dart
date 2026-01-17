import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/printer_provider.dart';
import '../models/printer.dart';

class MotionDeck extends StatefulWidget {
  final Printer printer;
  const MotionDeck({super.key, required this.printer});

  @override
  State<MotionDeck> createState() => _MotionDeckState();
}

class _MotionDeckState extends State<MotionDeck> {
  double _distance = 10.0;

  void _move(String axis, double value) {
    final provider = Provider.of<PrinterProvider>(context, listen: false);
    final script = "G91\nG1 $axis$value F3000\nG90";
    provider.sendCommand(widget.printer.id, '/printer/gcode/script?script=${Uri.encodeComponent(script)}');
  }

  @override
  Widget build(BuildContext context) {
    bool isPrinting = widget.printer.status == 'printing' || widget.printer.status == 'paused';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text(isPrinting ? "BABY STEPPING" : "MOTION CONTROL", style: GoogleFonts.anton(fontSize: 18, color: Theme.of(context).colorScheme.primary, letterSpacing: 1)),
        ),
        Card(
          color: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: isPrinting ? _buildBabystepping(context) : _buildMotionControls(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBabystepping(BuildContext context) {
    final provider = Provider.of<PrinterProvider>(context, listen: false);
    return Column(
      children: [
        Row(children: [
          Icon(LucideIcons.moveVertical, size: 16, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          const Text("Z-OFFSET ADJUSTMENT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          const Spacer(),
          IconButton(
            onPressed: () => provider.sendCommand(widget.printer.id, '/printer/gcode/script?script=SET_GCODE_OFFSET Z=0 MOVE=1'),
            icon: const Icon(LucideIcons.rotateCcw, size: 18, color: Colors.orange),
            tooltip: "Reset Z-Offset",
          )
        ]),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _offsetButton(context, -0.05),
            _offsetButton(context, -0.01),
            Container(width: 1, height: 24, color: Colors.white10),
            _offsetButton(context, 0.01),
            _offsetButton(context, 0.05),
          ],
        )
      ],
    );
  }

  Widget _offsetButton(BuildContext context, double amount) {
    final provider = Provider.of<PrinterProvider>(context, listen: false);
    final isPos = amount > 0;
    return ElevatedButton(
      onPressed: () => provider.sendCommand(
        widget.printer.id, 
        '/printer/gcode/script?script=${Uri.encodeComponent("SET_GCODE_OFFSET Z_ADJUST=$amount MOVE=1")}'
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: (isPos ? Colors.blue : Colors.red).withOpacity(0.1),
        foregroundColor: isPos ? Colors.blue : Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        minimumSize: const Size(60, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text("${isPos ? '+' : ''}$amount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget _buildMotionControls(BuildContext context) {
    return Column(
      children: [
        // Distance Selector Pill
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [0.1, 1.0, 10.0, 50.0].map((d) {
              bool isSelected = _distance == d;
              return GestureDetector(
                onTap: () => setState(() => _distance = d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    "${d.round() == d ? d.toInt() : d}mm",
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).colorScheme.onPrimary : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pixel-style XY Pad
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Column(
                children: [
                  _pixelButton(LucideIcons.chevronUp, () => _move("Y", _distance)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _pixelButton(LucideIcons.chevronLeft, () => _move("X", -_distance)),
                      const SizedBox(width: 8),
                      _pixelButton(LucideIcons.home, () => Provider.of<PrinterProvider>(context, listen: false).sendCommand(widget.printer.id, '/printer/gcode/script?script=G28 X Y'), isHome: true),
                      const SizedBox(width: 8),
                      _pixelButton(LucideIcons.chevronRight, () => _move("X", _distance)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _pixelButton(LucideIcons.chevronDown, () => _move("Y", -_distance)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Pixel-style Z Pill
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Column(
                children: [
                  _pixelButton(LucideIcons.chevronsUp, () => _move("Z", _distance), color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(height: 12),
                  _pixelButton(LucideIcons.home, () => Provider.of<PrinterProvider>(context, listen: false).sendCommand(widget.printer.id, '/printer/gcode/script?script=G28 Z'), isHome: true),
                  const SizedBox(height: 12),
                  _pixelButton(LucideIcons.chevronsDown, () => _move("Z", -_distance), color: Theme.of(context).colorScheme.secondary),
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _pixelButton(IconData icon, VoidCallback onTap, {bool isHome = false, Color? color}) {
    bool isPrinting = widget.printer.status == 'printing';
    Color primary = Theme.of(context).colorScheme.primary;
    Color bg = isHome ? primary : (color ?? Colors.white10);
    
    return GestureDetector(
      onTap: isPrinting ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          color: isPrinting ? Colors.white.withOpacity(0.02) : bg,
          shape: BoxShape.circle,
          boxShadow: isHome && !isPrinting ? [
            BoxShadow(color: primary.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)
          ] : null,
        ),
        child: Icon(
          icon,
          color: isPrinting ? Colors.white10 : (isHome || color != null ? Colors.black : Colors.white),
          size: 24,
        ),
      ),
    );
  }
}