import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/admin/admin_rooms_controller.dart';
import 'package:stay_booking_frontend/model/room_response_dto.dart';

class AdminRoomsTab extends StatefulWidget {
  const AdminRoomsTab({required this.user, super.key});

  final Map<String, dynamic> user;

  @override
  State<AdminRoomsTab> createState() => _AdminRoomsTabState();
}

class _AdminRoomsTabState extends State<AdminRoomsTab> {
  late final AdminRoomsController _controller;
  final _searchController = TextEditingController();
  final _hotelController = TextEditingController();

  static const _sortOptions = <String>[
    'roomType',
    'price',
    'available',
    'createdat',
    'updatedat',
    'hotelName',
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      AdminRoomsController(currentAdminEmail: _adminEmail()),
      tag: 'admin-rooms-controller',
    );
    _controller.loadFirstPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hotelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E1E86),
        foregroundColor: Colors.white,
        titleSpacing: 16,
        title: _buildSearchBar(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filledTonal(
              onPressed: _openFilterSheet,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.filter_alt_outlined),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _controller.refreshList,
        child: Obx(() {
          if (_controller.isLoading.value && _controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage.value.isNotEmpty && _controller.items.isEmpty) {
            return _ErrorState(
              message: _controller.errorMessage.value,
              onRetry: _controller.loadFirstPage,
            );
          }

          return ListView(
            padding: _contentPadding(context),
            children: [
              if (_controller.isEmpty)
                const _EmptyState(message: 'No rooms found.')
              else
                ..._controller.items.map(_buildRoomCard),
              const SizedBox(height: 12),
              _PaginationBar(controller: _controller),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: _controller.applySearch,
      decoration: InputDecoration(
        hintText: 'Search rooms',
        filled: true,
        fillColor: const Color(0xFFE7E5EC),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF595761)),
        suffixIcon: IconButton(
          onPressed: () => _controller.applySearch(_searchController.text),
          icon: const Icon(Icons.arrow_forward, color: Color(0xFF595761)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    String hotelValue = _controller.hotelNameFilter.value;
    bool? availableValue = _controller.availableFilter.value;
    String sortValue = _controller.sortBy.value;
    String directionValue = _controller.direction.value;

    _hotelController.text = hotelValue;

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
                    TextField(
                      controller: _hotelController,
                      decoration: const InputDecoration(labelText: 'Hotel Name'),
                      onChanged: (value) => hotelValue = value,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<bool?>(
                      initialValue: availableValue,
                      decoration: const InputDecoration(labelText: 'Availability'),
                      items: const [
                        DropdownMenuItem<bool?>(value: null, child: Text('All')),
                        DropdownMenuItem<bool?>(value: true, child: Text('Available')),
                        DropdownMenuItem<bool?>(value: false, child: Text('Unavailable')),
                      ],
                      onChanged: (value) => setModalState(() => availableValue = value),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: sortValue,
                      decoration: const InputDecoration(labelText: 'Sort By'),
                      items: _sortOptions
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(growable: false),
                      onChanged: (value) =>
                          setModalState(() => sortValue = value ?? 'updatedat'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: directionValue,
                      decoration: const InputDecoration(labelText: 'Direction'),
                      items: const [
                        DropdownMenuItem(value: 'asc', child: Text('Ascending')),
                        DropdownMenuItem(value: 'desc', child: Text('Descending')),
                      ],
                      onChanged: (value) =>
                          setModalState(() => directionValue = value ?? 'desc'),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              _searchController.clear();
                              _hotelController.clear();
                              await _controller.applySearch('');
                              await _controller.applyHotelName('');
                              await _controller.applyAvailable(null);
                              await _controller.setSort('updatedat');
                              if (_controller.direction.value != 'desc') {
                                await _controller.toggleDirection();
                              }
                            },
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await _controller.applyHotelName(hotelValue);
                              await _controller.applyAvailable(availableValue);
                              await _controller.setSort(sortValue);
                              if (_controller.direction.value != directionValue) {
                                await _controller.toggleDirection();
                              }
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

  Widget _buildRoomCard(RoomResponseDto room) {
    return Card(
      child: ListTile(
        title: Text('${room.roomType} - ${room.hotelName}'),
        subtitle: Text('Price: ${room.price} | Available: ${room.available}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: room.available,
              onChanged: (value) => _controller.toggleAvailability(room, value),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _controller.deleteRoom(room),
            ),
          ],
        ),
      ),
    );
  }

  String _adminEmail() {
    final email = (widget.user['email'] as String?)?.trim() ?? '';
    return email.isEmpty ? 'admin@gmail.com' : email;
  }

  EdgeInsets _contentPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = width >= 1200
        ? 32.0
        : width >= 900
            ? 24.0
            : 16.0;
    return EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24);
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.controller});

  final AdminRoomsController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Total: ${controller.totalElements.value} | Page ${controller.page.value + 1}/${controller.totalPages.value}',
        ),
        const Spacer(),
        IconButton(
          onPressed: controller.isFirstPage.value ? null : controller.goToPreviousPage,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          onPressed: controller.isLastPage.value ? null : controller.goToNextPage,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(message)),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
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
}
