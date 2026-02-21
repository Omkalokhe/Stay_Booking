import 'package:flutter/material.dart';
import 'package:stay_booking_frontend/controller/vendor_hotel_controller.dart';
import 'package:stay_booking_frontend/model/hotel_response_dto.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';
import 'package:get/get.dart';

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
                    controller.startCreate();
                    await _showHotelDialog(context, controller);
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

    return Card(
      elevation: 1.5,
      color: const Color(0xFFF9F8FD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.hotel_rounded,
                    color: Color(0xFF5A31D6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hotel.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
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
                  ? 'No description added.'
                  : hotel.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.black54,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${hotel.address}, ${hotel.city}, ${hotel.state}, ${hotel.country} - ${hotel.pincode}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      controller.startEdit(hotel);
                      await _showHotelDialog(context, controller);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      foregroundColor: Colors.white,
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
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(isDeleting ? 'Deleting' : 'Delete'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
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
                icon: const Icon(Icons.add_box_rounded, size: 18),
                label: const Text('Add Room For This Hotel'),
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _showHotelDialog(
    BuildContext context,
    VendorHotelController controller,
  ) async {
    final isEdit = controller.editingHotelId.value != null;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Update Hotel' : 'Create Hotel'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width > 900 ? 760 : 520,
            child: Form(
              key: controller.formKey,
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 640;
                    final width = isWide
                        ? (constraints.maxWidth - 12) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _formField(
                          width: width,
                          child: TextFormField(
                            controller: controller.nameController,
                            validator: (v) =>
                                controller.requiredField(v, 'Hotel name'),
                            decoration: _inputDecoration(
                              'Hotel Name',
                              Icons.hotel_rounded,
                            ),
                          ),
                        ),
                        _formField(
                          width: width,
                          child: TextFormField(
                            controller: controller.ratingController,
                            validator: controller.validateRating,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration(
                              'Rating (0-5)',
                              Icons.star_outline_rounded,
                            ),
                          ),
                        ),
                        _formField(
                          width: constraints.maxWidth,
                          child: TextFormField(
                            controller: controller.descriptionController,
                            validator: (v) =>
                                controller.requiredField(v, 'Description'),
                            maxLines: 3,
                            decoration: _inputDecoration(
                              'Description',
                              Icons.notes_rounded,
                            ),
                          ),
                        ),
                        _formField(
                          width: constraints.maxWidth,
                          child: TextFormField(
                            controller: controller.addressController,
                            validator: (v) =>
                                controller.requiredField(v, 'Address'),
                            decoration: _inputDecoration(
                              'Address',
                              Icons.location_on_outlined,
                            ),
                          ),
                        ),
                        _formField(
                          width: width,
                          child: TextFormField(
                            controller: controller.cityController,
                            validator: (v) =>
                                controller.requiredField(v, 'City'),
                            decoration: _inputDecoration(
                              'City',
                              Icons.location_city_outlined,
                            ),
                          ),
                        ),
                        _formField(
                          width: width,
                          child: TextFormField(
                            controller: controller.stateController,
                            validator: (v) =>
                                controller.requiredField(v, 'State'),
                            decoration: _inputDecoration(
                              'State',
                              Icons.map_outlined,
                            ),
                          ),
                        ),
                        _formField(
                          width: width,
                          child: TextFormField(
                            controller: controller.countryController,
                            validator: (v) =>
                                controller.requiredField(v, 'Country'),
                            decoration: _inputDecoration(
                              'Country',
                              Icons.public_outlined,
                            ),
                          ),
                        ),
                        _formField(
                          width: width,
                          child: TextFormField(
                            controller: controller.pincodeController,
                            validator: (v) =>
                                controller.requiredField(v, 'Pincode'),
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                              'Pincode',
                              Icons.pin_outlined,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            Obx(
              () => FilledButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : () async {
                        final ok = await controller.submitForm();
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEdit ? 'Update' : 'Create'),
              ),
            ),
          ],
        );
      },
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

  Widget _formField({required double width, required Widget child}) {
    return SizedBox(width: width, child: child);
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
