import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'games.dart';
import 'profile.dart';

/// ───────── ডিজাইন টোকেন ─────────
class AC {
  static const bg0 = Color(0xFF080420);
  static const bg1 = Color(0xFF170A4A);
  static const bg2 = Color(0xFF38108C);
  static const violet = Color(0xFF7C4DFF);
  static const pink = Color(0xFFFF4081);
  static const gold = Color(0xFFFFC83D);
  static const gold2 = Color(0xFFFF9F1C);
  static const cyan = Color(0xFF22D3EE);
  static const green = Color(0xFF2EE66B);
  static const green2 = Color(0xFF12A84A);
  static const blue = Color(0xFF3B82F6);
  static const goldGrad = [Color(0xFFFFE27A), Color(0xFFFF9F1C)];
  static const greenGrad = [Color(0xFF5CF28A), Color(0xFF0FA044)];
  static const violetGrad = [Color(0xFFA78BFF), Color(0xFF5B2BD6)];
  static const pinkGrad = [Color(0xFFFF7BB0), Color(0xFFD81B60)];
}

Color lighten(Color c, [double a = .3]) => Color.lerp(c, Colors.white, a)!;
Color darken(Color c, [double a = .3]) => Color.lerp(c, Colors.black, a)!;

String fmt(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return (n < 0 ? '-' : '') + b.toString();
}

String bnNum(int n) {
  const d = '০১২৩৪৫৬৭৮৯';
  return n.toString().split('').map((c) {
    final i = int.tryParse(c);
    return i == null ? c : d[i];
  }).join();
}

void tick() {
  if (Profile.haptic) HapticFeedback.selectionClick();
}

/// প্রতিটি গেমের নিজস্ব আধুনিক গ্রেডিয়েন্ট
List<Color> gameGrad(GameInfo g) {
  switch (g.id) {
    case 'ludo': return const [Color(0xFF9B6BFF), Color(0xFF5B2BD6)];
    case 'snake': return const [Color(0xFF2BD96B), Color(0xFF0B8F3F)];
    case 'chess': return const [Color(0xFF4F9BFF), Color(0xFF1E4FD8)];
    case 'carrom': return const [Color(0xFFFFA24C), Color(0xFFE5580C)];
    case 'gutti16': return const [Color(0xFFFF5C8A), Color(0xFFD1204F)];
    case 'gutti12': return const [Color(0xFFFF6BC1), Color(0xFF8E2DE2)];
    case 'gutti8': return const [Color(0xFFB36BFF), Color(0xFF5A2DD6)];
    case 'baghbakri': return const [Color(0xFFFFB347), Color(0xFFD9730D)];
    case 'kori': return const [Color(0xFF22D3EE), Color(0xFF0B79B8)];
    case 'pasha': return const [Color(0xFFE15BC0), Color(0xFF8E2DA8)];
    case 'hazari': return const [Color(0xFF5B8CFF), Color(0xFF2B3FD6)];
    case 'card29': return const [Color(0xFF3FA7B8), Color(0xFF14566B)];
    case 'rang': return const [Color(0xFFFF5A5F), Color(0xFFB8202E)];
    case 'solitaire': return const [Color(0xFF3FBF8F), Color(0xFF0F6B55)];
    case 'spades': return const [Color(0xFF8A94A6), Color(0xFF2E3440)];
  }
  return g.colors;
}

List<Offset> pipPos(int v) {
  const a = .27, b = .5, c = .73;
  switch (v) {
    case 1: return const [Offset(b, b)];
    case 2: return const [Offset(a, a), Offset(c, c)];
    case 3: return const [Offset(a, a), Offset(b, b), Offset(c, c)];
    case 4: return const [Offset(a, a), Offset(c, a), Offset(a, c), Offset(c, c)];
    case 5: return const [Offset(a, a), Offset(c, a), Offset(b, b), Offset(a, c), Offset(c, c)];
    default: return const [Offset(a, a), Offset(c, a), Offset(a, b), Offset(c, b), Offset(a, c), Offset(c, c)];
  }
}

/// ───────── অ্যানিমেটেড ব্যাকগ্রাউন্ড ─────────
class ArenaBg extends StatefulWidget {
  final Widget child;
  final bool floaters;
  const ArenaBg({super.key, required this.child, this.floaters = true});
  @override
  State<ArenaBg> createState() => _ArenaBgState();
}

