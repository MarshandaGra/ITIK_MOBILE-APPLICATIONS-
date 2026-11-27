import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/materi.dart';
import '../models/mapel_option.dart';
import '../theme/app_theme.dart';

class MapelSelectionList extends StatelessWidget {
  const MapelSelectionList({
    super.key,
    required this.mapelOptions,
    required this.counts,
    required this.itemLabel,
    required this.onSelect,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.detailBuilder,
  });

  final List<MapelOption> mapelOptions;
  final Map<String, int> counts;
  final String itemLabel;
  final ValueChanged<MapelOption> onSelect;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String Function(MapelOption mapel, int count)? detailBuilder;

  @override
  Widget build(BuildContext context) {
    if (mapelOptions.isEmpty) {
      return const EmptyState(text: 'Belum ada mata pelajaran yang tersedia.');
    }

    return Column(
      children: mapelOptions.map((mapel) {
        final count = counts[mapel.id] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SubjectSelectionCard(
            mapel: mapel,
            detail: detailBuilder?.call(mapel, count) ??
                '$count $itemLabel tersedia',
            icon: icon,
            onTap: () => onSelect(mapel),
          ),
        );
      }).toList(),
    );
  }
}

class MapelBackButton extends StatelessWidget {
  const MapelBackButton({
    super.key,
    required this.onPressed,
    this.compact = true,
  });

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: AppCompactActionButton(
        label: 'Pilih mata pelajaran lain',
        icon: Icons.arrow_back_rounded,
        alignment: Alignment.centerRight,
        backgroundColor: AppColors.purpleLight,
        foregroundColor: AppColors.purple,
        borderColor: AppColors.purple.withValues(alpha: 0.18),
        compact: compact,
        onPressed: onPressed,
      ),
    );
  }
}

class AppCompactActionButton extends StatelessWidget {
  const AppCompactActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.alignment,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final AlignmentGeometry alignment;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: compact ? 16 : 18),
      label: Text(
        label,
        maxLines: compact ? 1 : null,
        overflow: compact ? TextOverflow.ellipsis : null,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        side: BorderSide(color: borderColor),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 16,
          vertical: compact ? 8 : 10,
        ),
        textStyle: TextStyle(fontSize: compact ? 11 : 14),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );

    return Align(
      alignment: alignment,
      widthFactor: compact ? 1 : null,
      child: compact
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: button,
            )
          : button,
    );
  }
}

class SubjectSummaryBanner extends StatelessWidget {
  const SubjectSummaryBanner({
    super.key,
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF765CF6), Color(0xFF5943E5)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(17),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SubjectSelectionCard extends StatelessWidget {
  const SubjectSelectionCard({
    super.key,
    required this.mapel,
    required this.detail,
    required this.icon,
    required this.onTap,
  });

  final MapelOption mapel;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF9F7FF),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 210,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.purple, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.purple.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.purpleLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.purple, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                mapel.kode.isNotEmpty ? mapel.kode : mapel.id,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mapel.nama,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.purple,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MateriSelectionCard extends StatelessWidget {
  const MateriSelectionCard({
    super.key,
    required this.materi,
    this.onTap,
    this.icon = Icons.menu_book_rounded,
    this.badges = const [],
    this.footer,
    this.footerAction,
    this.actions,
  });

  final Materi materi;
  final VoidCallback? onTap;
  final IconData icon;
  final List<Widget> badges;
  final String? footer;
  final Widget? footerAction;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.purpleLight,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.purple, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (materi.bab.isNotEmpty) ...[
                      AppPill(
                        label: materi.bab,
                        color: AppColors.purple,
                        background: AppColors.purpleLight,
                      ),
                      const SizedBox(height: 7),
                    ],
                    Text(
                      materi.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (materi.deskripsi.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              materi.deskripsi,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 7, runSpacing: 6, children: badges),
          ],
          const Divider(height: 24),
          if (footer != null || footerAction != null)
            Row(
              children: [
                if (footer != null)
                  Expanded(
                    child: Text(
                      footer!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.purple,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (footerAction != null) footerAction!,
              ],
            ),
          if (actions != null) ...[
            if (footer != null || footerAction != null)
              const SizedBox(height: 6),
            actions!,
          ],
        ],
      ),
    );
  }
}

/// Setara `.list-item` pada desain: baris ikon + judul + subjudul + chevron.
class AppListItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppListItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.muted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 6),
            trailing ??
                const Icon(Icons.chevron_right,
                    color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// AppBar sederhana dengan tombol kembali, setara `backHeader()`.
PreferredSizeWidget simpleAppBar(String title, {List<Widget>? actions}) {
  return AppBar(title: Text(title), actions: actions);
}

/// Kotak notifikasi kuning untuk info remedial, setara `.notice-box` / `.remedial-box`.
class NoticeBox extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final Color background;
  final Color borderColor;
  final Widget? action;

  const NoticeBox({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.error_outline,
    this.color = const Color(0xFFB9701C),
    this.background = const Color(0xFFFFF1E2),
    this.borderColor = const Color(0xFFFCE3B8),
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
          const SizedBox(height: 6),
          Text(message,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.5, color: Color(0xFF5B4A2E))),
          if (action != null) ...[const SizedBox(height: 10), action!],
        ],
      ),
    );
  }
}

/// Tampilan kosong (empty state), setara `.empty`.
class EmptyState extends StatelessWidget {
  final String text;
  const EmptyState({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
      ),
    );
  }
}

/// Section title dengan link opsional di kanan, setara `.section-title`.
class SectionTitle extends StatelessWidget {
  final String title;
  final String? linkText;
  final VoidCallback? onLinkTap;
  const SectionTitle(this.title, {super.key, this.linkText, this.onLinkTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
          if (linkText != null)
            GestureDetector(
              onTap: onLinkTap,
              child: Text(linkText!,
                  style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5)),
            ),
        ],
      ),
    );
  }
}

/// Dialog konfirmasi kustom, setara `askConfirm()` pada prototipe.
Future<bool> confirmDialog(BuildContext context, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadius)),
      content:
          Text(message, style: const TextStyle(fontSize: 13.5, height: 1.55)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Ya, Lanjutkan'),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showAppToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ),
  );
}

Future<void> openPdfUrl(BuildContext context, String? url) async {
  await openExternalUrl(context, url, contentName: 'PDF');
}

Future<void> openExternalUrl(
  BuildContext context,
  String? url, {
  required String contentName,
}) async {
  final uri = Uri.tryParse(url ?? '');
  if (uri == null ||
      !['http', 'https'].contains(uri.scheme) ||
      uri.host.isEmpty) {
    showAppToast(context, 'URL $contentName tidak tersedia atau tidak valid.');
    return;
  }

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      showAppToast(context, '$contentName tidak dapat dibuka.');
    }
  } on PlatformException catch (error) {
    if (context.mounted) {
      showAppToast(
          context, 'Gagal membuka $contentName: ${error.message ?? 'error'}');
    }
  }
}

String fmtWaktu(int detik) {
  final d = detik.clamp(0, 1 << 30);
  final m = d ~/ 60;
  final s = d % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
