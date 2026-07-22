class Games {
  static const freeFire = 'free_fire';
  static const bgmi = 'bgmi';
  static const mlbb = 'mlbb';
  static const efootball = 'efootball';
  static const all = [freeFire, bgmi, mlbb, efootball];

  static String label(String game) => switch (game) {
    freeFire => 'Free Fire', bgmi => 'BGMI / PUBG', mlbb => 'MLBB', efootball => 'eFootball', _ => game,
  };
  static String emoji(String game) => switch (game) {
    freeFire => '🔥', bgmi => '🎯', mlbb => '⚔️', efootball => '⚽', _ => '🎮',
  };
  static bool usesTeamName(String game) => game == efootball;
}
