import 'package:flutter/material.dart';
import 'cards.dart';
import 'common.dart';
import 'games.dart';

class TrickPage extends StatefulWidget {
  final GameInfo g;
  final int humans;
  const TrickPage(this.g, this.humans, {super.key});
  @override
  State<TrickPage> createState() => _TS();
}

class _TS extends State<TrickPage> {
  String get k => widget.g.id;
  List<List<PC>> hands = [[], [], [], []];
  List<PC?> trick = [null, null, null, null];
  List<int> won = [0, 0, 0, 0], pts = [0, 0, 0, 0], total = [0, 0, 0, 0], bids = [0, 0, 0, 0];
  int turn = 0, leader = 0, lead = -1, trump = -1, view = 0, bidder = 0, bid = 0, done = 0, vis = 0;
  bool over = false, revealed = true, busy = false, playing = false;
  bool get teams => k == 'rang' || k == 'card29';
  bool human(int s) => s < widget.humans;
  static const _o29 = {11: 7, 9: 6, 14: 5, 10: 4, 13: 3, 12: 2, 8: 1, 7: 0};
  static const _v29 = {11: 3, 9: 2, 14: 1, 10: 1};

  int str(PC c) => k == 'card29' ? _o29[c.r]! : c.r;
  int val(PC c) => k == 'card29' ? (_v29[c.r] ?? 0) : k == 'hazari' ? c.r : 0;
  bool beats(PC a, PC b) => a.s == b.s ? str(a) > str(b) : a.s == trump;

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _sort(int i, int n) {
    final sub = hands[i].sublist(0, n)..sort((a, b) => a.s != b.s ? a.s - b.s : str(b) - str(a));
    hands[i] = [...sub, ...hands[i].sublist(n)];
  }

