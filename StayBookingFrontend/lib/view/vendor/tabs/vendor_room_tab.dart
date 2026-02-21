import 'package:flutter/material.dart';
import 'package:stay_booking_frontend/controller/vendor_room_controller.dart';
import 'package:stay_booking_frontend/model/room_response_dto.dart';
import 'package:stay_booking_frontend/view/vendor/room_view_screen.dart';
import 'package:get/get.dart';

class VendorRoomTab extends StatelessWidget {
  const VendorRoomTab({required this.user, super.key});

  final Map<String, dynamic> user;

  @override
  Widget build(BuildContext context) {
    final email = (user['email'] as String?)?.trim() ?? 'vendor';
    final tag = 'vendor-room-$email';
    final c = _resolveController(tag: tag);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 1000 ? 24.0 : 16.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerBar(context, c),
              const SizedBox(height: 12),
              Obx(() => c.isLoading.value ? const LinearProgressIndicator() : const SizedBox.shrink()),
              Obx(
                () => c.errorMessage.value.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _errorBanner(c.errorMessage.value),
                      ),
              ),
              const SizedBox(height: 12),
              Obx(() => c.rooms.isEmpty && !c.isLoading.value ? _emptyState() : _roomGrid(context, c)),
              const SizedBox(height: 12),
              Obx(() => _pagination(c)),
            ],
          ),
        );
      },
    );
  }

  VendorRoomController _resolveController({required String tag}) {
    if (Get.isRegistered<VendorRoomController>(tag: tag)) {
      final existing = Get.find<VendorRoomController>(tag: tag);
      if (!existing.isClosed) return existing;
      Get.delete<VendorRoomController>(tag: tag, force: true);
    }
    return Get.put(
      VendorRoomController(user: user),
      tag: tag,
      permanent: true,
    );
  }

  Widget _headerBar(BuildContext context, VendorRoomController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;

        final searchField = TextField(
          controller: controller.searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => controller.fetchRooms(resetPage: true),
          decoration: _input('Search rooms', Icons.search_rounded),
        );

        final filterButton = IconButton.filledTonal(
          tooltip: 'Filter',
          onPressed: () => _openFilterSheet(context, controller),
          icon: const Icon(Icons.filter_alt_outlined),
        );

        if (isCompact) {
          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 8),
              filterButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: searchField),
            const SizedBox(width: 8),
            filterButton,
          ],
        );
      },
    );
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    VendorRoomController controller,
  ) async {
    String selectedSort = controller.sortBy.value;
    String selectedDirection = controller.direction.value;
    bool? selectedAvailability = controller.availabilityFilter.value;

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
                      'Filter Rooms',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.hotelNameFilterController,
                      decoration: _input('Hotel Name', Icons.apartment_rounded),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedAvailability == null
                          ? 'all'
                          : selectedAvailability == true
                          ? 'available'
                          : 'unavailable',
                      decoration: _input('Status', Icons.event_available_outlined),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All')),
                        DropdownMenuItem(value: 'available', child: Text('Available')),
                        DropdownMenuItem(value: 'unavailable', child: Text('Unavailable')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedAvailability = value == 'all'
                              ? null
                              : value == 'available';
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedSort,
                      decoration: _input('Sort By', Icons.sort_rounded),
                      items: const [
                        DropdownMenuItem(value: 'roomType', child: Text('Room Type')),
                        DropdownMenuItem(value: 'price', child: Text('Price')),
                        DropdownMenuItem(value: 'available', child: Text('Availability')),
                        DropdownMenuItem(value: 'createdat', child: Text('Created At')),
                        DropdownMenuItem(value: 'updatedat', child: Text('Updated At')),
                        DropdownMenuItem(value: 'hotelName', child: Text('Hotel Name')),
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
                      decoration: _input('Direction', Icons.swap_vert_rounded),
                      items: const [
                        DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                        DropdownMenuItem(value: 'desc', child: Text('Descending')),
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
                              controller.resetFilters();
                              Navigator.of(context).pop();
                              controller.fetchRooms(resetPage: true);
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
                              controller.setAvailabilityFilter(selectedAvailability);
                              Navigator.of(context).pop();
                              controller.fetchRooms(resetPage: true);
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

  Widget _roomGrid(BuildContext context, VendorRoomController c) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100 ? 3 : width >= 760 ? 2 : 1;
        final gap = 12.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: c.rooms.map((room) => SizedBox(width: cardWidth, child: _card(context, c, room))).toList(),
        );
      },
    );
  }

  Widget _card(BuildContext context, VendorRoomController c, RoomResponseDto room) {
    final deleting = c.deletingRoomIds.contains(room.id);
    final photo = room.photos.isNotEmpty ? c.roomPhotoUrl(room.photos.first) : '';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final detailedRoom = await c.getRoomForView(room);
        if (!context.mounted) return;
        Get.to(() => RoomViewScreen(room: detailedRoom));
      },
      child: Card(
        color: const Color(0xFFF9F8FD),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (photo.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 16 / 8,
                    child: Image.network(photo, fit: BoxFit.cover),
                  ),
                ),
              if (photo.isNotEmpty) const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(room.roomType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  _status(room.available),
                ],
              ),
              const SizedBox(height: 8),
              Text(room.description.isEmpty ? 'No description added.' : room.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(
                'Hotel: ${room.hotelName.isNotEmpty ? room.hotelName : 'Hotel #${room.hotelId}'}  |  Rs ${room.price.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        c.startEdit(room);
                        await _openForm(context, c);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC62828), foregroundColor: Colors.white),
                      onPressed: deleting ? null : () async {
                        final ok = await _confirmDelete(context, room.roomType);
                        if (ok ?? false) await c.deleteRoom(room);
                      },
                      icon: deleting
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(deleting ? 'Deleting' : 'Delete'),
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

  Widget _status(bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFDFF6E4) : const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(available ? 'Available' : 'Unavailable'),
    );
  }

  Widget _pagination(VendorRoomController c) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(onPressed: c.page.value > 0 ? c.goToPreviousPage : null, child: const Text('Previous')),
          Text('Page ${c.page.value + 1} / ${c.totalPages.value}', style: const TextStyle(color: Colors.white)),
          OutlinedButton(
            onPressed: c.page.value < (c.totalPages.value - 1) ? c.goToNextPage : null,
            child: const Text('Next'),
          ),
          Text('Total: ${c.totalElements.value}', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, VendorRoomController c) async {
    final isEdit = c.editingRoomId.value != null;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Update Room' : 'Create Room'),
        content: SizedBox(
          width: 560,
          child: Form(
            key: c.formKey,
            child: SingleChildScrollView(
              child: Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isEdit) ...[
                      TextFormField(controller: c.hotelIdController, keyboardType: TextInputType.number, validator: c.validateHotelId, decoration: _input('Hotel ID', Icons.apartment_rounded)),
                      const SizedBox(height: 10),
                    ],
                    TextFormField(controller: c.roomTypeController, validator: (v) => c.requiredField(v, 'Room type'), decoration: _input('Room Type', Icons.bedroom_parent_outlined)),
                    const SizedBox(height: 10),
                    TextFormField(controller: c.priceController, validator: c.validatePrice, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _input('Price', Icons.currency_rupee_rounded)),
                    const SizedBox(height: 10),
                    TextFormField(controller: c.descriptionController, maxLines: 3, validator: (v) => c.requiredField(v, 'Description'), decoration: _input('Description', Icons.notes_rounded)),
                    SwitchListTile(value: c.available.value, onChanged: (v) => c.available.value = v, title: const Text('Available')),
                    Row(
                      children: [
                        TextButton.icon(onPressed: c.pickPhotos, icon: const Icon(Icons.photo_library_outlined), label: const Text('Select Photos')),
                        if (isEdit) Expanded(child: CheckboxListTile(value: c.replacePhotos.value, onChanged: (v) => c.replacePhotos.value = v ?? false, title: const Text('Replace existing'), controlAffinity: ListTileControlAffinity.leading)),
                      ],
                    ),
                    if (c.selectedPhotos.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: c.selectedPhotos
                              .map((file) => InputChip(label: Text(file.name), onDeleted: () => c.removePickedPhoto(file)))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          Obx(
            () => FilledButton(
              onPressed: c.isSubmitting.value
                  ? null
                  : () async {
                      final ok = await c.submitForm();
                      if (ok && context.mounted) Navigator.of(context).pop();
                    },
              child: c.isSubmitting.value
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(isEdit ? 'Update' : 'Create'),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
  }

  Widget _errorBanner(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFDECEC), borderRadius: BorderRadius.circular(12)),
        child: Text(message, style: const TextStyle(color: Color(0xFFC62828))),
      );

  Widget _emptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFFF5F2FB), borderRadius: BorderRadius.circular(12)),
        child: const Column(
          children: [
            Icon(Icons.bedroom_parent_outlined, size: 36, color: Colors.black54),
            SizedBox(height: 8),
            Text('No rooms found. Add your first room to get started.', style: TextStyle(color: Colors.black54)),
          ],
        ),
      );

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF4F2FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6B46E8), width: 1.2)),
    );
  }
}
