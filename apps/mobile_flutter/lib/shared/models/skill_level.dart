class SkillLevelInfo {
  const SkillLevelInfo({
    required this.code,
    required this.label,
    required this.helperText,
  });

  final String code;
  final String label;
  final String helperText;
}

const List<SkillLevelInfo> skillLevelCatalog = <SkillLevelInfo>[
  SkillLevelInfo(
    code: 'L1',
    label: 'L1 新手',
    helperText: '剛開始打球，還在熟悉握拍、腳步與基本回擊。',
  ),
  SkillLevelInfo(
    code: 'L2',
    label: 'L2 初階',
    helperText: '能穩定對打，適合節奏較慢、以練基本球感為主。',
  ),
  SkillLevelInfo(
    code: 'L3',
    label: 'L3 中階',
    helperText: '可維持球來回與控球，適合多數零打場。',
  ),
  SkillLevelInfo(
    code: 'L4',
    label: 'L4 進階',
    helperText: '球速與落點控制較穩，適合程度接近的球友。',
  ),
  SkillLevelInfo(
    code: 'L5',
    label: 'L5 競技',
    helperText: '偏比賽節奏，強度高、速度快，適合熟練球友。',
  ),
];

final Map<String, SkillLevelInfo> _skillLevelLookup = <String, SkillLevelInfo>{
  for (final SkillLevelInfo info in skillLevelCatalog) info.code: info,
};

SkillLevelInfo skillLevelInfo(String code) {
  final String normalized = code.trim().toUpperCase();
  return _skillLevelLookup[normalized] ??
      SkillLevelInfo(
        code: normalized.isEmpty ? 'L?' : normalized,
        label: '尚未選擇程度',
        helperText: '先選一個最接近目前實力的等級，主揪比較好配場。',
      );
}

String skillLevelLabel(String code) => skillLevelInfo(code).label;

String skillLevelHelperText(String code) => skillLevelInfo(code).helperText;

String skillLevelRangeLabel(String minLevel, String? maxLevel) {
  if (maxLevel == null || maxLevel.trim().isEmpty || maxLevel == minLevel) {
    return skillLevelLabel(minLevel);
  }

  return '${skillLevelLabel(minLevel)} - ${skillLevelLabel(maxLevel)}';
}
