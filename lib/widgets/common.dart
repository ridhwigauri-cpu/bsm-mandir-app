import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/qr.dart';

/* ---------------- आइकन ---------------- */
const Map<String, IconData> _iconMap = {
  'home': Icons.home_rounded,
  'heart': Icons.favorite_rounded,
  'video': Icons.videocam_rounded,
  'temple': Icons.temple_hindu_rounded,
  'lamp': Icons.local_fire_department_rounded,
  'bed': Icons.bed_rounded,
  'clock': Icons.schedule_rounded,
  'ticket': Icons.confirmation_number_rounded,
  'receipt': Icons.receipt_long_rounded,
  'list': Icons.list_alt_rounded,
  'lock': Icons.lock_outline_rounded,
  'file': Icons.description_rounded,
  'search': Icons.search_rounded,
  'info': Icons.info_outline_rounded,
  'eye': Icons.visibility_rounded,
  'bell': Icons.notifications_active_rounded,
  'play': Icons.play_arrow_rounded,
  'door': Icons.meeting_room_rounded,
  'chart': Icons.bar_chart_rounded,
  'bank': Icons.account_balance_rounded,
  'cash': Icons.payments_rounded,
  'rupee': Icons.currency_rupee_rounded,
  'shield': Icons.security_rounded,
  'alert': Icons.warning_amber_rounded,
  'users': Icons.people_rounded,
  'book': Icons.menu_book_rounded,
  'trend': Icons.trending_up_rounded,
  'camera': Icons.photo_camera_rounded,
  'check': Icons.check_rounded,
  'close': Icons.close_rounded,
  'download': Icons.file_download_rounded,
  'copy': Icons.copy_rounded,
};

class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size = 18, this.color = C.goldDeep});

  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(_iconMap[name] ?? Icons.info_outline_rounded, size: size, color: color);
  }
}

/* ---------------- कार्ड ---------------- */
class BsmCard extends StatelessWidget {
  const BsmCard({
    super.key,
    required this.child,
    this.color = C.paper,
    this.borderColor = C.line,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class CardHead extends StatelessWidget {
  const CardHead({super.key, required this.icon, required this.title, this.trailing});

  final String icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          AppIcon(icon, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(title, style: T.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/* ---------------- बटन ---------------- */
enum BtnKind { gold, dark, ghost }

class BsmButton extends StatelessWidget {
  const BsmButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = BtnKind.gold,
    this.icon,
    this.small = false,
    this.expand = true,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final BtnKind kind;
  final String? icon;
  final bool small;
  final bool expand;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color bg = switch (kind) {
      BtnKind.gold => C.gold,
      BtnKind.dark => C.maroon3,
      BtnKind.ghost => Colors.white,
    };
    final Color fg = switch (kind) {
      BtnKind.gold => C.onGold,
      BtnKind.dark => C.creamText,
      BtnKind.ghost => C.maroon,
    };

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          AppIcon(icon!, size: small ? 14 : 16, color: fg),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            style: small ? T.btnSmall : T.btn,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(small ? 10 : 12),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(small ? 10 : 12),
          child: Container(
            height: small ? 40 : 48,
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: small ? 10 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(small ? 10 : 12),
              border: kind == BtnKind.ghost ? Border.all(color: C.line) : null,
            ),
            child: DefaultTextStyle.merge(style: TextStyle(color: fg), child: content),
          ),
        ),
      ),
    );
  }
}

/* ---------------- चिप ---------------- */
class ChipPill extends StatelessWidget {
  const ChipPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.gold = false,
    this.expand = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;
  final bool gold;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final selBg = gold ? C.gold : C.maroon3;
    final selFg = gold ? C.onGold : C.creamText;

    final chip = Material(
      color: selected ? selBg : Colors.white,
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: selected ? selBg : C.line),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? selFg : C.ink2,
              decoration: enabled ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(right: 7, bottom: 7),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: expand ? SizedBox(width: double.infinity, child: chip) : chip,
      ),
    );
  }
}

/// चिप्स की ग्रिड — लंबी सूची स्क्रीन से बाहर नहीं जाती
class PillGrid extends StatelessWidget {
  const PillGrid({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    this.columns = 2,
    this.gold = false,
    this.enabledFor,
    this.labelFor,
  });

  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelect;
  final int columns;
  final bool gold;
  final bool Function(String item)? enabledFor;
  final String Function(String item)? labelFor;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += columns) {
      final chunk = items.sublist(i, (i + columns).clamp(0, items.length));
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var c = 0; c < columns; c++)
              Expanded(
                child: c < chunk.length
                    ? ChipPill(
                        label: labelFor?.call(chunk[c]) ?? chunk[c],
                        selected: selected == chunk[c],
                        enabled: enabledFor?.call(chunk[c]) ?? true,
                        gold: gold,
                        expand: true,
                        onTap: () => onSelect(chunk[c]),
                      )
                    : const SizedBox(height: 1),
              ),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

