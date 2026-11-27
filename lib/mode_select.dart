import 'package:flutter/material.dart';
import 'games.dart';
import 'setup.dart';
import 'lobby.dart';
import 'ui.dart';

const _modeGrads = [
  [Color(0xFF3FA2FF), Color(0xFF1B54E0)],
  [Color(0xFF35E06A), Color(0xFF0E9B3C)],
  [Color(0xFFB05CFF), Color(0xFF6A22D6)],
];

/// বড় গ্লসি অপশন কার্ড (মোড / প্লেয়ার সংখ্যা — দুই জায়গাতেই ব্যবহৃত)
class OptionCard extends StatelessWidget {
  final List<Color> grad;
  final Widget avatar;
  final String title, sub;
  final bool selected, dim;
  final VoidCallback onTap;
  const OptionCard({super.key, required this.grad, required this.avatar, required this.title, required this.sub, required this.onTap, this.selected = false, this.dim = false});
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: dim ? .6 : 1,
        child: Container(
          height: 116,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border.all(color: selected ? Colors.white : Colors.white.withOpacity(.4), width: selected ? 3 : 1.4),
            boxShadow: [BoxShadow(color: grad.last.withOpacity(selected ? .8 : .45), blurRadius: selected ? 26 : 16, offset: const Offset(0, 8))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(26),
              onTap: () {
                tick();
                onTap();
              },
              child: Stack(children: [
                Positioned(
                  left: 14,
                  right: 14,
                  top: 4,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(colors: [Colors.white.withOpacity(.3), Colors.white.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(children: [
                    SizedBox(width: 112, child: Center(child: FittedBox(child: avatar))),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black38, blurRadius: 6)])),
                        ),
                        const SizedBox(height: 2),
                        Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    const SizedBox(width: 6),
                    selected
                        ? Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                            child: Icon(Icons.check_rounded, color: grad.last),
                          )
                        : const ChevBtn(size: 34),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      );
}

class ModeSelectPage extends StatelessWidget {
  final GameInfo g;
  const ModeSelectPage(this.g, {super.key});

  Widget _avatar(PlayMode m) {
    switch (m) {
      case PlayMode.vsComputer:
        return Row(children: const [Face(Color(0xFFFF4D6D), size: 52), SizedBox(width: 4), Text('🤖', style: TextStyle(fontSize: 46))]);
      case PlayMode.localMulti:
        return const FaceCluster([Color(0xFFFF4D6D), Color(0xFF4D96FF)], size: 56);
      case PlayMode.onlineMulti:
        return Row(children: const [Text('🌐', style: TextStyle(fontSize: 46)), SizedBox(width: 4), Face(Color(0xFFFFB703), size: 52)]);
    }
  }

  void _tap(BuildContext context, PlayMode m) {
    final live = kLive.contains(g.id);
    if (live && m == PlayMode.onlineMulti) {
      if (kOnline.contains(g.id)) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => LobbyPage(g, (n) => gamePage(g, 2, false, n))));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('এই গেমের অনলাইন মোড পরের আপডেটে আসছে')));
      }
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => live ? SetupPage(g, m) : _SoonPage(g, m)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final gg = gameGrad(g);
    return Scaffold(
      body: ArenaBg(
        child: SafeArea(
          child: Column(children: [
            ArenaBar('মোড নির্বাচন', onBack: () => Navigator.pop(context), trailing: CircleBtn(Icons.home_rounded, () => Navigator.popUntil(context, (r) => r.isFirst))),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 20), children: [
                Glass(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  colors: [gg.first.withOpacity(.55), AC.violet.withOpacity(.25)],
                  child: Row(children: [
                    IconBubble(g.emoji, size: 62),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(g.bn, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                        const Text('কোন মোডে খেলবেন?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AC.gold)),
                        const Text('আপনার পছন্দের মোড নির্বাচন করুন', style: TextStyle(fontSize: 12.5, color: Colors.white70)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < g.modes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: OptionCard(
                      grad: _modeGrads[i % 3],
                      avatar: _avatar(g.modes[i]),
                      title: modeTitle(g.modes[i], g),
                      sub: modeSub(g.modes[i]),
                      onTap: () => _tap(context, g.modes[i]),
                    ),
                  ),
                const SizedBox(height: 6),
                const _CrownHint(),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CrownHint extends StatelessWidget {
  const _CrownHint();
  @override
  Widget build(BuildContext context) => Column(children: [
        const Crown(54),
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.black.withOpacity(.3),
            border: Border.all(color: AC.gold.withOpacity(.8), width: 1.6),
            boxShadow: [BoxShadow(color: AC.gold.withOpacity(.25), blurRadius: 16)],
          ),
          child: const Text('বেছে নিন আপনার মোড\nএবং শুরু করুন খেলা!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, height: 1.35)),
        ),
      ]);
}

class _SoonPage extends StatelessWidget {
  final GameInfo g;
  final PlayMode m;
  const _SoonPage(this.g, this.m);
  @override
  Widget build(BuildContext context) => Scaffold(
        body: ArenaBg(
          child: SafeArea(
            child: Column(children: [
              ArenaBar('${g.bn} • ${modeTitle(m, g)}', onBack: () => Navigator.pop(context)),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      IconBubble(g.emoji, size: 120),
                      const SizedBox(height: 20),
                      const Text('শীঘ্রই আসছে!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text('এই গেমটি ফেজ ${g.phase}-এ যুক্ত হবে।', style: const TextStyle(color: Colors.white60)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}
