import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'config/dependencies.dart';
import 'data/service/shared_preference_service.dart';
import 'routing/router.dart';
import 'ui/core/theme.dart';
import 'main_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Logger.root.level = Level.ALL;

  final prefsService = SharedPreferencesService();
  final host = await prefsService.getReadeckApiHost();
  final token = await prefsService.getReadeckApiToken();

  runApp(MultiProvider(
    providers: providers(host, token),
    child: const MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MainAppViewModel>(
      builder: (context, viewModel, child) {
        return MaterialApp.router(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: viewModel.themeMode,
          routerConfig: router(),
        );
      },
    );
  }
}


// class _ReadeckAppState extends State<ReadeckApp> {
//   static const String _themeModeKey = 'theme_mode';
//   final ReadeckApiService _apiService = ReadeckApiService();
//   final StorageService _storageService = StorageService.instance;
//   bool _isInitialized = false;
//   ThemeMode _themeMode = ThemeMode.system;

//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }

//   Future<void> _initializeApp() async {
//     await _storageService.initialize();
//     await _apiService.initialize();
//     await _loadThemeMode();
//     setState(() {
//       _isInitialized = true;
//     });
//   }

//   Future<void> _loadThemeMode() async {
//     final themeModeIndex =
//         _storageService.getInt(_themeModeKey) ?? ThemeMode.system.index;
//     _themeMode = ThemeMode.values[themeModeIndex];
//   }

//   Future<void> _changeThemeMode(ThemeMode themeMode) async {
//     await _storageService.saveInt(_themeModeKey, themeMode.index);
//     setState(() {
//       _themeMode = themeMode;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Readeck',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.deepPurple,
//           brightness: Brightness.light,
//         ),
//         useMaterial3: true,
//         appBarTheme: const AppBarTheme(
//           centerTitle: false,
//           elevation: 4.0,
//           titleTextStyle: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         cardTheme: CardTheme(
//           elevation: 2,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       ),
//       darkTheme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: Colors.deepPurple,
//           brightness: Brightness.dark,
//         ),
//         useMaterial3: true,
//         appBarTheme: const AppBarTheme(
//           centerTitle: false,
//           elevation: 4.0,
//           titleTextStyle: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         cardTheme: CardTheme(
//           elevation: 2,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       ),
//       themeMode: _themeMode,
//       home: _isInitialized
//           ? MainPage(
//               apiService: _apiService,
//               onThemeChanged: _changeThemeMode,
//               currentThemeMode: _themeMode,
//             )
//           : const Scaffold(
//               body: Center(
//                 child: CircularProgressIndicator(),
//               ),
//             ),
//       debugShowCheckedModeBanner: false,
//     );
//   }
// }
