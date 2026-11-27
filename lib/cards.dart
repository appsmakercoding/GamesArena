import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'ui.dart';

const kSym = ['♠', '♥', '♦', '♣'];
bool isRed(int s) => s == 1 || s == 2;

class PC {
  final int s, r; // suit 0-3, rank 2..14 (A=14) ; solitaire uses A=1
  const PC(this.s, this.r);
}

String rankLabel(int r) => r == 1 || r == 14 ? 'A' : r == 11 ? 'J' : r == 12 ? 'Q' : r == 13 ? 'K' : '$r';

/// রঙ (সুট) এর আকার আঁকা — ফন্টের ওপর নির্ভর করে না
Path suitPath(int s, Rect b) {
  final path = Path();
  Offset p(double x, double y) => Offset(b.left + x * b.width, b.top + y * b.height);
  void m(double x, double y) { final o = p(x, y); path.moveTo(o.dx, o.dy); }
  void l(double x, double y) { final o = p(x, y); path.lineTo(o.dx, o.dy); }
  void c3(double a, double b1, double c, double d, double e, double f) {
    final o1 = p(a, b1), o2 = p(c, d), o3 = p(e, f);
    path.cubicTo(o1.dx, o1.dy, o2.dx, o2.dy, o3.dx, o3.dy);
  }
  void q(double a, double b1, double c, double d) {
    final o1 = p(a, b1), o2 = p(c, d);
    path.quadraticBezierTo(o1.dx, o1.dy, o2.dx, o2.dy);
  }

  switch (s) {
    case 1: // ♥
      m(.5, .94);
      c3(.1, .64, 0, .38, .12, .2);
      c3(.24, .02, .46, .1, .5, .3);
      c3(.54, .1, .76, .02, .88, .2);
      c3(1, .38, .9, .64, .5, .94);
      path.close();
      break;
    case 2: // ♦
      m(.5, .02);
      q(.62, .38, .92, .5);
      q(.62, .62, .5, .98);
      q(.38, .62, .08, .5);
      q(.38, .38, .5, .02);
      path.close();
      break;
    case 0: // ♠
      m(.5, .04);
      c3(.9, .36, 1, .58, .88, .74);
      c3(.76, .92, .54, .86, .5, .66);
      c3(.52, .82, .58, .9, .66, .98);
      l(.34, .98);
      c3(.42, .9, .48, .82, .5, .66);
      c3(.46, .86, .24, .92, .12, .74);
      c3(0, .58, .1, .36, .5, .04);
      path.close();
      break;
    default: // ♣
      path.addOval(Rect.fromCircle(center: p(.5, .27), radius: b.width * .235));
      path.addOval(Rect.fromCircle(center: p(.26, .6), radius: b.width * .235));
      path.addOval(Rect.fromCircle(center: p(.74, .6), radius: b.width * .235));
      m(.5, .5);
      l(.36, .98);
      l(.64, .98);
      path.close();
  }
  return path;
}

class SuitIcon extends StatelessWidget {
  final int s;
  final double size;
  final Color? color;
  const SuitIcon(this.s, {super.key, this.size = 24, this.color});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _SuitPainter(s, color ?? (isRed(s) ? const Color(0xFFD7263D) : const Color(0xFF1A1A2E)))),
      );
}

class _SuitPainter extends CustomPainter {
  final int s;
  final Color col;
  _SuitPainter(this.s, this.col);
  @override
  void paint(Canvas c, Size z) => c.drawPath(suitPath(s, Offset.zero & z), Paint()..color = col);
  @override
  bool shouldRepaint(_SuitPainter o) => o.s != s || o.col != col;
}

const _pips = {
  2: [[.5, 0.0], [.5, 1.0]],
  3: [[.5, 0.0], [.5, .5], [.5, 1.0]],
  4: [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0], [1.0, 1.0]],
  5: [[0.0, 0.0], [1.0, 0.0], [.5, .5], [0.0, 1.0], [1.0, 1.0]],
  6: [[0.0, 0.0], [1.0, 0.0], [0.0, .5], [1.0, .5], [0.0, 1.0], [1.0, 1.0]],
  7: [[0.0, 0.0], [1.0, 0.0], [.5, .25], [0.0, .5], [1.0, .5], [0.0, 1.0], [1.0, 1.0]],
  8: [[0.0, 0.0], [1.0, 0.0], [.5, .25], [0.0, .5], [1.0, .5], [.5, .75], [0.0, 1.0], [1.0, 1.0]],
  9: [[0.0, 0.0], [1.0, 0.0], [0.0, .333], [1.0, .333], [.5, .5], [0.0, .667], [1.0, .667], [0.0, 1.0], [1.0, 1.0]],
  10: [[0.0, 0.0], [1.0, 0.0], [.5, .167], [0.0, .333], [1.0, .333], [0.0, .667], [1.0, .667], [.5, .833], [0.0, 1.0], [1.0, 1.0]],
};

class _FacePainter extends CustomPainter {
  final PC c;
  final bool dim;
  _FacePainter(this.c, this.dim);

