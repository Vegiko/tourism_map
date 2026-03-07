import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/explore_entities.dart';
import '../../../map/domain/entities/map_marker.dart';
import '../../../payment/presentation/pages/payment_screen.dart';

// ════════════════════════════════════════════════════════════
//  Detail Screen  –  شاشة التفاصيل
// ════════════════════════════════════════════════════════════
class DetailScreen extends StatefulWidget {
  final TravelPackage? package;
  final Hotel? hotel;
  final bool isArabic;

  const DetailScreen({
    super.key,
    this.package,
    this.hotel,
    required this.isArabic,
  }) : assert(package != null || hotel != null,
            'Must provide either package or hotel');

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  // ── Derived getters ──────────────────────────────
  bool get _isPkg => widget.package != null;

  List<String> get _images =>
      _isPkg ? widget.package!.imageUrls : widget.hotel!.imageUrls;

  String get _title => _isPkg
      ? (widget.isArabic ? widget.package!.titleAr : widget.package!.title)
      : (widget.isArabic ? widget.hotel!.nameAr : widget.hotel!.name);

  String get _subtitle => _isPkg
      ? (widget.isArabic
          ? widget.package!.agencyNameAr
          : widget.package!.agencyName)
      : (widget.isArabic
          ? '${widget.hotel!.stars} نجوم'
          : '${widget.hotel!.stars} Stars');

  String get _city => _isPkg
      ? (widget.isArabic
          ? widget.package!.destinationCityAr
          : widget.package!.destinationCity)
      : (widget.isArabic ? widget.hotel!.cityAr : widget.hotel!.city);

  String get _country => _isPkg
      ? (widget.isArabic ? widget.package!.countryAr : widget.package!.country)
      : (widget.isArabic ? widget.hotel!.countryAr : widget.hotel!.country);

  String get _description => _isPkg
      ? (widget.isArabic
          ? widget.package!.descriptionAr
          : widget.package!.description)
      : (widget.isArabic
          ? widget.hotel!.descriptionAr
          : widget.hotel!.description);

  double get _rating => _isPkg ? widget.package!.rating : widget.hotel!.rating;

  int get _reviewCount =>
      _isPkg ? widget.package!.reviewCount : widget.hotel!.reviewCount;

  double get _price => _isPkg
      ? widget.package!.price
      : widget.hotel!.pricePerNight;

  String get _priceLabel => widget.isArabic
      ? (_isPkg ? '/شخص' : '/ليلة')
      : (_isPkg ? '/person' : '/night');

  double get _lat =>
      _isPkg ? widget.package!.latitude : widget.hotel!.latitude;

  double get _lng =>
      _isPkg ? widget.package!.longitude : widget.hotel!.longitude;

  String get _address => _isPkg
      ? '$_city, $_country'
      : (widget.isArabic ? widget.hotel!.addressAr : widget.hotel!.address);

  List<String> get _features => _isPkg
      ? (widget.isArabic ? widget.package!.includesAr : widget.package!.includes)
      : (widget.isArabic ? widget.hotel!.amenitiesAr : widget.hotel!.amenities);

