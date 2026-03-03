import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/auth_controller.dart';
import 'package:stay_booking_frontend/controller/customer_hotel_controller.dart';
import 'package:stay_booking_frontend/model/hotel_response_dto.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/view/vendor/hotel_details_screen.dart';
import 'package:stay_booking_frontend/view/widgets/notification_bell_action.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({required this.user, super.key});

  final Map<String, dynamic> user;
  static const String _tag = 'customer-hotels';

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final hotelController =
        Get.isRegistered<CustomerHotelController>(tag: HomeTab._tag)
        ? Get.find<CustomerHotelController>(tag: HomeTab._tag)
        : Get.put(CustomerHotelController(), tag: HomeTab._tag);

    return Scaffold(
      backgroundColor: Color(0xFF3F1D89),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F1D89),
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              // padding: const EdgeInsets.all(6),
              child: Image.asset(
                'assets/images/logo_circle.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'StayBook',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          if (authController.isAuthenticated) const NotificationBellAction(),
          if (!authController.isAuthenticated)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => Get.toNamed(AppRoutes.login),
                child: const Text('Login'),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= 1280
              ? 1200.0
              : constraints.maxWidth >= 1024
              ? 980.0
              : constraints.maxWidth;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroSection(context, hotelController),
                    const SizedBox(height: 14),
                    Obx(
                      () => hotelController.isLoading.value
                          ? const LinearProgressIndicator(
                              borderRadius: BorderRadius.all(
                                Radius.circular(99),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Obx(
                      () => hotelController.errorMessage.value.isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: _errorBanner(
                                hotelController.errorMessage.value,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Discover Hotels',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () =>
                          hotelController.hotels.isEmpty &&
                              !hotelController.isLoading.value
                          ? _emptyState()
                          : _hotelGrid(context, hotelController),
                    ),
                    const SizedBox(height: 14),
                    Obx(() => _pagination(hotelController)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _heroSection(BuildContext context, CustomerHotelController c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        // gradient: const LinearGradient(
        //   colors: [Color(0xFF14213D), Color(0xFF24407D)],
        //   begin: Alignment.topLeft,
        //   end: Alignment.bottomRight,
        // ),
        image: const DecorationImage(
          opacity: .40,
          image: AssetImage('assets/images/hotel.png'),
          fit: BoxFit.cover, // makes image cover full container
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14213D).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find your next perfect stay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Search by city, filter quickly, and explore verified hotels.',
            style: TextStyle(color: Color(0xFFD9E0F8)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: c.searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => c.fetchHotels(resetPage: true),
                  decoration: InputDecoration(
                    hintText: 'Search hotels, city, country',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: () => c.fetchHotels(resetPage: true),
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFECF1FF),
                  foregroundColor: const Color(0xFF1E2A48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _openFilterSheet(context, c),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Filters'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Obx(() {
            final chips = <Widget>[
              if (c.cityFilterController.text.trim().isNotEmpty)
                _filterChip('City: ${c.cityFilterController.text.trim()}'),
              if (c.countryFilterController.text.trim().isNotEmpty)
                _filterChip(
                  'Country: ${c.countryFilterController.text.trim()}',
                ),
              _filterChip('Sort: ${c.sortBy.value} ${c.direction.value}'),
            ];
            return Wrap(spacing: 8, runSpacing: 8, children: chips);
          }),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    CustomerHotelController c,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _HotelFilterSheet(controller: c),
    );
  }

  Widget _hotelGrid(BuildContext context, CustomerHotelController c) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1180
            ? 3
            : width >= 760
            ? 2
            : 1;
        const gap = 14.0;
        final cardWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: c.hotels
              .map(
                (hotel) => SizedBox(width: cardWidth, child: _hotelCard(hotel)),
              )
              .toList(),
        );
      },
    );
  }

  Widget _hotelCard(HotelResponseDto hotel) {
    final image = hotel.photoUrls.isNotEmpty
        ? ApiEndpoints.resolveUrl(hotel.photoUrls.first)
        : '';

    final primary = const Color(0xFF5B6CFF); // Luxury soft indigo
    final gradient = const LinearGradient(
      colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return StatefulBuilder(
      builder: (context, setState) {
        return GestureDetector(
          onTapDown: (_) => setState(() => isPressed = true),
          onTapUp: (_) => setState(() => isPressed = false),
          onTapCancel: () => setState(() => isPressed = false),
          onTap: () =>
              Get.to(() => HotelDetailsScreen(hotel: hotel, user: widget.user)),
          child: AnimatedScale(
            scale: isPressed ? 0.98 : 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// IMAGE SECTION
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: AnimatedScale(
                            scale: isPressed ? 1.06 : 1,
                            duration: const Duration(milliseconds: 350),
                            child: image.isNotEmpty
                                ? Image.network(
                                    image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _imagePlaceholder(),
                                  )
                                : _imagePlaceholder(),
                          ),
                        ),

                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 90,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black87],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 16,
                          right: 16,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hotel.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotel.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),

                        const SizedBox(height: 8),

                        /// Location
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${hotel.city}, ${hotel.country}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        /// Description
                        Text(
                          hotel.description.trim().isEmpty
                              ? 'Experience comfort, elegance, and world-class hospitality.'
                              : hotel.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            height: 1.5,
                            fontSize: 14,
                            color: Color(0xFF444444),
                          ),
                        ),

                        const SizedBox(height: 18),

                        /// Bottom Row
                        Row(
                          children: [
                            Text(
                              "Starting ₹500",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              "/ night",
                              style: TextStyle(color: Colors.grey),
                            ),
                            const Spacer(),

                            /// Modern Pill Button
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primary, primary.withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Text(
                                "View Details",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFF0F3FA),
      alignment: Alignment.center,
      child: const Icon(
        Icons.hotel_rounded,
        size: 38,
        color: Color(0xFF7A889F),
      ),
    );
  }

  Widget _pagination(CustomerHotelController c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3F1D89),
        borderRadius: BorderRadius.circular(14),
        // border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: c.page.value > 0 ? c.goToPreviousPage : null,
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: const Text(
              'Previous',
              style: TextStyle(color: Colors.white),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white70),
            ),
          ),
          Text(
            'Page ${c.page.value + 1} / ${c.totalPages.value}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          OutlinedButton.icon(
            onPressed: c.page.value < (c.totalPages.value - 1)
                ? c.goToNextPage
                : null,
            label: const Text('Next', style: TextStyle(color: Colors.white)),
            icon: const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: Colors.white,
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white70),
            ),
          ),
          Text(
            'Total ${c.totalElements.value}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFC62828)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.travel_explore_rounded,
            size: 40,
            color: Color(0xFF7A889F),
          ),
          SizedBox(height: 10),
          Text(
            'No hotels found for current filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HotelFilterSheet extends StatefulWidget {
  const _HotelFilterSheet({required this.controller});

  final CustomerHotelController controller;

  @override
  State<_HotelFilterSheet> createState() => _HotelFilterSheetState();
}