class _ArenaBgState extends State<ArenaBg> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AC.bg2, AC.bg1, AC.bg0],
                stops: [0, .45, 1]),
          ),
        ),
        Positioned(
          top: -120,
          right: -90,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AC.violet.withOpacity(.35), Colors.transparent])),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -100,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AC.pink.withOpacity(.22), Colors.transparent])),
          ),
        ),
        if (widget.floaters)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) => CustomPaint(painter: _FloatPainter(_c.value), size: Size.infinite),
            ),
          ),
        widget.child,
      ]);
}

class _FloatPainter extends CustomPainter {
  final double t;
  _FloatPainter(this.t);
  static final _stars = () {
    final r = math.Random(11);
    return List.generate(34, (_) => [r.nextDouble(), r.nextDouble(), r.nextDouble() * 1.5 + .6, r.nextDouble()]);
  }();
  static const _dice = [
    [.08, .14, 30.0, 0.0, 5.0],
    [.88, .09, 38.0, .3, 3.0],
    [.93, .38, 24.0, .6, 6.0],
    [.05, .52, 28.0, .15, 2.0],
    [.84, .72, 34.0, .8, 4.0],
    [.14, .88, 26.0, .45, 1.0],
  ];
  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    for (final st in _stars) {
      final tw = .35 + .65 * (.5 + .5 * math.sin((t + st[3]) * math.pi * 2 * 3));
      p.color = Colors.white.withOpacity(.55 * tw);
      c.drawCircle(Offset(st[0] * s.width, st[1] * s.height), st[2], p);
    }
    for (final d in _dice) {
      final ph = d[3];
      final dy = math.sin((t + ph) * math.pi * 2) * 12;
      final z = d[2];
      c.save();
      c.translate(d[0] * s.width, d[1] * s.height + dy);
      c.rotate((t + ph) * math.pi * 2);
      final rr = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: z, height: z), Radius.circular(z * .28));
      c.drawRRect(rr, Paint()..color = Colors.white.withOpacity(.06));
      c.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..color = Colors.white.withOpacity(.16));
      for (final o in pipPos(d[4].toInt())) {
        c.drawCircle(Offset((o.dx - .5) * z, (o.dy - .5) * z), z * .06, Paint()..color = Colors.white.withOpacity(.16));
      }
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_FloatPainter o) => o.t != t;
}

/// ───────── গ্লাস কার্ড ─────────
class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<Color>? colors;
  final Color? borderColor;
  final VoidCallback? onTap;
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 22,
    this.colors,
    this.borderColor,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final deco = BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ?? [Colors.white.withOpacity(.14), Colors.white.withOpacity(.05)]),
      border: Border.all(color: borderColor ?? Colors.white.withOpacity(.16)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(.28), blurRadius: 18, offset: const Offset(0, 8))],
    );
    final inner = Padding(padding: padding, child: child);
    if (onTap == null) return Container(decoration: deco, child: inner);
    return Container(
      decoration: deco,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: () {
            tick();
            onTap!();
          },
          child: inner,
        ),
      ),
    );
  }
}

/// ───────── গ্লসি বাটন ─────────
class GlossBtn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final List<Color> colors;
  final IconData? icon;
  final double height, fontSize;
  final Color textColor;
  final bool wide;
  const GlossBtn(
    this.label, {
    super.key,
    this.onTap,
    this.colors = AC.violetGrad,
    this.icon,
    this.height = 54,
    this.fontSize = 18,
    this.textColor = Colors.white,
    this.wide = true,
  });
  @override
  State<GlossBtn> createState() => _GlossBtnState();
}

class _GlossBtnState extends State<GlossBtn> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final on = widget.onTap != null;
    final cols = on ? widget.colors : [Colors.grey.shade600, Colors.grey.shade800];
    return GestureDetector(
      onTapDown: on ? (_) => setState(() => down = true) : null,
      onTapUp: on ? (_) => setState(() => down = false) : null,
      onTapCancel: on ? () => setState(() => down = false) : null,
      onTap: on
          ? () {
              tick();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: down ? .95 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          height: widget.height,
          padding: EdgeInsets.symmetric(horizontal: widget.wide ? 18 : 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height),
            gradient: LinearGradient(colors: cols, begin: Alignment.topCenter, end: Alignment.bottomCenter),
            border: Border.all(color: Colors.white.withOpacity(.45), width: 1.4),
            boxShadow: [BoxShadow(color: cols.last.withOpacity(on ? .55 : 0), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Stack(alignment: Alignment.center, children: [
            Positioned(
              left: 8,
              right: 8,
              top: 2,
              height: widget.height * .4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.height),
                  gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(.4), Colors.white.withOpacity(0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter),
                ),
              ),
            ),
            Row(
              mainAxisSize: widget.wide ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: widget.textColor, size: widget.fontSize + 4),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: widget.textColor,
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: Colors.black.withOpacity(.25), blurRadius: 4, offset: const Offset(0, 1))])),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

