import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'home.dart';
import 'net.dart';
import 'profile.dart';
import 'logo.dart';
import 'ui.dart';

/// ───────── র‍্যাংক / প্রোফাইল ─────────
class RankTab extends StatelessWidget {
  const RankTab({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: Profile.rev,
        builder: (_, __, ___) => ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
          const ArenaBar('র‍্যাংক'),
          Glass(
            padding: const EdgeInsets.all(18),
            child: Column(children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AC.gold, width: 2.5), color: Colors.black26),
                  child: const Face(AC.blue, size: 62),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Profile.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text('লেভেল ${bnNum(Profile.level)}', style: const TextStyle(color: AC.gold, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ]),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: Profile.levelProgress, minHeight: 10, backgroundColor: Colors.white12, valueColor: const AlwaysStoppedAnimation(AC.gold)),
              ),
              const SizedBox(height: 6),
              Text('পরের লেভেলের জন্য ${bnNum(100 - Profile.xp % 100)} XP বাকি', style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [
            _Stat('🪙', 'কয়েন', fmt(Profile.coins)),
            _Stat('⭐', 'XP', fmt(Profile.xp)),
            _Stat('🔥', 'স্ট্রিক', bnNum(Profile.canClaim && Profile.lastClaim != Profile.yesterday ? 0 : Profile.streak + 1)),
          ]),
          const SizedBox(height: 14),
          Glass(
            padding: const EdgeInsets.all(20),
            child: const Column(children: [
              Text('🏆', style: TextStyle(fontSize: 46)),
              SizedBox(height: 6),
              Text('গ্লোবাল লিডারবোর্ড', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              SizedBox(height: 4),
              Text('শীঘ্রই আসছে — অনলাইন ম্যাচ জিতে র‍্যাংকে উঠুন!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
            ]),
          ),
        ]),
      );
}

class _Stat extends StatelessWidget {
  final String emoji, label, value;
  const _Stat(this.emoji, this.label, this.value);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Glass(
            radius: 18,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              FittedBox(child: Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
              Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.white60)),
            ]),
          ),
        ),
      );
}

/// ───────── ডেইলি রিওয়ার্ড ─────────
class RewardTab extends StatefulWidget {
  const RewardTab({super.key});
  @override
  State<RewardTab> createState() => _RewardTabState();
}

class _RewardTabState extends State<RewardTab> {
  void _claim() {
    final r = Profile.claimDaily();
    if (r > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎉 আপনি পেলেন +$r কয়েন!')));
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: Profile.rev,
        builder: (_, __, ___) {
          final idx = Profile.dayIndex;
          final claimed = !Profile.canClaim;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
            const ArenaBar('পুরস্কার'),
            Glass(
              colors: [AC.gold.withOpacity(.25), AC.pink.withOpacity(.15)],
              borderColor: AC.gold.withOpacity(.5),
              child: Row(children: [
                const Text('🎁', style: TextStyle(fontSize: 54)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ডেইলি পুরস্কার', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    SizedBox(height: 2),
                    Text('প্রতিদিন আসুন, পুরস্কার বাড়তে থাকবে!', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (_, c) {
              final w = (c.maxWidth - 30) / 4;
              return Wrap(spacing: 10, runSpacing: 10, children: [
                for (var i = 0; i < 7; i++)
                  SizedBox(
                    width: i == 6 ? w * 2 + 10 : w,
                    child: _DayTile(i, Profile.rewards[i], done: i < idx || (claimed && i == idx), current: !claimed && i == idx),
                  ),
              ]);
            }),
            const SizedBox(height: 18),
            GlossBtn(claimed ? 'আজকের পুরস্কার নেওয়া হয়েছে ✓' : 'আজকের পুরস্কার নিন', onTap: claimed ? null : _claim, colors: AC.goldGrad, textColor: const Color(0xFF4A2A00), icon: claimed ? null : Icons.redeem_rounded),
            const SizedBox(height: 12),
            GlossBtn(Profile.canSpin ? 'ভাগ্যচক্র ঘোরান 🎡' : 'আজকের স্পিন শেষ', onTap: Profile.canSpin ? () => showDialog(context: context, builder: (_) => const SpinDialog()) : null, colors: AC.pinkGrad),
          ]);
        },
      );
}

class _DayTile extends StatelessWidget {
  final int i, amount;
  final bool done, current;
  const _DayTile(this.i, this.amount, {required this.done, required this.current});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: current
              ? const LinearGradient(colors: AC.goldGrad, begin: Alignment.topCenter, end: Alignment.bottomCenter)
              : LinearGradient(colors: [Colors.white.withOpacity(done ? .08 : .14), Colors.white.withOpacity(.04)]),
          border: Border.all(color: current ? Colors.white : Colors.white.withOpacity(.14), width: current ? 2 : 1),
          boxShadow: current ? [BoxShadow(color: AC.gold.withOpacity(.55), blurRadius: 16)] : null,
        ),
        child: Column(children: [
          Text('দিন ${bnNum(i + 1)}', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: current ? const Color(0xFF4A2A00) : Colors.white70)),
          const SizedBox(height: 6),
          done ? const Icon(Icons.check_circle_rounded, color: AC.green, size: 30) : Text(i == 6 ? '🏆' : '🪙', style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 4),
          Text('$amount', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: current ? const Color(0xFF4A2A00) : Colors.white)),
        ]),
      );
}

