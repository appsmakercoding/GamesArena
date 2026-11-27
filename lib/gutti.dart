import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common.dart';
import 'net.dart';
import 'games.dart';
import 'game_ui.dart';
import 'ui.dart';

List<List<int>> _dirs(int x, int y) => [
      [1, 0], [-1, 0], [0, 1], [0, -1],
      if ((x + y) % 2 == 0) ...[[1, 1], [1, -1], [-1, 1], [-1, -1]],
    ];

/// Legal moves of piece i: [to, capturedIndex(-1 if none)]
List<List<int>> movesOf(int w, int h, List<int> bd, int i, {bool steps = true, bool jumps = true}) {
  final x = i % w, y = i ~/ w, me = bd[i], r = <List<int>>[];
  for (final d in _dirs(x, y)) {
    final nx = x + d[0], ny = y + d[1];
    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
    final j = ny * w + nx;
    if (bd[j] == 0) {
      if (steps) r.add([j, -1]);
    } else if (bd[j] != me && jumps) {
      final mx = nx + d[0], my = ny + d[1];
      if (mx < 0 || my < 0 || mx >= w || my >= h) continue;
      if (bd[my * w + mx] == 0) r.add([my * w + mx, j]);
    }
  }
  return r;
}

/// ───────── ব্যাকগ্রাউন্ড ─────────
class WoodBg extends StatelessWidget {
  final Widget child;
  const WoodBg({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        RepaintBoundary(child: CustomPaint(painter: _WoodPainter())),
        child,
      ]);
}

class _WoodPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = math.Random(5);
    const pal = [Color(0xFFF0C48A), Color(0xFFE6B476), Color(0xFFF6D3A0), Color(0xFFE2AC6E), Color(0xFFEBBB80)];
    var y = 0.0;
    while (y < s.height) {
      final bh = 70 + r.nextDouble() * 120;
      final rect = Rect.fromLTWH(0, y, s.width, bh);
      final base = pal[r.nextInt(pal.length)];
      c.drawRect(rect, Paint()..shader = LinearGradient(colors: [lighten(base, .08), base, darken(base, .05)]).createShader(rect));
      for (var k = 0; k < 16; k++) {
        final gy = y + r.nextDouble() * bh;
        final gx = r.nextDouble() * s.width;
        c.drawLine(Offset(gx, gy), Offset(gx + 40 + r.nextDouble() * 160, gy + (r.nextDouble() - .5) * 3),
            Paint()..color = const Color(0xFF8A5A2B).withOpacity(.07 + r.nextDouble() * .07)..strokeWidth = 1 + r.nextDouble() * 1.5);
      }
      final jx = r.nextDouble() * s.width;
      c.drawLine(Offset(jx, y), Offset(jx, y + bh), Paint()..color = const Color(0xFF8A5A2B).withOpacity(.12)..strokeWidth = 1.2);
      c.drawLine(Offset(0, y), Offset(s.width, y), Paint()..color = const Color(0xFF8A5A2B).withOpacity(.18)..strokeWidth = 1.5);
      y += bh;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class SlateBg extends StatelessWidget {
  final Widget child;
  const SlateBg({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -.2), radius: 1.2, colors: [Color(0xFFA7B9C4), Color(0xFF6D8493), Color(0xFF51677A)]),
        ),
        child: child,
      );
}

