import 'package:flutter/material.dart';

const kSym = ['♠', '♥', '♦', '♣'];
bool isRed(int s) => s == 1 || s == 2;

class PC {
  final int s, r; // suit 0-3, rank 2..14 (A=14) ; solitaire uses A=1
  const PC(this.s, this.r);
}

String rankLabel(int r) => r == 1 || r == 14 ? 'A' : r == 11 ? 'J' : r == 12 ? 'Q' : r == 13 ? 'K' : '$r';

Widget cardW(PC? c, {double w = 50, bool dim = false, bool sel = false, VoidCallback? onTap}) {
  final col = c == null ? Colors.white : isRed(c.s) ? const Color(0xFFE63757) : const Color(0xFF1B1B2F);
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      transform: Matrix4.translationValues(0, sel ? -12 : 0, 0),
      width: w,
      height: w * 1.4,
      decoration: BoxDecoration(
        color: c == null ? null : (dim ? const Color(0xFFCFCAE6) : Colors.white),
        gradient: c == null ? const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
        borderRadius: BorderRadius.circular(w * .16),
        border: Border.all(color: sel ? const Color(0xFF2EC4B6) : (c == null ? Colors.white54 : Colors.black12), width: sel ? 3 : 1.5),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
      ),
      child: c == null
          ? Center(child: Text('🂠', style: TextStyle(fontSize: w * .6, color: Colors.white54)))
          : Stack(children: [
              Positioned(
                top: 2, left: 5,
                child: Column(children: [
                  Text(rankLabel(c.r), style: TextStyle(fontSize: w * .32, fontWeight: FontWeight.w900, color: col, height: 1.05)),
                  Text(kSym[c.s], style: TextStyle(fontSize: w * .3, color: col, height: 1)),
                ]),
              ),
              Align(alignment: const Alignment(.5, .55), child: Text(kSym[c.s], style: TextStyle(fontSize: w * .55, color: col.withOpacity(.85)))),
            ]),
    ),
  );
}
