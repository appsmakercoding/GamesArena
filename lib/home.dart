import 'package:flutter/material.dart';
import 'games.dart';
import 'logo.dart';
import 'mode_select.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String q = '';
  int navIdx = 0;

  void _openTabSheet(int idx) {
    if (idx == 0) {
      setState(() => navIdx = 0);
      return;
    }
    setState(() => navIdx = idx);
    final info = idx == 1
        ? ('🏆 লিডারবোর্ড ও র‍্যাংক', 'অফলাইন ও অনলাইন ম্যাচে জিতে নিজের র‍্যাংক বাড়ান। মোট \${kGames.length}টি গেম রয়েছে।')
        : idx == 2
            ? ('🎁 প্রতিদিনের চ্যালেঞ্জ', 'প্রতিদিন লুডু, দাবা, ক্যারাম বা তাসের নতুন ম্যাচ খেলে মজা নিন!')
            : ('⚙️ অ্যাপ তথ্য', 'গেমস এরিনা • Powered by Hasan\nসব গেম মোড আগের মতোই সচল রয়েছে।');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1046),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info.$1, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(info.$2, style: const TextStyle(color: Colors.white70, height: 1.4)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(c);
                  setState(() => navIdx = 0);
                },
                child: const Text('ঠিক আছে'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = kGames
        .where((g) => g.bn.contains(q) || g.en.toLowerCase().contains(q.toLowerCase()))
        .toList();

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
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const ArenaLogo(size: 44),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '👑 গেমস এরিনা',
                            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                          ),
                          Text(
                            'খেলুন, জিতুন, মজা করুন!',
                            style: TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.withOpacity(.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, color: Colors.amber, size: 18),
                          SizedBox(width: 4),
                          Text('ARENA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2), Color(0xFFFF4081)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white.withOpacity(.2)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C4DFF).withOpacity(.36),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '🏆 গেমস এরিনা',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'খেলা হোক আরও মজার!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFFB703),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                if (kGames.isNotEmpty) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ModeSelectPage(kGames.first)),
                                  );
                                }
                              },
                              child: const Text(
                                'এখনই খেলুন ▶',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 68,
                        height: 68,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('🎲', style: TextStyle(fontSize: 38)),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  onChanged: (v) => setState(() => q = v),
                  decoration: InputDecoration(
                    hintText: 'গেম খুঁজুন...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white10,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🔥 জনপ্রিয় গেমসমূহ',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '\${list.length}টি গেম',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.18,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _GameCard(list[i]),
                ),
              ),
              _BottomBar(
                index: navIdx,
                onTap: _openTabSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameInfo g;
  const _GameCard(this.g);
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: g.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(.2)),
            boxShadow: [
              BoxShadow(
                color: g.colors.first.withOpacity(.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ModeSelectPage(g)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(g.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.bn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          g.en,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 22),
                ],
              ),
            ),
          ),
        ),
      );
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'হোম'),
      (Icons.emoji_events_rounded, 'র‍্যাংক'),
      (Icons.card_giftcard_rounded, 'পুরস্কার'),
      (Icons.settings_rounded, 'সেটিংস'),
    ];
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      decoration: const BoxDecoration(
        color: Color(0xFF140D33),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: i == index
                          ? const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)])
                          : null,
                      color: i == index ? null : Colors.white10,
                    ),
                    child: Icon(items[i].$1, size: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].$2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: i == index ? FontWeight.w800 : FontWeight.w500,
                      color: i == index ? Colors.white : Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
