import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'common.dart';
import 'net.dart';
import 'gutti.dart';
import 'game_ui.dart';
import 'ui.dart';

class TigerPage extends StatefulWidget {
  final bool vsPc;
  final Net? net;
  const TigerPage(this.vsPc, {super.key, this.net});
  @override
  State<TigerPage> createState() => _TigerState();
}

class _TigerState extends State<TigerPage> with NetMix<TigerPage>, SingleTickerProviderStateMixin {
  @override
  Net? get net => widget.net;
  @override
  bool remote(Map a) { _tap(a['i'] as int, true); return true; }

  late final AnimationController mv = AnimationController(vsync: this, duration: const Duration(milliseconds: 260), value: 1);
  int mFrom = -1, mTo = -1, ghost = -1, ghostV = 0;
  late List<int> b;
  int turn = 0, hand = 20, cap = 0, sel = -1;
  bool over = false;
  List<List<int>> tg = [];
  bool get bot => widget.vsPc && turn == 1;

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
    b = List.filled(25, 0);
    for (final t in [0, 4, 20, 24]) b[t] = 1;
    turn = 0; hand = 20; cap = 0; sel = -1; over = false; tg = [];
    mFrom = mTo = ghost = -1; mv.value = 1;
    setState(() {});
  }

  List<List<int>> _mv(int i) => movesOf(5, 5, b, i, jumps: b[i] == 1);

  List<List<int>> _tigerMoves() {
    final r = <List<int>>[];
    for (var i = 0; i < 25; i++) {
      if (b[i] == 1) for (final m in _mv(i)) r.add([i, ...m]);
    }
    return r;
  }

  void _win(String s, Color c, int wi) {
    over = true;
    final rw = giveWinReward(vsPc: widget.vsPc, turn: wi, net: net);
    showWin(context, s, c, net == null ? _init : () => Navigator.pop(context), reward: rw);
  }

  void _tap(int i, [bool rem = false]) {
    if (over || bot) return;
    if (!rem) { if (!canAct(turn)) return; emit({'i': i}); }
    if (turn == 0 && hand > 0) {
      if (b[i] == 0) { mFrom = mTo = ghost = -1; setState(() { b[i] = 2; hand--; }); _next(); }
      return;
    }
    if (sel >= 0) {
      final m = tg.where((e) => e[0] == i);
      if (m.isNotEmpty) { _act(sel, i, m.first[1]); return; }
    }
    if (b[i] == (turn == 0 ? 2 : 1)) setState(() { sel = i; tg = _mv(i); });
  }

  void _act(int f, int t, int c) {
    mFrom = f; mTo = t; ghost = c; ghostV = c >= 0 ? b[c] : 0;
    mv.forward(from: 0);
    setState(() { b[t] = b[f]; b[f] = 0; if (c >= 0) { b[c] = 0; cap++; } sel = -1; tg = []; });
    if (cap >= 8) { _win('🐯 বাঘ', kCol[2], 1); return; }
    _next();
  }

  void _next() {
    setState(() { turn = 1 - turn; sel = -1; tg = []; });
    if (turn == 1 && _tigerMoves().isEmpty) { _win('🐐 ছাগল', kCol[1], 0); return; }
    if (turn == 0 && hand == 0 && !List.generate(25, (i) => i).any((i) => b[i] == 2 && _mv(i).isNotEmpty)) {
      _win('🐯 বাঘ', kCol[2], 1);
      return;
    }
    if (bot) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted || over) return;
        final a = _tigerMoves();
        final caps = a.where((e) => e[2] >= 0).toList();
        final l = caps.isNotEmpty ? caps : a;
        final m = l[rnd.nextInt(l.length)];
        _act(m[0], m[1], m[2]);
      });
    }
  }

  String nm(int i) => playerName(i, n: 2, bots: [false, widget.vsPc], vsPc: widget.vsPc, net: net);
  static const tigerCol = Color(0xFFFF9800);
  static const goatCol = Color(0xFFFFF1DC);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: WoodBg(
          child: SafeArea(
            child: LayoutBuilder(builder: (_, bc) {
              final bw = math.min(bc.maxWidth - 28, bc.maxHeight - 80 * 2 - 120).clamp(200.0, 700.0).toDouble();
              final cs = bw / 5;
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
                      Expanded(child: WoodPlate(name: nm(1), sub: 'বাঘ 🐯', score: 'ধরেছে: ${bnNum(cap)}/৮', color: tigerCol, active: turn == 1 && !over)),
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
                    SizedBox(
                      width: bw,
                      height: bw,
                      child: GestureDetector(
                        onTapUp: (d) => _tap((d.localPosition.dy / cs).floor().clamp(0, 4).toInt() * 5 + (d.localPosition.dx / cs).floor().clamp(0, 4).toInt()),
                        child: CustomPaint(
                          painter: GridPainter(5, 5, b, sel, tg, {1: tigerCol, 2: goatCol}, {1: '🐯', 2: '🐐'}, 0, mv, mFrom, mTo, ghost, ghostV),
                          size: Size(bw, bw),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    WoodPlate(name: nm(0), sub: 'ছাগল 🐐 · হাতে ${bnNum(hand)}', score: 'হারিয়েছে: ${bnNum(cap)}', color: const Color(0xFF8D6E63), active: turn == 0 && !over),
                    const SizedBox(height: 6),
                    const Text('ছাগল: ২০টি বসান, সব বাঘ আটকে দিন। বাঘ: ৮টি ছাগল ধরুন।',
                        textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF5A3410), fontWeight: FontWeight.w800, fontSize: 12.5)),
                  ]),
                ),
              );
            }),
          ),
        ),
      );
}