/// ───────── স্পিন হুইল ─────────
class SpinDialog extends StatefulWidget {
  const SpinDialog({super.key});
  @override
  State<SpinDialog> createState() => _SpinDialogState();
}

class _SpinDialogState extends State<SpinDialog> with SingleTickerProviderStateMixin {
  static const prizes = [50, 100, 20, 200, 10, 500, 30, 150];
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
  double to = 0;
  int? won;
  bool spinning = false;

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  void spin() {
    if (spinning || !Profile.canSpin) return;
    final k = math.Random().nextInt(prizes.length);
    final seg = 2 * math.pi / prizes.length;
    to = 2 * math.pi * 5 - (k * seg + seg / 2);
    setState(() => spinning = true);
    c.forward(from: 0).then((_) {
      Profile.spinWon(prizes[k]);
      if (mounted) setState(() { won = prizes[k]; spinning = false; });
    });
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(colors: [AC.bg2, AC.bg1], begin: Alignment.topCenter, end: Alignment.bottomCenter),
            border: Border.all(color: AC.gold.withOpacity(.6), width: 1.5),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎡 ভাগ্যচক্র', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            SizedBox(
              width: 250,
              height: 262,
              child: Stack(alignment: Alignment.center, children: [
                Positioned(
                  top: 12,
                  child: AnimatedBuilder(
                    animation: c,
                    builder: (_, __) => Transform.rotate(
                      angle: to * Curves.easeOutCubic.transform(c.value),
                      child: CustomPaint(size: const Size(240, 240), painter: _WheelPainter(prizes)),
                    ),
                  ),
                ),
                Positioned(top: 12 + 120 - 22, child: Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: AC.goldGrad), border: Border.all(color: Colors.white, width: 3)), child: const Icon(Icons.star_rounded, color: Color(0xFF8A4B00)))),
                const Positioned(top: 0, child: Icon(Icons.arrow_drop_down_rounded, size: 46, color: Colors.white)),
              ]),
            ),
            const SizedBox(height: 12),
            if (won != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text('🎉 আপনি পেলেন +$won কয়েন!', style: const TextStyle(color: AC.gold, fontSize: 18, fontWeight: FontWeight.w900))),
            GlossBtn(won != null ? 'ঠিক আছে' : (Profile.canSpin ? (spinning ? 'ঘুরছে...' : 'ঘোরান') : 'আজকের স্পিন শেষ'),
                onTap: won != null ? () => Navigator.pop(context) : (Profile.canSpin && !spinning ? spin : null), colors: AC.pinkGrad),
          ]),
        ),
      );
}