/* ---------------- इनपुट ---------------- */
class InputField extends StatelessWidget {
  const InputField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.placeholder = '',
    this.keyboardType,
    this.maxLength = 120,
    this.controller,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? label;
  final String placeholder;
  final TextInputType? keyboardType;
  final int maxLength;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(label!, style: T.label),
          ),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
          style: const TextStyle(fontSize: 14, color: C.ink),
          decoration: InputDecoration(hintText: placeholder),
        ),
      ],
    );
  }
}

/* ---------------- बैज / KV / बार ---------------- */
class BadgeC extends StatelessWidget {
  const BadgeC({super.key, required this.text, this.tone = 'green'});

  final String text;
  final String tone;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      'red' => (C.red2, C.red),
      'blue' => (C.blue2, C.blue),
      'amber' => (C.amber2, C.amber),
      _ => (C.green2, C.green),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class KVRow extends StatelessWidget {
  const KVRow({
    super.key,
    required this.left,
    this.right = '',
    this.badge,
    this.tone = 'green',
    this.bold = false,
    this.divider = true,
  });

  final String left;
  final String right;
  final String? badge;
  final String tone;
  final bool bold;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  left,
                  style: bold
                      ? T.kvLeft.copyWith(color: C.ink, fontWeight: FontWeight.w600)
                      : T.kvLeft,
                ),
              ),
              if (badge != null)
                BadgeC(text: badge!, tone: tone)
              else if (right.isNotEmpty)
                Text(right, style: T.kvRight),
            ],
          ),
        ),
        if (divider) Container(height: 1, color: const Color(0x1A5E0F18)),
      ],
    );
  }
}

class ProgressBarM extends StatelessWidget {
  const ProgressBarM({super.key, required this.value, this.color = C.gold, this.height = 8});

  final int value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fraction = (value.clamp(0, 100)) / 100.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: Container(
        height: height,
        color: const Color(0xFFEFE2D2),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: fraction,
          child: Container(color: color),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, this.tag, required this.title, this.light = false});

  final String? tag;
  final String title;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (tag != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: light ? C.amber2 : const Color(0x24E8B54A),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: const Color(0x4DE8B54A)),
              ),
              child: Text(
                tag!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: light ? C.amber : C.gold2,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: light ? C.maroon : C.creamText,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: light ? const Color(0x265E0F18) : const Color(0x47E8B54A),
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------------- QR ---------------- */
class QrView extends StatelessWidget {
  const QrView({super.key, required this.value, this.side = 104});

  final String value;
  final double side;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: side,
      height: side,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.line),
      ),
      child: CustomPaint(painter: _QrPainter(qrMatrix(value)), size: Size.square(side)),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.matrix);

  final List<List<bool>> matrix;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = C.ink;
    final n = matrix.length;
    final cell = size.width / n;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (matrix[y][x]) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) => oldDelegate.matrix != matrix;
}

/* ---------------- टेक्स्ट हेल्पर ---------------- */
class MutedText extends StatelessWidget {
  const MutedText(this.text, {super.key, this.textAlign, this.color = C.ink3, this.size = 11});

  final String text;
  final TextAlign? textAlign;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(fontSize: size, color: color, height: 1.5),
    );
  }
}

class OkLine extends StatelessWidget {
  const OkLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const AppIcon('check', size: 14, color: C.green),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: C.green, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class SoftStrip extends StatelessWidget {
  const SoftStrip(this.text, {super.key, this.icon = 'check'});

  final String text;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 11),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: C.amber2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x80E8B54A)),
      ),
      child: Row(
        children: [
          AppIcon(icon, size: 13, color: const Color(0xFF6B4E12)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B4E12),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeroBlock extends StatelessWidget {
  const HeroBlock({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [C.maroon2, C.maroon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x66E8B54A)),
      ),
      child: child,
    );
  }
}

/* ---------------- स्क्रीन बेस ---------------- */
class BsmScreen extends StatelessWidget {
  const BsmScreen({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 11),
        ],
      ],
    );
  }
}

/* ---------------- टोस्ट ---------------- */
void showToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: const Duration(milliseconds: 2400),
        backgroundColor: C.ink,
      ),
    );
}

/// बॉटम शीट (पेमेंट गेटवे जैसे ब्लॉक के लिए)
Future<T?> showBsmSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(18), child: child),
      ),
    ),
  );
}
