/// Cinematografie escludibili dalle Impostazioni.
/// Il filtro lavora sulla lingua originale del film (`original_language` di TMDB).
enum Region {
  southAsia('Cinema indiano (Bollywood, Tollywood…)',
      {'hi', 'ta', 'te', 'ml', 'kn', 'bn', 'mr', 'pa', 'gu', 'ur', 'ne', 'si'}),
  eastAsia('Asia orientale (Giappone, Corea, Cina)', {'ja', 'ko', 'zh', 'cn'}),
  southeastAsia('Sud-est asiatico', {'th', 'vi', 'id', 'ms', 'tl'}),
  middleEast('Medio Oriente', {'ar', 'fa', 'he', 'tr'});

  final String label;
  final Set<String> languages;
  const Region(this.label, this.languages);
}
