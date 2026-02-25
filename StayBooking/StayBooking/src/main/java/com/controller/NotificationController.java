package com.controller;

import com.dto.MarkAllNotificationsReadResponseDto;
import com.dto.NotificationResponseDto;
import com.dto.PageResponseDto;
import com.dto.UnreadCountResponseDto;
import com.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
@CrossOrigin(origins = "*")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public ResponseEntity<PageResponseDto<NotificationResponseDto>> getMyNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "false") boolean unreadOnly
    ) {
        return ResponseEntity.ok(notificationService.getMyNotifications(page, size, unreadOnly));
    }

    @GetMapping("/unread-count")
    public ResponseEntity<UnreadCountResponseDto> getMyUnreadCount() {
        return ResponseEntity.ok(new UnreadCountResponseDto(notificationService.getMyUnreadCount()));
    }

    @PutMapping("/{id}/read")
    public ResponseEntity<NotificationResponseDto> markMyNotificationAsRead(@PathVariable("id") long id) {
        return ResponseEntity.ok(notificationService.markMyNotificationAsRead(id));
    }

    @PutMapping("/read-all")
    public ResponseEntity<MarkAllNotificationsReadResponseDto> markAllMyNotificationsAsRead() {
        return ResponseEntity.ok(notificationService.markAllMyNotificationsAsRead());
    }
}