class ChevBtn extends StatelessWidget {
  final double size;
  const ChevBtn({super.key, this.size = 30});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(.28),
          border: Border.all(color: Colors.white.withOpacity(.7), width: 1.6),
        ),
        child: Icon(Icons.chevron_right_rounded, color: Colors.white, size: size * .75),
      );
}

class CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badge;
  const CircleBtn(this.icon, this.onTap, {super.key, this.badge = 0});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          tick();
          onTap();
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.1),
                border: Border.all(color: Colors.white.withOpacity(.18)),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            if (badge > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFF3B5C)),
                  child: Text('$badge', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ),
          ]),
        ),
      );
}

class ArenaBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  const ArenaBar(this.title, {super.key, this.onBack, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        child: Row(children: [
          onBack == null ? const SizedBox(width: 44) : CircleBtn(Icons.arrow_back_rounded, onBack!),
          Expanded(
            child: Center(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            ),
          ),
          trailing ?? const SizedBox(width: 44),
        ]),
      );
}

InputDecoration arenaInput(String hint, {IconData? icon}) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(.4)),
      prefixIcon: icon == null ? null : Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: Colors.black.withOpacity(.25),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AC.gold, width: 1.6)),
    );

class StrokeText extends StatelessWidget {
  final String t;
  final double size;
  final Color fill, stroke;
  final double sw;
  const StrokeText(this.t, {super.key, required this.size, this.fill = Colors.white, this.stroke = const Color(0xFF1B0B52), this.sw = 6});
  @override
  Widget build(BuildContext context) => Stack(children: [
        Text(t,
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                height: 1.15,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = sw
                  ..strokeJoin = StrokeJoin.round
                  ..color = stroke)),
        Text(t,
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w900,
                height: 1.15,
                color: fill,
                shadows: [Shadow(color: Colors.black.withOpacity(.35), blurRadius: 8, offset: const Offset(0, 4))])),
      ]);
}

/// ───────── কয়েন / লেভেল চিপ ─────────
class Coin extends StatelessWidget {
  final double size;
  const Coin({super.key, this.size = 26});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(center: Alignment(-.3, -.4), colors: [Color(0xFFFFF0A0), Color(0xFFFFB800), Color(0xFFD97A00)]),
          border: Border.all(color: const Color(0xFFFFE27A), width: size * .07),
          boxShadow: [BoxShadow(color: AC.gold.withOpacity(.5), blurRadius: size * .35)],
        ),
        child: Center(child: Icon(Icons.star_rounded, color: const Color(0xFFB86B00), size: size * .62)),
      );
}

class CoinChip extends StatelessWidget {
  final VoidCallback? onAdd;
  const CoinChip({super.key, this.onAdd});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: Profile.rev,
        builder: (_, __, ___) => Glass(
          radius: 30,
          padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
          child: Row(children: [
            const Coin(size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(fmt(Profile.coins), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              ),
            ),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: AC.greenGrad, begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
              ),
            ),
          ]),
        ),
      );
}

class LevelChip extends StatelessWidget {
  const LevelChip({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: Profile.rev,
        builder: (_, __, ___) => Glass(
          radius: 30,
          padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
          child: Row(children: [
            const Icon(Icons.star_rounded, color: AC.gold, size: 30),
            const SizedBox(width: 6),
            Text('Lv.${Profile.level}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: Profile.levelProgress,
                  minHeight: 7,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(AC.gold),
                ),
              ),
            ),
          ]),
        ),
      );
}

/// ───────── ৩D ডাইস ─────────
class Dice3D extends StatelessWidget {
  final double size;
  final int top, left, right;
  const Dice3D({super.key, this.size = 120, this.top = 5, this.left = 3, this.right = 4});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _DicePainter(top, left, right)));
}

class _DicePainter extends CustomPainter {
  final int top, left, right;
  _DicePainter(this.top, this.left, this.right);
  @override
  void paint(Canvas c, Size s) {
    final r = s.width / 2 * .86;
    final o = Offset(s.width / 2, s.height / 2);
    Offset p(double x, double y) => Offset(o.dx + x * r, o.dy + y * r);
    final t = p(0, -1), ur = p(.866, -.5), lr = p(.866, .5), b = p(0, 1), ll = p(-.866, .5), ul = p(-.866, -.5);

    c.drawOval(
        Rect.fromCenter(center: Offset(o.dx, o.dy + r * 1.12), width: r * 1.7, height: r * .3),
        Paint()
          ..color = Colors.black.withOpacity(.4)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .12));

