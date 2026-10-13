import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'models/workflow.dart';
import 'screens/home_page.dart';
import 'screens/login_screen.dart';
import 'services/locale_controller.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocaleController.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home});
  final Widget? home;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale?>(
    valueListenable: LocaleController.instance.locale,
    builder: (context, locale, child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Factory Check',
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF087F8C)),
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFF4F7FA),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE1E7EC)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: home ?? const AuthGate(),
    ),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      return user == null
          ? const LoginPage()
          : _ProfileGate(key: ValueKey(user.uid), user: user);
    },
  );
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({super.key, required this.user});
  final User user;
  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late Future<FactoryUser> _profile;
  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  Future<FactoryUser> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .get();
    if (!doc.exists) throw const WorkflowException('profile');
    return FactoryUser.fromProfile(
      uid: widget.user.uid,
      email: widget.user.email ?? '',
      profile: doc.data()!,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<FactoryUser>(
    future: _profile,
    builder: (context, snap) {
      final t = AppLocalizations.of(context);
      if (snap.hasData) {
        return HomePage(
          actor: snap.data!,
          onSignOut: () async {
            await NotificationService.instance.reset();
            await FirebaseAuth.instance.signOut();
          },
        );
      }
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: snap.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.sessionError, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => setState(() => _profile = _load()),
                        child: Text(t.retry),
                      ),
                      TextButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: Text(t.logout),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
