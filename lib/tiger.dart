import 'package:flutter/material.dart';
import 'common.dart';
import 'net.dart';
import 'gutti.dart';

class TigerPage extends StatefulWidget {
  final bool vsPc;
  final Net? net;
  const TigerPage(this.vsPc, {super.key, this.net});
  @override
  State<TigerPage> createState() => _TigerState();
}

class _TigerState extends State<TigerPage> with NetMix<TigerPage> {
  @override
  Net? get net => widget.net;
  @override
  bool remote(Map a) { _tap(a['i'] as int, true); return true; }

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

  void _init() {
    b = List.filled(25, 0);
    for (final t in [0, 4, 20, 24]) b[t] = 1;
    turn = 0; hand = 20; cap = 0; sel = -1; over = false; tg = [];
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

  void _win(String s, Color c) { over = true; showWin(context, s, c, net == null ? _init : () => Navigator.pop(context)); }

  void _tap(int i, [bool rem = false]) {
    if (over || bot) return;
    if (!rem) { if (!canAct(turn)) return; emit({'i': i}); }
    if (turn == 0 && hand > 0) {
      if (b[i] == 0) { setState(() { b[i] = 2; hand--; }); _next(); }
      return;
    }
    if (sel >= 0) {
      final m = tg.where((e) => e[0] == i);
      if (m.isNotEmpty) { _act(sel, i, m.first[1]); return; }
    }
    if (b[i] == (turn == 0 ? 2 : 1)) setState(() { sel = i; tg = _mv(i); });
  }

  void _act(int f, int t, int c) {
    setState(() { b[t] = b[f]; b[f] = 0; if (c >= 0) { b[c] = 0; cap++; } sel = -1; tg = []; });
    if (cap >= 8) { _win('🐯 বাঘ', kCol[2]); return; }
    _next();
  }

  void _next() {
    setState(() { turn = 1 - turn; sel = -1; tg = []; });
    if (turn == 1 && _tigerMoves().isEmpty) { _win('🐐 ছাগল', kCol[1]); return; }
    if (turn == 0 && hand == 0 && !List.generate(25, (i) => i).any((i) => b[i] == 2 && _mv(i).isNotEmpty)) {
      _win('🐯 বাঘ', kCol[2]);
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('বাঘ-বকরি'), backgroundColor: Colors.transparent,
            actions: [if (net == null) IconButton(onPressed: _init, icon: const Icon(Icons.refresh_rounded))]),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(turn == 0 ? '🐐 ছাগলের চাল' : '🐯 বাঘের চাল',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: turn == 0 ? kCol[1] : kCol[2])),
            ),
            Text('হাতে ছাগল: $hand   •   ধরা পড়েছে: $cap/৮', style: const TextStyle(color: Colors.white70)),
            Expanded(child: BoardView(5, 5, GridPainter(5, 5, b, sel, tg, {1: kCol[2], 2: kCol[1]}, {1: '🐯', 2: '🐐'}), _tap)),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('ছাগল: ২০টি বসান, সব বাঘ আটকে দিন। বাঘ: ৮টি ছাগল ধরুন।',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ]),
        ),
      );
}
