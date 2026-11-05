import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/a11y_provider.dart';
import 'theme/app_theme.dart';
import 'models/user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/siswa/siswa_shell.dart';
import 'screens/guru/guru_shell.dart';

void main() {
  runApp(const EdukasiTikApp());
}

class EdukasiTikApp extends StatelessWidget {
  const EdukasiTikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => A11yProvider()),
      ],
      child: Consumer<A11yProvider>(
        builder: (context, a11y, _) {
          return MaterialApp(
            title: 'Edukasi TIK',
            debugShowCheckedModeBanner: false,
            theme: a11y.highContrast
                ? AppTheme.highContrastLight()
                : AppTheme.light(),
            darkTheme: a11y.highContrast
                ? AppTheme.highContrastDark()
                : AppTheme.dark(),
            themeMode: a11y.darkTheme ? ThemeMode.dark : ThemeMode.light,
            themeAnimationDuration: Duration.zero,
            navigatorObservers: [A11yRouteObserver(a11y)],
            builder: (context, child) {
              // Terapkan skala ukuran teks global sesuai pengaturan aksesibilitas.
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data:
                    mq.copyWith(textScaler: TextScaler.linear(a11y.fontScale)),
                child: child!,
              );
            },
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Mengarahkan ke Login jika belum ada sesi, atau ke shell sesuai peran
/// (Siswa/Guru) jika sudah login. Operator sengaja tidak memiliki shell di
/// aplikasi mobile ini — operator hanya tersedia di website admin.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    if (!app.sessionInitialized) {
      return const Scaffold(
        body: SizedBox.shrink(),
      );
    }
    if (!app.isLoggedIn) return const LoginScreen();
    return app.currentUser!.role == UserRole.siswa
        ? const SiswaShell()
        : const GuruShell();
  }
}
