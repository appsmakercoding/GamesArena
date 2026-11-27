import 'package:flutter/material.dart';
import 'ui.dart';

class ArenaLogo extends StatelessWidget {
  final double size;
  const ArenaLogo({super.key, this.size = 96});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          gradient: const LinearGradient(colors: [AC.violet, AC.pink], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: Colors.white.withOpacity(.4), width: 1.5),
          boxShadow: [BoxShadow(color: AC.violet.withOpacity(.55), blurRadius: size * .3, offset: Offset(0, size * .1))],
        ),
        child: Stack(alignment: Alignment.center, children: [
          Padding(padding: EdgeInsets.only(top: size * .14), child: Dice3D(size: size * .62)),
          Positioned(top: size * .06, child: Crown(size * .3)),
        ]),
      );
}
