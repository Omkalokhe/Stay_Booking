import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/customer_booking_controller.dart';
import 'package:stay_booking_frontend/model/room_response_dto.dart';
import 'package:stay_booking_frontend/view/vendor/room_view_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({required this.user, super.key});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    const tag = 'customer-booking';
    final roomController = Get.isRegistered<CustomerBookingController>(tag: tag)
        ? Get.find<CustomerBookingController>(tag: tag)
        : Get.put(CustomerBookingController(), tag: tag);

    return Scaffold(
      backgroundColor: Color(0xFF3F1D89),
      appBar: AppBar(
        backgroundColor: Color(0xFF3F1D89),
        toolbarHeight: 60,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _searchAndFilters(context, roomController),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth >= 1000 ? 24.0 : 16.0;
          final contentWidth = constraints.maxWidth >= 1000 ? 900.0 : 620.0;

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => roomController.isLoading.value
                          ? const LinearProgressIndicator()
                          : const SizedBox.shrink(),
                    ),
                    Obx(
                      () => roomController.errorMessage.value.isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: _errorBanner(
                                roomController.errorMessage.value,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () =>
                          roomController.rooms.isEmpty &&
                              !roomController.isLoading.value
                          ? _emptyState()
                          : _roomGrid(context, roomController),
                    ),
                    const SizedBox(height: 12),
                    Obx(() => _pagination(roomController)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _searchAndFilters(BuildContext context, CustomerBookingController c) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D6DF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: c.searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => c.fetchRooms(resetPage: true),
              decoration: _searchPillDecoration('Search hotels'),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 45,
          height: 45,
          decoration: const BoxDecoration(
            color: Color(0xFFD9D6DF),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => _openFilterSheet(context, c),
            icon: const Icon(Icons.filter_alt_outlined, size: 24),
            color: const Color(0xFF5A5A5A),
            tooltip: 'Filter',
          ),
        ),
      ],
    );
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    CustomerBookingController c,
  ) async {
    final localHotelController = TextEditingController(
      text: c.hotelNameFilterController.text,
    );
    String selectedAvailability = c.availabilityFilter.value == null
        ? 'all'
        : c.availabilityFilter.value!
        ? 'available'
        : 'unavailable';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setState) {
            return SafeArea(
              child: Padding(
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
                    Text(
                      'Filter Rooms',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: localHotelController,
                      decoration: _input('Hotel Name', Icons.apartment_rounded),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedAvailability,
                      decoration: _input(
                        'Status',
                        Icons.event_available_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(
                          value: 'available',
                          child: Text('Available'),
                        ),
                        DropdownMenuItem(
                          value: 'unavailable',
                          child: Text('Unavailable'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedAvailability = value;
                        });
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
                              c.fetchRooms(resetPage: true);
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              c.hotelNameFilterController.text =
                                  localHotelController.text.trim();
                              c.setAvailabilityFilter(
                                selectedAvailability == 'all'
                                    ? null
                                    : selectedAvailability == 'available',
                              );
                              Navigator.of(sheetContext).pop();
                              c.fetchRooms(resetPage: true);
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
    localHotelController.dispose();
  }

  Widget _roomGrid(BuildContext context, CustomerBookingController c) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1180
            ? 3
            : width >= 760
            ? 2
            : 1;
        final gap = 12.0;
        final cardWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: c.rooms
              .map(
                (room) => SizedBox(
                  width: cardWidth,
                  child: _roomCard(context, c, room),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _roomCard(
    BuildContext context,
    CustomerBookingController c,
    RoomResponseDto room,
  ) {
    final hotelName = room.hotelName.trim().isEmpty
        ? 'Hotel #${room.hotelId}'
        : room.hotelName.trim();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final detailed = await c.getRoomForView(room);
        if (!context.mounted) return;
        Get.to(() => RoomViewScreen(room: detailed, user: user));
      },
      child: Card(
        color: const Color(0xFFF9F8FD),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bedroom_parent_outlined,
                    size: 18,
                    color: Color(0xFF5A31D6),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      room.roomType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _statusChip(room.available),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                hotelName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                room.description.trim().isEmpty
                    ? 'No description added.'
                    : room.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Rs ${room.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'View Details',
                    style: TextStyle(
                      color: Color(0xFF5A31D6),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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

  Widget _statusChip(bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFDFF6E4) : const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        available ? 'Available' : 'Unavailable',
        style: TextStyle(
          color: available ? const Color(0xFF1B7D39) : const Color(0xFFC62828),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _pagination(CustomerBookingController c) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: c.page.value > 0 ? c.goToPreviousPage : null,
            child: const Text(
              'Previous',
              style: TextStyle(color: Colors.white),
            ),
          ),
          Text(
            'Page ${c.page.value + 1} / ${c.totalPages.value}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          OutlinedButton(
            onPressed: c.page.value < (c.totalPages.value - 1)
                ? c.goToNextPage
                : null,
            child: const Text('Next', style: TextStyle(color: Colors.white)),
          ),
          Text(
            'Total: ${c.totalElements.value}',
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F2FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: Colors.black54),
          SizedBox(height: 8),
          Text(
            'No rooms found for current filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
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
    );
  }

  InputDecoration _searchPillDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(
        Icons.search_rounded,
        color: Color(0xFF5A5A5A),
        size: 28,
      ),
      filled: true,
      fillColor: Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6B46E8), width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }
}