  // ── State ────────────────────────────────────────
  int _currentImageIndex = 0;
  bool _isSaved = false;
  bool _isDescExpanded = false;
  late PageController _pageCtrl;
  late AnimationController _entranceCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _bookingCtrl;
  late Animation<Offset> _bookingSlide;
  late AnimationController _imageCtrl;
  late Animation<double> _imageZoom;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();

    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);

    _bookingCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _bookingSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _bookingCtrl, curve: Curves.elasticOut));

    _imageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _imageZoom = Tween<double>(begin: 1.08, end: 1.0).animate(
        CurvedAnimation(parent: _imageCtrl, curve: Curves.easeOut));

    _entranceCtrl.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _bookingCtrl.forward();
    });
    _imageCtrl.forward();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _entranceCtrl.dispose();
    _bookingCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  void _onBook() {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          serviceId:    _isPkg ? widget.package!.id : widget.hotel!.id,
          serviceName:  _title,
          serviceNameAr: _isPkg ? widget.package!.titleAr : widget.hotel!.nameAr,
          serviceType:   _isPkg ? MarkerType.travelAgency : MarkerType.hotel,
          amount:        _price,
          guests:        2,
          checkIn:       now.add(const Duration(days: 14)),
          checkOut:      now.add(Duration(days: 14 + (_isPkg ? widget.package!.durationDays : 3))),
          isArabic:      widget.isArabic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // ── Scrollable Content ─────────────────
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Image Gallery Sliver
                SliverToBoxAdapter(child: _buildImageGallery()),
                // Main Content
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildContent(),
                  ),
                ),
                // Bottom padding for booking bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            ),

            // ── Floating AppBar ────────────────────
            _buildFloatingAppBar(),

            // ── Sticky Booking Bar ─────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _bookingSlide,
                child: _buildBookingBar(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  Image Gallery
  // ════════════════════════════════════════════════
  Widget _buildImageGallery() {
    return SizedBox(
      height: 360,
      child: Stack(
        children: [
          // Main pager
          PageView.builder(
            controller: _pageCtrl,
            itemCount: _images.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (_, i) => ScaleTransition(
              scale: i == 0 ? _imageZoom : const AlwaysStoppedAnimation(1.0),
              child: Image.network(
                _images[i],
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppColors.primarySurface,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                progress.expectedTotalBytes!
                            : null,
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primarySurface,
                  child: const Icon(Icons.image_not_supported_rounded,
                      color: AppColors.textHint, size: 60),
                ),
              ),
            ),
          ),

          // Bottom gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Page indicator dots
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_images.length, (i) {
                final isActive = i == _currentImageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

          // Thumbnail strip
          Positioned(
            bottom: 40,
            left: 12,
            right: 12,
            child: SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _images.length,
                itemBuilder: (_, i) {
                  final isSelected = i == _currentImageIndex;
                  return GestureDetector(
                    onTap: () => _pageCtrl.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 56 : 46,
                      height: isSelected ? 52 : 44,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                const BoxShadow(
                                    color: Colors.black38, blurRadius: 6)
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primarySurface,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Image count badge top right
          Positioned(
            top: 60,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.photo_library_rounded,
                    color: Colors.white, size: 12),
                const SizedBox(width: 5),
                Text(
                  '${_currentImageIndex + 1} / ${_images.length}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  Floating AppBar
  // ════════════════════════════════════════════════
  Widget _buildFloatingAppBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back button
            _GlassButton(
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
              onTap: () => Navigator.of(context).pop(),
            ),
            // Right actions
            Row(
              children: [
                _GlassButton(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isSaved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(_isSaved),
                      color: _isSaved ? AppColors.accent : Colors.white,
                      size: 18,
                    ),
                  ),
                  onTap: () => setState(() => _isSaved = !_isSaved),
                ),
                const SizedBox(width: 8),
                _GlassButton(
                  child: const Icon(Icons.share_rounded,
                      color: Colors.white, size: 18),
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  Main Content
  // ════════════════════════════════════════════════
  Widget _buildContent() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      // Pull up to cover image slightly
      transform: Matrix4.translationValues(0, -24, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Type Badge + Rating ──────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTypeBadge(),
                _buildRatingPill(),
              ],
            ),
            const SizedBox(height: 12),

            // ── Title ────────────────────────────
            Text(
              _title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),

            // ── Subtitle (Agency or Stars) ───────
            Text(
              _subtitle,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // ── Quick Info Row ───────────────────
            _buildQuickInfoRow(),
            const SizedBox(height: 24),

            // ── Features/Includes ────────────────
            _buildFeaturesSection(),
            const SizedBox(height: 24),

            // ── Description ─────────────────────
            _buildDescriptionSection(),
            const SizedBox(height: 24),

            // ── Map Section ──────────────────────
            _buildMapSection(),
            const SizedBox(height: 24),

            // ── Reviews Preview ──────────────────
            _buildReviewsPreview(),
          ],
        ),
      ),
    );
  }

  // ── Type Badge ──────────────────────────────────
  Widget _buildTypeBadge() {
    final gradient =
        _isPkg ? AppColors.sunsetGradient : AppColors.primaryGradient;
    final label = _isPkg
        ? _t('باقة سياحية', 'Travel Package')
        : _t('فندق', 'Hotel');
    final icon = _isPkg ? '✈️' : '🏨';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }

  // ── Rating Pill ─────────────────────────────────
  Widget _buildRatingPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, size: 14, color: AppColors.secondary),
        const SizedBox(width: 5),
        Text(
          _rating.toStringAsFixed(1),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '(${_formatCount(_reviewCount)})',
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ]),
    );
  }

  // ── Quick Info Row ──────────────────────────────
  Widget _buildQuickInfoRow() {
    final items = <_InfoItem>[];

    items.add(_InfoItem(
      icon: Icons.location_on_rounded,
      value: '$_city, $_country',
      label: _t('الموقع', 'Location'),
      color: AppColors.accent,
    ));

    if (_isPkg) {
      items.add(_InfoItem(
        icon: Icons.calendar_today_rounded,
        value: '${widget.package!.durationDays} ${_t('أيام', 'Days')}',
        label: _t('المدة', 'Duration'),
        color: AppColors.primary,
      ));
      items.add(_InfoItem(
        icon: Icons.nights_stay_rounded,
        value: '${widget.package!.durationNights} ${_t('ليالٍ', 'Nights')}',
        label: _t('الليالي', 'Nights'),
        color: AppColors.primaryLight,
      ));
    } else {
      items.add(_InfoItem(
        icon: Icons.star_rounded,
        value: '${widget.hotel!.stars}  ⭐',
        label: _t('النجوم', 'Stars'),
        color: AppColors.secondary,
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) => Expanded(child: _buildInfoCell(item))).toList(),
      ),
    );
  }

  Widget _buildInfoCell(_InfoItem item) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, size: 20, color: item.color),
        ),
        const SizedBox(height: 6),
        Text(
          item.value,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          item.label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 10,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  // ── Features Section ────────────────────────────
  Widget _buildFeaturesSection() {
    final sectionTitle =
        _isPkg ? _t('تشمل الباقة', 'Package Includes') : _t('المرافق', 'Amenities');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _features.map((feature) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.15),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  feature,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Description ──────────────────────────────────
  Widget _buildDescriptionSection() {
    const maxLines = 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('عن هذا المكان', 'About This Place'),
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _isDescExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            _description,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
          secondChild: Text(
            _description,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(
              _isDescExpanded
                  ? _t('عرض أقل', 'Show Less')
                  : _t('اقرأ المزيد', 'Read More'),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isDescExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary, size: 18),
            ),
          ]),
        ),
      ],
    );
  }

  // ── Map Section ──────────────────────────────────
  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _t('الموقع على الخريطة', 'Location on Map'),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.open_in_new_rounded,
                      size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    _t('فتح', 'Open'),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MapWidget(
          lat: _lat,
          lng: _lng,
          title: _title,
          address: _address,
          isArabic: widget.isArabic,
        ),
      ],
    );
  }

  // ── Reviews Preview ──────────────────────────────
  Widget _buildReviewsPreview() {
    final reviews = _generateMockReviews();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _t('آراء العملاء', 'Guest Reviews'),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              _t('عرض الكل', 'See All'),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Overall rating summary
        _buildRatingSummary(),
        const SizedBox(height: 16),
        // Review cards
        ...reviews.map((r) => _ReviewCard(review: r, isArabic: widget.isArabic)),
      ],
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Big rating number
          Column(
            children: [
              Text(
                _rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < _rating.floor()
                        ? Icons.star_rounded
                        : i < _rating
                            ? Icons.star_half_rounded
                            : Icons.star_border_rounded,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatCount(_reviewCount)} ${_t('تقييم', 'reviews')}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Rating bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final pct = star == 5
                    ? 0.72
                    : star == 4
                        ? 0.18
                        : star == 3
                            ? 0.06
                            : star == 2
                                ? 0.03
                                : 0.01;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Text(
                      '$star',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star_rounded,
                        size: 10, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: AppColors.surfaceVariant,
                          color: AppColors.secondary,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(pct * 100).toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  List<_ReviewData> _generateMockReviews() => [
        _ReviewData(
          name: _t('فاطمة الزهراء', 'Fatima Al-Zahra'),
          rating: 5.0,
          comment: _t(
            'تجربة لا تُنسى! كل شيء كان مثالياً من الخدمة إلى الموقع. سأعود قريباً بالتأكيد.',
            'Unforgettable experience! Everything was perfect from service to location. Will definitely return soon.',
          ),
          date: _t('منذ أسبوعين', '2 weeks ago'),
          avatarColor: const Color(0xFF9B59B6),
        ),
        _ReviewData(
          name: _t('أحمد عبدالله', 'Ahmed Abdullah'),
          rating: 4.5,
          comment: _t(
            'رائع جداً والموظفون كانوا متعاونين جداً. الطعام ممتاز والمناظر خلابة.',
            'Very amazing and the staff were very cooperative. Excellent food and breathtaking views.',
          ),
          date: _t('منذ شهر', '1 month ago'),
          avatarColor: const Color(0xFF2980B9),
        ),
      ];

  // ════════════════════════════════════════════════
  //  Booking Bar
  // ════════════════════════════════════════════════
  Widget _buildBookingBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '\$${_price.toInt()}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    Text(
                      _priceLabel,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ]),
              if (_isPkg && widget.package!.hasDiscount)
                Text(
                  '\$${widget.package!.originalPrice.toInt()}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textHint,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Book Button
          Expanded(
            child: GestureDetector(
              onTap: _onBook,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: _isPkg
                      ? AppColors.sunsetGradient
                      : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (_isPkg ? AppColors.accent : AppColors.primary)
                          .withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _t('احجز الآن', 'Book Now'),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) =>
      count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count';
}

// ════════════════════════════════════════════════════════════
//  Map Widget  –  Interactive-style map placeholder
// ════════════════════════════════════════════════════════════
class _MapWidget extends StatefulWidget {
  final double lat, lng;
  final String title, address;
  final bool isArabic;

  const _MapWidget({
    required this.lat,
    required this.lng,
    required this.title,
    required this.address,
    required this.isArabic,
  });

  @override
  State<_MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<_MapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pingCtrl;
  late Animation<double> _pingScale;
  late Animation<double> _pingOpacity;

  @override
  void initState() {
    super.initState();
    _pingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _pingScale = Tween<double>(begin: 0.5, end: 2.0).animate(
      CurvedAnimation(parent: _pingCtrl, curve: Curves.easeOut),
    );
    _pingOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pingCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate pseudo tile grid based on lat/lng
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isArabic
                  ? 'سيتم فتح الخريطة التفاعلية قريباً'
                  : 'Interactive map coming soon',
              style: const TextStyle(fontFamily: 'Cairo'),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // ── Map background using network tile ──
              Positioned.fill(
                child: _MapTileBackground(lat: widget.lat, lng: widget.lng),
              ),

              // ── Map overlay gradient ──
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.25),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Ping animation ──
              Center(
                child: AnimatedBuilder(
                  animation: _pingCtrl,
                  builder: (_, __) {
                    return SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ping ring
                          Opacity(
                            opacity: _pingOpacity.value,
                            child: Transform.scale(
                              scale: _pingScale.value,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.accent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Pin
                          const _MapPin(),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Location label ──
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppColors.sunsetGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.address,
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),

              // ── Tap to open hint ──
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.touch_app_rounded,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      widget.isArabic ? 'افتح الخريطة' : 'Open Map',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapTileBackground extends StatelessWidget {
  final double lat, lng;
  const _MapTileBackground({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    // Use openstreetmap tile URL
    final zoom = 13;
    final tileX = ((lng + 180) / 360 * pow(2, zoom)).floor();
    final latRad = lat * (3.141592653589793 / 180);
    final tileY =
        ((1 - (log(tan(latRad) + (1 / cos(latRad))) / 3.141592653589793)) /
                2 *
                pow(2, zoom))
            .floor();

    return Container(
      color: const Color(0xFFE8EBE4),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1,
        ),
        itemCount: 9,
        itemBuilder: (_, i) {
          final dx = (i % 3) - 1;
          final dy = (i ~/ 3) - 1;
          return Image.network(
            'https://tile.openstreetmap.org/$zoom/${tileX + dx}/${tileY + dy}.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _MapFallback(lat: lat, lng: lng),
          );
        },
      ),
    );
  }
}

class _MapFallback extends StatelessWidget {
  final double lat, lng;
  const _MapFallback({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapPainter(),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFE8EEE0);
    canvas.drawRect(Offset.zero & size, bg);

    // Draw simple road-like lines
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final road2 = Paint()
      ..color = const Color(0xFFD4D8CC)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
        Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.45), road);
    canvas.drawLine(
        Offset(size.width * 0.4, 0), Offset(size.width * 0.55, size.height), road);
    canvas.drawLine(
        Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.6), road2);

    // Water area
    final water = Paint()..color = const Color(0xFFB5D5E8).withOpacity(0.4);
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.75, size.width, size.height * 0.25),
        water);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Icon(
        Icons.location_on_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Review Card
// ════════════════════════════════════════════════════════════
class _ReviewCard extends StatelessWidget {
  final _ReviewData review;
  final bool isArabic;

  const _ReviewCard({required this.review, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: review.avatarColor,
                child: Text(
                  review.name[0],
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 12,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          review.date,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Booking Sheet
// ════════════════════════════════════════════════════════════
class _BookingSheet extends StatefulWidget {
  final String title;
  final double price;
  final String priceLabel;
  final bool isArabic;
  final bool isPkg;

  const _BookingSheet({
    required this.title,
    required this.price,
    required this.priceLabel,
    required this.isArabic,
    required this.isPkg,
  });

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  int _guests = 2;
  DateTime _checkIn = DateTime.now().add(const Duration(days: 7));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 14));

  double get _total => widget.price * _guests;

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  Future<void> _pickDate(bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut.isBefore(_checkIn)) {
            _checkOut = _checkIn.add(const Duration(days: 1));
          }
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _t('تفاصيل الحجز', 'Booking Details'),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              // Date row
              Row(
                children: [
                  Expanded(
                    child: _DateSelector(
                      label: _t('تاريخ الوصول', 'Check In'),
                      date: _checkIn,
                      icon: Icons.flight_land_rounded,
                      isArabic: widget.isArabic,
                      onTap: () => _pickDate(true),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: 32,
                      height: 2,
                      color: AppColors.textHint.withOpacity(0.3),
                    ),
                  ),
                  Expanded(
                    child: _DateSelector(
                      label: _t('تاريخ المغادرة', 'Check Out'),
                      date: _checkOut,
                      icon: Icons.flight_takeoff_rounded,
                      isArabic: widget.isArabic,
                      onTap: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Guests
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      const Icon(Icons.people_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('عدد الأشخاص', 'Number of Guests'),
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '$_guests ${_t('أشخاص', 'Guests')}',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ]),
                    ]),
                    Row(children: [
                      _CounterButton(
                        icon: Icons.remove_rounded,
                        onTap: _guests > 1
                            ? () => setState(() => _guests--)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '$_guests',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      _CounterButton(
                        icon: Icons.add_rounded,
                        onTap: _guests < 10
                            ? () => setState(() => _guests++)
                            : null,
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Price summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(children: [
                  _PriceRow(
                    label: _t('السعر', 'Price'),
                    value: '\$${widget.price.toInt()} × $_guests',
                    isArabic: widget.isArabic,
                  ),
                  const SizedBox(height: 8),
                  _PriceRow(
                    label: _t('رسوم الخدمة', 'Service Fee'),
                    value: '\$${(_total * 0.05).toInt()}',
                    isArabic: widget.isArabic,
                  ),
                  const Divider(height: 16, color: Color(0xFFCCDFE8)),
                  _PriceRow(
                    label: _t('الإجمالي', 'Total'),
                    value: '\$${(_total * 1.05).toInt()}',
                    isArabic: widget.isArabic,
                    isTotal: true,
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Confirm Button
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _t('تم تأكيد الحجز بنجاح! 🎉',
                            'Booking confirmed successfully! 🎉'),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: widget.isPkg
                        ? AppColors.sunsetGradient
                        : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (widget.isPkg ? AppColors.accent : AppColors.primary)
                                .withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _t('تأكيد الحجز', 'Confirm Booking'),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small helper widgets ──────────────────────────
class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _GlassButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final IconData icon;
  final bool isArabic;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.icon,
    required this.isArabic,
    required this.onTap,
  });

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            _formatDate(date),
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ]),
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CounterButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient:
              onTap != null ? AppColors.primaryGradient : null,
          color: onTap == null ? AppColors.surfaceVariant : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap != null ? Colors.white : AppColors.textHint),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final bool isArabic, isTotal;
  const _PriceRow({
    required this.label,
    required this.value,
    required this.isArabic,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: isTotal ? 18 : 13,
            fontWeight: FontWeight.w700,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Data classes ──────────────────────────────────
class _InfoItem {
  final IconData icon;
  final String value, label;
  final Color color;
  const _InfoItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
}

class _ReviewData {
  final String name, comment, date;
  final double rating;
  final Color avatarColor;
  const _ReviewData({
    required this.name,
    required this.rating,
    required this.comment,
    required this.date,
    required this.avatarColor,
  });
}
