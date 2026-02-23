import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/printer_provider.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService.init();
  await BackgroundService.init();
  
  final printerProvider = PrinterProvider();
  await printerProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: printerProvider),
      ],
      child: FarmManagerApp(printerProvider: printerProvider),
    ),
  );
}

class FarmManagerApp extends StatefulWidget {
  final PrinterProvider printerProvider;
  const FarmManagerApp({super.key, required this.printerProvider});

  @override
  State<FarmManagerApp> createState() => _FarmManagerAppState();
}

class _FarmManagerAppState extends State<FarmManagerApp> {
  late final AppLifecycleListener _listener;
  static const platform = MethodChannel('com.example.farm_manager/widget');

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onStateChange: _onStateChanged,
    );
    
    platform.setMethodCallHandler((call) async {
      if (call.method == "triggerPrinterSelection") {
        _showSelection();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWidgetLaunch();
    });
  }

  void _showSelection() {
    // We use a global key or a simpler way to trigger the dialog on the dashboard
    DashboardScreen.triggerPinDialog();
  }

  void _checkWidgetLaunch() async {
    final String? action = await platform.invokeMethod('getIntentAction');
    if (action == "SELECT_PRINTER") {
      _showSelection();
    }
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  void _onStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      widget.printerProvider.pause();
    } else if (state == AppLifecycleState.resumed) {
      widget.printerProvider.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrinterProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Farm Manager',
          debugShowCheckedModeBanner: false,
          theme: provider.themeMode == 'expressive' 
            ? AppTheme.expressiveTheme 
            : provider.themeMode == 'liquid'
              ? AppTheme.liquidTheme
              : AppTheme.darkTheme,
          home: const DashboardScreen(),
        );
      },
    );
  }
}
