import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../providers/printer_provider.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String? _selectedPrinterId;
  final _filenameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PrinterProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.arrowLeft),
                  ),
                  const SizedBox(width: 8),
                  Text("SCHEDULE", style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 40)),
                ],
              ),
              const SizedBox(height: 32),
              
              // New Job Card
              _sectionTitle("NEW JOB"),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(color: Color(0xFF8A3FD6), shape: BoxShape.circle),
                          todayDecoration: BoxDecoration(color: const Color(0xFF8A3FD6).withOpacity(0.2), shape: BoxShape.circle),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: GoogleFonts.anton(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration("SELECT PRINTER"),
                        value: _selectedPrinterId,
                        items: provider.printers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                        onChanged: (val) => setState(() => _selectedPrinterId = val),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _filenameController,
                        decoration: _inputDecoration("FILENAME"),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _schedule,
                        child: const Text("SCHEDULE PRINT"),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Queue Card
              _sectionTitle("UPCOMING QUEUE"),
              if (provider.jobs.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("NO JOBS SCHEDULED", style: TextStyle(color: Colors.white24)))),
              ...provider.jobs.map((job) {
                final printer = provider.printers.firstWhere((p) => p.id == job.printerId, orElse: () => provider.printers.first);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Card(
                    color: Colors.white.withOpacity(0.03),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(job.filename, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${printer.name} • ${DateFormat.yMMMd().format(job.scheduledTime)}"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: const Text("PENDING", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 16),
      child: Text(title, style: GoogleFonts.anton(fontSize: 18, color: const Color(0xFF8A3FD6))),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white38),
      filled: true,
      fillColor: Colors.black12,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  void _schedule() {
    if (_selectedDay != null && _selectedPrinterId != null && _filenameController.text.isNotEmpty) {
      Provider.of<PrinterProvider>(context, listen: false).scheduleJob(
        _selectedPrinterId!,
        _filenameController.text,
        _selectedDay!,
      );
      _filenameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(ApiResponseSnackBar(message: "JOB SCHEDULED"));
    }
  }
}

class ApiResponseSnackBar extends SnackBar {
  final String message;
  ApiResponseSnackBar({super.key, required this.message}) : super(
    content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
    backgroundColor: const Color(0xFFDFFF4F),
    behavior: SnackBarBehavior.floating,
  );
}
