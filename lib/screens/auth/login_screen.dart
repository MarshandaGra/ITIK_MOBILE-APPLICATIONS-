import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final identifierCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void dispose() {
    identifierCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _isiDariAkun(String identifier, String password) {
    setState(() {
      identifierCtrl.text = identifier;
      passCtrl.text = password;
    });
  }

  void _login() {
    final app = context.read<AppProvider>();
    final id = identifierCtrl.text;
    final pass = passCtrl.text;

    // Role ditentukan otomatis: coba siswa dulu, lalu guru.
    final errSiswa = app.login(id, pass, UserRole.siswa);
    if (errSiswa == null) return;

    final errGuru = app.login(id, pass, UserRole.guru);
    if (errGuru == null) return;

    showAppToast(context, errSiswa);
    // Navigasi otomatis ditangani oleh AuthGate lewat Consumer<AppProvider>.
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    // Hanya akun siswa & guru yang relevan untuk aplikasi mobile ini.
    final akunDemo = app.users
        .where((u) => u.role == UserRole.siswa || u.role == UserRole.guru);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _LoginHeader(),
            // Konten naik sedikit menimpa lengkungan header.
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Kartu form login
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('NISN / NIP',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12.5)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: identifierCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan NISN atau NIP',
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text('Kata Sandi',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12.5)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: passCtrl,
                            obscureText: true,
                            decoration:
                                const InputDecoration(hintText: 'Kata sandi'),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                              onPressed: _login, child: const Text('Masuk')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Akun Demo',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12.5)),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap salah satu akun untuk mengisi form otomatis. Sandi semua akun: 123456.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.muted),
                    ),
                    const SizedBox(height: 10),
                    ...akunDemo.map((u) {
                      final isGuru = u.role == UserRole.guru;
                      return AppListItem(
                        icon: isGuru
                            ? Icons.school_rounded
                            : Icons.person_rounded,
                        iconColor: isGuru ? AppColors.green : AppColors.blue,
                        iconBg:
                            isGuru ? AppColors.greenLight : AppColors.blueLight,
                        title: u.nama,
                        subtitle: u.kelas == null
                            ? u.induk ?? '-'
                            : '${u.induk ?? '-'} • ${u.kelas}',
                        trailing: AppPill(
                          label: isGuru ? 'Guru' : 'Siswa',
                          color: isGuru ? AppColors.green : AppColors.blue,
                          background: isGuru
                              ? AppColors.greenLight
                              : AppColors.blueLight,
                        ),
                        onTap: () => _isiDariAkun(u.induk ?? '', u.password),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header gradasi biru dengan lengkungan bawah, ikon dekoratif TIK,
/// logo, teks sambutan, dan chip fitur.
class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 28, 20, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, Color(0xFF1E4FBF)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ikon dekoratif samar
          const Positioned(
              left: -6, top: 4, child: _DecoIcon(Icons.code_rounded, 34, -0.2)),
          const Positioned(
              right: 4,
              top: 0,
              child: _DecoIcon(Icons.laptop_mac_rounded, 36, 0.2)),
          const Positioned(
              left: 0, top: 70, child: _DecoIcon(Icons.wifi_rounded, 26, 0.1)),
          const Positioned(
              right: 0,
              top: 74,
              child: _DecoIcon(Icons.lock_outline_rounded, 26, -0.15)),
          // Konten utama (selebar header supaya center)
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/smkn2_jember.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Edukasi TIK',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Selamat datang kembali 👋',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: .92),
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Masuk untuk melanjutkan belajar',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: .75),
                        fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecoIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final double angle;

  const _DecoIcon(this.icon, this.size, this.angle);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Icon(icon, size: size, color: Colors.white.withValues(alpha: .14)),
    );
  }
}
