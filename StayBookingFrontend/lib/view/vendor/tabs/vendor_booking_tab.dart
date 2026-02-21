import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/booking/booking_controller.dart';
import 'package:stay_booking_frontend/model/booking_response_dto.dart';
import 'package:stay_booking_frontend/model/update_booking_request_dto.dart';
import 'package:stay_booking_frontend/model/update_booking_status_request_dto.dart';

class VendorBookingTab extends StatefulWidget {
  const VendorBookingTab({required this.user, super.key});

  final Map<String, dynamic> user;

  @override
  State<VendorBookingTab> createState() => _VendorBookingTabState();
}

class _VendorBookingTabState extends State<VendorBookingTab> {
  late final BookingController _controller;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final email = (widget.user['email'] as String?)?.trim() ?? 'vendor';
    final tag = 'vendor-booking-$email';
    _controller = Get.isRegistered<BookingController>(tag: tag)
        ? Get.find<BookingController>(tag: tag)
        : Get.put(BookingController(currentUser: widget.user), tag: tag);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _controller.refreshList,
      child: Obx(() {
        if (_controller.isLoading.value && _controller.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_controller.errorMessage.value.isNotEmpty &&
            _controller.items.isEmpty) {
          return _errorState(
            _controller.errorMessage.value,
            () => _controller.loadFirstPage(showLoader: true),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 1000
                ? 24.0
                : 16.0;
            final isWide = constraints.maxWidth >= 980;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                24,
              ),
              children: [
                _headerBar(),
                const SizedBox(height: 12),
                if (_controller.isEmpty)
                  _emptyState('No vendor bookings found for selected filters.')
                else if (isWide)
                  _bookingTable(_controller.items)
                else
                  ..._controller.items.map(_bookingCard),
                const SizedBox(height: 12),
                _pagination(),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _headerBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: _controller.applySearch,
            decoration: InputDecoration(
              hintText: 'Search bookings',
              filled: true,
              fillColor: const Color(0xFFE7E5EC),
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: _openFilterSheet,
          icon: const Icon(Icons.filter_alt_outlined),
          tooltip: 'Filters',
        ),
      ],
    );
  }

  Future<void> _openFilterSheet() async {
    int? hotelId = _controller.selectedHotelId.value;
    int? roomId = _controller.selectedRoomId.value;
    String? bookingStatus = _controller.bookingStatusFilter.value;
    String? paymentStatus = _controller.paymentStatusFilter.value;
    DateTime? checkInFrom = _controller.checkInFrom.value;
    DateTime? checkOutTo = _controller.checkOutTo.value;
    String sortBy = _controller.sortBy.value;
    String direction = _controller.direction.value;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final rooms = _controller.roomsForHotel(hotelId);
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int?>(
                      initialValue: hotelId,
                      decoration: _input('Hotel'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Hotels'),
                        ),
                        ..._controller.hotels.map(
                          (h) => DropdownMenuItem<int?>(
                            value: h.id,
                            child: Text(h.name),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => hotelId = value),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int?>(
                      initialValue: roomId,
                      decoration: _input('Room'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Rooms'),
                        ),
                        ...rooms.map(
                          (r) => DropdownMenuItem<int?>(
                            value: r.id,
                            child: Text('${r.roomType} (${r.hotelName})'),
                          ),
                        ),
                      ],
                      onChanged: (value) => setModalState(() => roomId = value),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String?>(
                      initialValue: bookingStatus,
                      decoration: _input('Booking Status'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Booking Status'),
                        ),
                        ...BookingController.bookingStatuses.map(
                          (e) => DropdownMenuItem<String?>(
                            value: e,
                            child: Text(e),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => bookingStatus = value),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String?>(
                      initialValue: paymentStatus,
                      decoration: _input('Payment Status'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Payment Status'),
                        ),
                        ...BookingController.paymentStatuses.map(
                          (e) => DropdownMenuItem<String?>(
                            value: e,
                            child: Text(e),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setModalState(() => paymentStatus = value),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await _pickDate(checkInFrom);
                              if (picked == null) return;
                              setModalState(() => checkInFrom = picked);
                            },
                            icon: const Icon(Icons.date_range_outlined),
                            label: Text(
                              checkInFrom == null
                                  ? 'Check-In From'
                                  : _dateOnly(checkInFrom!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await _pickDate(checkOutTo);
                              if (picked == null) return;
                              setModalState(() => checkOutTo = picked);
                            },
                            icon: const Icon(Icons.date_range_outlined),
                            label: Text(
                              checkOutTo == null
                                  ? 'Check-Out To'
                                  : _dateOnly(checkOutTo!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: sortBy,
                      decoration: _input('Sort By'),
                      items: BookingController.sortOptions
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) =>
                          setModalState(() => sortBy = value ?? 'updatedat'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: direction,
                      decoration: _input('Direction'),
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
                      onChanged: (value) =>
                          setModalState(() => direction = value ?? 'desc'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              _searchController.clear();
                              await _controller.resetFilters();
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _controller.setHotelFilter(hotelId);
                              await _controller.setRoomFilter(roomId);
                              await _controller.setBookingStatusFilter(
                                bookingStatus,
                              );
                              await _controller.setPaymentStatusFilter(
                                paymentStatus,
                              );
                              await _controller.setCheckInFrom(checkInFrom);
                              await _controller.setCheckOutTo(checkOutTo);
                              await _controller.setSort(sortBy);
                              await _controller.setDirection(direction);
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

  Widget _bookingTable(List<BookingResponseDto> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Hotel')),
          DataColumn(label: Text('Room')),
          DataColumn(label: Text('Check-In')),
          DataColumn(label: Text('Check-Out')),
          DataColumn(label: Text('Booking')),
          DataColumn(label: Text('Payment')),
          DataColumn(label: Text('Actions')),
        ],
        rows: items
            .map(
              (b) => DataRow(
                cells: [
                  DataCell(Text('${b.id}')),
                  DataCell(Text(b.userEmail)),
                  DataCell(Text(b.hotelName)),
                  DataCell(Text(b.roomType)),
                  DataCell(Text(b.checkInDate)),
                  DataCell(Text(b.checkOutDate)),
                  DataCell(Text(b.bookingStatus)),
                  DataCell(Text(b.paymentStatus)),
                  DataCell(
                    Wrap(
                      spacing: 2,
                      children: [
                        IconButton(
                          tooltip: 'View',
                          onPressed: () => _openBookingDetails(b),
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => _openUpdateBookingSheet(b),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Update Status',
                          onPressed: () => _openStatusUpdateSheet(b),
                          icon: const Icon(Icons.swap_horiz_outlined),
                        ),
                        IconButton(
                          tooltip: 'Cancel Booking',
                          onPressed: () => _controller.cancelBooking(b),
                          icon: const Icon(Icons.cancel_outlined),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _bookingCard(BookingResponseDto booking) {
    return Card(
      color: const Color(0xFFF9F8FD),
      child: ListTile(
        title: Text(
          '${booking.hotelName} - ${booking.roomType}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${booking.userEmail}\n${booking.checkInDate} to ${booking.checkOutDate}\nBooking: ${booking.bookingStatus} | Payment: ${booking.paymentStatus}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'view') await _openBookingDetails(booking);
            if (value == 'edit') await _openUpdateBookingSheet(booking);
            if (value == 'status') await _openStatusUpdateSheet(booking);
            if (value == 'cancel') await _controller.cancelBooking(booking);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'view', child: Text('View')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'status', child: Text('Update Status')),
            PopupMenuItem(value: 'cancel', child: Text('Cancel')),
          ],
        ),
      ),
    );
  }

  Future<void> _openUpdateBookingSheet(BookingResponseDto booking) async {
    DateTime? checkInDate = _parseDate(booking.checkInDate);
    DateTime? checkOutDate = _parseDate(booking.checkOutDate);
    final guestsController = TextEditingController(
      text: '${booking.numberOfGuests}',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Update Booking #${booking.id}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await _pickDate(checkInDate);
                              if (picked == null) return;
                              setModalState(() => checkInDate = picked);
                            },
                            child: Text(
                              checkInDate == null
                                  ? 'Check-In Date'
                                  : _dateOnly(checkInDate!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await _pickDate(checkOutDate);
                              if (picked == null) return;
                              setModalState(() => checkOutDate = picked);
                            },
                            child: Text(
                              checkOutDate == null
                                  ? 'Check-Out Date'
                                  : _dateOnly(checkOutDate!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: guestsController,
                      keyboardType: TextInputType.number,
                      decoration: _input('Number of Guests'),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => FilledButton(
                          onPressed: _controller.isSubmitting.value
                              ? null
                              : () async {
                                  if (checkInDate == null ||
                                      checkOutDate == null) {
                                    Get.snackbar(
                                      'Validation',
                                      'Please select check-in and check-out dates.',
                                    );
                                    return;
                                  }
                                  final guests =
                                      int.tryParse(
                                        guestsController.text.trim(),
                                      ) ??
                                      0;
                                  if (guests <= 0) {
                                    Get.snackbar(
                                      'Validation',
                                      'Guests must be greater than 0.',
                                    );
                                    return;
                                  }
                                  final result = await _controller
                                      .updateBooking(
                                        booking.id,
                                        UpdateBookingRequestDto(
                                          checkInDate: _dateOnly(checkInDate!),
                                          checkOutDate: _dateOnly(
                                            checkOutDate!,
                                          ),
                                          numberOfGuests: guests,
                                        ),
                                      );
                                  if (result != null && context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                          child: _controller.isSubmitting.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Update Booking'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    guestsController.dispose();
  }

  Future<void> _openStatusUpdateSheet(BookingResponseDto booking) async {
    String? bookingStatus = booking.bookingStatus;
    String? paymentStatus = booking.paymentStatus;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String?>(
                      initialValue: bookingStatus,
                      decoration: _input('Booking Status'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No Change'),
                        ),
                        ...BookingController.bookingStatuses.map(
                          (e) => DropdownMenuItem<String?>(
                            value: e,
                            child: Text(e),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => bookingStatus = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: paymentStatus,
                      decoration: _input('Payment Status'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('No Change'),
                        ),
                        ...BookingController.paymentStatuses.map(
                          (e) => DropdownMenuItem<String?>(
                            value: e,
                            child: Text(e),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModalState(() => paymentStatus = v),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: Obx(
                        () => FilledButton(
                          onPressed: _controller.isSubmitting.value
                              ? null
                              : () async {
                                  final result = await _controller.updateStatus(
                                    booking.id,
                                    UpdateBookingStatusRequestDto(
                                      bookingStatus: bookingStatus,
                                      paymentStatus: paymentStatus,
                                    ),
                                  );
                                  if (result != null && context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                          child: _controller.isSubmitting.value
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Update Status'),
                        ),
                      ),
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

  Future<void> _openBookingDetails(BookingResponseDto booking) async {
    final latest = await _controller.getBookingById(booking.id);
    final data = latest ?? booking;
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking #${data.id}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _kv('User', data.userEmail),
                  _kv('Hotel', data.hotelName),
                  _kv('Room', data.roomType),
                  _kv('Check-In', data.checkInDate),
                  _kv('Check-Out', data.checkOutDate),
                  _kv('Guests', '${data.numberOfGuests}'),
                  _kv(
                    'Total Amount',
                    'Rs ${data.totalAmount.toStringAsFixed(2)}',
                  ),
                  _kv('Booking Status', data.bookingStatus),
                  _kv('Payment Status', data.paymentStatus),
                  _kv('Created', data.createdAt),
                  _kv('Updated', data.updatedAt),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$key:',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _pagination() {
    return Row(
      children: [
        Text(
          'Total: ${_controller.totalElements.value} | '
          'Page ${_controller.page.value + 1}/${_controller.totalPages.value}',
          style: const TextStyle(color: Colors.white),
        ),
        const Spacer(),
        IconButton(
          onPressed: _controller.isFirstPage.value
              ? null
              : _controller.goToPreviousPage,
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        IconButton(
          onPressed: _controller.isLastPage.value
              ? null
              : _controller.goToNextPage,
          icon: const Icon(Icons.chevron_right, color: Colors.white),
        ),
      ],
    );
  }

  Widget _emptyState(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(message)),
      ),
    );
  }

  Widget _errorState(String message, Future<void> Function() onRetry) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<DateTime?> _pickDate(DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
      initialDate: initial ?? now,
    );
  }

  DateTime? _parseDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _dateOnly(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
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
}
