import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/printer_provider.dart';
import '../models/printer.dart';
import '../widgets/motion_deck.dart';
import 'gcode_viewer_screen.dart';
import 'dashboard_screen.dart';

class PrinterDetailScreen extends StatefulWidget {
  final String printerId;
  const PrinterDetailScreen({super.key, required this.printerId});

  @override
  State<PrinterDetailScreen> createState() => _PrinterDetailScreenState();
}

class _PrinterDetailScreenState extends State<PrinterDetailScreen> {
  bool _webcamError = false;
  DateTime _lastLedUpdate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PrinterProvider>(context);
    final printer = provider.printers.firstWhere((p) => p.id == widget.printerId, orElse: () => Printer(id: '', name: 'NOT FOUND', ip: ''));

    if (printer.id.isEmpty) return const Scaffold(body: Center(child: Text("PRINTER NOT FOUND")));
    
    final bool isPrinting = printer.status == 'printing' || printer.status == 'paused';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(printer.name.toUpperCase(), style: GoogleFonts.anton(fontSize: 24)),
        actions: [
          IconButton(onPressed: () => provider.refreshPrinter(printer.id), icon: const Icon(LucideIcons.refreshCw)),
        ],
      ),
      bottomNavigationBar: isPrinting ? _buildBottomBar(context, provider, printer) : null,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildWebcam(printer),
                if (isPrinting) ...[
                  const SizedBox(height: 24),
                  _buildPrintingStatusHeader(printer),
                ],
                const SizedBox(height: 24),
                _buildTelemetry(context, provider, printer),
                const SizedBox(height: 24),
                if (printer.boxTurtle != null) ...[
                   _buildBoxTurtleInfo(context, printer.boxTurtle!),
                   const SizedBox(height: 24),
                ],
                if (printer.currentSpool != null)
                  _buildSpoolInfo(printer.currentSpool!, printer.id)
                else
                  _buildEmptySpoolInfo(context, printer.id),
                const SizedBox(height: 24),
                // Tools Bar (Only show when NOT printing)
                if (!isPrinting) ...[
                  Row(
                    children: [
                      Expanded(child: _toolButton(context, "CONSOLE", LucideIcons.terminal, () => _showConsole(context, printer))),
                      const SizedBox(width: 12),
                      Expanded(child: _toolButton(context, "OBJECTS", LucideIcons.layers, () => _showObjects(context, printer))),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                MotionDeck(printer: printer),
                const SizedBox(height: 24),
                _buildTabCard(context, provider, printer, isPrinting),
              ],
            ),
          ),
          
          // Emergency Stop Overlay
          if (printer.status == 'error')
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
                      ),
                      child: const Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 64),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "EMERGENCY STOP",
                      style: GoogleFonts.anton(fontSize: 32, letterSpacing: 1),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Firmware has been halted. Verify the physical state of your machine before proceeding.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: () => provider.sendCommand(printer.id, '/printer/firmware_restart'),
                      icon: const Icon(LucideIcons.refreshCw),
                      label: const Text("FIRMWARE RESTART"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        minimumSize: const Size.fromHeight(64),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CLOSE VIEW", style: TextStyle(color: Colors.white38)),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _toolButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        foregroundColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        minimumSize: const Size.fromHeight(50),
      ),
    );
  }

  void _showConsole(BuildContext context, Printer printer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DraggablePopup(
        title: "CONSOLE",
        icon: LucideIcons.terminal,
        child: ConsoleView(printer: printer),
      ),
    );
  }

  void _showObjects(BuildContext context, Printer printer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DraggablePopup(
        title: "OBJECTS",
        icon: LucideIcons.layers,
        child: ObjectsView(printer: printer),
      ),
    );
  }

  Widget _buildWebcam(Printer printer) {
    if (_webcamError) return const SizedBox();
    return AspectRatio(
      aspectRatio: 16/9,
      child: Card(
        color: Colors.black,
        clipBehavior: Clip.none,
        child: Stack(
          children: [
            Positioned.fill(child: Image.network('http://${printer.ip}/webcam/?action=stream', fit: BoxFit.contain, 
              errorBuilder: (ctx, _, __) {
                WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _webcamError = true); });
                return const SizedBox();
              })),
            if (printer.status == 'printing' || printer.status == 'paused')
              Positioned(bottom: 16, left: 16, right: 16, child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
                child: Row(children: [
                  Text("${printer.progress}%", style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(width: 16),
                  Expanded(child: Text(printer.currentFile ?? "UNKNOWN", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                ]),
              ))
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetry(BuildContext context, PrinterProvider provider, Printer printer) {
    return Row(children: [
      Expanded(child: InkWell(onTap: () => _showTempDialog(context, provider, printer, 'extruder'), 
        child: _tempCapsule("EXTRUDER", printer.nozzleTemp, printer.targetNozzle, Colors.purple, List.generate(printer.history.length, (i) => FlSpot(i.toDouble(), printer.history[i].nozzle))))),
      const SizedBox(width: 16),
      Expanded(child: InkWell(onTap: () => _showTempDialog(context, provider, printer, 'heater_bed'), 
        child: _tempCapsule("BED", printer.bedTemp, printer.targetBed, Colors.blue, List.generate(printer.history.length, (i) => FlSpot(i.toDouble(), printer.history[i].bed))))),
    ]);
  }

  Widget _buildEmptySpoolInfo(BuildContext context, String printerId) {
    return InkWell(
      onTap: () => DashboardScreen.showSpoolmanMenu(context, printerId: printerId),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.database, color: Colors.white24, size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("FILAMENT", style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
                  Text("NO SPOOL ASSIGNED", style: GoogleFonts.anton(fontSize: 18, color: Colors.white24)),
                ],
              ),
            ),
            Icon(LucideIcons.plus, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSpoolInfo(Spool spool, String printerId) {
    return Card(
      color: Colors.white.withOpacity(0.02),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: spool.color != null 
                  ? Color(int.parse("0xFF${spool.color!.replaceAll('#', '')}"))
                  : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (spool.color != null 
                      ? Color(int.parse("0xFF${spool.color!.replaceAll('#', '')}"))
                      : Theme.of(context).colorScheme.primary).withOpacity(0.3),
                    blurRadius: 10,
                  )
                ]
              ),
              child: const Icon(LucideIcons.database, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spool.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
                  Text("${spool.vendor} ${spool.material}", style: GoogleFonts.anton(fontSize: 18, letterSpacing: 0.5)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("REMAINING", style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
                Text("${spool.remainingWeight.round()}g", style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary)),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => DashboardScreen.showSpoolmanMenu(context, printerId: printerId),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 20),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text("CHANGE", style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxTurtleInfo(BuildContext context, BoxTurtle boxTurtle) {
    return Card(
      color: Colors.white.withOpacity(0.02),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.container, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Text("BOX TURTLE AFC", style: GoogleFonts.anton(fontSize: 18, letterSpacing: 0.5)),
                const Spacer(),
                Text(boxTurtle.status.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: boxTurtle.lanes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final lane = boxTurtle.lanes[index];
                  final isActive = boxTurtle.activeLane == lane.id;
                  final color = lane.color != null ? Color(int.parse("0xFF${lane.color!.replaceAll('#', '')}")) : Colors.grey;
                  
                  return Container(
                    width: 80,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isActive ? color : Colors.transparent, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: isActive ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)] : null,
                          ),
                          child: isActive ? const Icon(LucideIcons.check, size: 16, color: Colors.white) : null,
                        ),
                        const Spacer(),
                        Text(lane.name ?? "L${lane.id}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(lane.material ?? "UNK", style: const TextStyle(fontSize: 10, color: Colors.white54)),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTabCard(BuildContext context, PrinterProvider provider, Printer printer, bool isPrinting) {
    return DefaultTabController(
      length: isPrinting ? 2 : 3,
      child: Card(
        child: Column(children: [
          TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            tabs: isPrinting 
              ? const [Tab(text: "CONSOLE"), Tab(text: "OBJECTS")]
              : const [Tab(text: "FILES"), Tab(text: "MACROS"), Tab(text: "CONTROLS")]
          ),
          SizedBox(height: 400, child: TabBarView(children: isPrinting ? [
            ConsoleView(printer: printer),
            ObjectsView(printer: printer),
          ] : [
            // Files
            ListView(padding: const EdgeInsets.all(16), children: [
              if (printer.files.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("NO FILES"))),
              ...printer.files.map((f) => ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                onTap: () {
                  final baseUrl = printer.ip.startsWith('http') ? printer.ip : 'http://${printer.ip}';
                  Navigator.push(context, MaterialPageRoute(builder: (context) => GCodeViewerScreen(
                    fileName: f.name,
                    gcodeUrl: '$baseUrl/server/files/gcodes/${Uri.encodeComponent(f.name)}',
                  )));
                },
                leading: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    image: f.thumbnailUrl != null 
                      ? DecorationImage(image: NetworkImage(f.thumbnailUrl!), fit: BoxFit.cover)
                      : null,
                  ),
                  child: f.thumbnailUrl == null ? const Icon(LucideIcons.fileCode, size: 16, color: Colors.white24) : null,
                ),
                title: Text(f.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(onPressed: () {
                      final baseUrl = printer.ip.startsWith('http') ? printer.ip : 'http://${printer.ip}';
                      Navigator.push(context, MaterialPageRoute(builder: (context) => GCodeViewerScreen(
                        fileName: f.name,
                        gcodeUrl: '$baseUrl/server/files/gcodes/${Uri.encodeComponent(f.name)}',
                      )));
                    }, icon: const Icon(LucideIcons.eye, size: 16, color: Colors.white38)),
                    IconButton(onPressed: () => provider.sendCommand(printer.id, '/printer/print/start?filename=${Uri.encodeComponent(f.name)}'), icon: Icon(LucideIcons.play, size: 16, color: Theme.of(context).colorScheme.secondary))
                  ],
                )
              ))
            ]),
            GridView.builder(padding: const EdgeInsets.all(16), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.5),
              itemCount: printer.macros.length,
              itemBuilder: (ctx, i) => ElevatedButton(
                onPressed: () => provider.sendCommand(printer.id, '/printer/gcode/script?script=${Uri.encodeComponent(printer.macros[i])}'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text(printer.macros[i], style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
              ),
            ),
            // Controls
            ListView(padding: const EdgeInsets.all(16), children: [
              if (printer.devices.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("NO DEVICES DETECTED"))),
              ...printer.devices.map((device) => _buildDeviceControl(context, provider, printer, device)),
            ]),
          ]))
        ]),
      ),
    );
  }

  Widget _buildDeviceControl(BuildContext context, PrinterProvider provider, Printer printer, KlipperDevice device) {
    IconData icon;
    
    switch (device.type) {
      case 'fan':
      case 'fan_generic':
        icon = LucideIcons.fan;
        break;
      case 'led':
        icon = LucideIcons.lightbulb;
        break;
      case 'output_pin':
        icon = LucideIcons.toggleRight;
        break;
      default:
        icon = LucideIcons.cpu;
    }

    return Card(
      color: Colors.white.withOpacity(0.02),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: device.value > 0 ? Theme.of(context).colorScheme.secondary : Colors.white24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: () => _showManualValueDialog(context, provider, printer, device),
                    child: Text("${(device.value * 100).round()}%", style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                  ),
                ],
              ),
            ),
            if (device.type == 'fan' || device.type == 'fan_generic' || device.type == 'output_pin')
              Switch(
                value: device.value > 0.01,
                activeColor: Theme.of(context).colorScheme.secondary,
                onChanged: (val) {
                  final target = val ? 1.0 : 0.0;
                  String cmd;
                  if (device.type == 'fan') {
                    cmd = val ? 'M106 S255' : 'M107';
                  } else if (device.type == 'fan_generic') {
                    cmd = 'SET_FAN_SPEED FAN=${device.name} SPEED=$target';
                  } else {
                    cmd = 'SET_PIN PIN=${device.name} VALUE=$target';
                  }
                  provider.sendCommand(printer.id, '/printer/gcode/script?script=${Uri.encodeComponent(cmd)}');
                },
              ),
            if (device.type == 'led')
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: device.value.clamp(0.0, 1.0),
                    activeColor: Theme.of(context).colorScheme.secondary,
                    inactiveColor: Colors.white10,
                    onChanged: (val) {
                      final now = DateTime.now();
                      if (now.difference(_lastLedUpdate).inMilliseconds > 250) {
                        _lastLedUpdate = now;
                        final cmd = 'SET_LED LED=${device.name} RED=$val GREEN=$val BLUE=$val WHITE=$val TRANSMIT=1';
                        provider.sendCommand(printer.id, '/printer/gcode/script?script=${Uri.encodeComponent(cmd)}');
                      }
                    },
                    onChangeEnd: (val) {
                      final cmd = 'SET_LED LED=${device.name} RED=$val GREEN=$val BLUE=$val WHITE=$val TRANSMIT=1';
                      provider.sendCommand(printer.id, '/printer/gcode/script?script=${Uri.encodeComponent(cmd)}');
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showManualValueDialog(BuildContext context, PrinterProvider provider, Printer printer, KlipperDevice device) {
    final controller = TextEditingController(text: (device.value * 100).round().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text("SET ${device.name.toUpperCase()} %", style: GoogleFonts.anton(fontSize: 18)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            suffixText: "%",
            hintText: "0-100",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                final target = (val / 100).clamp(0.0, 1.0);
                String cmd;
                if (device.type == 'fan') {
                  final s = (target * 255).round();
                  cmd = s > 0 ? 'M106 S$s' : 'M107';
                } else if (device.type == 'fan_generic') {
                  cmd = 'SET_FAN_SPEED FAN=${device.name} SPEED=$target';
                } else if (device.type == 'output_pin') {
                  cmd = 'SET_PIN PIN=${device.name} VALUE=$target';
                } else {
                  cmd = 'SET_LED LED=${device.name} RED=$target GREEN=$target BLUE=$target WHITE=$target TRANSMIT=1';
                }
                provider.sendCommand(printer.id, '/printer/gcode/script?script=${Uri.encodeComponent(cmd)}');
              }
              Navigator.pop(context);
            },
            child: const Text("SET"),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, PrinterProvider provider, Printer printer) {
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
      child: Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: () => provider.sendCommand(printer.id, printer.status == 'printing' ? '/printer/print/pause' : '/printer/print/resume'), 
          icon: Icon(printer.status == 'printing' ? LucideIcons.pause : LucideIcons.play), label: Text(printer.status == 'printing' ? "PAUSE" : "RESUME"),
          style: ElevatedButton.styleFrom(backgroundColor: printer.status == 'printing' ? Colors.orange : Colors.green, foregroundColor: Colors.black, minimumSize: const Size(0, 56)))),
        const SizedBox(width: 12),
        IconButton.filled(onPressed: () => provider.sendCommand(printer.id, '/printer/print/cancel'), icon: const Icon(LucideIcons.square), style: IconButton.styleFrom(backgroundColor: Colors.white10, minimumSize: const Size(56, 56))),
        const SizedBox(width: 12),
        IconButton.filled(onPressed: () => provider.sendCommand(printer.id, '/printer/emergency_stop'), icon: const Icon(LucideIcons.alertCircle), style: IconButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(56, 56))),
      ]));
  }

  Widget _tempCapsule(String label, double val, double target, Color color, List<FlSpot> spots) {
    return Card(child: Container(height: 140, padding: const EdgeInsets.all(20), child: Stack(children: [
      if (spots.length > 1) LineChart(LineChartData(minX: 0, maxX: 59, minY: 0, gridData: const FlGridData(show: false), titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false),
        lineBarsData: [LineChartBarData(spots: spots, isCurved: true, curveSmoothness: 0.1, color: color.withOpacity(0.3), barWidth: 3, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: false))])),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
        Text("${val.round()}°", style: GoogleFonts.anton(fontSize: 32)),
        Text("/ ${target.round()}°", style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white38)),
      ])
    ])));
  }

  Widget _buildPrintingStatusHeader(Printer printer) {
    return Card(
      color: Colors.white.withOpacity(0.02),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                image: printer.thumbnailUrl != null 
                  ? DecorationImage(image: NetworkImage(printer.thumbnailUrl!), fit: BoxFit.cover)
                  : null,
              ),
              child: printer.thumbnailUrl == null 
                ? const Icon(LucideIcons.fileCode, color: Colors.white24)
                : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    printer.currentFile?.toUpperCase() ?? "UNKNOWN FILE",
                    style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    printer.status == 'paused' ? "PAUSED" : "PRINTING",
                    style: GoogleFonts.anton(fontSize: 24, letterSpacing: 1, color: printer.status == 'paused' ? Colors.orange : Colors.white),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: printer.progress / 100,
                    backgroundColor: Colors.white10,
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Text(
              "${printer.progress}%",
              style: GoogleFonts.anton(fontSize: 32, color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showTempDialog(BuildContext context, PrinterProvider provider, Printer printer, String type) {
    final controller = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: Theme.of(context).colorScheme.surface, title: Text("SET ${type.toUpperCase()} TEMP", style: GoogleFonts.anton()),
      content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "TEMPERATURE (°C)")),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")), ElevatedButton(onPressed: () {
        final temp = int.tryParse(controller.text);
        if (temp != null) provider.sendCommand(printer.id, '/printer/gcode/script?script=${type == 'extruder' ? 'M104' : 'M140'} S$temp');
        Navigator.pop(context);
      }, child: const Text("SET"))]));
  }
}

