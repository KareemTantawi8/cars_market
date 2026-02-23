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
