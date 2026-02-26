import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/vendor_hotel_controller.dart';
import 'package:stay_booking_frontend/routes/hotel_form_binding.dart';
import 'package:stay_booking_frontend/view/vendor/hotel_create_page.dart';
import 'package:stay_booking_frontend/view/vendor/hotel_edit_page.dart';
import 'package:stay_booking_frontend/model/hotel_response_dto.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';
import 'package:stay_booking_frontend/service/core/api_endpoints.dart';
import 'package:stay_booking_frontend/view/vendor/hotel_details_screen.dart';

class VendorHotelTab extends StatelessWidget {
  const VendorHotelTab({required this.user, super.key});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final emailKey = (user['email'] as String?)?.trim() ?? 'vendor';
    final tag = 'vendor-hotel-$emailKey';
    final controller = Get.isRegistered<VendorHotelController>(tag: tag)
        ? Get.find<VendorHotelController>(tag: tag)
        : Get.put(VendorHotelController(user: user), tag: tag);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 1000 ? 24.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerBar(context, controller),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () async {
                    final created = await Get.to<bool>(
                      () => const HotelCreatePage(),
                      binding: HotelFormBinding(),
                      arguments: {'user': user},
                    );
                    if (created == true) {
                      await controller.fetchHotels(resetPage: true);
                    }
                  },
                  icon: const Icon(Icons.add_business_rounded),
                  label: const Text('Add Hotel'),
                ),
              ),
              const SizedBox(height: 14),
              Obx(
                () => controller.isLoading.value
                    ? const LinearProgressIndicator()
                    : const SizedBox.shrink(),
              ),
              Obx(
                () => controller.errorMessage.value.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _errorBanner(controller.errorMessage.value),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Obx(
                () => controller.hotels.isEmpty && !controller.isLoading.value
                    ? _emptyState()
                    : _hotelCardGrid(context, controller),
              ),
              const SizedBox(height: 12),
              Obx(() => _paginationControls(controller)),
            ],
          ),
        );
      },
    );
  }

  Widget _headerBar(BuildContext context, VendorHotelController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        // final title = Text(
        //   'Hotel Management',
        //   style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        //         fontWeight: FontWeight.w700,
        //       ),
        // );

        final searchField = TextField(
          controller: controller.searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => controller.fetchHotels(resetPage: true),
          decoration: _inputDecoration('Search hotels', Icons.search_rounded),
        );

        final filterButton = IconButton.filledTonal(
          tooltip: 'Filter',
          onPressed: () => _openFilterSheet(context, controller),
          icon: const Icon(Icons.filter_alt_outlined),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: searchField),
                  const SizedBox(width: 8),
                  filterButton,
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            const SizedBox(width: 16),
            Expanded(child: searchField),
            const SizedBox(width: 8),
            filterButton,
          ],
        );
      },
    );
  }

  Widget _hotelCardGrid(
    BuildContext context,
    VendorHotelController controller,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 3
            : width >= 760
            ? 2
            : 1;
        final gap = 12.0;
        final cardWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: controller.hotels
              .map(
                (hotel) => SizedBox(
                  width: cardWidth,
                  child: _hotelCard(
                    context: context,
                    controller: controller,
                    hotel: hotel,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _hotelCard({
    required BuildContext context,
    required VendorHotelController controller,
    required HotelResponseDto hotel,
  }) {
    final isDeleting = controller.deletingHotelIds.contains(hotel.id);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Get.to(() => HotelDetailsScreen(hotel: hotel));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFF7F5FF), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hotelImage(hotel),
              const SizedBox(height: 12),

            /// Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C5CFF), Color(0xFF5A31D6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.hotel_rounded, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hotel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _ratingChip(hotel.rating),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              hotel.description.isEmpty
                  ? 'No description available'
                  : hotel.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${hotel.city}, ${hotel.state}',
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            /// Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final updated = await Get.to<bool>(
                        () => const HotelEditPage(),
                        binding: HotelFormBinding(),
                        arguments: {
                          'hotelId': hotel.id,
                          'user': user,
                        },
                      );
                      if (updated == true) {
                        await controller.fetchHotels();
                      }
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                    ),
                    onPressed: isDeleting
                        ? null
                        : () async {
                            final confirm = await _confirmDelete(
                              context,
                              hotel.name,
                            );
                            if (confirm ?? false) {
                              await controller.deleteHotel(hotel);
                            }
                          },
                    icon: isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(isDeleting ? 'Deleting' : 'Delete'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A31D6),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Get.toNamed(
                    AppRoutes.vendorAddRoom,
                    arguments: {
                      'user': user,
                      'hotelId': hotel.id,
                      'hotelName': hotel.name,
                    },
                  );
                },
                icon: const Icon(Icons.add_box_rounded),
                label: const Text('Add Room For This Hotel'),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hotelImage(HotelResponseDto hotel) {
    final imageUrl = _primaryPhotoUrl(hotel);
    if (imageUrl == null) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFE8E1FF), Color(0xFFF5F2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 30, color: Color(0xFF6B5F91)),
            SizedBox(height: 6),
            Text(
              'No hotel image',
              style: TextStyle(
                color: Color(0xFF6B5F91),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFF5F2FF),
            child: const Center(
              child: Icon(Icons.broken_image_outlined, color: Color(0xFF6B5F91)),
            ),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: const Color(0xFFF5F2FF),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
        ),
      ),
    );
  }

  String? _primaryPhotoUrl(HotelResponseDto hotel) {
    if (hotel.photoUrls.isEmpty) return null;
    final first = hotel.photoUrls.first.trim();
    if (first.isEmpty) return null;
    return ApiEndpoints.resolveUrl(first);
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    VendorHotelController controller,
  ) async {
    String selectedSort = controller.sortBy.value;
    String selectedDirection = controller.direction.value;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
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
                    Text(
                      'Filter Hotels',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.cityFilterController,
                      decoration: _inputDecoration(
                        'City',
                        Icons.location_city_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller.countryFilterController,
                      decoration: _inputDecoration(
                        'Country',
                        Icons.public_outlined,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSort,
                      decoration: _inputDecoration(
                        'Sort By',
                        Icons.sort_rounded,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'name', child: Text('Name')),
                        DropdownMenuItem(value: 'city', child: Text('City')),
                        DropdownMenuItem(
                          value: 'rating',
                          child: Text('Rating'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedSort = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDirection,
                      decoration: _inputDecoration(
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
                        setState(() {
                          selectedDirection = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              controller.cityFilterController.clear();
                              controller.countryFilterController.clear();
                              controller.setSortBy('updatedat');
                              controller.setDirection('desc');
                              Navigator.of(context).pop();
                              controller.fetchHotels(resetPage: true);
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              controller.setSortBy(selectedSort);
                              controller.setDirection(selectedDirection);
                              Navigator.of(context).pop();
                              controller.fetchHotels(resetPage: true);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _ratingChip(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E1FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: Color(0xFF5A31D6)),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Color(0xFF5A31D6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paginationControls(VendorHotelController controller) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton(
            onPressed: controller.page.value > 0
                ? controller.goToPreviousPage
                : null,
            style: OutlinedButton.styleFrom(
              backgroundColor: controller.page.value > 0
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
            ),
            child: const Text(
              'Previous',
              style: TextStyle(color: Colors.black),
            ),
          ),
          Text(
            'Page ${controller.page.value + 1} / ${controller.totalPages.value}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          OutlinedButton(
            onPressed: controller.page.value < (controller.totalPages.value - 1)
                ? controller.goToNextPage
                : null,
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  controller.page.value < (controller.totalPages.value - 1)
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.6),
            ),
            child: const Text('Next', style: TextStyle(color: Colors.black)),
          ),
          Text(
            'Total: ${controller.totalElements.value}',
            style: const TextStyle(color: Colors.white70),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.hotel_outlined, size: 36, color: Colors.black54),
          SizedBox(height: 8),
          Text(
            'No hotels found. Add your first hotel to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Hotel'),
          content: Text('Are you sure you want to delete "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF4F2FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6B46E8), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD63D3D), width: 1.1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD63D3D), width: 1.1),
      ),
    );
  }
}

