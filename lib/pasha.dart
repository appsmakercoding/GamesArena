import 'dart:async';
import 'package:flutter/material.dart';
import 'common.dart';

class PashaPage extends StatefulWidget {
  final int n;
  final bool vsPc;
  const PashaPage(this.n, this.vsPc, {super.key});
  @override
  State<PashaPage> createState() => _PashaState();
}

class _PashaState extends State<PashaPage> {
  late List<int> sc;
  List<int> d = [0, 0, 0];
  List<bool> hold = [false, false, false];
  int turn = 0, round = 1, left = 3;
  bool rolling = false, over = false;
  bool get bot => widget.vsPc && turn > 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    sc = List.filled(widget.n, 0);
    turn = 0; round = 1; over = false; _reset();
    setState(() {});
  }

  void _reset() {
    d = [0, 0, 0]; hold = [false, false, false]; left = 3; rolling = false;
    if (bot) Future.delayed(const Duration(milliseconds: 900), () { if (mounted && !over) _roll(); });
  }

  int _score() {
    final s = [...d]..sort();
    var p = s[0] + s[1] + s[2];
    if (s[0] == s[2]) p += 30;
    else if (s[0] == s[1] || s[1] == s[2]) p += 10;
    else if (s[1] == s[0] + 1 && s[2] == s[1] + 1) p += 20;
    return p;
  }

  void _roll() {
    if (rolling || left == 0 || over) return;
    rolling = true;
    var k = 0;
    Timer.periodic(const Duration(milliseconds: 70), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() { for (var i = 0; i < 3; i++) if (!hold[i]) d[i] = rnd.nextInt(6) + 1; });
      if (++k >= 8) {
        t.cancel();
        setState(() { rolling = false; left--; });
        if (bot) Future.delayed(const Duration(milliseconds: 900), _botStep);
        else if (left == 0) Future.delayed(const Duration(milliseconds: 700), _end);
      }
    });
  }

  void _botStep() {
    if (!mounted || over) return;
    if (left == 0 || (d[0] == d[1] && d[1] == d[2])) { _end(); return; }
    setState(() {
      for (var i = 0; i < 3; i++) {
        final same = d.where((e) => e == d[i]).length > 1;
        hold[i] = same || (d.toSet().length == 3 && d[i] >= 5);
      }
    });
    _roll();
  }

  void _end() {
    if (!mounted || over || d[0] == 0) return;
    setState(() { sc[turn] += _score(); turn++; });
    if (turn == widget.n) {
      turn = 0; round++;
      if (round > 5) {
        over = true;
        final w = sc.indexOf(sc.reduce((a, b) => a > b ? a : b));
        setState(() {});
        showWin(context, '${kNames[w]} (${sc[w]} পয়েন্ট)', kCol[w], _init);
        return;
      }
    }
    setState(_reset);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('পাশা খেলা • রাউন্ড ${round > 5 ? 5 : round}/৫'), backgroundColor: Colors.transparent,
            actions: [IconButton(onPressed: _init, icon: const Icon(Icons.refresh_rounded))]),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < widget.n; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: i == turn ? kCol[i] : Colors.white10, borderRadius: BorderRadius.circular(30)),
                    child: Text('${kNames[i]}${widget.vsPc && i > 0 ? ' 🤖' : ''}: ${sc[i]}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
              ]),
            ),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(children: [
                    DiceView(d[i], active: hold[i], color: hold[i] ? kCol[1] : kCol[turn],
                        onTap: bot || left == 3 || left == 0 || rolling ? null : () => setState(() => hold[i] = !hold[i])),
                    const SizedBox(height: 6),
                    Text(hold[i] ? '🔒 রাখা' : '', style: TextStyle(color: kCol[1])),
                  ]),
                ),
            ]),
            const SizedBox(height: 12),
            Text(d[0] == 0 ? '' : 'এই চালের স্কোর: ${_score()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (!bot)
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: kCol[turn], padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                  onPressed: rolling || left == 0 ? null : _roll,
                  child: Text(left == 3 ? '🎲 ছুড়ুন' : '🎲 আবার ছুড়ুন ($left)', style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                  onPressed: rolling || left == 3 ? null : _end,
                  child: const Text('✅ রাখুন', style: TextStyle(fontSize: 16)),
                ),
              ]),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text('৩ ডাইস • জোড়া +১০, সিকোয়েন্স +২০, তিনটি সমান +৩০। ডাইসে ট্যাপ করে রেখে আবার ছুড়ুন।',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ]),
        ),
      );
}