/// কাঠের প্লেট (প্লেয়ার তথ্য)
class WoodPlate extends StatelessWidget {
  final String name, sub, score;
  final Color color;
  final bool active;
  const WoodPlate({super.key, required this.name, required this.sub, required this.score, required this.color, required this.active});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 80,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          Positioned(
            left: 0,
            right: 0,
            top: 9,
            height: 62,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Color(0xFFF6D6A6), Color(0xFFE7B374)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                border: Border.all(color: active ? color : const Color(0xFFC08040), width: active ? 3 : 2),
                boxShadow: [BoxShadow(color: active ? color.withOpacity(.5) : Colors.black26, blurRadius: active ? 16 : 8, offset: const Offset(0, 3))],
              ),
              child: Row(children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF4A2A12), fontSize: 15, fontWeight: FontWeight.w900)),
                      Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF7A4B22), fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
                const SizedBox(width: 84),
                Expanded(
                  child: Center(child: Text(score, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF4A2A12), fontSize: 17, fontWeight: FontWeight.w900))),
                ),
              ]),
            ),
          ),
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFFFEBC9), Color(0xFFE2AD6B)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              border: Border.all(color: active ? color : const Color(0xFF8A5A2B), width: 4),
              boxShadow: [BoxShadow(color: active ? color.withOpacity(.7) : Colors.black38, blurRadius: active ? 18 : 8)],
            ),
            child: ClipOval(child: Face(color, size: 54)),
          ),
        ]),
      );
}

/// ───────── বোর্ড পেইন্টার ─────────
class GridPainter extends CustomPainter {
  final int w, h, sel, theme, mFrom, mTo, ghost, ghostV;
  final List<int> b;
  final List<List<int>> tg;
  final Map<int, Color> col;
  final Map<int, String>? icon;
  final Animation<double>? anim;
  final bool flip;
  GridPainter(this.w, this.h, this.b, this.sel, this.tg, this.col,
      [this.icon, this.theme = 0, this.anim, this.mFrom = -1, this.mTo = -1, this.ghost = -1, this.ghostV = 0, this.flip = false])
      : super(repaint: anim);

  Offset P(int i) {
    final x = i % w, y = i ~/ w;
    return Offset(x + .5, (flip ? h - 1 - y : y) + .5);
  }

  void _gem(Canvas c, Offset o, Color colr, {double r = .38, double lift = 0, double a = 1, String? emoji}) {
    final b = o.translate(0, -lift);
    c.drawCircle(o.translate(.02, .09), r, Paint()..color = Colors.black.withOpacity(.3 * a)..maskFilter = const MaskFilter.blur(BlurStyle.normal, .06));
    c.drawCircle(
        b,
        r,
        Paint()
          ..shader = RadialGradient(
              center: const Alignment(-.35, -.45),
              colors: [lighten(colr, .55).withOpacity(a), colr.withOpacity(a), darken(colr, .35).withOpacity(a)],
              stops: const [0, .5, 1]).createShader(Rect.fromCircle(center: b, radius: r)));
    c.drawCircle(b, r, Paint()..style = PaintingStyle.stroke..strokeWidth = .035..color = darken(colr, .5).withOpacity(a));
    if (emoji != null) {
      final tp = TextPainter(text: TextSpan(text: emoji, style: TextStyle(fontSize: r * 1.15, color: Colors.white.withOpacity(a))), textDirection: TextDirection.ltr)..layout();
      tp.paint(c, b - Offset(tp.width / 2, tp.height / 2));
    } else if (theme == 0) {
      c.drawPath(star5(b, r * .42, r * .2), Paint()..color = darken(colr, .5).withOpacity(.85 * a));
    }
    c.drawCircle(b + Offset(-r * .35, -r * .42), r * .16, Paint()..color = Colors.white.withOpacity(.55 * a));
  }

  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / w);
    final board = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
    if (theme == 1) {
      final rr = RRect.fromRectAndRadius(board, const Radius.circular(.4));
      c.drawRRect(rr.shift(const Offset(0, .12)), Paint()..color = Colors.black.withOpacity(.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, .18));
      c.drawRRect(rr, Paint()..shader = const LinearGradient(colors: [Color(0xFFF4F7FA), Color(0xFFDDE4EB)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(board));
    }
    final lc = theme == 0 ? const Color(0xFF8A1C12) : const Color(0xFF303A46);
    final lw = theme == 0 ? .07 : .055;
    final shadow = Paint()..color = Colors.black.withOpacity(theme == 0 ? .16 : .0)..strokeWidth = lw..strokeCap = StrokeCap.round;
    final ln = Paint()..color = lc..strokeWidth = lw..strokeCap = StrokeCap.round;
    void seg(int a, int z) {
      c.drawLine(P(a) + const Offset(.02, .03), P(z) + const Offset(.02, .03), shadow);
      c.drawLine(P(a), P(z), ln);
    }

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        if (x + 1 < w) seg(i, i + 1);
        if (y + 1 < h) seg(i, i + w);
        if ((x + y) % 2 == 0 && y + 1 < h) {
          if (x + 1 < w) seg(i, i + w + 1);
          if (x > 0) seg(i, i + w - 1);
        }
      }
    }
    for (var i = 0; i < w * h; i++) {
      c.drawCircle(P(i), .07, Paint()..color = lc);
    }
    for (final t in tg) {
      final o = P(t[0]);
      c.drawCircle(o, .3, Paint()..color = const Color(0xFF2EE66B).withOpacity(.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, .1));
      c.drawCircle(o, .2, Paint()..color = const Color(0xFF2EE66B).withOpacity(.9));
      c.drawCircle(o, .2, Paint()..style = PaintingStyle.stroke..strokeWidth = .04..color = Colors.white);
    }
    final u = anim?.value ?? 1.0;
    for (var i = 0; i < w * h; i++) {
      final v = b[i];
      if (v <= 0) continue;
      var o = P(i);
      var lift = 0.0;
      if (i == mTo && mFrom >= 0 && u < 1) {
        o = Offset.lerp(P(mFrom), o, Curves.easeInOut.transform(u))!;
        lift = math.sin(math.pi * u) * .25;
      }
      if (i == sel) {
        c.drawCircle(o, .56, Paint()..color = Colors.white.withOpacity(.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, .12));
        c.drawCircle(o, .5, Paint()..style = PaintingStyle.stroke..strokeWidth = .07..color = AC.gold);
      }
      _gem(c, o, col[v]!, r: theme == 0 ? .36 : .4, lift: lift, emoji: icon?[v]);
    }
    if (ghost >= 0 && u < 1) {
      _gem(c, P(ghost), col[ghostV]!, r: (theme == 0 ? .36 : .4) * (1 - u * .4), a: 1 - u, emoji: icon?[ghostV]);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) => true;
}