class _DraggablePopup extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DraggablePopup({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: GoogleFonts.anton(fontSize: 24, letterSpacing: 1)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x))
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class ConsoleView extends StatefulWidget {
  final Printer printer;
  const ConsoleView({super.key, required this.printer});

  @override
  State<ConsoleView> createState() => _ConsoleViewState();
}

class _ConsoleViewState extends State<ConsoleView> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PrinterProvider>(context, listen: false);
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)),
            child: Consumer<PrinterProvider>(
              builder: (context, prov, _) {
                final p = prov.printers.firstWhere((item) => item.id == widget.printer.id);
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: p.terminalLogs.length,
                  itemBuilder: (context, i) => Text(p.terminalLogs[i], style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.greenAccent)),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: "SEND GCODE...",
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () {
                if (_textController.text.isEmpty) return;
                provider.sendCommand(widget.printer.id, '/printer/gcode/script?script=${Uri.encodeComponent(_textController.text)}');
                _textController.clear();
              },
              icon: const Icon(LucideIcons.send),
            )
          ],
        )
      ],
    );
  }
}

class ObjectsView extends StatelessWidget {
  final Printer printer;
  const ObjectsView({super.key, required this.printer});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PrinterProvider>(context, listen: false);
    return Consumer<PrinterProvider>(
      builder: (context, prov, _) {
        final p = prov.printers.firstWhere((item) => item.id == printer.id);
        if (p.excludeObject?.objects.isEmpty ?? true) return const Center(child: Text("NO OBJECTS FOUND"));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: p.excludeObject!.objects.map((name) {
            bool isExcluded = p.excludeObject!.excluded.contains(name);
            bool isCurrent = p.excludeObject!.current == name;
            return ListTile(
              title: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isExcluded ? Colors.white24 : Colors.white)),
              leading: Icon(LucideIcons.layers, size: 18, color: isExcluded ? Colors.red : isCurrent ? Colors.green : Colors.white38),
              trailing: isExcluded ? null : IconButton(
                onPressed: () => provider.sendCommand(printer.id, '/printer/exclude_object/exclude?name=${Uri.encodeComponent(name)}'),
                icon: const Icon(LucideIcons.trash2, color: Colors.orangeAccent),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
