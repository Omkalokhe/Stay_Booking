import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/vendor_room_controller.dart';
import 'package:stay_booking_frontend/routes/app_routes.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({
    required this.user,
    required this.hotelId,
    required this.hotelName,
    super.key,
  });

  final Map<String, dynamic> user;
  final int hotelId;
  final String hotelName;

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  static const List<String> _roomTypeOptions = [
    'Deluxe',
    'Standard',
    'Suite',
    'Executive',
    'Family',
    'Twin',
  ];

  late final VendorRoomController _controller;
  String? _selectedRoomType;

  @override
  void initState() {
    super.initState();
    final email = (widget.user['email'] as String?)?.trim() ?? 'vendor';
    final tag = 'vendor-room-$email';
    if (Get.isRegistered<VendorRoomController>(tag: tag)) {
      final existing = Get.find<VendorRoomController>(tag: tag);
      if (existing.isClosed) {
        Get.delete<VendorRoomController>(tag: tag, force: true);
        _controller = Get.put(
          VendorRoomController(user: widget.user),
          tag: tag,
          permanent: true,
        );
      } else {
        _controller = existing;
      }
    } else {
      _controller = Get.put(
        VendorRoomController(user: widget.user),
        tag: tag,
        permanent: true,
      );
    }
    _controller.startCreate(presetHotelId: widget.hotelId, lockHotelId: true);
    final presetRoomType = _controller.roomTypeController.text.trim();
    if (_roomTypeOptions.contains(presetRoomType)) {
      _selectedRoomType = presetRoomType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeHotelName = widget.hotelName.trim().isEmpty
        ? 'Selected Hotel'
        : widget.hotelName.trim();
    return Scaffold(
      backgroundColor: const Color(0xFF3F1D89),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3F1D89),
        title: Text(
          'Add Room - $safeHotelName',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Card(
                color: const Color(0xFFF9F8FD),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _controller.formKey,
                    child: Obx(
                      () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Room',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Create a room for $safeHotelName.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedRoomType,
                            decoration: _inputDecoration(
                              'Room Type',
                              Icons.bedroom_parent_outlined,
                            ),
                            items: _roomTypeOptions
                                .map(
                                  (type) => DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _selectedRoomType = value;
                              });
                              _controller.roomTypeController.text = value;
                            },
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Room type is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _controller.priceController,
                            validator: _controller.validatePrice,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _inputDecoration(
                              'Price',
                              Icons.currency_rupee_rounded,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _controller.descriptionController,
                            validator: (v) =>
                                _controller.requiredField(v, 'Description'),
                            maxLines: 3,
                            decoration: _inputDecoration(
                              'Description',
                              Icons.notes_rounded,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F2FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text('Available'),
                                const Spacer(),
                                Switch(
                                  value: _controller.available.value,
                                  onChanged: (value) =>
                                      _controller.available.value = value,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F2FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextButton.icon(
                                  onPressed: _controller.pickPhotos,
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                  ),
                                  label: const Text('Select Photos (Multiple)'),
                                ),
                                if (_controller.selectedPhotos.isNotEmpty)
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _controller.selectedPhotos
                                        .map(
                                          (file) => InputChip(
                                            label: Text(file.name),
                                            onDeleted: () => _controller
                                                .removePickedPhoto(file),
                                          ),
                                        )
                                        .toList(),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _controller.isSubmitting.value
                                  ? null
                                  : () async {
                                      final ok = await _controller.submitForm();
                                      if (ok && context.mounted) {
                                        Get.offAllNamed(
                                          AppRoutes.vendorHome,
                                          arguments: {
                                            'user': widget.user,
                                            'initialTab': 1,
                                          },
                                        );
                                      }
                                    },
                              icon: _controller.isSubmitting.value
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline),
                              label: Text(
                                _controller.isSubmitting.value
                                    ? 'Saving...'
                                    : 'Create Room',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
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
