import 'dart:math';
import 'package:flutter/material.dart';

const kCol = [Color(0xFFFF4D6D), Color(0xFF2EC4B6), Color(0xFFFFB703), Color(0xFF4D96FF)];
const kNames = ['লাল', 'সবুজ', 'হলুদ', 'নীল'];
Random rnd = Random();
void seedRnd(int s) => rnd = Random(s);

class DiceView extends StatelessWidget {
  final int v;
  final bool active;
  final Color color;
  final VoidCallback? onTap;
  const DiceView(this.v, {super.key, this.active = false, this.color = Colors.white, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 84,
          height: 84,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color, width: 4),
            boxShadow: [BoxShadow(color: color.withOpacity(active ? .8 : .2), blurRadius: active ? 24 : 6)],
          ),
          child: Text(v == 0 ? '🎲' : '⚀⚁⚂⚃⚄⚅'[v - 1],
              style: const TextStyle(fontSize: 56, color: Colors.black87, height: 1)),
        ),
      );
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

void showWin(BuildContext c, String name, Color col, VoidCallback again) => showDialog(
      context: c,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B1140),
        title: Text('🏆 $name জিতেছে!', textAlign: TextAlign.center, style: TextStyle(color: col, fontWeight: FontWeight.w900)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(onPressed: () { Navigator.pop(c); Navigator.pop(c); }, child: const Text('হোম')),
          FilledButton(onPressed: () { Navigator.pop(c); again(); }, child: const Text('আবার খেলুন')),
        ],
      ),
    );
