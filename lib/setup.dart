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

class SetupPage extends StatefulWidget {
  final GameInfo g;
  final PlayMode m;
  const SetupPage(this.g, this.m, {super.key});
  @override
  State<SetupPage> createState() => _SetupState();
}

class _SetupState extends State<SetupPage> {
  int n = 2;
  @override
  Widget build(BuildContext context) {
    final pc = widget.m == PlayMode.vsComputer;
    final id = widget.g.id;
    final fixed = kTwoOnly.contains(id) || id == 'solitaire' || (kCards.contains(id) && pc);
    return Scaffold(
      appBar: AppBar(title: Text(widget.g.bn), backgroundColor: Colors.transparent),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.g.emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            if (fixed)
              Text(id == 'solitaire' ? 'একা খেলার গেম' : kCards.contains(id) ? 'আপনি + ৩ কম্পিউটার' : '২ জনের খেলা', style: const TextStyle(fontSize: 18))
            else ...[
              Text(kCards.contains(id) ? 'কতজন মানুষ খেলবেন? (বাকিরা কম্পিউটার)' : pc ? 'মোট খেলোয়াড় (আপনি + কম্পিউটার)' : 'কতজন খেলবেন?', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Wrap(spacing: 12, children: [
                for (final k in [2, 3, 4])
                  ChoiceChip(
                    label: Text('$k জন', style: const TextStyle(fontSize: 16)),
                    selected: n == k,
                    selectedColor: widget.g.colors.first,
                    onSelected: (_) => setState(() => n = k),
                  ),
              ]),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: widget.g.colors.first, padding: const EdgeInsets.all(16)),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('খেলা শুরু', style: TextStyle(fontSize: 18)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => gamePage(widget.g, n, pc))),
              ),
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
