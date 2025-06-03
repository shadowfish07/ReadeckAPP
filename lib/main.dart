import 'package:flutter/material.dart';
import 'services/readeck_api_service.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const ReadeckApp());
}

class ReadeckApp extends StatefulWidget {
  const ReadeckApp({super.key});

  @override
  State<ReadeckApp> createState() => _ReadeckAppState();
}

class _ReadeckAppState extends State<ReadeckApp> {
  final ReadeckApiService _apiService = ReadeckApiService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _apiService.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Readeck',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          iconTheme: const IconThemeData(
            color: Colors.black87,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: _isInitialized
          ? HomePage(apiService: _apiService)
          : const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
      debugShowCheckedModeBanner: false,
    );
  }
}
