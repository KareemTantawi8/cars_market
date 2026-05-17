import '../../features/home/data/models/category_models.dart';

/// Home search: only Cairo, Alexandria, Sharqia, and Suez (from API list).
class GovernorateFilter {
  GovernorateFilter._();

  /// User-facing names (normalized matching).
  static const List<String> homeGovernorateLabels = [
    'القاهره',
    'الاسكندريه',
    'الشرقيه',
    'السويس',
  ];

  static const List<String> _allowedSlugs = [
    'cairo',
    'al_cairo',
    'alexandria',
    'alex',
    'sharqia',
    'sharkeya',
    'eastern',
    'suez',
  ];

  static const List<String> _allowedNormalizedNames = [
    'القاهره',
    'القاهرة',
    'الاسكندريه',
    'الاسكندرية',
    'الشرقيه',
    'الشرقية',
    'السويس',
    'السوي',
    'cairo',
    'alexandria',
    'sharqia',
    'sharkeya',
    'eastern',
    'suez',
  ];

  static String normalize(String value) {
    var s = value.trim().toLowerCase();
    const replacements = {
      'أ': 'ا',
      'إ': 'ا',
      'آ': 'ا',
      'ى': 'ي',
      'ة': 'ه',
      'ﻻ': 'لا',
    };
    for (final e in replacements.entries) {
      s = s.replaceAll(e.key, e.value);
    }
    return s.replaceAll(RegExp(r'[\s\-_]+'), '');
  }

  static bool isHomeGovernorate(GovernorateModel g) {
    final slug = normalize(g.slug ?? '');
    if (slug.isNotEmpty) {
      for (final allowed in _allowedSlugs) {
        if (slug == allowed || slug.contains(allowed)) return true;
      }
    }

    final candidates = <String>[
      g.displayName,
      g.name,
      if (g.nameAr != null) g.nameAr!,
    ];

    for (final raw in candidates) {
      final n = normalize(raw);
      if (n.isEmpty) continue;

      for (final allowed in _allowedNormalizedNames) {
        final a = normalize(allowed);
        if (n == a || n.startsWith(a) || a.startsWith(n)) return true;
      }
    }
    return false;
  }

  /// Keeps only the four home governorates (preserves API ids for search).
  static List<GovernorateModel> forHomeSearch(List<GovernorateModel> all) {
    final filtered = all.where(isHomeGovernorate).toList();

    int orderOf(GovernorateModel g) {
      final n = normalize(g.displayName);
      final slug = normalize(g.slug ?? '');
      if (n.contains('قاهره') || slug.contains('cairo')) return 0;
      if (n.contains('اسكندريه') || slug.contains('alex')) return 1;
      if (n.contains('شرقيه') || slug.contains('sharqia') || slug.contains('eastern')) {
        return 2;
      }
      if (n.contains('سويس') || n.contains('السوي') || slug.contains('suez')) {
        return 3;
      }
      return 99;
    }

    filtered.sort((a, b) => orderOf(a).compareTo(orderOf(b)));
    return filtered;
  }
}
