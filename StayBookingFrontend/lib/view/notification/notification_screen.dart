import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stay_booking_frontend/controller/notification_controller.dart';
import 'package:stay_booking_frontend/model/notification_response_dto.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<NotificationController>();
    _controller.loadFirstPage();
    _controller.fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E1E86),
      appBar: AppBar(
        backgroundColor: const Color(0xFF3E1E86),
        foregroundColor: Colors.white,
        title: const Text('Notifications'),
        actions: [
          Obx(
            () => TextButton(
              onPressed: _controller.isMarkingAll.value
                  ? null
                  : _controller.markAllAsRead,
              child: Text(
                _controller.isMarkingAll.value ? 'Marking...' : 'Mark all read',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _controller.refreshList,
          child: Column(
            children: [
              _buildToolbar(),
              Expanded(
                child: Obx(() {
                  if (_controller.isLoading.value &&
                      _controller.notifications.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_controller.errorMessage.value.isNotEmpty &&
                      _controller.notifications.isEmpty) {
                    return _ErrorState(
                      message: _controller.errorMessage.value,
                      onRetry: () => _controller.loadFirstPage(),
                    );
                  }

                  if (_controller.notifications.isEmpty) {
                    return _EmptyState(unreadOnly: _controller.unreadOnly.value);
                  }

                  final grouped = _groupByDate(_controller.notifications);
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontal = constraints.maxWidth >= 1000 ? 24.0 : 12.0;
                      return ListView(
                        padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 18),
                        children: [
                          for (final entry in grouped.entries) ...[
                            _SectionHeader(title: entry.key),
                            const SizedBox(height: 8),
                            ...entry.value.map(_buildNotificationCard),
                            const SizedBox(height: 8),
                          ],
                          _LoadMoreBar(controller: _controller),
                        ],
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: const Color(0xFF2D1761),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Obx(
            () => FilterChip(
              selected: _controller.unreadOnly.value,
              showCheckmark: false,
              selectedColor: const Color(0xFFDBCFFF),
              label: Text(_controller.unreadOnly.value ? 'Unread only' : 'All'),
              onSelected: (selected) => _controller.setUnreadOnly(selected),
            ),
          ),
          const SizedBox(width: 10),
          Obx(
            () => Text(
              'Unread: ${_controller.unreadCount.value}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationResponseDto item) {
    final style = _styleForType(item.type);
    final createdTime = _formatTime(item.createdAt);
    final bookingContext = _controller.bookingContextText(item);
    final safeTitle = _sanitizeBookingIds(item.title, item.referenceId);
    final safeMessage = _sanitizeBookingIds(item.message, item.referenceId);

    return Card(
      color: item.isReadEffective
          ? const Color(0xFFF8F7FC)
          : const Color(0xFFFFFFFF),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _controller.markAsRead(item),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: item.isReadEffective
                    ? const Color(0xFFDDD7EF)
                    : style.color,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(style.icon, color: style.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            safeTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: item.isReadEffective
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: const Color(0xFF1B1533),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          createdTime,
                          style: const TextStyle(
                            color: Color(0xFF6B6680),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      safeMessage,
                      style: const TextStyle(
                        color: Color(0xFF4B4460),
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                    if (bookingContext.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        bookingContext,
                        style: TextStyle(
                          color: style.color,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pill(item.channel.name.toUpperCase()),
                        _pill(item.deliveryStatus.name.toUpperCase()),
                        if (!item.isReadEffective)
                          _pill('UNREAD', color: style.color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<NotificationResponseDto>> _groupByDate(
    List<NotificationResponseDto> items,
  ) {
    final sorted = List<NotificationResponseDto>.from(items)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final groups = <String, List<NotificationResponseDto>>{
      'Today': [],
      'Yesterday': [],
      'Older': [],
    };

    for (final item in sorted) {
      final d = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
      if (d == today) {
        groups['Today']!.add(item);
      } else if (d == yesterday) {
        groups['Yesterday']!.add(item);
      } else {
        groups['Older']!.add(item);
      }
    }

    groups.removeWhere((_, value) => value.isEmpty);
    return groups;
  }

  _NotificationTypeStyle _styleForType(NotificationType type) {
    return switch (type) {
      NotificationType.bookingCreated => const _NotificationTypeStyle(
        icon: Icons.event_available_rounded,
        color: Color(0xFF2E7D32),
      ),
      NotificationType.bookingUpdated => const _NotificationTypeStyle(
        icon: Icons.edit_calendar_rounded,
        color: Color(0xFF1565C0),
      ),
      NotificationType.bookingCancelled => const _NotificationTypeStyle(
        icon: Icons.event_busy_rounded,
        color: Color(0xFFC62828),
      ),
      NotificationType.bookingStatusChanged => const _NotificationTypeStyle(
        icon: Icons.sync_alt_rounded,
        color: Color(0xFF6A1B9A),
      ),
      NotificationType.paymentSuccess => const _NotificationTypeStyle(
        icon: Icons.check_circle_outline_rounded,
        color: Color(0xFF1B5E20),
      ),
      NotificationType.paymentFailed => const _NotificationTypeStyle(
        icon: Icons.error_outline_rounded,
        color: Color(0xFFD84315),
      ),
      NotificationType.unknown => const _NotificationTypeStyle(
        icon: Icons.notifications_none_rounded,
        color: Color(0xFF455A64),
      ),
    };
  }

  Widget _pill(String text, {Color? color}) {
    final chipColor = color ?? const Color(0xFF6D6591);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: chipColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _sanitizeBookingIds(String text, int? referenceId) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || referenceId == null) return trimmed;

    final patterns = <RegExp>[
      RegExp('#\\s*$referenceId\\b', caseSensitive: false),
      RegExp('booking\\s*id\\s*[:#-]?\\s*$referenceId\\b', caseSensitive: false),
      RegExp('booking\\s*#\\s*$referenceId\\b', caseSensitive: false),
    ];

    var sanitized = trimmed;
    for (final pattern in patterns) {
      sanitized = sanitized.replaceAll(pattern, '').trim();
    }

    sanitized = sanitized.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    if (sanitized.endsWith('-') || sanitized.endsWith(':')) {
      sanitized = sanitized.substring(0, sanitized.length - 1).trim();
    }
    return sanitized;
  }
}

class _NotificationTypeStyle {
  const _NotificationTypeStyle({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 16,
      ),
    );
  }
}

class _LoadMoreBar extends StatelessWidget {
  const _LoadMoreBar({required this.controller});

  final NotificationController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingMore.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (controller.isLastPage.value) {
        return const SizedBox(height: 2);
      }
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Center(
          child: FilledButton.tonal(
            onPressed: controller.loadNextPage,
            child: const Text('Load more'),
          ),
        ),
      );
    });
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.unreadOnly});

  final bool unreadOnly;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F2FB),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 38,
                color: Colors.black54,
              ),
              const SizedBox(height: 8),
              Text(
                unreadOnly
                    ? 'No unread notifications.'
                    : 'No notifications available.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDECEC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFC62828)),
              ),
              const SizedBox(height: 10),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }
}
