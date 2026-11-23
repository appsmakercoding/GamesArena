import 'dart:async';
import 'package:flutter/material.dart';
import 'common.dart';
import 'net.dart';

Offset _cell(int i) {
  i %= 40;
  if (i < 10) return Offset(.5, 10 - i + .5);
  if (i < 20) return Offset(i - 10 + .5, .5);
  if (i < 30) return Offset(10.5, i - 20 + .5);
  return Offset(10 - (i - 30) + .5, 10.5);
}

class KoriPage extends StatefulWidget {
  final int n;
  final bool vsPc;
  final Net? net;
  const KoriPage(this.n, this.vsPc, {super.key, this.net});
  @override
  State<KoriPage> createState() => _KoriState();
}

class _KoriState extends State<KoriPage> with NetMix<KoriPage> {
  @override
  Net? get net => widget.net;
  bool ready = false;

  @override
  bool remote(Map a) {
    if (!ready || a['t'] != 'r') return false;
    _throw();
    return true;
  }

  void _uThrow() {
    if (!canAct(turn) || !ready || busy) return;
    emit({'t': 'r'});
    _throw();
  }

  late List<int> pos;
  late List<bool> bots;
  List<bool> cow = [false, false, false, false];
  int turn = 0;
  bool busy = false, over = false;
  String msg = 'কড়ি ছুড়তে ট্যাপ করুন';

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    pos = List.filled(widget.n, 0);
    bots = List.generate(widget.n, (i) => widget.vsPc && i > 0);
    turn = 0; busy = false; over = false; cow = [false, false, false, false];
    msg = 'কড়ি ছুড়তে ট্যাপ করুন';
    setState(() {});
    _auto();
  }

  void _auto() {
    ready = true;
    if (bots[turn] && !over) Future.delayed(const Duration(milliseconds: 800), () { if (mounted) _throw(); });
  }

  void _throw() {
    if (busy || over || !ready) return;
    ready = false;
    busy = true;
    var k = 0;
    Timer.periodic(const Duration(milliseconds: 80), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => cow = List.generate(4, (_) => rnd.nextBool()));
      if (++k >= 8) { t.cancel(); _move(); }
    });
  }

  void _move() {
    final up = cow.where((e) => e).length;
    final steps = up == 0 ? 8 : up;
    var extra = up == 0 || up == 4;
    final np = pos[turn] + steps;
    setState(() {
      pos[turn] = np;
      if (np < 40 && np % 8 != 0) {
        for (var j = 0; j < widget.n; j++) {
          if (j != turn && pos[j] == np) { pos[j] = 0; extra = true; }
        }
      }
      msg = '${kNames[turn]}: $steps ঘর ${extra ? '(আবার চাল!)' : ''}';
    });
    busy = false;
    if (np >= 40) {
      over = true;
      showWin(context, kNames[turn], kCol[turn], net == null ? _init : () => Navigator.pop(context));
      return;
    }
    if (!extra) setState(() => turn = (turn + 1) % widget.n);
    _auto();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('কড়ি খেলা'), backgroundColor: Colors.transparent,
            actions: [if (net == null) IconButton(onPressed: _init, icon: const Icon(Icons.refresh_rounded))]),
        body: SafeArea(
          child: Column(children: [
            TurnBar(List.generate(widget.n, (i) => i), turn, bots),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: AspectRatio(aspectRatio: 1, child: CustomPaint(painter: _KoriPainter(pos), size: Size.infinite)),
                ),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final up in cow)
                Container(
                  margin: const EdgeInsets.all(6),
                  width: 40,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1D6),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE0B66B), width: 3),
                  ),
                  child: up ? Center(child: Container(width: 6, height: 30, decoration: BoxDecoration(color: const Color(0xFF8D5B2E), borderRadius: BorderRadius.circular(4)))) : null,
                ),
            ]),
            const SizedBox(height: 8),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kCol[turn], padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14)),
              onPressed: bots[turn] || busy || !canAct(turn) ? null : _uThrow,
              child: const Text('🐚 কড়ি ছুড়ুন', style: TextStyle(fontSize: 18)),
            ),
            Padding(padding: const EdgeInsets.all(12), child: Text(msg, style: const TextStyle(color: Colors.white54))),
          ]),
        ),
      );
}

class _KoriPainter extends CustomPainter {
  final List<int> pos;
  _KoriPainter(this.pos);
  static const pal = [Color(0xFFFFE5EC), Color(0xFFE0F7F4), Color(0xFFFFF3D6), Color(0xFFE3EEFF)];
  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 11);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 11, 11), const Radius.circular(.6)), Paint()..color = const Color(0xFF241A4D));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(1.4, 1.4, 8.2, 8.2), const Radius.circular(.8)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)]).createShader(const Rect.fromLTWH(1, 1, 9, 9)));
    final tp = TextPainter(text: const TextSpan(text: '🐚', style: TextStyle(fontSize: 3)), textDirection: TextDirection.ltr)..layout();
    tp.paint(c, Offset(5.5 - tp.width / 2, 5.5 - tp.height / 2));
    for (var i = 0; i < 40; i++) {
      final o = _cell(i);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: .92, height: .92), const Radius.circular(.2)),
          Paint()..color = i == 0 ? const Color(0xFF2EC4B6) : pal[i % 4]);
      if (i % 8 == 0 && i > 0) c.drawCircle(o, .17, Paint()..color = const Color(0xFF7C4DFF));
    }
    for (var i = 0; i < pos.length; i++) {
      final o = _cell(pos[i]) + Offset((i % 2 - .5) * .34, (i ~/ 2 - .5) * .34);
      c.drawCircle(o + const Offset(0, .05), .26, Paint()..color = Colors.black38);
      c.drawCircle(o, .26, Paint()..color = Colors.white);
      c.drawCircle(o, .2, Paint()..color = kCol[i]);
    }
  }
  @override
  bool shouldRepaint(_) => true;
}
