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

  @override
  Widget build(BuildContext context) {
    final list = kGames
        .where((g) => g.bn.contains(q) || g.en.toLowerCase().contains(q.toLowerCase()))
        .toList();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF1B1140), Color(0xFF0E0B1F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(children: [
                const ArenaLogo(size: 50),
                const SizedBox(width: 14),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('গেমস এরিনা',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  Text('খেলুন, জিতুন, মজা করুন!',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                ]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                onChanged: (v) => setState(() => q = v),
                decoration: InputDecoration(
                  hintText: 'গেম খুঁজুন...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white10,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: .95),
                itemCount: list.length,
                itemBuilder: (_, i) => _GameCard(list[i]),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10, top: 4),
              child: Text('Powered by Hasan',
                  style: TextStyle(color: Colors.white38, letterSpacing: 1.5, fontSize: 12)),
            ),
          ]),
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
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
                colors: g.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [
              BoxShadow(
                  color: g.colors.first.withOpacity(.4), blurRadius: 14, offset: const Offset(0, 6))
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => ModeSelectPage(g))),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.22), shape: BoxShape.circle),
                  child: Text(g.emoji, style: const TextStyle(fontSize: 36)),
                ),
                const SizedBox(height: 10),
                Text(g.bn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                Text(g.en,
                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ]),
            ),
          ),
        ),
      );
}
