import 'package:flutter/material.dart';
import 'cards.dart';
import 'common.dart';

class SolitairePage extends StatefulWidget {
  const SolitairePage({super.key});
  @override
  State<SolitairePage> createState() => _SolState();
}

class _SolState extends State<SolitairePage> {
  List<PC> stock = [], waste = [];
  List<List<PC>> found = [[], [], [], []], tab = [];
  List<int> up = [];
  int sc = -1, si = 0; // source: 0-6 tableau, 7 waste

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    final d = [for (var s = 0; s < 4; s++) for (var r = 1; r <= 13; r++) PC(s, r)]..shuffle(rnd);
    tab = List.generate(7, (i) => d.sublist(i * (i + 1) ~/ 2, (i + 1) * (i + 2) ~/ 2));
    stock = d.sublist(28);
    waste = []; found = [[], [], [], []]; up = List.filled(7, 1); sc = -1;
    setState(() {});
  }

  bool _canTab(PC c, int i) => tab[i].isEmpty ? c.r == 13 : isRed(tab[i].last.s) != isRed(c.s) && tab[i].last.r == c.r + 1;
  bool _canFound(PC c) => found[c.s].isEmpty ? c.r == 1 : found[c.s].last.r == c.r - 1;
  List<PC> _sel() => sc == 7 ? [waste.last] : tab[sc].sublist(si);

  void _remove(int n) {
    if (sc == 7) {
      waste.removeLast();
    } else {
      tab[sc].removeRange(tab[sc].length - n, tab[sc].length);
      up[sc] -= n;
      if (up[sc] <= 0 && tab[sc].isNotEmpty) up[sc] = 1;
    }
    sc = -1;
  }

  bool _toTab(int i) {
    if (sc < 0 || sc == i) return false;
    final cs = _sel();
    if (!_canTab(cs.first, i)) return false;
    setState(() { tab[i].addAll(cs); up[i] += cs.length; _remove(cs.length); });
    return true;
  }

  bool _toFound() {
    if (sc < 0) return false;
    final cs = _sel();
    if (cs.length != 1 || !_canFound(cs.first)) return false;
    setState(() { found[cs.first.s].add(cs.first); _remove(1); });
    _check();
    return true;
  }

  void _auto() {
    var moved = true;
    while (moved) {
      moved = false;
      for (var i = 0; i < 8 && !moved; i++) {
        if (i == 7 ? waste.isEmpty : tab[i].isEmpty) continue;
        sc = i; si = i == 7 ? 0 : tab[i].length - 1;
        if (_toFound()) moved = true; else sc = -1;
      }
    }
    setState(() {});
  }

  void _check() {
    if (found.every((f) => f.length == 13)) showWin(context, 'আপনি', kCol[1], _init);
  }

  void _stock() => setState(() {
        sc = -1;
        if (stock.isNotEmpty) { waste.add(stock.removeLast()); } else { stock = waste.reversed.toList(); waste = []; }
      });

  void _tapTab(int i, int j) {
    if (sc == i && si == j) { _toFound(); return; }
    if (sc >= 0 && _toTab(i)) return;
    if (j >= tab[i].length - up[i]) setState(() { sc = i; si = j; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('সলিটেয়ার'), backgroundColor: Colors.transparent, actions: [
          IconButton(onPressed: _auto, icon: const Icon(Icons.auto_fix_high_rounded)),
          IconButton(onPressed: _init, icon: const Icon(Icons.refresh_rounded)),
        ]),
        body: SafeArea(
          child: LayoutBuilder(builder: (_, bc) {
            final cw = (bc.maxWidth - 16) / 7, w = cw - 4;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(children: [
                Row(children: [
                  SizedBox(width: cw, child: GestureDetector(onTap: _stock, child: stock.isEmpty ? _slot(w, '↻') : cardW(null, w: w))),
                  SizedBox(width: cw, child: waste.isEmpty ? _slot(w, '') : cardW(waste.last, w: w, sel: sc == 7, onTap: () {
                        if (sc == 7) { _toFound(); } else { setState(() { sc = 7; si = 0; }); }
                      })),
                  const Spacer(),
                  for (var s = 0; s < 4; s++)
                    SizedBox(width: cw, child: GestureDetector(onTap: _toFound, child: found[s].isEmpty ? _slot(w, kSym[s]) : cardW(found[s].last, w: w))),
                ]),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (var i = 0; i < 7; i++)
                    SizedBox(
                      width: cw,
                      height: 20 + tab[i].length * 26 + w * 1.4,
                      child: GestureDetector(
                        onTap: () => _toTab(i),
                        behavior: HitTestBehavior.opaque,
                        child: Stack(children: [
                          if (tab[i].isEmpty) _slot(w, ''),
                          for (var j = 0; j < tab[i].length; j++)
                            Positioned(
                              top: j < tab[i].length - up[i] ? j * 12.0 : (tab[i].length - up[i]) * 12.0 + (j - (tab[i].length - up[i])) * 26.0,
                              child: cardW(j < tab[i].length - up[i] ? null : tab[i][j], w: w,
                                  sel: sc == i && j >= si, onTap: j < tab[i].length - up[i] ? null : () => _tapTab(i, j)),
                            ),
                        ]),
                      ),
                    ),
                ]),
                const SizedBox(height: 40),
              ]),
            );
          }),
        ),
      );

  Widget _slot(double w, String t) => Container(
        width: w, height: w * 1.4,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(w * .16), border: Border.all(color: Colors.white24)),
        child: Text(t, style: const TextStyle(fontSize: 22, color: Colors.white38)),
      );
}