  void _text(Canvas cv, String t, double size, Color col, Offset center) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: col, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(cv, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _suit(Canvas cv, Offset center, double size, Color col, {bool flip = false}) {
    cv.save();
    cv.translate(center.dx, center.dy);
    if (flip) cv.rotate(math.pi);
    cv.drawPath(suitPath(c.s, Rect.fromCenter(center: Offset.zero, width: size, height: size)), Paint()..color = col);
    cv.restore();
  }

  void _index(Canvas cv, double w, double h, Color col) {
    final label = rankLabel(c.r);
    _text(cv, label, w * (label.length > 1 ? .25 : .3), col, Offset(w * .17, h * .1));
    _suit(cv, Offset(w * .17, h * .1 + w * .24), w * .2, col);
  }

  void _crown(Canvas cv, Rect r, int points) {
    final p = Path()..moveTo(r.left, r.bottom);
    p.lineTo(r.left, r.top + r.height * .35);
    for (var i = 0; i < points; i++) {
      final x0 = r.left + r.width * i / points, x1 = r.left + r.width * (i + .5) / points, x2 = r.left + r.width * (i + 1) / points;
      p.lineTo(x1, r.top);
      p.lineTo(x2, r.top + r.height * .35);
      if (x0 < 0) p.lineTo(x0, r.top);
    }
    p.lineTo(r.right, r.bottom);
    p.close();
    cv.drawPath(p, Paint()..shader = const LinearGradient(colors: [Color(0xFFFFE27A), Color(0xFFE59A12)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(r));
    cv.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = r.width * .04..strokeJoin = StrokeJoin.round..color = const Color(0xFF8A5A00));
  }

  @override
  void paint(Canvas cv, Size s) {
    final w = s.width, h = s.height;
    final col = isRed(c.s) ? const Color(0xFFD7263D) : const Color(0xFF1A1A2E);
    final full = Offset.zero & s;
    cv.drawRect(
        full,
        Paint()
          ..shader = LinearGradient(
                  colors: dim ? const [Color(0xFFD3CEE4), Color(0xFFB9B3D3)] : const [Color(0xFFFFFFFF), Color(0xFFF2EEE4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              .createShader(full));
    cv.drawRRect(RRect.fromRectAndRadius(full.deflate(.5), Radius.circular(w * .14)), Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.black.withOpacity(.18));
    _index(cv, w, h, col);
    cv.save();
    cv.translate(w, h);
    cv.rotate(math.pi);
    _index(cv, w, h, col);
    cv.restore();

    final r = c.r == 1 ? 14 : c.r;
    if (r == 14) {
      _suit(cv, Offset(w * .5, h * .5), w * (c.s == 0 ? .6 : .52), col);
    } else if (r <= 10) {
      final ps = w * .21;
      for (final pt in _pips[r]!) {
        final x = w * (.33 + pt[0] * .34), y = h * (.15 + pt[1] * .7);
        _suit(cv, Offset(x, y), ps, col, flip: pt[1] > .5);
      }
    } else {
      final frame = RRect.fromRectAndRadius(Rect.fromLTWH(w * .26, h * .13, w * .5, h * .74), Radius.circular(w * .06));
      cv.drawRRect(
          frame,
          Paint()
            ..shader = LinearGradient(
                    colors: isRed(c.s) ? const [Color(0xFFFFEAEE), Color(0xFFFFCBD4)] : const [Color(0xFFE9EDF8), Color(0xFFC9D2EA)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter)
                .createShader(frame.outerRect));
      cv.drawRRect(frame, Paint()..style = PaintingStyle.stroke..strokeWidth = w * .02..color = col.withOpacity(.55));
      if (r == 13) _crown(cv, Rect.fromLTWH(w * .36, h * .17, w * .3, h * .13), 3);
      if (r == 12) _crown(cv, Rect.fromLTWH(w * .34, h * .17, w * .34, h * .12), 5);
      _text(cv, rankLabel(r), w * .42, col, Offset(w * .51, h * .45));
      _suit(cv, Offset(w * .51, h * .72), w * .22, col);
    }
  }

  @override
  bool shouldRepaint(_FacePainter o) => o.c != c || o.dim != dim;
}

class _BackPainter extends CustomPainter {
  @override
  void paint(Canvas cv, Size s) {
    final w = s.width, h = s.height;
    final full = Offset.zero & s;
    cv.drawRect(full, Paint()..color = Colors.white);
    final inner = RRect.fromRectAndRadius(full.deflate(w * .07), Radius.circular(w * .09));
    cv.drawRRect(inner, Paint()..shader = const LinearGradient(colors: [Color(0xFFE23A55), Color(0xFFA3132E)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(full));
    cv.save();
    cv.clipRRect(inner);
    final ln = Paint()..color = Colors.white.withOpacity(.4)..strokeWidth = w * .028;
    final step = w * .17;
    for (var d = -h; d < w + h; d += step) {
      cv.drawLine(Offset(d, 0), Offset(d + h, h), ln);
      cv.drawLine(Offset(d, h), Offset(d + h, 0), ln);
    }
    cv.restore();
    cv.drawRRect(inner, Paint()..style = PaintingStyle.stroke..strokeWidth = w * .02..color = Colors.white.withOpacity(.8));
  }

  @override
  bool shouldRepaint(_) => false;
}

Widget cardW(PC? c, {double w = 50, bool dim = false, bool sel = false, VoidCallback? onTap, bool hint = false}) {
  final h = w * 1.4;
  final rad = BorderRadius.circular(w * .14);
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      transform: Matrix4.translationValues(0, sel ? -w * .22 : 0, 0),
      width: w,
      height: h,
      decoration: BoxDecoration(borderRadius: rad, boxShadow: [BoxShadow(color: Colors.black.withOpacity(.35), blurRadius: w * .08, offset: Offset(0, w * .03))]),
      foregroundDecoration: (sel || hint) ? BoxDecoration(borderRadius: rad, border: Border.all(color: hint ? AC.gold : const Color(0xFF2EE66B), width: 3)) : null,
      child: ClipRRect(borderRadius: rad, child: CustomPaint(size: Size(w, h), painter: c == null ? _BackPainter() : _FacePainter(c, dim))),
    ),
  );
}
