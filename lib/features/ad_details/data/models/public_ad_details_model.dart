import '../../../ads/data/models/ad_model.dart';

/// Public ad details model for the ad details screen
class PublicAdDetailsModel {
  final String id;
  final String title;
  final String priceFormatted;
  final String location;
  final String timeAgo;
  final String statusLabel; // e.g. جديد
  final List<String> imageUrls;
  final String type; // النوع e.g. قطع غيار
  final String condition; // الحالة e.g. جديد تماماً
  final String warranty; // الضمان e.g. متاح
  final String size; // المقاس e.g. ١٧ بوصة
  final String description;
  final String sellerName;
  final double sellerRating;
  final int sellerReviewCount;
  final String? sellerAvatarUrl;
  final bool sellerIsOnline;
  final String? sellerId;
  final String? sellerPhone;
  final List<SimilarAdItem> similarAds;

  /// Build from API AdModel
  factory PublicAdDetailsModel.fromAdModel(AdModel a) {
    return PublicAdDetailsModel(
      id: a.id.toString(),
      title: a.title,
      priceFormatted: a.priceFormatted,
      location: a.user?.name ?? '',
      timeAgo: _timeAgo(a.createdAt),
      statusLabel: a.statusLabel,
      imageUrls: a.images,
      type: 'قطع غيار',
      condition: a.condition == 'new' ? 'جديد تماماً' : 'مستعمل',
      warranty: 'متاح',
      size: a.year?.name ?? '',
      description: a.description ?? '',
      sellerName: a.user?.name ?? '',
      sellerRating: 0,
      sellerReviewCount: 0,
      sellerAvatarUrl: null,
      sellerIsOnline: false,
      sellerId: a.user?.id.toString(),
      sellerPhone: a.isPhoneVisible ? a.user?.phone : null,
      similarAds: const [],
    );
  }

  static String _timeAgo(String? iso) {
    if (iso == null) return '';
    try {
      final d = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(d);
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
      if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '';
    }
  }

  const PublicAdDetailsModel({
    required this.id,
    required this.title,
    required this.priceFormatted,
    required this.location,
    required this.timeAgo,
    required this.statusLabel,
    this.imageUrls = const [],
    required this.type,
    required this.condition,
    required this.warranty,
    required this.size,
    required this.description,
    required this.sellerName,
    required this.sellerRating,
    required this.sellerReviewCount,
    this.sellerAvatarUrl,
    this.sellerIsOnline = false,
    this.sellerId,
    this.sellerPhone,
    this.similarAds = const [],
  });
}

class SimilarAdItem {
  final String id;
  final String title;
  final String priceFormatted;
  final String? imageUrl;

  const SimilarAdItem({
    required this.id,
    required this.title,
    required this.priceFormatted,
    this.imageUrl,
  });
}
