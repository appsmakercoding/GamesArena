import 'package:flutter/material.dart';
import 'games.dart';
import 'mode_select.dart';
import 'lobby.dart';
import 'setup.dart';
import 'extras.dart';
import 'profile.dart';
import 'ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  void go(int i) => setState(() => tab = i);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AC.bg0,
        body: Column(children: [
          Expanded(
            child: ArenaBg(
              child: SafeArea(
                bottom: false,
                child: IndexedStack(index: tab, children: [
                  _HomeTab(go),
                  const RankTab(),
                  const RewardTab(),
                  const SettingsTab(),
                  const MoreTab(),
                ]),
              ),
            ),
          ),
          _NavBar(tab, go),
        ]),
      );
}

/// ───────── হোম ট্যাব ─────────
class _HomeTab extends StatelessWidget {
  final void Function(int) go;
  const _HomeTab(this.go);

  static const popular = ['ludo', 'snake', 'chess', 'carrom', 'gutti16', 'gutti12'];

  void _friends(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AC.bg1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('বন্ধুর সাথে খেলুন', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('একটি গেম বেছে রুম খুলুন, কোড বন্ধুকে দিন', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final g in kGames.where((g) => kOnline.contains(g.id)))
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LobbyPage(g, (n) => gamePage(g, 2, false, n))));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(colors: gameGrad(g)),
                    ),
                    child: Text('${g.emoji} ${g.bn}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final games = kGames.where((g) => popular.contains(g.id)).toList();
    final ludo = kGames.firstWhere((g) => g.id == 'ludo');
    return CustomScrollView(slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            // টপ বার
            ValueListenableBuilder<int>(
              valueListenable: Profile.rev,
              builder: (_, __, ___) => Row(children: [
                CircleBtn(Icons.menu_rounded, () => go(4)),
                const Expanded(
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Crown(34),
                    SizedBox(width: 8),
                    Text('গেমস ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    Text('এরিনা', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AC.gold)),
                  ]),
                ),
                CircleBtn(Icons.notifications_rounded, () => go(2), badge: (Profile.canClaim ? 1 : 0) + (Profile.canSpin ? 1 : 0)),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(flex: 6, child: CoinChip(onAdd: () => go(2))),
              const SizedBox(width: 10),
              const Expanded(flex: 5, child: LevelChip()),
            ]),
            const SizedBox(height: 14),
            // ব্যানার
            _Banner(onPlay: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ModeSelectPage(ludo)))),
            const SizedBox(height: 14),
            // কুইক অ্যাকশন
            Row(children: [
              _Quick('🎁', 'পুরস্কার', () => go(2)),
              _Quick('👑', 'র‍্যাংক', () => go(1)),
              _Quick('🎡', 'স্পিন', () => showDialog(context: context, builder: (_) => const SpinDialog())),
              _Quick('👥', 'বন্ধু', () => _friends(context)),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              const Text('🔥 ', style: TextStyle(fontSize: 20)),
              const Text('জনপ্রিয় গেমসমূহ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllGamesPage())),
                child: const Text('সব দেখুন ›', style: TextStyle(color: AC.cyan, fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 12),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 102),
          delegate: SliverChildBuilderDelegate((_, i) => GameTile(games[i]), childCount: games.length),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        sliver: SliverToBoxAdapter(
          child: Glass(
            radius: 20,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            colors: [AC.cyan.withOpacity(.22), AC.violet.withOpacity(.2)],
            child: Row(children: [
              const Text('🎁', style: TextStyle(fontSize: 38)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('প্রতিদিন খেলুন', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  Text('পান আকর্ষণীয় পুরস্কার!', style: TextStyle(color: AC.gold, fontWeight: FontWeight.w700, fontSize: 13)),
                ]),
              ),
              GlossBtn('এখনই নিন', onTap: () => go(2), colors: AC.goldGrad, textColor: const Color(0xFF4A2A00), height: 40, fontSize: 14, wide: false),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _Banner extends StatelessWidget {
  final VoidCallback onPlay;
  const _Banner({required this.onPlay});
  @override
  Widget build(BuildContext context) => Container(
        height: 158,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFD1309E), Color(0xFFFF7A3D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: Colors.white.withOpacity(.35), width: 1.4),
          boxShadow: [BoxShadow(color: AC.violet.withOpacity(.5), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(left: 8, bottom: 6, child: Text('🏆', style: TextStyle(fontSize: 92, shadows: [Shadow(color: AC.gold.withOpacity(.8), blurRadius: 28)]))),
          const Positioned(left: 96, bottom: 8, child: Text('🎲', style: TextStyle(fontSize: 38))),
          const Positioned(left: 10, top: 10, child: Text('🪙', style: TextStyle(fontSize: 24))),
          const Positioned(right: 12, top: 8, child: Text('✨', style: TextStyle(fontSize: 22))),
          Positioned(
            right: 14,
            top: 14,
            bottom: 14,
            left: 130,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Transform.rotate(
                angle: -.07,
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    StrokeText('খেলা হোক', size: 24, sw: 5, stroke: Color(0xFF3A0F80)),
                    StrokeText('আরও মজার!', size: 28, fill: AC.gold, sw: 5, stroke: Color(0xFF3A0F80)),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              GlossBtn('এখনই খেলুন', onTap: onPlay, colors: AC.goldGrad, textColor: const Color(0xFF4A2A00), height: 40, fontSize: 15, wide: false, icon: Icons.play_arrow_rounded),
            ]),
          ),
        ]),
      );
}

class _Quick extends StatelessWidget {
  final String emoji, label;
  final VoidCallback onTap;
  const _Quick(this.emoji, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Glass(
            onTap: onTap,
            radius: 18,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      );
}

/// ───────── গেম টাইল ─────────
class GameTile extends StatelessWidget {
  final GameInfo g;
  const GameTile(this.g, {super.key});
  @override
  Widget build(BuildContext context) {
    final cols = gameGrad(g);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(colors: cols, begin: Alignment.topLeft, end: Alignment.bottomRight),
        border: Border.all(color: Colors.white.withOpacity(.3), width: 1.2),
        boxShadow: [BoxShadow(color: cols.last.withOpacity(.5), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            tick();
            Navigator.push(context, MaterialPageRoute(builder: (_) => ModeSelectPage(g)));
          },
          child: Stack(children: [
            Positioned(
              left: 10,
              right: 10,
              top: 3,
              height: 34,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: [Colors.white.withOpacity(.28), Colors.white.withOpacity(0)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(children: [
                IconBubble(g.emoji, size: 52),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(g.bn, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black38, blurRadius: 4)])),
                    ),
                    Text(g.en, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
            ),
            Positioned(right: 8, bottom: 8, child: const ChevBtn(size: 26)),
            if (kOnline.contains(g.id))
              Positioned(right: 10, top: 8, child: Icon(Icons.public_rounded, size: 14, color: Colors.white.withOpacity(.75))),
          ]),
        ),
      ),
    );
  }
}

/// ───────── সব গেম ─────────
class AllGamesPage extends StatefulWidget {
  const AllGamesPage({super.key});
  @override
  State<AllGamesPage> createState() => _AllGamesPageState();
}

class _AllGamesPageState extends State<AllGamesPage> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final list = kGames.where((g) => g.bn.contains(q) || g.en.toLowerCase().contains(q.toLowerCase())).toList();
    return Scaffold(
      body: ArenaBg(
        child: SafeArea(
          child: Column(children: [
            ArenaBar('সব গেম', onBack: () => Navigator.pop(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(onChanged: (v) => setState(() => q = v), decoration: arenaInput('গেম খুঁজুন...', icon: Icons.search_rounded)),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 102),
                itemCount: list.length,
                itemBuilder: (_, i) => GameTile(list[i]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// ───────── বটম নেভিগেশন ─────────
class _NavBar extends StatelessWidget {
  final int i;
  final void Function(int) on;
  const _NavBar(this.i, this.on);

  static const _items = [
    [Icons.home_rounded, 'হোম'],
    [Icons.emoji_events_rounded, 'র‍্যাংক'],
    [Icons.card_giftcard_rounded, 'পুরস্কার'],
    [Icons.settings_rounded, 'সেটিংস'],
    [Icons.menu_rounded, 'আরও'],
  ];

  @override
  Widget build(BuildContext context) => Container(
        color: AC.bg0,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 92,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 66,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1E0F5E), Color(0xFF100733)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(.12))),
                  ),
                  child: Row(children: [
                    for (var k = 0; k < 5; k++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            tick();
                            on(k);
                          },
                          child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                            if (k != 2) Icon(_items[k][0] as IconData, size: 28, color: i == k ? AC.gold : Colors.white54),
                            if (k == 2) const SizedBox(height: 28),
                            const SizedBox(height: 2),
                            Text(_items[k][1] as String,
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: i == k ? AC.gold : Colors.white54)),
                            const SizedBox(height: 7),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      tick();
                      on(2);
                    },
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF3A1A9E), Color(0xFF1A0B4D)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        border: Border.all(color: AC.gold, width: 3),
                        boxShadow: [BoxShadow(color: AC.gold.withOpacity(i == 2 ? .7 : .35), blurRadius: 18)],
                      ),
                      child: const Icon(Icons.card_giftcard_rounded, color: AC.gold, size: 32),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
}