/// পুরনো BoardView (সামঞ্জস্যের জন্য)
class BoardView extends StatelessWidget {
  final int w, h;
  final CustomPainter p;
  final void Function(int) onCell;
  const BoardView(this.w, this.h, this.p, this.onCell, {super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: AspectRatio(
            aspectRatio: w / h,
            child: LayoutBuilder(builder: (_, bc) {
              final cs = bc.maxWidth / w;
              return GestureDetector(
                onTapUp: (d) => onCell(((d.localPosition.dy / cs).floor().clamp(0, h - 1).toInt()) * w +
                    (d.localPosition.dx / cs).floor().clamp(0, w - 1).toInt()),
                child: CustomPaint(painter: p, size: Size.infinite),
              );
            }),
          ),
        ),
      );
}

const _cfg = {'gutti16': [7, 5, 16], 'gutti12': [5, 5, 12], 'gutti8': [5, 4, 8]};

class GuttiPage extends StatefulWidget {
  final GameInfo g;
  final bool vsPc;
  final Net? net;
  const GuttiPage(this.g, this.vsPc, {super.key, this.net});
  @override
  State<GuttiPage> createState() => _GuttiState();
}

class _GuttiState extends State<GuttiPage> with NetMix<GuttiPage>, SingleTickerProviderStateMixin {
  @override
  Net? get net => widget.net;
  @override
  bool remote(Map a) { _tap(a['i'] as int, true); return true; }

  late final AnimationController mv = AnimationController(vsync: this, duration: const Duration(milliseconds: 260), value: 1);
  int mFrom = -1, mTo = -1, ghost = -1, ghostV = 0;

  late int w, h, n;
  late List<int> b;
  int turn = 0, sel = -1, forced = -1;
  bool over = false;
  List<List<int>> tg = [];
  static const ids = [0, 3];

