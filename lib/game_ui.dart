import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'net.dart';
import 'profile.dart';
import 'ui.dart';

/// সব গেমের জন্য সাধারণ ইন-গেম UI (ধাপ ৩ থেকে ব্যবহৃত)

String playerName(int i, {required int n, required List<bool> bots, required bool vsPc, Net? net}) {
  if (bots[i]) return n == 2 ? 'কম্পিউটার' : 'কম্পিউটার ${bnNum(i)}';
  if (net != null) return i == net.seat ? '${Profile.name} (আপনি)' : 'বন্ধু';
  if (vsPc) return Profile.name;
  return 'প্লেয়ার ${bnNum(i + 1)}';
}

/// জিতলে পুরস্কার: কম্পিউটারের বিপক্ষে (প্লেয়ার ১) বা অনলাইনে নিজে জিতলে
int giveWinReward({required bool vsPc, required int turn, Net? net}) {
  final rw = ((vsPc && turn == 0) || (net != null && net.seat == turn)) ? 50 : 0;
  if (rw > 0) {
    Profile.addCoins(rw);
    Profile.addXp(20);
  }
  return rw;
}

class GameScaffold extends StatelessWidget {
  final String title;
  final VoidCallback? onRestart;
  final Widget child;
  const GameScaffold({super.key, required this.title, required this.child, this.onRestart});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: ArenaBg(
          floaters: false,
          child: SafeArea(
            child: Column(children: [
              ArenaBar(title, onBack: () => Navigator.pop(context), trailing: onRestart == null ? null : CircleBtn(Icons.refresh_rounded, onRestart!)),
              Expanded(child: child),
            ]),
          ),
        ),
      );
}

class PlayerChip extends StatelessWidget {
  final String name, sub;
  final Color color;
  final bool active;
  const PlayerChip({super.key, required this.name, required this.sub, required this.color, required this.active});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 58,
        padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(colors: [color.withOpacity(active ? .6 : .2), AC.bg1.withOpacity(.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: active ? Colors.white : Colors.white.withOpacity(.15), width: active ? 2 : 1),
          boxShadow: active ? [BoxShadow(color: color.withOpacity(.55), blurRadius: 16)] : const [],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black26, border: Border.all(color: color, width: 2.2)),
            child: ClipOval(child: Face(color, size: 30)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
              Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: lighten(color, .55))),
            ]),
          ),
        ]),
      );
}

class PlayerStrip extends StatelessWidget {
  final List<Widget> chips;
  const PlayerStrip(this.chips, {super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) {
          final w = chips.length <= 1 ? c.maxWidth : (c.maxWidth - 8) / 2;
          return Wrap(spacing: 8, runSpacing: 8, children: [for (final ch in chips) SizedBox(width: w, child: ch)]);
        },
      );
}

/// গুটির হাঁটার রুট (ঘর ধরে ধরে বা স্লাইড)
class PawnRoute {
  final List<Offset> pts;
  final bool hop;
  const PawnRoute(this.pts, this.hop);
}

class RouteAt {
  final Offset o;
  final double lift;
  const RouteAt(this.o, this.lift);
}

RouteAt routeAt(PawnRoute r, double u) {
  final segs = r.pts.length - 1;
  if (segs <= 0) return RouteAt(r.pts.first, 0);
  final f = (u * segs).clamp(0.0, segs.toDouble()).toDouble();
  final idx = math.min(f.floor(), segs - 1);
  final local = f - idx;
  final a = r.pts[idx], b = r.pts[idx + 1];
  final e = segs == 1 ? Curves.easeInOut.transform(local) : local;
  final lift = (r.hop && a != b) ? math.sin(math.pi * local) * (segs == 1 ? .6 : .3) : 0.0;
  return RouteAt(Offset.lerp(a, b, e)!, lift);
}

/// গ্লসি ৩D টোকেন
void drawToken(Canvas c, Offset o, Color col, double r, {bool glow = false, double lift = 0}) {
  final g = o.translate(0, r * .6);
  c.drawOval(Rect.fromCenter(center: g, width: r * 1.9, height: r * .7), Paint()..color = Colors.black.withOpacity(.3));
  final b = o.translate(0, -lift);
  if (glow) {
    c.drawCircle(b, r * 1.4, Paint()..color = col.withOpacity(.4)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .5));
  }
  c.drawCircle(
      b,
      r,
      Paint()
        ..shader = RadialGradient(center: const Alignment(-.4, -.5), colors: [lighten(col, .55), col, darken(col, .3)], stops: const [0, .55, 1])
            .createShader(Rect.fromCircle(center: b, radius: r)));
  c.drawCircle(
      b,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .24
        ..color = Colors.white);
  c.drawCircle(b.translate(-r * .35, -r * .4), r * .16, Paint()..color = Colors.white.withOpacity(.7));
}

Path star5(Offset o, double ro, double ri) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? ro : ri;
    final x = o.dx + r * math.cos(a), y = o.dy + r * math.sin(a);
    if (i == 0) {
      p.moveTo(x, y);
    } else {
      p.lineTo(x, y);
    }
  }
  p.close();
  return p;
}
