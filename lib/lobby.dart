import 'package:flutter/material.dart';
import 'common.dart';
import 'games.dart';
import 'net.dart';

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
      setState(() { busy = false; myCode = null; status = 'সংযোগ ব্যর্থ। ডাটাবেস URL ও ইন্টারনেট দেখুন।'; });
    }
  }

  Future<void> _join() async {
    setState(() { busy = true; status = ''; });
    try {
      await saveDbUrl(url.text);
      _go(await Net.join(code.text, widget.g.id));
    } catch (e) {
      setState(() { busy = false; status = 'যোগ দেওয়া যায়নি: কোড বা URL ঠিক নেই।'; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${widget.g.bn} • অনলাইন'), backgroundColor: Colors.transparent),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          Center(child: Text(widget.g.emoji, style: const TextStyle(fontSize: 64))),
          const SizedBox(height: 16),
          TextField(
            controller: url,
            decoration: const InputDecoration(labelText: 'Firebase Realtime Database URL', hintText: 'https://xxxx-default-rtdb.firebaseio.com', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          if (myCode != null) ...[
            const Text('আপনার রুম কোড (বন্ধুকে দিন):', textAlign: TextAlign.center),
            Text(myCode!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 8)),
          ] else ...[
            FilledButton.icon(
              style: FilledButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: widget.g.colors.first),
              onPressed: busy ? null : _create,
              icon: const Icon(Icons.add_rounded),
              label: const Text('রুম তৈরি করুন', style: TextStyle(fontSize: 17)),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Center(child: Text('অথবা', style: TextStyle(color: Colors.white54)))),
            TextField(
              controller: code,
              textCapitalization: TextCapitalization.characters,
              maxLength: 5,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, letterSpacing: 6),
              decoration: const InputDecoration(hintText: 'রুম কোড', border: OutlineInputBorder()),
            ),
            OutlinedButton(onPressed: busy ? null : _join, style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)), child: const Text('রুমে যোগ দিন', style: TextStyle(fontSize: 17))),
          ],
          const SizedBox(height: 16),
          Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
        ]),
      );
}
