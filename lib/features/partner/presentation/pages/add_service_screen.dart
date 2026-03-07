import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/partner_service.dart';
import '../bloc/partner_bloc.dart';
import '../../../auth/domain/entities/app_user.dart';

class AddServiceScreen extends StatefulWidget {
  final AppUser partner;
  final bool isArabic;

  const AddServiceScreen({
    super.key,
    required this.partner,
    required this.isArabic,
  });

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen>
    with TickerProviderStateMixin {
  // Form key
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl         = TextEditingController();
  final _nameArCtrl       = TextEditingController();
  final _descCtrl         = TextEditingController();
  final _descArCtrl       = TextEditingController();
  final _priceCtrl        = TextEditingController();
  final _addressCtrl      = TextEditingController();
  final _cityCtrl         = TextEditingController();

  // State
  ServiceType _selectedType = ServiceType.hotel;
  final List<File> _selectedImages = [];
  ServiceLocation? _location;
  bool _fetchingLocation = false;
  bool _locationPicked = false;
  int _currentStep = 0;

  // Animations
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;
  late AnimationController _fabCtrl;
  late Animation<double> _fabScale;

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();

    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fabScale = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 500),
        () { if (mounted) _fabCtrl.forward(); });
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _nameArCtrl.dispose();
    _descCtrl.dispose(); _descArCtrl.dispose();
    _priceCtrl.dispose(); _addressCtrl.dispose(); _cityCtrl.dispose();
    _slideCtrl.dispose(); _fabCtrl.dispose();
    super.dispose();
  }

  String _t(String ar, String en) => widget.isArabic ? ar : en;

  // ════════════════════════════════════════════════
  //  Image Picker
  // ════════════════════════════════════════════════
  Future<void> _pickImages() async {
    final remaining = 5 - _selectedImages.length;
    if (remaining <= 0) {
      _showSnack(_t('الحد الأقصى 5 صور', 'Maximum 5 images'), isError: true);
      return;
    }

    final picked = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked.isEmpty) return;

    final toAdd = picked.take(remaining).map((x) => File(x.path)).toList();
    setState(() => _selectedImages.addAll(toAdd));
    HapticFeedback.lightImpact();
  }

  Future<void> _pickFromCamera() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;
    if (_selectedImages.length >= 5) {
      _showSnack(_t('الحد الأقصى 5 صور', 'Maximum 5 images'), isError: true);
      return;
    }
    setState(() => _selectedImages.add(File(picked.path)));
    HapticFeedback.lightImpact();
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
    HapticFeedback.lightImpact();
  }

  // ════════════════════════════════════════════════
  //  Geo Location
  // ════════════════════════════════════════════════
  Future<void> _detectCurrentLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      // Check permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _showSnack(
          _t('الرجاء السماح بالوصول للموقع في الإعدادات',
              'Please enable location in settings'),
          isError: true,
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _location = ServiceLocation(
          latitude:  pos.latitude,
          longitude: pos.longitude,
          address:   _addressCtrl.text.isNotEmpty
              ? _addressCtrl.text
              : '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
          city:    _cityCtrl.text.isNotEmpty ? _cityCtrl.text : 'غير محدد',
          country: '',
        );
        _locationPicked = true;
        if (_addressCtrl.text.isEmpty) {
          _addressCtrl.text =
              '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
        }
      });
      HapticFeedback.mediumImpact();
      _showSnack(_t('تم تحديد موقعك بنجاح ✓', 'Location detected ✓'));
    } catch (e) {
      _showSnack(
        _t('تعذر تحديد الموقع: $e', 'Could not get location: $e'),
        isError: true,
      );
    } finally {
      setState(() => _fetchingLocation = false);
    }
  }

  void _saveManualLocation() {
    if (_addressCtrl.text.isEmpty || _cityCtrl.text.isEmpty) {
      _showSnack(
        _t('أدخل العنوان والمدينة', 'Enter address and city'),
        isError: true,
      );
      return;
    }
    setState(() {
      _location = ServiceLocation(
        latitude:  0,
        longitude: 0,
        address:   _addressCtrl.text.trim(),
        city:      _cityCtrl.text.trim(),
        country:   '',
      );
      _locationPicked = true;
    });
    HapticFeedback.lightImpact();
    _showSnack(_t('تم حفظ الموقع ✓', 'Location saved ✓'));
  }

  // ════════════════════════════════════════════════
  //  Validation
  // ════════════════════════════════════════════════
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Basic info
        if (_nameCtrl.text.trim().isEmpty) {
          _showSnack(_t('أدخل اسم الخدمة', 'Enter service name'), isError: true);
          return false;
        }
        if (_priceCtrl.text.isEmpty ||
            double.tryParse(_priceCtrl.text) == null) {
          _showSnack(_t('أدخل سعراً صحيحاً', 'Enter a valid price'), isError: true);
          return false;
        }
        return true;
      case 1: // Images
        if (_selectedImages.isEmpty) {
          _showSnack(
            _t('أضف صورة واحدة على الأقل', 'Add at least one image'),
            isError: true,
          );
          return false;
        }
        return true;
      case 2: // Location
        return true; // location is optional, show warning only
    }
    return true;
  }

  void _goNext() {
    if (_validateCurrentStep()) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
        _slideCtrl.reset();
        _slideCtrl.forward();
      } else {
        _submit();
      }
    }
  }

  void _goPrev() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _slideCtrl.reset();
      _slideCtrl.forward();
    }
  }

  // ════════════════════════════════════════════════
  //  Submit
  // ════════════════════════════════════════════════
  void _submit() {
    if (_location == null && (_addressCtrl.text.isEmpty)) {
      _showSnack(
        _t('يُفضّل إضافة الموقع لزيادة الظهور',
            'Location recommended for better visibility'),
      );
    }

    context.read<PartnerBloc>().add(AddServiceSubmittedEvent(
      partnerId:     widget.partner.uid,
      partnerName:   widget.partner.displayName,
      partnerNameAr: widget.partner.displayName,
      name:          _nameCtrl.text.trim(),
      nameAr:        _nameArCtrl.text.trim().isNotEmpty
          ? _nameArCtrl.text.trim()
          : _nameCtrl.text.trim(),
      description:   _descCtrl.text.trim(),
      descriptionAr: _descArCtrl.text.trim(),
      serviceType:   _selectedType,
      price:         double.tryParse(_priceCtrl.text) ?? 0,
      location:      _location ?? ((_addressCtrl.text.isNotEmpty)
          ? ServiceLocation(
              latitude:  0,
              longitude: 0,
              address:   _addressCtrl.text.trim(),
              city:      _cityCtrl.text.trim(),
              country:   '',
            )
          : null),
      images: _selectedImages,
    ));
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: BlocListener<PartnerBloc, PartnerState>(
        listener: (context, state) {
          if (state is ServiceAddedSuccess) {
            _showSnack(_t('تمت إضافة الخدمة بنجاح! 🎉',
                'Service added successfully! 🎉'));
            Navigator.of(context).pop(true);
          }
          if (state is PartnerDashboardLoaded &&
              state.errorMessage != null) {
            _showSnack(state.errorMessage!, isError: true);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: BlocBuilder<PartnerBloc, PartnerState>(
            builder: (ctx, state) {
              final isLoading = state is PartnerDashboardLoaded &&
                  state.isAddingService;
              return Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      _buildAppBar(context, isLoading),
                      SliverToBoxAdapter(
                        child: _buildStepIndicator(),
                      ),
                      SliverToBoxAdapter(
                        child: SlideTransition(
                          position: _slideAnim,
                          child: _buildCurrentStep(),
                        ),
                      ),
                      const SliverToBoxAdapter(
                          child: SizedBox(height: 120)),
                    ],
                  ),
                  // Bottom action bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomBar(isLoading),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────
  Widget _buildAppBar(BuildContext context, bool isLoading) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 0,
      backgroundColor: AppColors.surface,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        _t('إضافة خدمة جديدة', 'Add New Service'),
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          fontSize: 17,
        ),
      ),
      actions: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  // ── Step Indicator ──────────────────────────────
  Widget _buildStepIndicator() {
    final steps = [
      _t('المعلومات الأساسية', 'Basic Info'),
      _t('الصور', 'Photos'),
      _t('الموقع', 'Location'),
    ];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: AppColors.surfaceVariant,
              color: AppColors.primary,
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 14),
          // Step labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: steps.asMap().entries.map((e) {
              final i = e.key;
              final label = e.value;
              final isDone    = i < _currentStep;
              final isActive  = i == _currentStep;
              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive || isDone
                            ? AppColors.primaryGradient
                            : null,
                        color: (!isActive && !isDone)
                            ? AppColors.surfaceVariant
                            : null,
                        boxShadow: isActive
                            ? [BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )]
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 16)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isActive
                                      ? Colors.white
                                      : AppColors.textHint,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Dispatch step to right widget ────────────────
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildStep1BasicInfo();
      case 1: return _buildStep2Photos();
      case 2: return _buildStep3Location();
      default: return _buildStep1BasicInfo();
    }
  }

  // ════════════════════════════════════════════════
  //  STEP 1 – Basic Info
  // ════════════════════════════════════════════════
  Widget _buildStep1BasicInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section: Service Type ──────────────
            _SectionLabel(_t('نوع الخدمة *', 'Service Type *')),
            const SizedBox(height: 12),
            _buildServiceTypeSelector(),
            const SizedBox(height: 24),

            // ── Service name (en) ──────────────────
            _SectionLabel(_t('اسم الخدمة (إنجليزي) *', 'Service Name (English) *')),
            const SizedBox(height: 8),
            _FormField(
              controller: _nameCtrl,
              hint: _t('مثال: Al Nujoom Hotel', 'e.g. Al Nujoom Hotel'),
              icon: Icons.business_rounded,
              inputType: TextInputType.text,
              required: true,
            ),
            const SizedBox(height: 16),

            // ── Service name (ar) ──────────────────
            _SectionLabel(_t('اسم الخدمة (عربي)', 'Service Name (Arabic)')),
            const SizedBox(height: 8),
            _FormField(
              controller: _nameArCtrl,
              hint: _t('مثال: فندق النجوم', 'e.g. فندق النجوم'),
              icon: Icons.translate_rounded,
              inputType: TextInputType.text,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),

            // ── Price ──────────────────────────────
            _SectionLabel(_t('السعر (بالدولار) *', 'Price (USD) *')),
            const SizedBox(height: 8),
            _FormField(
              controller: _priceCtrl,
              hint: _t('مثال: 150', 'e.g. 150'),
              icon: Icons.attach_money_rounded,
              inputType: const TextInputType.numberWithOptions(decimal: true),
              prefix: '\$',
              required: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
            ),
            const SizedBox(height: 16),

            // ── Description ────────────────────────
            _SectionLabel(_t('وصف الخدمة (اختياري)', 'Description (optional)')),
            const SizedBox(height: 8),
            _FormField(
              controller: _descCtrl,
              hint: _t(
                'صف خدمتك بالتفصيل...',
                'Describe your service in detail...',
              ),
              icon: Icons.description_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _SectionLabel(_t('الوصف بالعربية (اختياري)', 'Arabic Description (optional)')),
            const SizedBox(height: 8),
            _FormField(
              controller: _descArCtrl,
              hint: _t('صف خدمتك بالعربية...', 'الوصف بالعربية...'),
              icon: Icons.description_rounded,
              maxLines: 3,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  // ── Service Type Selector Grid ──────────────────
  Widget _buildServiceTypeSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ServiceType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () {
            setState(() => _selectedType = type);
            HapticFeedback.selectionClick();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : AppColors.textHint.withOpacity(0.3),
              ),
              boxShadow: isSelected
                  ? [BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )]
                  : [BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                    )],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(type.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                widget.isArabic ? type.nameAr : type.nameEn,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 14),
              ],
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ════════════════════════════════════════════════
  //  STEP 2 – Photos
  // ════════════════════════════════════════════════
  Widget _buildStep2Photos() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.photo_library_rounded,
                  color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    _t('الصور تزيد الحجوزات بنسبة 40%!',
                        'Photos increase bookings by 40%!'),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _t('أضف حتى 5 صور عالية الجودة',
                        'Add up to 5 high-quality photos'),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedImages.length}/5',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Image grid
          if (_selectedImages.isNotEmpty) ...[
            _SectionLabel(_t('الصور المختارة', 'Selected Photos')),
            const SizedBox(height: 12),
            _buildImageGrid(),
            const SizedBox(height: 20),
          ],

          // Add button row
          if (_selectedImages.length < 5) ...[
            _SectionLabel(_t('أضف صوراً', 'Add Photos')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PickerButton(
                    icon: Icons.photo_library_rounded,
                    label: _t('من المعرض', 'Gallery'),
                    color: AppColors.primary,
                    onTap: _pickImages,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerButton(
                    icon: Icons.camera_alt_rounded,
                    label: _t('الكاميرا', 'Camera'),
                    color: AppColors.accent,
                    onTap: _pickFromCamera,
                  ),
                ),
              ],
            ),
          ],

          // Tips
          const SizedBox(height: 24),
          _buildPhotoTips(),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _selectedImages.length,
      itemBuilder: (_, i) {
        final isFirst = i == 0;
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImages[i],
                fit: BoxFit.cover,
              ),
            ),
            // First image badge
            if (isFirst)
              Positioned(
                bottom: 6,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: AppColors.sunsetGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _t('رئيسية', 'Main'),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            // Remove button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeImage(i),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                      )
                    ],
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhotoTips() {
    final tips = [
      _t('صوّر في ضوء النهار الطبيعي', 'Shoot in natural daylight'),
      _t('أظهر المناطق المميزة في خدمتك', 'Showcase your best areas'),
      _t('تجنب الصور الضبابية أو المظلمة', 'Avoid blurry or dark photos'),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lightbulb_rounded,
                color: AppColors.secondary, size: 16),
            const SizedBox(width: 6),
            Text(
              _t('نصائح للصور', 'Photo Tips'),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_rounded,
                    size: 12, color: AppColors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  STEP 3 – Location
  // ════════════════════════════════════════════════
  Widget _buildStep3Location() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-detect card
          _buildDetectLocationCard(),
          const SizedBox(height: 24),

          // Divider with OR
          _OrDivider(text: _t('أو أدخل يدوياً', 'or enter manually')),
          const SizedBox(height: 20),

          // Manual entry
          _SectionLabel(_t('العنوان التفصيلي', 'Detailed Address')),
          const SizedBox(height: 8),
          _FormField(
            controller: _addressCtrl,
            hint: _t(
              'مثال: شارع الملك فهد، الرياض',
              'e.g. King Fahd Road, Riyadh',
            ),
            icon: Icons.pin_drop_rounded,
          ),
          const SizedBox(height: 16),
          _SectionLabel(_t('المدينة', 'City')),
          const SizedBox(height: 8),
          _FormField(
            controller: _cityCtrl,
            hint: _t('مثال: الرياض', 'e.g. Riyadh'),
            icon: Icons.location_city_rounded,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _saveManualLocation,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: Text(
                _t('حفظ الموقع', 'Save Location'),
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Location confirmed badge
          if (_locationPicked) ...[
            const SizedBox(height: 20),
            _buildLocationConfirmed(),
          ],

          // Optional badge
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t(
                    'الموقع اختياري ولكنه يزيد من ظهور خدمتك بشكل كبير في نتائج البحث.',
                    'Location is optional but greatly increases your service visibility in search results.',
                  ),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.primary,
                    height: 1.5,
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _locationPicked
            ? const LinearGradient(
                colors: [Color(0xFF27AE60), Color(0xFF1E8449)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _locationPicked
                    ? Icons.check_circle_rounded
                    : Icons.my_location_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _locationPicked
                        ? _t('تم تحديد الموقع ✓', 'Location Set ✓')
                        : _t('تحديد موقعي الحالي', 'Use My Current Location'),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    _locationPicked
                        ? (_location?.address ?? '')
                        : _t(
                            'استخدام GPS للتحديد التلقائي',
                            'Use GPS for automatic detection',
                          ),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetchingLocation ? null : _detectCurrentLocation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_fetchingLocation)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  else
                    const Icon(Icons.gps_fixed_rounded,
                        color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _fetchingLocation
                        ? _t('جارٍ التحديد...', 'Detecting...')
                        : _t('تحديد الموقع', 'Detect Location'),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationConfirmed() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('تم تحديد الموقع', 'Location Set'),
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.success,
                ),
              ),
              if (_location != null)
                Text(
                  _location!.latitude != 0
                      ? 'Lat: ${_location!.latitude.toStringAsFixed(4)}, '
                          'Lng: ${_location!.longitude.toStringAsFixed(4)}'
                      : _location!.address,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_rounded,
              color: AppColors.textHint, size: 18),
          onPressed: () => setState(() {
            _locationPicked = false;
            _location = null;
          }),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════
  //  Bottom Action Bar
  // ════════════════════════════════════════════════
  Widget _buildBottomBar(bool isLoading) {
    final isLast = _currentStep == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          if (_currentStep > 0)
            GestureDetector(
              onTap: _goPrev,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textSecondary),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          // Next / Submit button
          Expanded(
            child: GestureDetector(
              onTap: isLoading ? null : _goNext,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 52,
                decoration: BoxDecoration(
                  gradient: isLoading
                      ? null
                      : (isLast
                          ? AppColors.sunsetGradient
                          : AppColors.primaryGradient),
                  color: isLoading ? AppColors.surfaceVariant : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isLoading
                      ? null
                      : [
                          BoxShadow(
                            color: (isLast
                                    ? AppColors.accent
                                    : AppColors.primary)
                                .withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    else ...[
                      Icon(
                        isLast
                            ? Icons.cloud_upload_rounded
                            : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLoading
                            ? _t('جارٍ الحفظ...', 'Saving...')
                            : isLast
                                ? _t('نشر الخدمة', 'Publish Service')
                                : _t('التالي', 'Next'),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  Reusable Helper Widgets
// ════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _FormField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType inputType;
  final int maxLines;
  final bool required;
  final String? prefix;
  final List<TextInputFormatter>? inputFormatters;
  final TextDirection? textDirection;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.inputType = TextInputType.text,
    this.maxLines = 1,
    this.required = false,
    this.prefix,
    this.inputFormatters,
    this.textDirection,
  });

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _focused
                ? AppColors.primary.withOpacity(0.12)
                : Colors.black.withOpacity(0.04),
            blurRadius: _focused ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: _focused
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.textHint.withOpacity(0.2),
          width: _focused ? 1.5 : 1,
        ),
      ),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: TextFormField(
          controller:         widget.controller,
          keyboardType:       widget.inputType,
          maxLines:           widget.maxLines,
          inputFormatters:    widget.inputFormatters,
          textDirection:      widget.textDirection,
          decoration: InputDecoration(
            hintText:         widget.hint,
            prefixIcon:       Icon(widget.icon,
                color: _focused ? AppColors.primary : AppColors.textHint,
                size: 20),
            prefixText:       widget.prefix,
            prefixStyle:      const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
            border:           InputBorder.none,
            enabledBorder:    InputBorder.none,
            focusedBorder:    InputBorder.none,
            contentPadding:   const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            hintStyle:        const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.textHint,
              fontSize: 13,
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Cairo',
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final String text;
  const _OrDivider({required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: AppColors.textHint,
          ),
        ),
      ),
      const Expanded(child: Divider()),
    ]);
  }
}