    void face(List<Offset> pts, List<Color> cols) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (var i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      path.close();
      final sh = LinearGradient(colors: cols, begin: Alignment.topLeft, end: Alignment.bottomRight)
          .createShader(path.getBounds());
      c.drawPath(path, Paint()..shader = sh);
      c.drawPath(
          path,
          Paint()
            ..shader = sh
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * .1
            ..strokeJoin = StrokeJoin.round);
    }

    face([ul, t, ur, o], const [Color(0xFFFFFFFF), Color(0xFFF1EEFF)]);
    face([ul, o, b, ll], const [Color(0xFFE6E2F7), Color(0xFFBDB5E3)]);
    face([o, ur, lr, b], const [Color(0xFFCFC8EE), Color(0xFF9A8FD0)]);

    final edge = Paint()
      ..color = const Color(0xFF8B7FC8).withOpacity(.45)
      ..strokeWidth = r * .025
      ..strokeCap = StrokeCap.round;
    c.drawLine(o, ul, edge);
    c.drawLine(o, ur, edge);
    c.drawLine(o, b, edge);

    void pips(Offset origin, Offset u, Offset v, int val) {
      c.save();
      c.transform(Float64List.fromList([u.dx, u.dy, 0, 0, v.dx, v.dy, 0, 0, 0, 0, 1, 0, origin.dx, origin.dy, 0, 1]));
      for (final q in pipPos(val)) {
        c.drawCircle(q, .105, Paint()..color = const Color(0xFF16102E));
        c.drawCircle(Offset(q.dx - .03, q.dy - .03), .03, Paint()..color = Colors.white.withOpacity(.35));
      }
      c.restore();
    }

    pips(ul, t - ul, o - ul, top);
    pips(ul, o - ul, ll - ul, left);
    pips(ur, o - ur, lr - ur, right);
  }

  @override
  bool shouldRepaint(_DicePainter o) => o.top != top || o.left != left || o.right != right;
}

/// ───────── মুকুট ─────────
class Crown extends StatelessWidget {
  final double w;
  const Crown(this.w, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(width: w, height: w * .8, child: CustomPaint(painter: _CrownPainter()));
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final body = Path()
      ..moveTo(w * .06, h * .88)
      ..lineTo(w * .0, h * .24)
      ..lineTo(w * .27, h * .52)
      ..lineTo(w * .5, h * .1)
      ..lineTo(w * .73, h * .52)
      ..lineTo(w * 1.0, h * .24)
      ..lineTo(w * .94, h * .88)
      ..close();
    final rect = Rect.fromLTWH(0, 0, w, h);
    final sh = const LinearGradient(colors: [Color(0xFFFFF0A0), Color(0xFFFFB800), Color(0xFFE08500)], begin: Alignment.topCenter, end: Alignment.bottomCenter)
        .createShader(rect);
    c.drawPath(body, Paint()..shader = sh);
    c.drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .025
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFB86B00));
    final band = RRect.fromRectAndRadius(Rect.fromLTWH(w * .05, h * .78, w * .9, h * .17), Radius.circular(h * .08));
    c.drawRRect(band, Paint()..shader = const LinearGradient(colors: [Color(0xFFFFD34D), Color(0xFFD97A00)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(rect));
    c.drawRRect(
        band,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .02
          ..color = const Color(0xFFB86B00));
    void gem(double x, double y, Color col, double r) {
      c.drawCircle(Offset(w * x, h * y), r, Paint()..color = col);
      c.drawCircle(Offset(w * x - r * .3, h * y - r * .3), r * .35, Paint()..color = Colors.white.withOpacity(.7));
    }

    gem(.5, .6, const Color(0xFFFF3B5C), w * .06);
    gem(.27, .7, const Color(0xFF3B82F6), w * .045);
    gem(.73, .7, const Color(0xFF2EE66B), w * .045);
    for (final pt in const [Offset(.02, .2), Offset(.5, .07), Offset(.98, .2)]) {
      c.drawCircle(Offset(w * pt.dx, h * pt.dy), w * .06, Paint()..color = const Color(0xFFFFF3B0));
      c.drawCircle(
          Offset(w * pt.dx, h * pt.dy),
          w * .06,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * .02
            ..color = const Color(0xFFB86B00));
    }
  }

  @override
  bool shouldRepaint(_CrownPainter o) => false;
}

