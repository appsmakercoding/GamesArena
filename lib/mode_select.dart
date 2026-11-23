import 'package:flutter/material.dart';
import 'games.dart';
import 'setup.dart';
import 'lobby.dart';

class ModeSelectPage extends StatelessWidget {
  final GameInfo g;
  const ModeSelectPage(this.g, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [g.colors.first.withOpacity(.55), const Color(0xFF0E0B1F)],
                begin: Alignment.topCenter,
                end: Alignment.center),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded))),
                Text(g.emoji, style: const TextStyle(fontSize: 72)),
                Text(g.bn,
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('কীভাবে খেলতে চান?', style: TextStyle(color: Colors.white60)),
                const SizedBox(height: 28),
                for (final m in g.modes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Material(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          final live = kLive.contains(g.id);
                          if (live && m == PlayMode.onlineMulti) {
                            if (kOnline.contains(g.id)) {
                              Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => LobbyPage(g, (n) => gamePage(g, 2, false, n))));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('এই গেমের অনলাইন মোড পরের আপডেটে আসছে')));
                            }
                          } else {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (_) => live ? SetupPage(g, m) : _SoonPage(g, m)));
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            CircleAvatar(
                                radius: 26,
                                backgroundColor: g.colors.first,
                                child: Icon(modeIcon(m), color: Colors.white)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(modeTitle(m, g),
                                    style: const TextStyle(
                                        fontSize: 17, fontWeight: FontWeight.w700)),
                                Text(modeSub(m),
                                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ]),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ]),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      );
}

class _SoonPage extends StatelessWidget {
  final GameInfo g;
  final PlayMode m;
  const _SoonPage(this.g, this.m);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${g.bn} • ${modeTitle(m, g)}'), backgroundColor: Colors.transparent),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(g.emoji, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              const Text('শীঘ্রই আসছে!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('এই গেমটি ফেজ ${g.phase}-এ যুক্ত হবে।',
                  style: const TextStyle(color: Colors.white60)),
            ]),
          ),
        ),
      );
}
