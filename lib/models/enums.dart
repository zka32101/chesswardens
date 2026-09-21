/// Chess piece type corresponding to Warden
enum PieceType {
  king('King', '鬼王'),
  queen('Queen', '九尾'),
  rook('Rook', '大蛇'),
  knight('Knight', '天狗'),
  bishop('Bishop', null),
  pawn('Pawn', null);

  const PieceType(this.englishName, this.japaneseeName);

  final String englishName;
  final String? japaneseeName;

  /// Convert to board notation
  String toNotation() => englishName[0].toUpperCase();
}

/// Skill trigger condition
enum SkillTriggerCondition {
  onDamage('被弾時'),
  onAttackSuccess('攻撃成功時'),
  onTurnStart('ターン開始時'),
  onMove('移動確定後');

  const SkillTriggerCondition(this.label);
  final String label;
}

/// Skill effect type
enum SkillEffectType {
  immortality('不死'),           // Oni King
  spreadDamage('炎ダメージ拡散'),  // Kitsune
  shieldTurns('鉄壁'),           // Orochi
  jumpMove('追加ジャンプ'),       // Tengu
  freeze('凍結'),                // Yuki-onna (seasonal)
  drain('吸収'),                 // Kappa (seasonal)
  luck('幸運');                  // Zashiki-warashi (seasonal)

  const SkillEffectType(this.label);
  final String label;
}

/// Seasonal availability window for LiveOps wardens
enum Season {
  winter('冬', '雪女'),
  summer('夏', '河童'),
  yearRound('通年', '座敷童');

  const Season(this.label, this.representativeWarden);
  final String label;
  final String representativeWarden;
}

/// Match result
enum MatchResult {
  win('勝利'),
  loss('敗北'),
  draw('引き分け');

  const MatchResult(this.label);
  final String label;
}

/// AI difficulty level
enum AIDifficulty {
  easy('イージー', 1),
  normal('ノーマル', 2),
  hard('ハード', 3),
  veryHard('ベリーハード', 4);

  const AIDifficulty(this.label, this.minimax_depth);
  final String label;
  final int minimax_depth;
}
