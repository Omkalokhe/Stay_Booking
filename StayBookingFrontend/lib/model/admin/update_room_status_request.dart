class UpdateRoomStatusRequest {
  const UpdateRoomStatusRequest({
    required this.available,
    required this.updatedBy,
  });

  final bool available;
  final String updatedBy;

  Map<String, dynamic> toJson() {
    return {
      'available': available,
      'updatedBy': updatedBy.trim(),
    };
  }
}