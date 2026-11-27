import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// প্লেয়ারের কয়েন, লেভেল, ডেইলি রিওয়ার্ড — সব ফোনে সেভ থাকে।
class Profile {
  static int coins = 1000, xp = 0, streak = 0;
  static String name = 'প্লেয়ার', lastClaim = '', lastSpin = '';
  static bool haptic = true;
  static final rev = ValueNotifier<int>(0);
  static const rewards = [100, 150, 200, 250, 300, 400, 1000];

  static int get level => 1 + xp ~/ 100;
  static double get levelProgress => (xp % 100) / 100;

  static String _d(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  static String get today => _d(DateTime.now());
  static String get yesterday => _d(DateTime.now().subtract(const Duration(days: 1)));

  static bool get canClaim => lastClaim != today;
  static bool get canSpin => lastSpin != today;

  /// আজকের (বা পরবর্তী) পুরস্কারের দিন নম্বর (০-৬)
  static int get dayIndex {
    if (lastClaim == today) return streak % 7;
    if (lastClaim == yesterday) return (streak + 1) % 7;
    return 0;
  }

  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      coins = p.getInt('coins') ?? 1000;
      xp = p.getInt('xp') ?? 0;
      streak = p.getInt('streak') ?? 0;
      name = p.getString('pname') ?? 'প্লেয়ার';
      lastClaim = p.getString('lastClaim') ?? '';
      lastSpin = p.getString('lastSpin') ?? '';
      haptic = p.getBool('haptic') ?? true;
    } catch (_) {}
  }

  static void _save() {
    rev.value++;
    () async {
      try {
        final p = await SharedPreferences.getInstance();
        await p.setInt('coins', coins);
        await p.setInt('xp', xp);
        await p.setInt('streak', streak);
        await p.setString('pname', name);
        await p.setString('lastClaim', lastClaim);
        await p.setString('lastSpin', lastSpin);
        await p.setBool('haptic', haptic);
      } catch (_) {}
    }();
  }

  static void addCoins(int n) { coins += n; _save(); }
  static void addXp(int n) { xp += n; _save(); }
  static void setName(String n) { name = n.trim().isEmpty ? 'প্লেয়ার' : n.trim(); _save(); }
  static void setHaptic(bool v) { haptic = v; _save(); }

  static int claimDaily() {
    if (!canClaim) return 0;
    streak = lastClaim == yesterday ? streak + 1 : 0;
    final r = rewards[streak % 7];
    lastClaim = today;
    coins += r;
    xp += 10;
    _save();
    return r;
  }

  static void spinWon(int prize) {
    lastSpin = today;
    coins += prize;
    xp += 5;
    _save();
  }
}