class _WheelPainter extends CustomPainter {
  final List<int> prizes;
  _WheelPainter(this.prizes);
  static const cols = [Color(0xFF7C4DFF), Color(0xFFFF4081), Color(0xFF22D3EE), Color(0xFFFFB300)];
  @override
  void paint(Canvas c, Size s) {
    final r = s.width / 2;
    final o = Offset(r, r);
    final n = prizes.length;
    final seg = 2 * math.pi / n;
    for (var i = 0; i < n; i++) {
      c.drawArc(Rect.fromCircle(center: o, radius: r - 4), -math.pi / 2 + i * seg, seg, true, Paint()..color = cols[i % cols.length]);
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(-math.pi / 2 + i * seg + seg / 2);
      final tp = TextPainter(
        text: TextSpan(text: '${prizes[i]}', style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(r * .5, -tp.height / 2));
      c.restore();
    }
    c.drawCircle(
        o,
        r - 4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = AC.gold);
  }

  @override
  bool shouldRepaint(_WheelPainter o) => false;
}

/// ───────── সেটিংস ─────────
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});
  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final name = TextEditingController(text: Profile.name);
  late final url = TextEditingController(text: dbUrl);

  @override
  void dispose() {
    name.dispose();
    url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        const ArenaBar('সেটিংস'),
        Glass(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('প্লেয়ারের নাম', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            TextField(controller: name, decoration: arenaInput('আপনার নাম', icon: Icons.person_rounded), onChanged: Profile.setName),
          ]),
        ),
        const SizedBox(height: 12),
        Glass(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: ValueListenableBuilder<int>(
            valueListenable: Profile.rev,
            builder: (_, __, ___) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: AC.gold,
              title: const Text('ভাইব্রেশন / হ্যাপটিক', style: TextStyle(fontWeight: FontWeight.w800)),
              value: Profile.haptic,
              onChanged: Profile.setHaptic,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Glass(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Firebase Realtime Database URL', style: TextStyle(fontWeight: FontWeight.w800)),
            const Text('অনলাইন মাল্টিপ্লেয়ারের জন্য', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(controller: url, decoration: arenaInput('https://xxxx-default-rtdb.firebaseio.com', icon: Icons.link_rounded)),
            const SizedBox(height: 10),
            GlossBtn('সেভ করুন', height: 46, fontSize: 16, colors: AC.greenGrad, onTap: () async {
              await saveDbUrl(url.text);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সেভ হয়েছে ✓')));
            }),
          ]),
        ),
      ]);
}

/// ───────── আরও ─────────
class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  void _guide(BuildContext context) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AC.bg1,
          title: const Text('অনলাইনে কীভাবে খেলবেন?', style: TextStyle(fontWeight: FontWeight.w900)),
          content: const Text('১. সেটিংসে Firebase URL দিন।\n২. গেম বেছে "অনলাইন মাল্টিপ্লেয়ার" চাপুন।\n৩. "রুম তৈরি করুন" চাপলে ৫ অক্ষরের কোড পাবেন।\n৪. কোডটি বন্ধুকে দিন — সে "রুমে যোগ দিন" এ কোড বসাবে।'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('বুঝেছি'))],
        ),
      );

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        const ArenaBar('আরও'),
        Glass(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            const ArenaLogo(size: 64),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('গেমস এরিনা', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                Text('সংস্করণ 1.0.0', style: TextStyle(color: Colors.white60, fontSize: 12)),
                SizedBox(height: 2),
                Text('Powered by Hasan', style: TextStyle(color: AC.gold, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        _Row(Icons.grid_view_rounded, 'সব গেম', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AllGamesPage()))),
        _Row(Icons.public_rounded, 'অনলাইনে খেলার নিয়ম', () => _guide(context)),
      ]);
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Row(this.icon, this.label, this.onTap);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Glass(
          onTap: onTap,
          radius: 18,
          child: Row(children: [
            Icon(icon, color: AC.cyan),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ]),
        ),
      );
}
