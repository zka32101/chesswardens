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
  jumpMove('追加ジャンプ');       // Tengu

  const SkillEffectType(this.label);
  final String label;
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