  Future<int> _pick(String t, List<String> l, List<int> v) async =>
      await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF1B1140),
          title: Text(t),
          content: Wrap(spacing: 8, runSpacing: 8, children: [
            for (var i = 0; i < l.length; i++) FilledButton(onPressed: () => Navigator.pop(c, v[i]), child: Text(l[i])),
          ]),
        ),
      ) ??
      v[0];

  Future<void> _deal() async {
    over = false; playing = false;
    final ranks = k == 'card29' ? [7, 8, 9, 10, 11, 12, 13, 14] : List.generate(13, (i) => i + 2);
    final d = [for (var s = 0; s < 4; s++) for (final r in ranks) PC(s, r)]..shuffle(rnd);
    final per = ranks.length;
    hands = List.generate(4, (i) => d.sublist(i * per, (i + 1) * per));
    won = [0, 0, 0, 0]; pts = [0, 0, 0, 0]; trick = [null, null, null, null];
    done = 0; trump = -1; lead = -1; leader = 0; turn = 0; view = 0; revealed = true;
    vis = per;
    if (k == 'spades') {
      trump = 0;
      for (var i = 0; i < 4; i++) {
        if (human(i)) {
          view = i; _sortAll(); setState(() {});
          bids[i] = await _pick('${kNames[i]}: আপনার বিড কত হাত?', [for (var b = 1; b <= 8; b++) '$b'], [for (var b = 1; b <= 8; b++) b]);
        } else {
          bids[i] = hands[i].where((c) => c.r >= 13 || (c.s == 0 && c.r >= 9)).length.clamp(1, 6).toInt();
        }
      }
    } else if (k == 'rang') {
      vis = 5; for (var i = 0; i < 4; i++) _sort(i, 5);
      setState(() {});
      trump = await _pick('ট্রাম্প (রং) বেছে নিন', kSym, [0, 1, 2, 3]);
      vis = 13;
    } else if (k == 'card29') {
      vis = 4; for (var i = 0; i < 4; i++) _sort(i, 4);
      setState(() {});
      var high = 15; bidder = -1;
      for (var i = 0; i < 4; i++) {
        final p4 = hands[i].take(4).fold(0, (a, c) => a + val(c));
        if (human(i)) {
          view = i; setState(() {});
          final b = await _pick('${kNames[i]}: বিড (পয়েন্ট)', ['পাস', for (var x = high + 1; x <= high + 5 && x <= 28; x++) '$x'], [0, for (var x = high + 1; x <= high + 5 && x <= 28; x++) x]);
          if (b > 0) { high = b; bidder = i; }
        } else if (high + 1 <= 15 + p4 && high < 28) {
          high = high + 1 < 16 ? 16 : high + 1; bidder = i;
        }
      }
      if (bidder < 0) { bidder = 3; high = 16; }
      bid = high;
      if (human(bidder)) {
        view = bidder; setState(() {});
        trump = await _pick('${kNames[bidder]}: ট্রাম্প বেছে নিন', kSym, [0, 1, 2, 3]);
      } else {
        final sc = List.filled(4, 0);
        for (final c in hands[bidder].take(4)) sc[c.s] += 1 + val(c);
        trump = sc.indexOf(sc.reduce((a, b) => a > b ? a : b));
      }
      vis = 8;
    }
    _sortAll();
    view = widget.humans > 1 ? 0 : 0;
    playing = true;
    setState(() {});
    _auto();
  }

  void _sortAll() { for (var i = 0; i < 4; i++) _sort(i, hands[i].length); }

  List<PC> _legal(int s) {
    final h = hands[s];
    if (lead < 0) return h;
    final f = h.where((c) => c.s == lead).toList();
    return f.isEmpty ? h : f;
  }

  void _auto() {
    if (over || busy || !playing) return;
    if (human(turn)) {
      if (widget.humans > 1) revealed = false;
      view = turn;
      setState(() {});
      return;
    }
    if (widget.humans > 1) view = -1;
    busy = true;
    setState(() {});
    Future.delayed(const Duration(milliseconds: 750), () {
      busy = false;
      if (mounted && !over) _play(turn, _botPick(turn));
    });
  }

  PC _botPick(int s) {
    final l = _legal(s)..sort((a, b) => str(a) - str(b));
    if (lead < 0) return l.where((c) => c.s != trump).isNotEmpty ? l.where((c) => c.s != trump).last : l.last;
    var w = leader;
    for (var j = 1; j < 4; j++) {
      final t = (leader + j) % 4;
      if (trick[t] != null && beats(trick[t]!, trick[w]!)) w = t;
    }
    if (teams && w % 2 == s % 2) return l.first;
    final wins = l.where((c) => beats(c, trick[w]!)).toList();
    return wins.isNotEmpty ? wins.first : l.first;
  }

  void _play(int s, PC c) {
    setState(() {
      hands[s].remove(c);
      trick[s] = c;
      if (lead < 0) lead = c.s;
    });
    if (trick.every((e) => e != null)) {
      Future.delayed(const Duration(milliseconds: 1000), _resolve);
    } else {
      turn = (s + 1) % 4;
      _auto();
    }
  }

  void _resolve() {
    if (!mounted) return;
    var w = leader;
    for (var j = 1; j < 4; j++) {
      final t = (leader + j) % 4;
      if (beats(trick[t]!, trick[w]!)) w = t;
    }
    setState(() {
      won[w]++;
      pts[w] += trick.fold(0, (a, c) => a + val(c!));
      done++;
      if (k == 'card29' && hands[0].isEmpty) pts[w] += 1;
      trick = [null, null, null, null]; lead = -1; leader = w; turn = w;
    });
    hands[0].isEmpty ? _end() : _auto();
  }

  void _end() {
    over = true;
    if (k == 'spades') {
      for (var i = 0; i < 4; i++) total[i] += won[i] >= bids[i] ? bids[i] * 10 + (won[i] - bids[i]) : -bids[i] * 10;
      final w = total.indexOf(total.reduce((a, b) => a > b ? a : b));
      showWin(context, '${kNames[w]} (${total[w]} পয়েন্ট)', kCol[w], () { total = [0, 0, 0, 0]; _deal(); });
    } else if (k == 'hazari') {
      for (var i = 0; i < 4; i++) total[i] += pts[i];
      final m = total.reduce((a, b) => a > b ? a : b);
      if (m >= 1000) {
        final w = total.indexOf(m);
        showWin(context, '${kNames[w]} ($m)', kCol[w], () { total = [0, 0, 0, 0]; _deal(); });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ডিল শেষ। সর্বোচ্চ: $m / ১০০০')));
        Future.delayed(const Duration(seconds: 2), () { if (mounted) _deal(); });
      }
    } else {
      final t = k == 'rang' ? (won[0] + won[2] >= 7 ? 0 : 1) : (pts[bidder % 2] + pts[bidder % 2 + 2] >= bid ? bidder % 2 : 1 - bidder % 2);
      showWin(context, '${kNames[t]} ও ${kNames[t + 2]}', kCol[t], _deal);
    }
  }

  String _stat(int i) => k == 'spades' ? '${won[i]}/${bids[i]}' : k == 'hazari' ? '${total[i] + pts[i]}' : k == 'card29' ? '${pts[i]}pt' : '${won[i]}';

  @override
  Widget build(BuildContext context) {
    final canPlay = playing && human(turn) && turn == view && revealed && !over && trick[turn] == null;
    final legal = canPlay ? _legal(turn) : <PC>[];
    final vs = view < 0 ? 0 : view;
    const al = [Alignment(0, .9), Alignment(-.95, 0), Alignment(0, -.9), Alignment(.95, 0)];
    return Scaffold(
      appBar: AppBar(title: Text(widget.g.bn), backgroundColor: Colors.transparent, actions: [
        if (trump >= 0) Padding(padding: const EdgeInsets.only(right: 8), child: Center(child: Text('ট্রাম্প ${kSym[trump]}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))),
        IconButton(onPressed: () { total = [0, 0, 0, 0]; _deal(); }, icon: const Icon(Icons.refresh_rounded)),
      ]),
      body: Stack(children: [
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < 4; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                    decoration: BoxDecoration(color: i == turn ? kCol[i] : Colors.white10, borderRadius: BorderRadius.circular(20)),
                    child: Text('${kNames[i]}${human(i) ? '' : '🤖'} ${_stat(i)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
              ]),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: [Color(0xFF0F5C4A), Color(0xFF0B3D33)])),
                child: Stack(children: [
                  for (var r = 0; r < 4; r++)
                    Align(alignment: al[r], child: cardW(trick[(vs + r) % 4], w: 50)),
                  Center(child: Text(over ? '' : '${kNames[turn]}-এর চাল', style: const TextStyle(color: Colors.white38))),
                ]),
              ),
            ),
            SizedBox(
              height: 100,
              child: LayoutBuilder(builder: (_, bc) {
                final h = hands[vs];
                final step = h.length < 2 ? 40.0 : ((bc.maxWidth - 24 - 52) / (h.length - 1)).clamp(10.0, 40.0);
                final tw = 52 + step * (h.length - 1);
                return Center(
                  child: SizedBox(
                    width: tw, height: 90,
                    child: Stack(children: [
                      for (var i = 0; i < h.length && i < vis; i++)
                        Positioned(
                          left: i * step, top: 10,
                          child: cardW(view < 0 ? null : h[i], w: 52,
                              dim: canPlay && !legal.contains(h[i]),
                              onTap: canPlay && legal.contains(h[i]) ? () => _play(turn, h[i]) : null),
                        ),
                    ]),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
          ]),
        ),
        if (widget.humans > 1 && playing && human(turn) && !revealed && !over)
          Positioned.fill(
            child: Container(
              color: const Color(0xF20E0B1F),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('ফোনটি ${kNames[turn]}-কে দিন', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kCol[turn])),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => setState(() => revealed = true), child: const Text('আমার কার্ড দেখুন')),
              ]),
            ),
          ),
      ]),
    );
  }
}
