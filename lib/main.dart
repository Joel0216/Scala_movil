import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'screens/login_screen.dart';
import 'screens/groups_screen.dart';
import 'screens/group_detail_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/exam_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vqsduyfkgdqnigzkxazk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZxc2R1eWZrZ2Rxbmlnemt4YXprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwMzIyOTMsImV4cCI6MjA4NDYwODI5M30.l5bZubjb3PIvcFG43JTfoeguldEwwIK7wlnOnl-Ec5o',
  );

  final supabaseService = SupabaseService();
  final authProvider = AuthProvider(supabaseService);

  await authProvider.checkSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => DataProvider(supabaseService)),
      ],
      child: ScalaApp(initialRoute: authProvider.maestro != null ? '/groups' : '/login'),
    ),
  );
}

class ScalaApp extends StatelessWidget {
  final String initialRoute;
  const ScalaApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCALA Maestros',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Outfit',
        scaffoldBackgroundColor: const Color(0xFFdbd6df), // --color-lavender
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF738fbd), // --color-blueish
          primary: const Color(0xFF738fbd), // --color-blueish
          secondary: const Color(0xFFdb88a4), // --color-pink
          tertiary: const Color(0xFFcc8eb1), // --color-mauve
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF738fbd), // --color-blueish
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/groups': (context) => const GroupsScreen(),
        '/group-detail': (context) => const GroupDetailScreen(),
        '/verify': (context) => const VerificationScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/exam': (context) => const ExamScreen(),
        '/exam-session': (context) => const ExamSessionScreen(),
      },
    );
  }
}