/// ───────── লুডু গুটি ─────────
class Pawn extends StatelessWidget {
  final Color color;
  final double size;
  const Pawn(this.color, {super.key, this.size = 48});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size * 1.25, child: CustomPaint(painter: _PawnPainter(color)));
}

class _PawnPainter extends CustomPainter {
  final Color col;
  _PawnPainter(this.col);
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final sh = LinearGradient(colors: [lighten(col, .45), col, darken(col, .25)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(rect);
    c.drawOval(
        Rect.fromCenter(center: Offset(w * .5, h * .93), width: w * .95, height: h * .13),
        Paint()
          ..color = Colors.black.withOpacity(.35)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .04));
    final base = Rect.fromCenter(center: Offset(w * .5, h * .86), width: w * .86, height: h * .15);
    c.drawOval(base, Paint()..shader = sh);
    final body = Path()
      ..moveTo(w * .14, h * .86)
      ..quadraticBezierTo(w * .34, h * .56, w * .36, h * .46)
      ..lineTo(w * .64, h * .46)
      ..quadraticBezierTo(w * .66, h * .56, w * .86, h * .86)
      ..close();
    c.drawPath(body, Paint()..shader = sh);
    c.drawCircle(Offset(w * .5, h * .3), w * .24, Paint()..shader = sh);
    c.drawOval(Rect.fromCenter(center: Offset(w * .42, h * .22), width: w * .14, height: w * .1), Paint()..color = Colors.white.withOpacity(.55));
  }

  @override
  bool shouldRepaint(_PawnPainter o) => o.col != col;
}

/// ───────── হাসিমুখ ক্যারেক্টার ─────────
class Face extends StatelessWidget {
  final Color color;
  final double size;
  const Face(this.color, {super.key, this.size = 56});
  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size * 1.1, child: CustomPaint(painter: _FacePainter(color)));
}

class _FacePainter extends CustomPainter {
  final Color col;
  _FacePainter(this.col);
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final body = RRect.fromRectAndCorners(Rect.fromLTWH(w * .06, h * .62, w * .88, h * .38),
        topLeft: Radius.circular(w * .42), topRight: Radius.circular(w * .42), bottomLeft: Radius.circular(w * .1), bottomRight: Radius.circular(w * .1));
    c.drawRRect(body, Paint()..shader = LinearGradient(colors: [col, darken(col, .3)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(body.outerRect));
    final hc = Offset(w * .5, h * .38);
    final hr = w * .36;
    c.drawCircle(hc, hr, Paint()..shader = RadialGradient(center: const Alignment(-.3, -.4), colors: [lighten(col, .4), col, darken(col, .15)]).createShader(Rect.fromCircle(center: hc, radius: hr)));
    for (final dx in [-.12, .12]) {
      final e = Offset(w * (.5 + dx), h * .35);
      c.drawOval(Rect.fromCenter(center: e, width: w * .1, height: w * .13), Paint()..color = Colors.white);
      c.drawCircle(e.translate(0, w * .01), w * .035, Paint()..color = const Color(0xFF1A1033));
    }
    c.drawArc(
        Rect.fromCenter(center: Offset(w * .5, h * .42), width: w * .28, height: w * .2),
        .2,
        math.pi - .4,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .035
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF1A1033));
    c.drawOval(Rect.fromCenter(center: Offset(w * .36, h * .2), width: w * .16, height: w * .08), Paint()..color = Colors.white.withOpacity(.35));
  }

  @override
  bool shouldRepaint(_FacePainter o) => o.col != col;
}

class FaceCluster extends StatelessWidget {
  final List<Color> colors;
  final double size;
  const FaceCluster(this.colors, {super.key, this.size = 56});
  @override
  Widget build(BuildContext context) {
    final step = size * .62;
    return SizedBox(
      width: size + step * (colors.length - 1),
      height: size * 1.1,
      child: Stack(children: [
        for (var i = colors.length - 1; i >= 0; i--) Positioned(left: step * i, child: Face(colors[i], size: size)),
      ]),
    );
  }
}

/// ───────── গেম আইকন বাবল ─────────
class IconBubble extends StatelessWidget {
  final String emoji;
  final double size;
  const IconBubble(this.emoji, {super.key, this.size = 52});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(center: const Alignment(-.3, -.4), colors: [Colors.white.withOpacity(.55), Colors.white.withOpacity(.12)]),
          border: Border.all(color: Colors.white.withOpacity(.4)),
        ),
        child: Text(emoji, style: TextStyle(fontSize: size * .55, height: 1)),
      );
}
