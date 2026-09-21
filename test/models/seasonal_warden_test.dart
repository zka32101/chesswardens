import 'package:flutter_test/flutter_test.dart';
import 'package:chesswardens/models/index.dart';

void main() {
  group('Seasonal Wardens (Phase 4 LiveOps)', () {
    test('seasonalWardens returns 雪女・河童・座敷童', () {
      final wardens = Warden.seasonalWardens();
      expect(wardens.length, 3);
      expect(wardens.map((w) => w.japaneseeName),
          containsAll(['雪女', '河童', '座敷童']));
    });

    test('seasonal wardens expose their season', () {
      expect(Warden.yukionna().season, Season.winter);
      expect(Warden.kappa().season, Season.summer);
      expect(Warden.zashikiWarashi().season, Season.yearRound);
      expect(Warden.yukionna().isSeasonal, isTrue);
    });

    test('MVP wardens are not seasonal', () {
      for (final warden in Warden.mvpWardens()) {
        expect(warden.isSeasonal, isFalse);
        expect(warden.season, isNull);
      }
    });

    test('allWardens combines MVP and seasonal sets', () {
      expect(Warden.allWardens().length, 7);
    });

    test('each seasonal warden references a valid skill definition', () {
      final skills = {for (final s in SkillDefinition.seasonalSkills()) s.id: s};
      for (final warden in Warden.seasonalWardens()) {
        expect(skills.containsKey(warden.skillId), isTrue,
            reason: '${warden.japaneseeName} の skillId が未定義');
      }
    });
  });

  group('Seasonal SkillDefinitions', () {
    test('freeze/drain/luck are defined with valid level curves', () {
      for (final skill in SkillDefinition.seasonalSkills()) {
        expect(skill.triggerRateByLevel.length, 4);
        expect(skill.valueByLevel.length, 4);
        expect(skill.getTriggerRate(1), skill.triggerRateByLevel[0]);
        expect(skill.getValue(4), skill.valueByLevel[3]);
      }
    });
  });

  group('SkillEvaluationService with seasonal skills', () {
    final service = SkillEvaluationService();

    test('freeze contributes a strong positive board evaluation', () {
      final skill = SkillDefinition.freeze();
      final score = service.evaluateSkillContribution(skill, true, 1);
      expect(score, greaterThan(0));
    });

    test('inactive skill contributes zero regardless of type', () {
      for (final skill in SkillDefinition.seasonalSkills()) {
        expect(service.evaluateSkillContribution(skill, false, 4), 0);
      }
    });
  });
}
