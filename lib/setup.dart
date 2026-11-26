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

  static const _cardGrads = [
    [Color(0xFF0072FF), Color(0xFF00C6FF)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFF8E2DE2), Color(0xFFFF4081)],
  ];

  void _start(int players) {
    final pc = widget.m == PlayMode.vsComputer;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => gamePage(widget.g, players, pc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pc = widget.m == PlayMode.vsComputer;
    final id = widget.g.id;
    final fixed = kTwoOnly.contains(id) || id == 'solitaire' || (kCards.contains(id) && pc);
    final fixedPlayers = id == 'solitaire' ? 1 : (kTwoOnly.contains(id) ? 2 : (kCards.contains(id) ? 1 : 2));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D114D), Color(0xFF0C081D), Color(0xFF060410)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        'খেলোয়াড় নির্বাচন',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A11CB), Color(0xFF9C27B0)],
                    ),
                    border: Border.all(color: Colors.white.withOpacity(.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '\${widget.g.emoji} \${widget.g.bn}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fixed
                            ? (id == 'solitaire'
                                ? 'একা খেলার গেম'
                                : kCards.contains(id)
                                    ? 'আপনি + ৩ কম্পিউটার'
                                    : '২ জনের খেলা')
                            : (kCards.contains(id)
                                ? 'কতজন মানুষ খেলবেন? (বাকিরা কম্পিউটার)'
                                : pc
                                    ? 'মোট খেলোয়াড় (আপনি + কম্পিউটার)'
                                    : 'কতজন খেলবেন?'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (fixed)
                  _BannerOption(
                    title: id == 'solitaire'
                        ? '১ জন'
                        : kCards.contains(id)
                            ? 'সোলো ম্যাচ'
                            : '২ জন',
                    subtitle: id == 'solitaire'
                        ? 'একা খেলুন'
                        : kCards.contains(id)
                            ? 'আপনি + ৩ বট'
                            : 'দুই জনের জন্য',
                    emoji: widget.g.emoji,
                    colors: _cardGrads[0],
                    onTap: () => _start(fixedPlayers),
                  )
                else
                  for (var idx = 0; idx < 3; idx++) ...[
                    Builder(builder: (_) {
                      final k = [2, 3, 4][idx];
                      final label = k == 2 ? '২ জন' : k == 3 ? '৩ জন' : '৪ জন';
                      final sub = k == 2
                          ? 'দুই জনের জন্য'
                          : k == 3
                              ? 'তিন জনের জন্য'
                              : 'চার জনের জন্য';
                      return _BannerOption(
                        title: label,
                        subtitle: sub,
                        emoji: k == 2 ? '👥' : k == 3 ? '👨‍👩‍👦' : '👨‍👩‍👧‍👦',
                        colors: _cardGrads[idx],
                        onTap: () {
                          setState(() => n = k);
                          _start(k);
                        },
                      );
                    }),
                    if (idx < 2) const SizedBox(height: 14),
                  ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFF1D1344),
                    border: Border.all(color: Colors.amber.withOpacity(.55)),
                  ),
                  child: const Text(
                    '👑 বেছে নিন আপনার প্লেয়ার এবং শুরু করুন খেলা!',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.amberAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerOption extends StatelessWidget {
  final String title, subtitle, emoji;
  final List<Color> colors;
  final VoidCallback onTap;

  const _BannerOption({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(colors: colors, begin: Alignment.centerLeft, end: Alignment.centerRight),
            border: Border.all(color: Colors.white.withOpacity(.2)),
            boxShadow: [
              BoxShadow(
                color: colors.last.withOpacity(.32),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(.22),
                    ),
                    child: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

Widget gamePage(GameInfo g, int n, bool pc, [Net? net]) {
  switch (g.id) {
    case 'ludo':
      return LudoPage(n, pc, net: net);
    case 'snake':
      return SnakePage(n, pc, net: net);
    case 'baghbakri':
      return TigerPage(pc, net: net);
    case 'kori':
      return KoriPage(n, pc, net: net);
    case 'pasha':
      return PashaPage(n, pc);
    case 'chess':
      return ChessPage(pc, net: net);
    case 'carrom':
      return CarromPage(pc, net: net);
    case 'solitaire':
      return const SolitairePage();
    case 'hazari':
    case 'card29':
    case 'rang':
    case 'spades':
      return TrickPage(g, pc ? 1 : n);
    default:
      return GuttiPage(g, pc, net: net);
  }
}
