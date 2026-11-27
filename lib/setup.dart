import 'package:flutter/material.dart';
import 'games.dart';
import 'ludo.dart';
import 'snake.dart';
import 'gutti.dart';
import 'tiger.dart';
import 'kori.dart';
import 'pasha.dart';
import 'trick.dart';
import 'solitaire.dart';
import 'chess.dart';
import 'carrom.dart';
import 'net.dart';
import 'common.dart';
import 'mode_select.dart';
import 'ui.dart';

class SetupPage extends StatefulWidget {
  final GameInfo g;
  final PlayMode m;
  const SetupPage(this.g, this.m, {super.key});
  @override
  State<SetupPage> createState() => _SetupState();
}

class _SetupState extends State<SetupPage> {
  int n = 2;
  static const _grads = [
    [Color(0xFF3FA2FF), Color(0xFF1B54E0)],
    [Color(0xFF35E06A), Color(0xFF0E9B3C)],
    [Color(0xFFB05CFF), Color(0xFF6A22D6)],
  ];
  static const _words = {2: 'দুই', 3: 'তিন', 4: 'চার'};

  @override
  Widget build(BuildContext context) {
    final pc = widget.m == PlayMode.vsComputer;
    final id = widget.g.id;
    final fixed = kTwoOnly.contains(id) || id == 'solitaire' || (kCards.contains(id) && pc);
    final heading = fixed
        ? (id == 'solitaire' ? 'একা খেলার গেম' : kCards.contains(id) ? 'আপনি + ৩ কম্পিউটার' : '২ জনের খেলা')
        : (kCards.contains(id) ? 'কতজন মানুষ খেলবেন? (বাকিরা কম্পিউটার)' : pc ? 'মোট খেলোয়াড় (আপনি + কম্পিউটার)' : 'কতজন খেলবেন?');
    return Scaffold(
      body: ArenaBg(
        child: SafeArea(
          child: Column(children: [
            ArenaBar(widget.g.bn, onBack: () => Navigator.pop(context)),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 16), children: [
                Glass(
                  colors: [gameGrad(widget.g).first.withOpacity(.55), AC.violet.withOpacity(.25)],
                  child: Row(children: [
                    IconBubble(widget.g.emoji, size: 58),
                    const SizedBox(width: 14),
                    Expanded(child: Text(heading, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                  ]),
                ),
                const SizedBox(height: 16),
                if (fixed)
                  Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: IconBubble(widget.g.emoji, size: 130)))
                else
                  for (final k in [2, 3, 4])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: OptionCard(
                        grad: _grads[k - 2],
                        selected: n == k,
                        dim: n != k,
                        avatar: FaceCluster(kCol.take(k).toList(), size: 52),
                        title: '${bnNum(k)} জন',
                        sub: '${_words[k]} জনের জন্য',
                        onTap: () => setState(() => n = k),
                      ),
                    ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: GlossBtn('খেলা শুরু', icon: Icons.play_arrow_rounded, colors: AC.goldGrad, textColor: const Color(0xFF4A2A00), height: 60, fontSize: 21, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => gamePage(widget.g, n, pc)))),
            ),
          ]),
        ),
      ),
    );
  }
}

Widget gamePage(GameInfo g, int n, bool pc, [Net? net]) {
  switch (g.id) {
    case 'ludo': return LudoPage(n, pc, net: net);
    case 'snake': return SnakePage(n, pc, net: net);
    case 'baghbakri': return TigerPage(pc, net: net);
    case 'kori': return KoriPage(n, pc, net: net);
    case 'pasha': return PashaPage(n, pc);
    case 'chess': return ChessPage(pc, net: net);
    case 'carrom': return CarromPage(pc, net: net);
    case 'solitaire': return const SolitairePage();
    case 'hazari': case 'card29': case 'rang': case 'spades': return TrickPage(g, pc ? 1 : n);
    default: return GuttiPage(g, pc, net: net);
  }
}