class _HotelFilterSheetState extends State<_HotelFilterSheet> {
  late final TextEditingController _localCityController;
  late final TextEditingController _localCountryController;
  late String _selectedSort;
  late String _selectedDirection;

  @override
  void initState() {
    super.initState();
    _localCityController = TextEditingController(
      text: widget.controller.cityFilterController.text,
    );
    _localCountryController = TextEditingController(
      text: widget.controller.countryFilterController.text,
    );
    _selectedSort = widget.controller.sortBy.value;
    _selectedDirection = widget.controller.direction.value;
  }

  @override
  void dispose() {
    _localCityController.dispose();
    _localCountryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.88;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hotel Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _sheetInput(
                _localCityController,
                'City',
                Icons.location_city_outlined,
              ),
              const SizedBox(height: 10),
              _sheetInput(
                _localCountryController,
                'Country',
                Icons.public_outlined,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedSort,
                decoration: _sheetDecoration('Sort By', Icons.sort_rounded),
                items: const [
                  DropdownMenuItem(value: 'updatedat', child: Text('Updated')),
                  DropdownMenuItem(value: 'createdat', child: Text('Created')),
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'city', child: Text('City')),
                  DropdownMenuItem(value: 'country', child: Text('Country')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedSort = value);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _selectedDirection,
                decoration: _sheetDecoration(
                  'Direction',
                  Icons.swap_vert_rounded,
                ),
                items: const [
                  DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                  DropdownMenuItem(value: 'desc', child: Text('Descending')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedDirection = value);
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.controller.resetFilters();
                        Navigator.of(context).pop();
                        widget.controller.fetchHotels(resetPage: true);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        widget.controller.cityFilterController.text =
                            _localCityController.text.trim();
                        widget.controller.countryFilterController.text =
                            _localCountryController.text.trim();
                        widget.controller.setSortBy(_selectedSort);
                        widget.controller.setDirection(_selectedDirection);
                        Navigator.of(context).pop();
                        widget.controller.fetchHotels(resetPage: true);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetInput(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: _sheetDecoration(label, icon),
    );
  }

  InputDecoration _sheetDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF3F5FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF24407D), width: 1.2),
      ),
    );
  }
}
