import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

String dbUrl = kDbUrl;

Future<void> loadDbUrl() async {
  try {
    final u = (await SharedPreferences.getInstance()).getString('dbUrl');
    if (u != null && u.isNotEmpty) dbUrl = u;
  } catch (_) {}
}

Future<void> saveDbUrl(String u) async {
  dbUrl = u.trim().replaceAll(RegExp(r'/+$'), '');
  try { await (await SharedPreferences.getInstance()).setString('dbUrl', dbUrl); } catch (_) {}
}

Future<dynamic> _req(String m, String path, [Object? body]) async {
  final c = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final r = await c.openUrl(m, Uri.parse('$dbUrl/$path'));
    if (body != null) { r.headers.contentType = ContentType.json; r.write(jsonEncode(body)); }
    final res = await r.close().timeout(const Duration(seconds: 10));
    final s = await res.transform(utf8.decoder).join();
    if (res.statusCode >= 400) throw Exception(s);
    return s.isEmpty || s == 'null' ? null : jsonDecode(s);
  } finally {
    c.close();
  }
}

/// Lockstep online room: both devices run the same game code with the same
/// random seed; only player actions are exchanged through Firebase REST.
class Net {
  final String code;
  final int seat, seed;
  int n = 0;
  final _q = <Map>[];
  final _mine = <String>{};
  Timer? _t;
  bool _busy = false;
  bool Function(Map)? _h;
  Net(this.code, this.seat, this.seed);

  static String _key(int i) => 'a${i.toString().padLeft(6, '0')}';

  static Future<Net> create(String game) async {
    final code = String.fromCharCodes(List.generate(5, (_) => 65 + Random().nextInt(26)));
    final seed = Random().nextInt(1 << 30);
    await _req('PUT', 'rooms/$code.json', {'game': game, 'seed': seed, 'guest': false});
    return Net(code, 0, seed);
  }

  static Future<Net> join(String code, String game) async {
    code = code.trim().toUpperCase();
    final r = await _req('GET', 'rooms/$code.json');
    if (r == null || r['game'] != game) throw Exception('এই কোডে রুম পাওয়া যায়নি');
    await _req('PATCH', 'rooms/$code.json', {'guest': true});
    return Net(code, 1, r['seed'] as int);
  }

  Future<bool> guestJoined() async => (await _req('GET', 'rooms/$code/guest.json')) == true;

  void send(Map a) {
    final k = _key(n++);
    _mine.add(k);
    () async {
      for (var i = 0; i < 4; i++) {
        try { await _req('PUT', 'rooms/$code/acts/$k.json', a); return; } catch (_) { await Future.delayed(const Duration(seconds: 1)); }
      }
    }();
  }

  void start(bool Function(Map) h) {
    _h = h;
    _t = Timer.periodic(const Duration(milliseconds: 600), (_) => _poll());
  }

  void stop() => _t?.cancel();

  Future<void> _poll() async {
    if (!_busy) {
      _busy = true;
      try {
        final r = await _req('GET', 'rooms/$code/acts.json?orderBy=%22%24key%22&startAt=%22${_key(n)}%22');
        if (r is Map) {
          final ks = r.keys.map((e) => e.toString()).toList()..sort();
          for (final k in ks) {
            if (_mine.contains(k)) continue;
            _q.add(Map.from(r[k] as Map));
            n = int.parse(k.substring(1)) + 1;
          }
        }
      } catch (_) {}
      _busy = false;
    }
    while (_q.isNotEmpty && (_h?.call(_q.first) ?? false)) { _q.removeAt(0); }
  }
}

mixin NetMix<T extends StatefulWidget> on State<T> {
  Net? get net;
  bool remote(Map a);
  bool canAct(int seat) => net == null || net!.seat == seat;
  void emit(Map a) => net?.send(a);

  @override
  void initState() {
    super.initState();
    net?.start(remote);
  }

  @override
  void dispose() {
    net?.stop();
    super.dispose();
  }
}
