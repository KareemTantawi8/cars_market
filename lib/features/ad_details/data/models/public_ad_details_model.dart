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
  /// ماركة + موديل + سنة (للعرض تحت «الموديل»)
  final String vehicleModelLine;
  final String description;
  final String sellerName;
  final double sellerRating;
  final int sellerReviewCount;
  final String? sellerAvatarUrl;
  final bool sellerIsOnline;
  final String? sellerId;
  /// Backend `vendors.id` for the seller, when included on ad `user` — avoids wrong chat matches.
  final int? sellerVendorRecordId;
  final String? sellerPhone;
  final List<SimilarAdItem> similarAds;

  /// Build from API AdModel
  factory PublicAdDetailsModel.fromAdModel(AdModel a) {
    return PublicAdDetailsModel(
      id: a.id.toString(),
      title: a.title,
      priceFormatted: a.priceFormatted,
      location: a.locationLabel ?? '',
      timeAgo: _timeAgo(a.createdAt),
      statusLabel: a.statusLabel,
      imageUrls: a.images,
      type: 'قطع غيار',
      condition: a.condition == 'new' ? 'جديد تماماً' : 'مستعمل',
      warranty: 'متاح',
      vehicleModelLine: _vehicleModelLine(a),
      description: a.description ?? '',
      sellerName: a.user?.name ?? '',
      sellerRating: 0,
      sellerReviewCount: 0,
      sellerAvatarUrl: null,
      sellerIsOnline: false,
      sellerId: a.user?.id.toString(),
      sellerVendorRecordId: a.user?.vendorRecordId,
      sellerPhone: a.isPhoneVisible ? a.user?.phone : null,
      similarAds: const [],
    );
  }

  static String _vehicleModelLine(AdModel a) {
    final parts = <String>[];
    void add(String? s) {
      final t = s?.trim();
      if (t != null && t.isNotEmpty && !parts.contains(t)) parts.add(t);
    }

    add(a.brand?.name);
    add(a.carModel?.name);
    add(a.year?.name);
    return parts.join('، ');
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
    required this.vehicleModelLine,
    required this.description,
    required this.sellerName,
    required this.sellerRating,
    required this.sellerReviewCount,
    this.sellerAvatarUrl,
    this.sellerIsOnline = false,
    this.sellerId,
    this.sellerVendorRecordId,
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
