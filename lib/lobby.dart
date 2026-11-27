import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'common.dart';
import 'games.dart';
import 'net.dart';
import 'ui.dart';

class LobbyPage extends StatefulWidget {
  final GameInfo g;
  final Widget Function(Net) build;
  const LobbyPage(this.g, this.build, {super.key});
  @override
  State<LobbyPage> createState() => _LobbyState();
}

class _LobbyState extends State<LobbyPage> {
  late final url = TextEditingController(text: dbUrl);
  final code = TextEditingController();
  String status = '';
  String? myCode;
  bool busy = false;

  @override
  void dispose() {
    url.dispose();
    code.dispose();
    super.dispose();
  }

  void _go(Net n) {
    if (!mounted) return;
    seedRnd(n.seed);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => widget.build(n)));
  }

  Future<void> _create() async {
    setState(() { busy = true; status = ''; });
    try {
      await saveDbUrl(url.text);
      final n = await Net.create(widget.g.id);
      setState(() { myCode = n.code; status = 'বন্ধুর জন্য অপেক্ষা করছি...'; });
      while (mounted) {
        await Future.delayed(const Duration(seconds: 1));
        if (await n.guestJoined()) { _go(n); return; }
      }
    } catch (e) {
      if (mounted) setState(() { busy = false; myCode = null; status = 'সংযোগ ব্যর্থ। ডাটাবেস URL ও ইন্টারনেট দেখুন।'; });
    }
  }

  Future<void> _join() async {
    setState(() { busy = true; status = ''; });
    try {
      await saveDbUrl(url.text);
      _go(await Net.join(code.text, widget.g.id));
    } catch (e) {
      if (mounted) setState(() { busy = false; status = 'যোগ দেওয়া যায়নি: কোড বা URL ঠিক নেই।'; });
    }
  }

  Widget _stat(String emoji, String label, String value) => Expanded(
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final g = widget.g;
    final gg = gameGrad(g);
    return Scaffold(
      body: ArenaBg(
        child: SafeArea(
          child: Column(children: [
            ArenaBar('${g.bn} লবি', onBack: () => Navigator.pop(context), trailing: CircleBtn(Icons.home_rounded, () => Navigator.popUntil(context, (r) => r.isFirst))),
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 6, 16, 24), children: [
                Glass(
                  padding: const EdgeInsets.all(16),
                  colors: [gg.first.withOpacity(.55), AC.violet.withOpacity(.25)],
                  child: Row(children: [
                    Container(
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(colors: gg, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        border: Border.all(color: Colors.white.withOpacity(.5), width: 1.5),
                        boxShadow: [BoxShadow(color: gg.last.withOpacity(.6), blurRadius: 16)],
                      ),
                      child: Text(g.emoji, style: const TextStyle(fontSize: 44)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(g.bn, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                        Text(g.en, style: const TextStyle(color: Colors.white60)),
                        const SizedBox(height: 4),
                        const Text('খেলুন, জিতুন!', style: TextStyle(color: AC.gold, fontWeight: FontWeight.w800, fontSize: 16)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Glass(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [
                    _stat('👥', 'খেলোয়াড়', '২ জন'),
                    Container(width: 1, height: 44, color: Colors.white24),
                    _stat('🌐', 'মোড', 'অনলাইন'),
                    Container(width: 1, height: 44, color: Colors.white24),
                    _stat('🔑', 'রুম কোড', '৫ অক্ষর'),
                  ]),
                ),
                const SizedBox(height: 14),
                Glass(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('সংযোগ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 8),
                    TextField(controller: url, decoration: arenaInput('https://xxxx-default-rtdb.firebaseio.com', icon: Icons.link_rounded)),
                  ]),
                ),
                const SizedBox(height: 14),
                if (myCode != null)
                  Glass(
                    colors: [AC.gold.withOpacity(.2), AC.violet.withOpacity(.2)],
                    borderColor: AC.gold.withOpacity(.5),
                    padding: const EdgeInsets.all(18),
                    child: Column(children: [
                      const Text('আপনার রুম কোড (বন্ধুকে দিন)', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        for (final ch in myCode!.split(''))
                          Container(
                            width: 48,
                            height: 58,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(colors: AC.goldGrad, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                              boxShadow: [BoxShadow(color: AC.gold.withOpacity(.4), blurRadius: 10)],
                            ),
                            child: Text(ch, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF4A2A00))),
                          ),
                      ]),
                      const SizedBox(height: 14),
                      GlossBtn('কোড কপি করুন', icon: Icons.copy_rounded, height: 44, fontSize: 15, wide: false, onTap: () {
                        Clipboard.setData(ClipboardData(text: myCode!));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('কোড কপি হয়েছে ✓')));
                      }),
                      const SizedBox(height: 14),
                      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: AC.gold)),
                        SizedBox(width: 10),
                        Text('বন্ধুর জন্য অপেক্ষা করছি...', style: TextStyle(color: Colors.white70)),
                      ]),
                    ]),
                  )
                else ...[
                  GlossBtn('নিজেই রুম তৈরি করুন', icon: Icons.bolt_rounded, colors: AC.violetGrad, onTap: busy ? null : _create),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Center(child: Text('অথবা', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700)))),
                  Glass(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('লবিতে যোগ দিন', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: code,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 5,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 26, letterSpacing: 8, fontWeight: FontWeight.w900),
                        decoration: arenaInput('রুম কোড').copyWith(counterText: ''),
                      ),
                      const SizedBox(height: 12),
                      GlossBtn('যোগ দিন', icon: Icons.login_rounded, colors: AC.greenGrad, onTap: busy ? null : _join),
                    ]),
                  ),
                ],
                if (status.isNotEmpty && myCode == null)
                  Padding(padding: const EdgeInsets.only(top: 14), child: Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFB4C0), fontWeight: FontWeight.w700))),
                const SizedBox(height: 10),
                const Center(child: Opacity(opacity: .9, child: Row(mainAxisSize: MainAxisSize.min, children: [Pawn(Color(0xFF3B82F6), size: 34), SizedBox(width: 6), Dice3D(size: 56), SizedBox(width: 6), Pawn(Color(0xFFFF4D6D), size: 34)]))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
