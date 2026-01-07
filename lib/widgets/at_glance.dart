import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/printer.dart';

class AtGlance extends StatelessWidget {
  final List<Printer> printers;

  const AtGlance({super.key, required this.printers});

  @override
  Widget build(BuildContext context) {
    final stats = {
      'total': printers.length,
      'printing': printers.where((p) => p.status == 'printing').length,
      'error': printers.where((p) => p.status == 'error').length,
      'offline': printers.where((p) => p.status == 'offline').length,
    };

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.8,
      children: [
        _buildStatCard(
          "TOTAL",
          stats['total'].toString(),
          LucideIcons.printer,
          const Color(0xFF8A3FD6),
        ),
        _buildStatCard(
          "ACTIVE",
          stats['printing'].toString(),
          LucideIcons.play,
          const Color(0xFFDFFF4F),
        ),
        _buildStatCard(
          "ERRORS",
          stats['error'].toString(),
          LucideIcons.alertCircle,
          Colors.redAccent,
        ),
        _buildStatCard(
          "OFFLINE",
          stats['offline'].toString(),
          LucideIcons.wifiOff,
          Colors.white24,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white38,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.anton(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
