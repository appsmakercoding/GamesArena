import 'package:flutter/material.dart';

class ArenaLogo extends StatelessWidget {
  final double size;
  const ArenaLogo({super.key, this.size = 96});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.28),
          gradient: const LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF7C4DFF).withOpacity(.55),
                blurRadius: size * .3,
                offset: Offset(0, size * .1))
          ],
        ),
        child: Icon(Icons.sports_esports_rounded,
            color: Colors.white, size: size * .58),
      );
}
