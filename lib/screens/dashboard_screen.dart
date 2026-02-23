import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/printer_provider.dart';
import '../models/printer.dart';
import '../widgets/printer_card.dart';
import '../widgets/at_glance.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static final GlobalKey<ScaffoldMessengerState> scaffoldKey = GlobalKey<ScaffoldMessengerState>();
  static BuildContext? _lastContext;

  @override
  Widget build(BuildContext context) {
    _lastContext = context;
    final provider = Provider.of<PrinterProvider>(context);

    return Scaffold(
      key: GlobalKey(), // unique key to force rebuild if needed
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text("CONTROL\nCENTER", style: Theme.of(context).textTheme.displayLarge, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => _showSpoolmanSettings(context, provider),
                          icon: const Icon(LucideIcons.settings, size: 18, color: Colors.white24),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton.filled(
                          onPressed: () => showSpoolmanMenu(context),
                          icon: const Icon(LucideIcons.database, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.05),
                            foregroundColor: const Color(0xFF8A3FD6),
                            minimumSize: const Size(56, 56),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () => _showAddDialog(context),
                          icon: const Icon(LucideIcons.plus, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            minimumSize: const Size(56, 56),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              AtGlance(printers: provider.printers),
              const SizedBox(height: 32),
              Expanded(
                child: provider.printers.isEmpty 
                  ? Center(
                      child: Opacity(
                        opacity: 0.3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.printer, size: 64),
                            const SizedBox(height: 16),
                            Text("NO MACHINES FOUND", style: GoogleFonts.anton(fontSize: 24)),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: provider.printers.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: SizedBox(
                          height: 300, // Enlarged cards
                          child: PrinterCard(printer: provider.printers[index]),
                        ),
                      ),
                    ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showSpoolmanSettings(BuildContext context, PrinterProvider provider) {
    final controller = TextEditingController(text: provider.spoolmanUrl);
    String selectedTheme = provider.themeMode;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text("SETTINGS", style: GoogleFonts.anton()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SPOOLMAN URL", style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Theme.of(context).colorScheme.primary)),
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: "http://ip:8000"),
              ),
              const SizedBox(height: 24),
              Text("THEME", style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Theme.of(context).colorScheme.primary)),
              DropdownButton<String>(
                value: selectedTheme,
                isExpanded: true,
                underline: Container(height: 1, color: Colors.white10),
                items: const [
                  DropdownMenuItem(value: 'dark', child: Text("Aubergine (Dark)")),
                  DropdownMenuItem(value: 'expressive', child: Text("Material 3 Expressive")),
                  DropdownMenuItem(value: 'liquid', child: Text("Liquid Glass")),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => selectedTheme = v);
                },
              ),
            ],
          ),
          actions: [
            if (provider.printers.isNotEmpty)
              TextButton(
                onPressed: () async {
                  final printer = provider.printers.first;
                  try {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restarting Moonraker...")));
                    await provider.sendCommand(printer.id, '/machine/services/restart', body: {'service': 'moonraker'});
                  } catch (e) {
                    // ignore
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
                child: const Text("RESTART MOONRAKER"),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () {
                provider.updateSpoolmanUrl(controller.text);
                provider.updateThemeMode(selectedTheme);
                Navigator.pop(context);
              },
              child: const Text("SAVE"),
            )
          ],
        ),
      ),
    );
  }

  static void showSpoolmanMenu(BuildContext context, {String? printerId}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1020),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(LucideIcons.database, color: Color(0xFF8A3FD6)),
                  const SizedBox(width: 12),
                  Text("FILAMENT INVENTORY", style: GoogleFonts.anton(fontSize: 24, letterSpacing: 1)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<Spool>>(
                future: Provider.of<PrinterProvider>(context, listen: false).fetchAllSpools(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.packageX, size: 48, color: Colors.white10),
                          const SizedBox(height: 16),
                          Text("NO SPOOLS FOUND", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                          const Text("Connect Spoolman to Moonraker", style: TextStyle(color: Colors.white10, fontSize: 10)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: snapshot.data!.length + (printerId != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (printerId != null && index == 0) {
                        return Card(
                          color: Colors.redAccent.withOpacity(0.05),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () async {
                              try {
                                await Provider.of<PrinterProvider>(context, listen: false).setPrinterSpool(printerId, null);
                                if (context.mounted) Navigator.pop(context);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent));
                                }
                              }
                            },
                            leading: const Icon(LucideIcons.xCircle, color: Colors.redAccent, size: 20),
                            title: const Text("UNASSIGN SPOOL", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                          ),
                        );
                      }
                      
                      final spool = snapshot.data![printerId != null ? index - 1 : index];
                      return Card(
                        color: Colors.white.withOpacity(0.02),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: printerId != null ? () async {
                            try {
                              await Provider.of<PrinterProvider>(context, listen: false).setPrinterSpool(printerId, spool.id);
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent));
                              }
                            }
                          } : null,
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 12, height: double.infinity,
                            decoration: BoxDecoration(
                              color: spool.color != null 
                                ? Color(int.parse("0xFF${spool.color!.replaceAll('#', '')}"))
                                : const Color(0xFF8A3FD6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          title: Text(spool.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38)),
                          subtitle: Text("${spool.vendor} ${spool.material}", style: GoogleFonts.anton(fontSize: 18, color: Colors.white)),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (printerId != null) 
                                const Text("SELECT", style: TextStyle(fontSize: 8, color: Color(0xFF8A3FD6), fontWeight: FontWeight.bold)),
                              Text("${spool.remainingWeight.round()}g", style: GoogleFonts.jetBrainsMono(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFDFFF4F))),
                              const Text("LEFT", style: TextStyle(fontSize: 8, color: Colors.white24)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    // ... logic ...
  }

  static void triggerPinDialog() {
    if (_lastContext != null) {
      showPinPrinterDialog(_lastContext!);
    }
  }

  static void showPinPrinterDialog(BuildContext context) {
    final provider = Provider.of<PrinterProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1020),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(LucideIcons.pin, color: Color(0xFF8A3FD6)),
                  const SizedBox(width: 12),
                  Text("PIN TO WIDGET", style: GoogleFonts.anton(fontSize: 24, letterSpacing: 1)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: provider.printers.isEmpty 
                ? const Center(child: Text("NO PRINTERS CONFIGURED"))
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: provider.printers.length,
                    itemBuilder: (context, index) {
                      final printer = provider.printers[index];
                      final isSelected = provider.selectedWidgetPrinterId == printer.id;
                      
                      return Card(
                        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.02),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () {
                            provider.setWidgetPrinter(printer.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("${printer.name} pinned to widget")),
                            );
                          },
                          leading: Icon(LucideIcons.printer, color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white24),
                          title: Text(printer.name.toUpperCase(), style: GoogleFonts.anton(fontSize: 18)),
                          subtitle: Text(printer.status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white38)),
                          trailing: isSelected ? const Icon(LucideIcons.check, color: Colors.green) : null,
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}