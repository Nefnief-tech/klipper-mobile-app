import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/printer.dart';
import '../screens/printer_detail_screen.dart';

class PrinterCard extends StatelessWidget {
  final Printer printer;

  const PrinterCard({super.key, required this.printer});

  Color getStatusColor(BuildContext context) {
    switch (printer.status) {
      case 'printing': return Theme.of(context).colorScheme.secondary;
      case 'paused': return Colors.orange;
      case 'error': return Colors.redAccent;
      case 'offline': return Colors.grey;
      default: return Colors.white24;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(context);
    bool hasThumb = (printer.status == 'printing' || printer.status == 'paused') && printer.thumbnailUrl != null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PrinterDetailScreen(printerId: printer.id)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Full Background Thumbnail
            if (hasThumb)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: Image.network(
                    printer.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            // Gradient Overlay for readability
            if (hasThumb)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              printer.name.toUpperCase(),
                              style: GoogleFonts.anton(
                                fontSize: 24, 
                                color: hasThumb ? Colors.white : Theme.of(context).colorScheme.primary,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(printer.ip, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.white38)),
                            if (printer.currentSpool != null)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: BoxDecoration(
                                        color: printer.currentSpool!.color != null 
                                          ? Color(int.parse("0xFF${printer.currentSpool!.color!.replaceAll('#', '')}"))
                                          : Theme.of(context).colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "${printer.currentSpool!.material} (${printer.currentSpool!.remainingWeight.round()}g)",
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(printer.status == 'printing' ? 1.0 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          printer.status.toUpperCase(),
                          style: TextStyle(
                            color: printer.status == 'printing' ? Colors.black : statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (printer.status == 'printing' || printer.status == 'paused') ...[
                    Center(
                      child: Text(
                        "${printer.progress}%",
                        style: GoogleFonts.anton(
                          fontSize: 64,
                          color: Colors.white,
                          shadows: [const Shadow(blurRadius: 20, color: Colors.black)],
                        ),
                      ),
                    ),
                    const Spacer(),
                    LinearProgressIndicator(
                      value: printer.progress / 100,
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 8,
                      backgroundColor: Colors.white10,
                      color: statusColor,
                    ),
                  ] else ...[
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: printer.history.length > 1 
                          ? LineChart(LineChartData(
                              minX: 0, maxX: 59, minY: 0,
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(printer.history.length, (i) => FlSpot(i.toDouble(), printer.history[i].nozzle)),
                                  isCurved: true, curveSmoothness: 0.1, color: Theme.of(context).colorScheme.primary, barWidth: 3, dotData: const FlDotData(show: false),
                                ),
                                LineChartBarData(
                                  spots: List.generate(printer.history.length, (i) => FlSpot(i.toDouble(), printer.history[i].bed)),
                                  isCurved: true, curveSmoothness: 0.1, color: Colors.blueAccent, barWidth: 3, dotData: const FlDotData(show: false),
                                ),
                              ],
                            ))
                          : const Center(child: Text("IDLE", style: TextStyle(color: Colors.white10))),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _tempInfo("NOZZLE", printer.nozzleTemp, printer.targetNozzle),
                      _tempInfo("BED", printer.bedTemp, printer.targetBed),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tempInfo(String label, double temp, double target) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text("${temp.round()}°", style: GoogleFonts.jetBrainsMono(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(width: 4),
            Text("/${target.round()}°", style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.white24)),
          ],
        ),
      ],
    );
  }
}