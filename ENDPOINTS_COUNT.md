# API Endpoints Count from Documentation

## Total Unique Endpoints: **32**

### Authentication (12 endpoints)
1. `GET /api/v1/auth/me` - Get current user
2. `POST /api/v1/auth/login` - Login
3. `POST /api/v1/auth/register` - Register customer
4. `POST /api/v1/auth/register-vendor` - Register vendor
5. `POST /api/v1/auth/logout` - Logout
6. `POST /api/v1/auth/refresh` - Refresh token
7. `POST /api/v1/auth/forgot-password` - Send OTP
8. `POST /api/v1/auth/verify-otp` - Verify OTP
9. `POST /api/v1/auth/reset-password` - Reset password
10. `GET /api/v1/auth/tokens` - Get active tokens
11. `DELETE /api/v1/auth/tokens/{tokenId}` - Revoke token
12. `POST /api/v1/auth/logout-all` - Logout all devices

### Categories & Governorates (3 endpoints)
13. `GET /api/v1/categories/brands` - Get brands
14. `GET /api/v1/categories/brands/{brand}/models` - Get models for brand
15. `GET /api/v1/governorates` - Get governorates

### Search Requests (5 endpoints)
16. `POST /api/v1/search-requests` - Create search request
17. `GET /api/v1/search-requests/my` - Get my search requests
18. `GET /api/v1/search-requests/{searchRequest}` - Get search request details
19. `POST /api/v1/search-requests/{id}/accept` - Accept request (vendor)
20. `POST /api/v1/search-requests/{id}/reject` - Reject request (vendor)

### Vendor (3 endpoints)
21. `GET /api/v1/vendor/search-requests` - Get vendor incoming requests
22. `POST /api/v1/vendor/online` - Toggle online status
23. `GET /api/v1/vendors/{vendor}` - Get vendor profile

### Chat (5 endpoints)
24. `GET /api/v1/chats` - Get all chats
25. `GET /api/v1/chats/{chat}` - Get chat details
26. `GET /api/v1/chats/{chat}/messages` - Get messages (paginated)
27. `POST /api/v1/chats/{chat}/messages` - Send message
28. `POST /api/v1/chats/{chat}/read` - Mark chat as read

### Notifications (3 endpoints)
29. `GET /api/v1/notifications` - Get notifications (paginated)
30. `POST /api/v1/notifications/{id}/read` - Mark notification as read
31. `POST /api/v1/notifications/read-all` - Mark all as read

### WebSocket Auth (1 endpoint)
32. `POST /api/broadcasting/auth` - WebSocket channel authentication

---

## Summary by Category:
- **Authentication**: 12 endpoints
- **Search Requests**: 5 endpoints
- **Chat**: 5 endpoints
- **Vendor**: 3 endpoints
- **Categories**: 3 endpoints
- **Notifications**: 3 endpoints
- **WebSocket**: 1 endpoint

**Total: 32 unique endpoints**

