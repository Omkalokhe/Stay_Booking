import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stay_booking_frontend/constants/hotel_form_constants.dart';
import 'package:stay_booking_frontend/controller/hotel_form_controller.dart';

class HotelForm extends StatefulWidget {
  const HotelForm({
    required this.controller,
    required this.isEditMode,
    required this.onSubmit,
    super.key,
  });

  final HotelFormController controller;
  final bool isEditMode;
  final Future<void> Function() onSubmit;

  @override
  State<HotelForm> createState() => _HotelFormState();
}

class _HotelFormState extends State<HotelForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _pincodeCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.controller.name.value);
    _cityCtrl = TextEditingController(text: widget.controller.city.value);
    _countryCtrl = TextEditingController(text: widget.controller.country.value);
    _descriptionCtrl = TextEditingController(
      text: widget.controller.description.value,
    );
    _addressCtrl = TextEditingController(text: widget.controller.address.value);
    _stateCtrl = TextEditingController(text: widget.controller.state.value);
    _pincodeCtrl = TextEditingController(text: widget.controller.pincode.value);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AbsorbPointer(
        absorbing: widget.controller.isLoading.value,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(_nameCtrl, HotelFormConstants.hintName, onChanged: (v) {
                widget.controller.name.value = v;
              }),
              const SizedBox(height: 10),
              _buildField(_cityCtrl, HotelFormConstants.hintCity, onChanged: (v) {
                widget.controller.city.value = v;
              }),
              const SizedBox(height: 10),
              _buildField(
                _countryCtrl,
                HotelFormConstants.hintCountry,
                onChanged: (v) => widget.controller.country.value = v,
              ),
              const SizedBox(height: 10),
              _buildField(
                _descriptionCtrl,
                HotelFormConstants.hintDescription,
                maxLines: 3,
                onChanged: (v) => widget.controller.description.value = v,
              ),
              const SizedBox(height: 10),
              _buildField(
                _addressCtrl,
                HotelFormConstants.hintAddress,
                onChanged: (v) => widget.controller.address.value = v,
              ),
              const SizedBox(height: 10),
              _buildField(
                _stateCtrl,
                HotelFormConstants.hintState,
                onChanged: (v) => widget.controller.state.value = v,
              ),
              const SizedBox(height: 10),
              _buildField(
                _pincodeCtrl,
                HotelFormConstants.hintPincode,
                keyboardType: TextInputType.number,
                onChanged: (v) => widget.controller.pincode.value = v,
              ),
              if (widget.isEditMode) ...[
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  title: const Text(HotelFormConstants.labelReplacePhotos),
                  value: widget.controller.replacePhotos.value,
                  onChanged: (value) => widget.controller.replacePhotos.value = value,
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: widget.controller.pickImages,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text(HotelFormConstants.buttonPickImages),
              ),
              const SizedBox(height: 8),
              _buildSelectedImages(widget.controller.selectedImages),
              if (widget.isEditMode) ...[
                const SizedBox(height: 8),
                _buildExistingImages(widget.controller.existingPhotoUrls),
              ],
              if (widget.controller.errorMessage.value != null) ...[
                const SizedBox(height: 10),
                Text(
                  widget.controller.errorMessage.value!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.controller.isLoading.value ? null : widget.onSubmit,
                  child: widget.controller.isLoading.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.isEditMode
                              ? HotelFormConstants.buttonUpdateHotel
                              : HotelFormConstants.buttonCreateHotel,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSelectedImages(List<XFile> files) {
    if (files.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: files.length,
      itemBuilder: (_, index) {
        final file = files[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                widget.controller.fileFromXFile(file),
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: CircleAvatar(
                radius: 12,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 14,
                  onPressed: () => widget.controller.removeSelectedImageAt(index),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExistingImages(List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: urls.length,
      itemBuilder: (_, index) {
        final url = widget.controller.resolvePhotoUrl(urls[index]);
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(url, fit: BoxFit.cover),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: CircleAvatar(
                radius: 12,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 14,
                  onPressed: () => widget.controller.removeExistingPhotoAt(index),
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