  bool get bot => widget.vsPc && turn == 1;
  bool get wood => widget.g.id == 'gutti16';
  bool get flip => !(net != null && net!.seat == 1);
  List<bool> get bots => [false, widget.vsPc];
  String nm(int i) => playerName(i, n: 2, bots: bots, vsPc: widget.vsPc, net: net);

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    mv.dispose();
    super.dispose();
  }

  void _init() {
    final c = _cfg[widget.g.id]!;
    w = c[0]; h = c[1]; n = c[2];
    b = List.filled(w * h, 0);
    for (var i = 0; i < n; i++) { b[i] = 1; b[w * h - 1 - i] = 2; }
    turn = 0; sel = -1; forced = -1; over = false; tg = [];
    mFrom = mTo = ghost = -1;
    mv.value = 1;
    setState(() {});
  }

  List<List<int>> _all() {
    final r = <List<int>>[];
    for (var i = 0; i < b.length; i++) {
      if (b[i] != turn + 1 || (forced >= 0 && i != forced)) continue;
      for (final m in movesOf(w, h, b, i, steps: forced < 0)) r.add([i, ...m]);
    }
    return r;
  }

  void _tap(int i, [bool rem = false]) {
    if (over || bot) return;
    if (!rem) { if (!canAct(turn)) return; emit({'i': i}); }
    if (sel >= 0) {
      final m = tg.where((e) => e[0] == i);
      if (m.isNotEmpty) { _move(sel, i, m.first[1]); return; }
    }
    if (b[i] == turn + 1 && (forced < 0 || forced == i)) {
      setState(() { sel = i; tg = movesOf(w, h, b, i, steps: forced < 0); });
    }
  }

  void _move(int f, int t, int cap) {
    mFrom = f; mTo = t; ghost = cap; ghostV = cap >= 0 ? b[cap] : 0;
    setState(() { b[t] = b[f]; b[f] = 0; if (cap >= 0) b[cap] = 0; sel = -1; tg = []; });
    mv.forward(from: 0);
    if (cap >= 0 && movesOf(w, h, b, t, steps: false).isNotEmpty) {
      forced = t;
      if (!bot) setState(() { sel = t; tg = movesOf(w, h, b, t, steps: false); });
      _bot();
      return;
    }
    forced = -1;
    setState(() => turn = 1 - turn);
    if (_all().isEmpty) {
      over = true;
      final wi = 1 - turn;
      final rw = giveWinReward(vsPc: widget.vsPc, turn: wi, net: net);
      showWin(context, nm(wi), kCol[ids[wi]], net == null ? _init : () => Navigator.pop(context), reward: rw);
      return;
    }
    _bot();
  }

  void _bot() {
    if (!bot || over) return;
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || over || !bot) return;
      final a = _all();
      if (a.isEmpty) return;
      final caps = a.where((e) => e[3] >= 0).toList();
      final l = caps.isNotEmpty ? caps : a;
      final m = l[rnd.nextInt(l.length)];
      _move(m[0], m[1], m[2]);
    });
  }

  Color get c1 => wood ? const Color(0xFFE53935) : const Color(0xFFF5C518);
  Color get c2 => wood ? const Color(0xFF1E40C8) : const Color(0xFF2B3440);
  Color pc(int p) => p == 0 ? c1 : c2;
  int left(int p) => b.where((e) => e == p + 1).length;
  int score(int p) => n - left(1 - p);

  Widget _board(double bw) {
    final bh = bw * h / w;
    final cs = bw / w;
    return SizedBox(
      width: bw,
      height: bh,
      child: GestureDetector(
        onTapUp: (d) {
          final cx = (d.localPosition.dx / cs).floor().clamp(0, w - 1).toInt();
          var cy = (d.localPosition.dy / cs).floor().clamp(0, h - 1).toInt();
          if (flip) cy = h - 1 - cy;
          _tap(cy * w + cx);
        },
        child: CustomPaint(painter: GridPainter(w, h, b, sel, tg, {1: c1, 2: c2}, null, wood ? 0 : 1, mv, mFrom, mTo, ghost, ghostV, flip), size: Size(bw, bh)),
      ),
    );
  }

  String get hintText => forced >= 0 ? 'আবার লাফ দিন!' : 'গুটি বেছে নিন, তারপর সবুজ ঘরে ট্যাপ করুন';

  // ── কাঠের লেআউট (১৬ গুটি) ──
  Widget _woodLayout() {
    final me = flip ? 0 : 1, op = 1 - me;
    return WoodBg(
      child: SafeArea(
        child: LayoutBuilder(builder: (_, bc) {
          final bw = math.min(bc.maxWidth - 28, (bc.maxHeight - 80 * 2 - 70) * w / h).clamp(200.0, 800.0).toDouble();
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.9), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)]),
                      child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E40C8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: WoodPlate(name: nm(op), sub: 'গুটি: ${bnNum(left(op))}', score: 'স্কোর: ${bnNum(score(op))}', color: pc(op), active: turn == op && !over)),
                  const SizedBox(width: 8),
                  net == null
                      ? GestureDetector(
                          onTap: _init,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.9), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)]),
                            child: const Icon(Icons.refresh_rounded, color: Color(0xFF1E40C8)),
                          ),
                        )
                      : const SizedBox(width: 44),
                ]),
                const SizedBox(height: 14),
                _board(bw),
                const SizedBox(height: 14),
                WoodPlate(name: nm(me), sub: 'গুটি: ${bnNum(left(me))}', score: 'স্কোর: ${bnNum(score(me))}', color: pc(me), active: turn == me && !over),
                const SizedBox(height: 6),
                Text(hintText, style: const TextStyle(color: Color(0xFF5A3410), fontWeight: FontWeight.w800)),
              ]),
            ),
          );
        }),
      ),
    );
  }

  // ── স্লেট লেআউট (১২/৮ গুটি) ──
  Widget _pill(int p) {
    final active = turn == p && !over;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(40), border: Border.all(color: AC.gold.withOpacity(.35))),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 62,
        padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: LinearGradient(colors: active ? const [Color(0xFF22D66B), Color(0xFF05B04A)] : const [Color(0xFFDADADD), Color(0xFFB4B6BB)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black26, border: Border.all(color: pc(p), width: 2.5)),
            child: ClipOval(child: Face(pc(p), size: 36)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(nm(p), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: active ? Colors.white : const Color(0xFF222831)))),
          Text('স্কোর ${bnNum(score(p))}', style: TextStyle(fontWeight: FontWeight.w800, color: active ? Colors.white : Colors.black54)),
        ]),
      ),
    );
  }

  Widget _remain(int p) => Container(
        height: 44,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: Colors.white.withOpacity(.14)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('অবশিষ্ট:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          const SizedBox(width: 12),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(center: const Alignment(-.3, -.4), colors: [lighten(pc(p), .5), pc(p), darken(pc(p), .3)])),
          ),
          const SizedBox(width: 8),
          Text('×${bnNum(left(p))}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ]),
      );

  Widget _slateLayout() {
    final me = flip ? 0 : 1, op = 1 - me;
    return SlateBg(
      child: SafeArea(
        child: LayoutBuilder(builder: (_, bc) {
          final bw = math.min(bc.maxWidth - 36, (bc.maxHeight - 340) * w / h).clamp(200.0, 800.0).toDouble();
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ArenaBar(widget.g.bn, onBack: () => Navigator.pop(context), trailing: net == null ? CircleBtn(Icons.refresh_rounded, _init) : null),
                _pill(op),
                const SizedBox(height: 8),
                _remain(op),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: const Color(0xFF4A5560), border: Border.all(color: AC.gold.withOpacity(.5))),
                  child: Text(over ? 'খেলা শেষ' : forced >= 0 ? 'আবার লাফ দিন!' : '${nm(turn)} এর চাল', style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 14),
                _board(bw),
                const SizedBox(height: 14),
                _remain(me),
                const SizedBox(height: 8),
                _pill(me),
                const SizedBox(height: 8),
                Text(hintText, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ]),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: wood ? _woodLayout() : _slateLayout());
}
