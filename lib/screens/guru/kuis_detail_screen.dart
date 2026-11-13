import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/kuis.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import 'kuis_form_screen.dart';
import 'soal_form_screen.dart';

class KuisDetailScreen extends StatelessWidget {
  final String kuisId;
  const KuisDetailScreen({super.key, required this.kuisId});

  Future<void> _hapusKuis(BuildContext context, AppProvider app, Kuis k) async {
    final ok = await confirmDialog(context,
        'Hapus "${k.judul}" beserta ${k.soal.length} soal di dalamnya?\n\nTindakan ini tidak dapat dibatalkan.');
    if (ok) {
      app.hapusKuis(k.id);
      if (context.mounted) {
        Navigator.pop(context);
        showAppToast(context, 'Kuis telah dihapus');
      }
    }
  }

  Future<void> _hapusSoal(
      BuildContext context, AppProvider app, String kuisId, int index) async {
    final ok = await confirmDialog(
        context, 'Hapus soal nomor ${index + 1} dari kuis ini?');
    if (ok) {
      app.hapusSoal(kuisId, index);
      if (context.mounted) showAppToast(context, 'Soal telah dihapus');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final k = app.kuisById(kuisId);
    if (k == null) {
      return const Scaffold(body: Center(child: Text('Kuis tidak ditemukan')));
    }
    final m = app.materiById(k.materiId);
    const letters = ['A', 'B', 'C', 'D', 'E'];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            const Text(
              'PORTAL GURU',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final buttonStyle = OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                );

                Widget label(String value) => FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(value, maxLines: 1),
                    );

                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: buttonStyle,
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: label('Kembali'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: buttonStyle,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KuisFormScreen(kuisId: k.id),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: label('Edit Kuis'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SoalFormScreen(kuisId: k.id),
                          ),
                        ),
                        icon: const Icon(Icons.settings_outlined, size: 16),
                        label: label('Kelola Kuis'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Text(
              k.judul,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Detail kuis, jadwal, daftar butir soal, dan publikasi.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            if (!k.isPublished)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFCF2),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFFFFE6A6)),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kuis masih dalam status DRAFT',
                            style: TextStyle(
                              color: Color(0xFF9A6700),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Publikasikan kuis agar siswa dapat melihat dan mengerjakannya.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (k.soal.isEmpty) {
                          showAppToast(
                            context,
                            'Tambahkan minimal satu soal sebelum menerbitkan kuis',
                          );
                          return;
                        }
                        app.setKuisPublished(k.id, true);
                        showAppToast(context, 'Kuis diterbitkan');
                      },
                      child: const Text('Publikasikan'),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.green),
                    SizedBox(width: 8),
                    Text(
                      'Kuis telah diterbitkan',
                      style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Informasi Kuis',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        AppPill(
                          label: k.isPublished ? 'Terbit' : 'Draft',
                          color: k.isPublished
                              ? AppColors.green
                              : AppColors.orange,
                          background: k.isPublished
                              ? AppColors.greenLight
                              : AppColors.orangeLight,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ringkasan konfigurasi dan parameter pengerjaan.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _InfoTile(
                          label: 'Mata Pelajaran',
                          value: m?.mataPelajaran ?? '-',
                        ),
                        _InfoTile(label: 'Kategori', value: k.kategori ?? '-'),
                        _InfoTile(label: 'Tingkat Kesulitan', value: k.level),
                        _InfoTile(label: 'KKM', value: k.kkm.toString()),
                        _InfoTile(
                          label: 'Alokasi Waktu',
                          value: '${k.waktu} Menit',
                        ),
                        _InfoTile(
                          label: 'Tahun Ajaran',
                          value: k.tahunAjaran ?? '-',
                        ),
                      ],
                    ),
                    if ((k.deskripsi ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.purpleLight.withValues(alpha: .35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DESKRIPSI / PETUNJUK',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(k.deskripsi!),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _hapusKuis(context, app, k),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.red,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Hapus Kuis'),
                      ),
                    ),
                  ]),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Materi Terkait',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Bab pembelajaran yang dicakup oleh kuis ini.',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.purpleLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.purple,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          m == null ? 'Belum terkait materi' : m.judul,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (m != null)
                        Text(
                          'Bab: ${m.bab}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionTitle('Butir Soal (${k.soal.length})'),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Pratinjau butir pertanyaan dalam kuis ini.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            if (k.soal.isEmpty)
              const EmptyState(text: 'Belum ada soal pada kuis ini.')
            else
              ...List.generate(k.soal.length, (idx) {
                final s = k.soal[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Soal ${idx + 1}',
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.muted)),
                                if (s.gambar != null)
                                  const Text('🖼 bergambar',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.muted)),
                              ]),
                          const SizedBox(height: 6),
                          AppPill(
                            label: s.jenis,
                            color: AppColors.blue,
                            background: AppColors.blueLight,
                          ),
                          const SizedBox(height: 6),
                          Text(s.pertanyaan,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5)),
                          if (s.gambar != null) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                s.gambar!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                          if (s.jenis == Soal.esai)
                            Text(
                              'Kunci jawaban: ${s.jawabanEsai}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.green,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          else ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: List.generate(s.opsi.length, (i) {
                                final benar = i == s.jawaban;
                                return AppPill(
                                  label: '${letters[i]}. ${s.opsi[i]}',
                                  color:
                                      benar ? AppColors.green : AppColors.muted,
                                  background: benar
                                      ? AppColors.greenLight
                                      : AppColors.bg,
                                );
                              }),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => SoalFormScreen(
                                            kuisId: k.id, index: idx))),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Edit Soal',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.red,
                                    side: const BorderSide(
                                        color: AppColors.redLight)),
                                onPressed: () =>
                                    _hapusSoal(context, app, k.id, idx),
                                icon:
                                    const Icon(Icons.delete_outline, size: 16),
                                label: const Text('Hapus Soal',
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ]),
                        ]),
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => SoalFormScreen(kuisId: k.id))),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Soal'),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.purpleLight.withValues(alpha: .28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
