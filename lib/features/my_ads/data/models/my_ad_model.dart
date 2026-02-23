/// Status of a user ad
enum MyAdStatus {
  active,   // نشط
  underReview, // قيد المراجعة
  pending,  // معلق
}

/// Model for a single "My Ad" listing
class MyAdModel {
  final String id;
  final String title;
  final String priceFormatted; // e.g. "5,000 ج.م"
  final MyAdStatus status;
  final int viewCount; // -1 for "—" when not available
  final String? imageUrl; // optional network image
  final bool isFeatured; // مميز

  const MyAdModel({
    required this.id,
    required this.title,
    required this.priceFormatted,
    required this.status,
    this.viewCount = 0,
    this.imageUrl,
    this.isFeatured = false,
  });

  String get statusLabel {
    switch (status) {
      case MyAdStatus.active:
        return 'نشط';
      case MyAdStatus.underReview:
        return 'قيد المراجعة';
      case MyAdStatus.pending:
        return 'معلق';
    }
  }

  String get viewsLabel {
    if (viewCount < 0) return '-- مشاهدة';
    return '$viewCount مشاهدة';
  }
}
