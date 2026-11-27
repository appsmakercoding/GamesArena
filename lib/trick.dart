import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'cards.dart';
import 'common.dart';
import 'games.dart';
import 'game_ui.dart';
import 'profile.dart';
import 'ui.dart';

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

  Future<int> _pick(String t, List<String> l, List<int> v, {bool suits = false}) async =>
      await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (c) => _PickPanel(title: t, labels: l, values: v, suits: suits, th: _theme(k)),
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
      trump = await _pick('ট্রাম্প (রং) বেছে নিন', kSym, [0, 1, 2, 3], suits: true);
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
        trump = await _pick('${kNames[bidder]}: ট্রাম্প বেছে নিন', kSym, [0, 1, 2, 3], suits: true);
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
      showWin(context, '${kNames[w]} (${total[w]} পয়েন্ট)', kCol[w], () { total = [0, 0, 0, 0]; _deal(); }, reward: _rw(w == 0));
    } else if (k == 'hazari') {
      for (var i = 0; i < 4; i++) total[i] += pts[i];
      final m = total.reduce((a, b) => a > b ? a : b);
      if (m >= 1000) {
        final w = total.indexOf(m);
        showWin(context, '${kNames[w]} ($m)', kCol[w], () { total = [0, 0, 0, 0]; _deal(); }, reward: _rw(w == 0));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ডিল শেষ। সর্বোচ্চ: $m / ১০০০')));
        Future.delayed(const Duration(seconds: 2), () { if (mounted) _deal(); });
      }
    } else {
      final t = k == 'rang' ? (won[0] + won[2] >= 7 ? 0 : 1) : (pts[bidder % 2] + pts[bidder % 2 + 2] >= bid ? bidder % 2 : 1 - bidder % 2);
      showWin(context, '${kNames[t]} ও ${kNames[t + 2]}', kCol[t], _deal, reward: _rw(t == 0));
    }
  }

  int _rw(bool humanWon) {
    if (widget.humans != 1 || !humanWon) return 0;
    Profile.addCoins(50);
    Profile.addXp(20);
    return 50;
  }

  String _stat(int i) => k == 'spades' ? '${won[i]}/${bids[i]}' : k == 'hazari' ? '${total[i] + pts[i]}' : k == 'card29' ? '${pts[i]}pt' : '${won[i]}';

  String _name(int i) => (i == 0 && widget.humans == 1) ? 'আপনি' : '${kNames[i]}${human(i) ? '' : ' 🤖'}';

  Widget _plate(String t, {double size = 12}) => Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: const LinearGradient(colors: [Color(0xFF8A5513), Color(0xFF4A2A08)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          border: Border.all(color: const Color(0xFFE0B04A), width: 1.4),
        ),
        child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: const Color(0xFFFFE6A8))),
      );

  Widget _seat(int i) {
    final active = i == turn && !over && playing;
    return SizedBox(
      width: 88,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFF3A2A6A), Color(0xFF1A1040)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            border: Border.all(color: active ? Colors.white : AC.gold, width: active ? 3.5 : 2.5),
            boxShadow: active ? [BoxShadow(color: kCol[i].withOpacity(.8), blurRadius: 18)] : const [],
          ),
          child: ClipOval(child: Face(kCol[i], size: 40)),
        ),
        const SizedBox(height: 3),
        _plate(_name(i)),
        const SizedBox(height: 2),
        _plate(_stat(i), size: 12.5),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = playing && human(turn) && turn == view && revealed && !over && trick[turn] == null;
    final legal = canPlay ? _legal(turn) : <PC>[];
    final vs = view < 0 ? 0 : view;
    final th = _theme(k);
    const al = [Alignment(0, .55), Alignment(-.42, 0), Alignment(0, -.2), Alignment(.42, 0)];
    const rot = [.05, -.22, .1, .2];
    const seatAl = [Alignment(-1, 1), Alignment(-1, -.45), Alignment(0, -1), Alignment(1, -.45)];
    return Scaffold(
      body: Stack(children: [
        Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: th.bg, begin: Alignment.topCenter, end: Alignment.bottomCenter)),
          child: SafeArea(
            child: Column(children: [
              ArenaBar(widget.g.bn, onBack: () => Navigator.pop(context), trailing: CircleBtn(Icons.refresh_rounded, () { total = [0, 0, 0, 0]; _deal(); })),
              SizedBox(
                height: 40,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (trump >= 0)
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 5, 14, 5),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black38, border: Border.all(color: AC.gold.withOpacity(.6))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Text('ট্রাম্প ', style: TextStyle(fontWeight: FontWeight.w800)),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                          child: SuitIcon(trump, size: 18),
                        ),
                      ]),
                    ),
                  if (k == 'card29' && bidder >= 0 && playing) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black38, border: Border.all(color: AC.gold.withOpacity(.6))),
                      child: Text('বিড ${bnNum(bid)} • ${kNames[bidder]}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ]),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: RadialGradient(colors: th.table, radius: .95),
                    border: Border.all(color: AC.gold.withOpacity(.5), width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(children: [
                      Positioned.fill(child: CustomPaint(painter: _TableDeco(th.mark, k == 'card29'))),
                      for (var r = 0; r < 4; r++)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                          child: Align(alignment: seatAl[r], child: _seat((vs + r) % 4)),
                        ),
                      for (var r = 0; r < 4; r++)
                        if (trick[(vs + r) % 4] != null)
                          Align(alignment: al[r], child: Transform.rotate(angle: rot[r], child: cardW(trick[(vs + r) % 4], w: 56))),
                      Align(
                        alignment: const Alignment(0, .98),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.black38),
                            child: Text(over ? 'খেলা শেষ' : busy ? '${kNames[turn]} ভাবছে...' : '${kNames[turn]}-এর চাল', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white70)),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              SizedBox(
                height: 150,
                child: LayoutBuilder(builder: (_, bc) {
                  final h = hands[vs];
                  final n = h.length < vis ? h.length : vis;
                  const cw = 62.0;
                  final step = n < 2 ? 0.0 : ((bc.maxWidth - 24 - cw) / (n - 1)).clamp(12.0, 46.0).toDouble();
                  final total = cw + step * (n < 1 ? 0 : n - 1);
                  final left0 = (bc.maxWidth - total) / 2;
                  return Stack(children: [
                    for (var i = 0; i < n; i++)
                      Positioned(
                        left: left0 + i * step,
                        top: 26.0 + ((i - (n - 1) / 2) * (i - (n - 1) / 2)) * (n > 9 ? .5 : .9) - (canPlay && legal.contains(h[i]) ? 10 : 0),
                        child: Transform.rotate(
                          angle: (i - (n - 1) / 2) * (n > 9 ? .03 : .045),
                          alignment: Alignment.bottomCenter,
                          child: cardW(view < 0 ? null : h[i], w: cw,
                              dim: canPlay && !legal.contains(h[i]),
                              onTap: canPlay && legal.contains(h[i]) ? () => _play(turn, h[i]) : null),
                        ),
                      ),
                  ]);
                }),
              ),
            ]),
          ),
        ),
        if (widget.humans > 1 && playing && human(turn) && !revealed && !over)
          Positioned.fill(
            child: Container(
              color: const Color(0xF20E0B1F),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('ফোনটি ${kNames[turn]}-কে দিন', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kCol[turn])),
                const SizedBox(height: 20),
                SizedBox(width: 240, child: GlossBtn('আমার কার্ড দেখুন', onTap: () => setState(() => revealed = true), colors: AC.goldGrad, textColor: const Color(0xFF4A2A00))),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _Th {
  final List<Color> bg, table;
  final int mark;
  const _Th(this.bg, this.table, this.mark);
}

_Th _theme(String k) {
  switch (k) {
    case 'spades':
      return const _Th([Color(0xFF0A1630), Color(0xFF06101F)], [Color(0xFF1D3F78), Color(0xFF0E2148)], 0);
    case 'card29':
      return const _Th([Color(0xFF3A1F0C), Color(0xFF1E0F06)], [Color(0xFFB8702F), Color(0xFF6B3815)], -1);
    case 'hazari':
      return const _Th([Color(0xFF062B24), Color(0xFF03140F)], [Color(0xFF1B8A6B), Color(0xFF0B4A3A)], 3);
    default:
      return const _Th([Color(0xFF1C0B33), Color(0xFF0C0518)], [Color(0xFF6A2E9A), Color(0xFF2E1250)], 1);
  }
}

class _TableDeco extends CustomPainter {
  final int mark;
  final bool wood;
  _TableDeco(this.mark, this.wood);
  @override
  void paint(Canvas c, Size s) {
    if (wood) {
      final ln = Paint()..color = const Color(0xFF3A1D08).withOpacity(.18)..strokeWidth = 1.5;
      for (var y = 14.0; y < s.height; y += 22) {
        c.drawLine(Offset(0, y), Offset(s.width, y + (y % 3) - 1), ln);
      }
      c.drawOval(Rect.fromLTWH(s.width * .04, s.height * .08, s.width * .92, s.height * .84),
          Paint()..style = PaintingStyle.stroke..strokeWidth = 7..color = const Color(0xFFE0A15A).withOpacity(.55));
    } else {
      final r = math.min(s.width, s.height) * .3;
      c.drawCircle(s.center(Offset.zero), r * 1.2, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white.withOpacity(.07));
    }
    if (mark >= 0) {
      final z = math.min(s.width, s.height) * .45;
      c.drawPath(suitPath(mark, Rect.fromCenter(center: s.center(Offset.zero), width: z, height: z)), Paint()..color = Colors.white.withOpacity(.06));
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _PickPanel extends StatelessWidget {
  final String title;
  final List<String> labels;
  final List<int> values;
  final bool suits;
  final _Th th;
  const _PickPanel({required this.title, required this.labels, required this.values, required this.suits, required this.th});
  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(colors: th.bg, begin: Alignment.topCenter, end: Alignment.bottomCenter),
            border: Border.all(color: AC.gold.withOpacity(.7), width: 1.6),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.6), blurRadius: 24)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AC.gold)),
            const SizedBox(height: 16),
            if (suits)
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                for (var i = 0; i < labels.length; i++)
                  GestureDetector(
                    onTap: () => Navigator.pop(context, values[i]),
                    child: Container(
                      width: 62,
                      height: 78,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(colors: [Colors.white, Color(0xFFE8E3F5)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
                      ),
                      child: SuitIcon(i, size: 38),
                    ),
                  ),
              ])
            else
              Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
                for (var i = 0; i < labels.length; i++)
                  GestureDetector(
                    onTap: () { tick(); Navigator.pop(context, values[i]); },
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 62),
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: [Color(0xFFB8702F), Color(0xFF6B3815)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        border: Border.all(color: const Color(0xFFE0B04A), width: 1.5),
                      ),
                      child: Text(labels[i], style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
              ]),
          ]),
        ),
      );
}
