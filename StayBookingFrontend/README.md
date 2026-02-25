# stay_booking_frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## JWT Auth Flow (Updated)

- Login uses `POST /api/auth/login` and stores `tokenType`, `accessToken`, `expiresInMinutes`, and `user` in secure storage.
- App startup restores auth session from secure storage and validates `expiresAt`; expired sessions are cleared automatically.
- A centralized HTTP client interceptor adds `Authorization: <tokenType> <accessToken>` to protected API calls.
- Public endpoints stay unauthenticated:
  - `/api/auth/login`
  - `/api/auth/password/**`
  - `/api/users/register`
  - `GET /api/hotels/**`
  - `GET /api/rooms/**`
  - `GET /api/reviews/hotel/**`
- Global auth error handling:
  - `401`: clears session, redirects to login, shows session-expired message.
  - `403`: shows "not authorized" toast/snackbar.
- Route guards:
  - Admin pages require `ADMIN`.
  - Vendor management pages require `VENDOR` or `ADMIN`.
  - Public hotel/room/review browsing remains accessible without login.
