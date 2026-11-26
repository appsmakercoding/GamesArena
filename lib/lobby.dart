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
  bool _waiting = false;

  void _go(Net n) {
    if (!mounted) return;
    _waiting = false;
    seedRnd(n.seed);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => widget.build(n)));
  }

  Future<void> _create() async {
    setState(() {
      busy = true;
      _waiting = true;
      status = '';
    });
    try {
      await saveDbUrl(url.text);
      final n = await Net.create(widget.g.id);
      setState(() {
        myCode = n.code;
        status = 'বন্ধুর জন্য অপেক্ষা করছি...';
      });
      while (mounted && _waiting) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted || !_waiting) return;
        if (await n.guestJoined()) {
          _go(n);
          return;
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        _waiting = false;
        myCode = null;
        status = 'সংযোগ ব্যর্থ। ডাটাবেস URL ও ইন্টারনেট দেখুন।';
      });
    }
  }

  void _cancelRoom() {
    setState(() {
      _waiting = false;
      busy = false;
      myCode = null;
      status = '';
    });
  }

  Future<void> _join() async {
    setState(() {
      busy = true;
      status = '';
    });
    try {
      await saveDbUrl(url.text);
      _go(await Net.join(code.text, widget.g.id));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        status = 'যোগ দেওয়া যায়নি: কোড বা URL ঠিক নেই।';
      });
    }
  }

  @override
  void dispose() {
    _waiting = false;
    url.dispose();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D114D), Color(0xFF0C081D), Color(0xFF060410)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        '\${widget.g.bn} লবি',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.home_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white10,
                    border: Border.all(color: widget.g.colors.first.withOpacity(.55)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(colors: widget.g.colors),
                        ),
                        child: Text(widget.g.emoji, style: const TextStyle(fontSize: 36)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.g.bn,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            const Text(
                              'খেলুন, জিতুন অনলাইনে!',
                              style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: const Color(0xFF150E36),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatPill(icon: Icons.people_alt_rounded, label: 'খেলোয়াড়', value: '২ জন'),
                      _StatPill(icon: Icons.bolt_rounded, label: 'মোড', value: 'রিয়েল-টাইম'),
                      _StatPill(icon: Icons.vpn_key_rounded, label: 'কোড', value: '৫ অক্ষর'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: url,
                  decoration: InputDecoration(
                    labelText: 'Firebase Realtime Database URL',
                    hintText: 'https://xxxx-default-rtdb.firebaseio.com',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 18),
                if (myCode != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white10,
                      border: Border.all(color: const Color(0xFF38EF7D)),
                    ),
                    child: Column(
                      children: [
                        const Text('আপনার রুম কোড (বন্ধুকে দিন):', textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(
                          myCode!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                            color: Color(0xFF38EF7D),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _cancelRoom,
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('বাতিল করুন'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white10,
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'রুম কোড দিয়ে যোগ দিন',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: code,
                                textCapitalization: TextCapitalization.characters,
                                maxLength: 5,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 6,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  hintText: 'ABCDE',
                                  filled: true,
                                  fillColor: Colors.black26,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF00C853),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: busy ? null : _join,
                              child: const Text(
                                'যোগ দিন ▶',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: widget.g.colors.first,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: busy ? null : _create,
                    icon: const Icon(Icons.bolt_rounded),
                    label: const Text(
                      'নিজেই রুম তৈরি করুন +',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (busy)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _StatPill({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: Colors.amberAccent, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      );
}
