import 'dart:math';
import 'package:flutter/material.dart';
import 'ui.dart';

const kCol = [Color(0xFFFF4D6D), Color(0xFF2EC4B6), Color(0xFFFFB703), Color(0xFF4D96FF)];
const kNames = ['লাল', 'সবুজ', 'হলুদ', 'নীল'];
Random rnd = Random();
void seedRnd(int s) => rnd = Random(s);

/// আধুনিক ডাইস — সব গেমে একই কনস্ট্রাক্টর, শুধু নতুন ডিজাইন
class DiceView extends StatelessWidget {
  final int v;
  final bool active, rolling;
  final Color color;
  final VoidCallback? onTap;
  final double size;
  const DiceView(this.v,
      {super.key, this.active = false, this.color = Colors.white, this.onTap, this.size = 84, this.rolling = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: rolling ? Matrix4.rotationZ(v.isEven ? .14 : -.14) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE6E1FA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(size * .24),
            border: Border.all(color: color, width: size * .045),
            boxShadow: [
              BoxShadow(color: color.withOpacity(active ? .85 : .25), blurRadius: active ? size * .4 : size * .1, spreadRadius: active ? 1 : 0),
              BoxShadow(color: Colors.black.withOpacity(.25), blurRadius: size * .12, offset: Offset(0, size * .06)),
            ],
          ),
          child: v == 0
              ? Icon(Icons.casino_rounded, color: color == Colors.white ? Colors.black54 : color, size: size * .5)
              : CustomPaint(painter: _PipPainter(v)),
        ),
      );
}

class _PipPainter extends CustomPainter {
  final int v;
  _PipPainter(this.v);
  @override
  void paint(Canvas c, Size s) {
    for (final o in pipPos(v)) {
      final p = Offset(o.dx * s.width, o.dy * s.height);
      c.drawCircle(p, s.width * .088, Paint()..color = const Color(0xFF1A1033));
      c.drawCircle(p.translate(-s.width * .025, -s.width * .025), s.width * .026, Paint()..color = Colors.white.withOpacity(.4));
    }
  }

  @override
  bool shouldRepaint(_PipPainter o) => o.v != v;
}

class TurnBar extends StatelessWidget {
  final List<int> ids;
  final int turn;
  final List<bool> bots;
  const TurnBar(this.ids, this.turn, this.bots, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < ids.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: i == turn ? kCol[ids[i]] : Colors.white10,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text('${kNames[ids[i]]}${bots[i] ? ' 🤖' : ''}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: i == turn ? Colors.white : Colors.white60)),
            ),
        ]),
      );
}

/// আধুনিক বিজয়ী ডায়ালগ (সিগনেচার একই, শুধু optional reward যোগ)
void showWin(BuildContext c, String name, Color col, VoidCallback again, {int reward = 0}) => showDialog(
      context: c,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(colors: [AC.bg2, AC.bg1], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            border: Border.all(color: AC.gold.withOpacity(.7), width: 1.6),
            boxShadow: [BoxShadow(color: AC.gold.withOpacity(.3), blurRadius: 30)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Crown(90),
            const SizedBox(height: 10),
            const Text('🏆 অভিনন্দন!', style: TextStyle(fontSize: 15, color: Colors.white70, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('$name জিতেছে!', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: col)),
            if (reward > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), color: Colors.black26, border: Border.all(color: AC.gold.withOpacity(.5))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Coin(size: 26),
                  const SizedBox(width: 8),
                  Text('+$reward কয়েন   +20 XP', style: const TextStyle(fontWeight: FontWeight.w900, color: AC.gold)),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: GlossBtn('হোম', height: 48, fontSize: 16, colors: const [Color(0xFF6B6F8F), Color(0xFF3A3D5C)], onTap: () {
                  Navigator.pop(c);
                  Navigator.pop(c);
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GlossBtn('আবার খেলুন', height: 48, fontSize: 16, colors: AC.goldGrad, textColor: const Color(0xFF4A2A00), onTap: () {
                  Navigator.pop(c);
                  again();
                }),
              ),
            ]),
          ]),
        ),
      ),
    );
