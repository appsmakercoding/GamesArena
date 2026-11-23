import 'package:flutter/material.dart';

enum PlayMode { vsComputer, localMulti, onlineMulti }

class GameInfo {
  final String id, bn, en, emoji;
  final int phase;
  final List<Color> colors;
  final List<PlayMode> modes;
  const GameInfo(this.id, this.bn, this.en, this.emoji, this.phase, this.colors,
      {this.modes = PlayMode.values});
}

const kGames = <GameInfo>[
  GameInfo('ludo', 'লুডু', 'Ludo', '🎲', 2, [Color(0xFFFF5F6D), Color(0xFFFFC371)]),
  GameInfo('snake', 'সাপ-লুডু', 'Snakes & Ladders', '🐍', 2, [Color(0xFF11998E), Color(0xFF38EF7D)]),
  GameInfo('chess', 'দাবা', 'Chess', '♟️', 5, [Color(0xFF434343), Color(0xFF8E9EAB)]),
  GameInfo('carrom', 'ক্যারাম বোর্ড', 'Carrom', '🎯', 5, [Color(0xFFF7971E), Color(0xFFFFD200)]),
  GameInfo('gutti16', '১৬ গুটি', 'Sixteen Gutti', '🔴', 3, [Color(0xFFEB3349), Color(0xFFF45C43)]),
  GameInfo('gutti12', '১২ গুটি', 'Twelve Gutti', '🟠', 3, [Color(0xFFFF512F), Color(0xFFDD2476)]),
  GameInfo('gutti8', '৮ গুটি', 'Eight Gutti', '🟣', 3, [Color(0xFF8E2DE2), Color(0xFF4A00E0)]),
  GameInfo('baghbakri', 'বাঘ-বকরি', 'Tiger & Goats', '🐯', 3, [Color(0xFFF2994A), Color(0xFFF2C94C)]),
  GameInfo('kori', 'কড়ি খেলা', 'Kori', '🐚', 3, [Color(0xFF00B4DB), Color(0xFF0083B0)]),
  GameInfo('pasha', 'পাশা খেলা', 'Pasha', '🎰', 3, [Color(0xFFB24592), Color(0xFFF15F79)]),
  GameInfo('hazari', 'হাজারি', 'Hazari', '🃏', 4, [Color(0xFF396AFC), Color(0xFF2948FF)]),
  GameInfo('card29', '২৯ কার্ড', '29 Cards', '♠️', 4, [Color(0xFF0F2027), Color(0xFF2C5364)]),
  GameInfo('rang', 'রং', 'Rang', '♦️', 4, [Color(0xFFCB2D3E), Color(0xFFEF473A)]),
  GameInfo('solitaire', 'সলিটেয়ার', 'Patience', '♣️', 4, [Color(0xFF134E5E), Color(0xFF71B280)],
      modes: [PlayMode.vsComputer]),
  GameInfo('spades', 'স্পেডস', 'Spades', '🂡', 4, [Color(0xFF232526), Color(0xFF616161)]),
];

String modeTitle(PlayMode m, GameInfo g) {
  switch (m) {
    case PlayMode.vsComputer:
      return g.id == 'solitaire' ? 'একা খেলুন' : 'কম্পিউটারের সাথে';
    case PlayMode.localMulti:
      return 'অফলাইন মাল্টিপ্লেয়ার';
    case PlayMode.onlineMulti:
      return 'অনলাইন মাল্টিপ্লেয়ার';
  }
}

String modeSub(PlayMode m) {
  switch (m) {
    case PlayMode.vsComputer:
      return 'ইন্টারনেট ছাড়াই AI-এর বিপক্ষে';
    case PlayMode.localMulti:
      return 'এক ফোনে বন্ধুদের সাথে';
    case PlayMode.onlineMulti:
      return 'রুম কোড দিয়ে অনলাইনে খেলুন';
  }
}

IconData modeIcon(PlayMode m) => m == PlayMode.vsComputer
    ? Icons.smart_toy_rounded
    : m == PlayMode.localMulti
        ? Icons.people_alt_rounded
        : Icons.public_rounded;

const kLive = {'ludo', 'snake', 'gutti16', 'gutti12', 'gutti8', 'baghbakri', 'kori', 'pasha', 'hazari', 'card29', 'rang', 'spades', 'solitaire', 'chess', 'carrom'};
const kOnline = {'ludo', 'snake', 'kori', 'chess', 'gutti16', 'gutti12', 'gutti8', 'baghbakri', 'carrom'};
const kCards = {'hazari', 'card29', 'rang', 'spades'};
const kTwoOnly = {'gutti16', 'gutti12', 'gutti8', 'baghbakri', 'chess', 'carrom'};
