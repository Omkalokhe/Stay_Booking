import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/auth_controller.dart';
import 'package:stay_booking_frontend/controller/customer_hotel_controller.dart';
import 'package:stay_booking_frontend/model/hotel_response_dto.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/view/vendor/hotel_details_screen.dart';
import 'package:stay_booking_frontend/view/widgets/notification_bell_action.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({required this.user, super.key});

  final Map<String, dynamic> user;
  static const String _tag = 'customer-hotels';

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final hotelController = Get.isRegistered<CustomerHotelController>(tag: _tag)
        ? Get.find<CustomerHotelController>(tag: _tag)
        : Get.put(CustomerHotelController(), tag: _tag);

    return Scaffold(
      backgroundColor: Color(0xFF3F1D89),
      appBar: AppBar(
        backgroundColor: Color(0xFF3F1D89),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'StayBook',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
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
    final localCityController = TextEditingController(
      text: c.cityFilterController.text,
    );
    final localCountryController = TextEditingController(
      text: c.countryFilterController.text,
    );
    String selectedSort = c.sortBy.value;
    String selectedDirection = c.direction.value;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            final maxSheetHeight =
                MediaQuery.of(sheetContext).size.height * 0.88;
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxSheetHeight),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    10,
                    16,
                    16 + MediaQuery.of(sheetContext).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hotel Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sheetInput(
                        localCityController,
                        'City',
                        Icons.location_city_outlined,
                      ),
                      const SizedBox(height: 10),
                      _sheetInput(
                        localCountryController,
                        'Country',
                        Icons.public_outlined,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedSort,
                        decoration: _sheetDecoration(
                          'Sort By',
                          Icons.sort_rounded,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'updatedat',
                            child: Text('Updated'),
                          ),
                          DropdownMenuItem(
                            value: 'createdat',
                            child: Text('Created'),
                          ),
                          DropdownMenuItem(value: 'name', child: Text('Name')),
                          DropdownMenuItem(value: 'city', child: Text('City')),
                          DropdownMenuItem(
                            value: 'country',
                            child: Text('Country'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => selectedSort = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedDirection,
                        decoration: _sheetDecoration(
                          'Direction',
                          Icons.swap_vert_rounded,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'asc',
                            child: Text('Ascending'),
                          ),
                          DropdownMenuItem(
                            value: 'desc',
                            child: Text('Descending'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => selectedDirection = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                c.resetFilters();
                                Navigator.of(sheetContext).pop();
                                c.fetchHotels(resetPage: true);
                              },
                              child: const Text('Reset'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                c.cityFilterController.text =
                                    localCityController.text.trim();
                                c.countryFilterController.text =
                                    localCountryController.text.trim();
                                c.setSortBy(selectedSort);
                                c.setDirection(selectedDirection);
                                Navigator.of(sheetContext).pop();
                                c.fetchHotels(resetPage: true);
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
          },
        );
      },
    );
    localCityController.dispose();
    localCountryController.dispose();
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

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Get.to(() => HotelDetailsScreen(hotel: hotel, user: user)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8ECF5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Color(0xFF667085),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${hotel.city}, ${hotel.country}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF667085)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hotel.description.trim().isEmpty
                        ? 'A comfortable stay with premium amenities.'
                        : hotel.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      height: 1.35,
                      color: Color(0xFF2F3645),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7EEFF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Rating ${hotel.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF21418C),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'View details',
                        style: TextStyle(
                          color: Color(0xFF21418C),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF5)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: c.page.value > 0 ? c.goToPreviousPage : null,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Previous'),
          ),
          Text(
            'Page ${c.page.value + 1} / ${c.totalPages.value}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          OutlinedButton.icon(
            onPressed: c.page.value < (c.totalPages.value - 1)
                ? c.goToNextPage
                : null,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Next'),
          ),
          Text(
            'Total ${c.totalElements.value}',
            style: const TextStyle(
              color: Color(0xFF667085),
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
