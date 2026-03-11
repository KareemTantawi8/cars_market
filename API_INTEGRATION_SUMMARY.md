# API Integration Summary

This document summarizes the API endpoint integration with the Flutter UI according to the W4S Linder Mobile API Integration Document.

## ✅ Completed Integrations

### 1. API Endpoints (`lib/core/network/api_endpoints.dart`)
All endpoints from the documentation have been added:
- ✅ Authentication endpoints (login, register, logout, refresh, me, forgot-password, verify-otp, reset-password, tokens)
- ✅ Search Requests endpoints (create, my, details, accept, reject)
- ✅ Vendor endpoints (incoming requests, online toggle)
- ✅ Chat endpoints (list, details, messages, send, read)
- ✅ Notifications endpoints (list, mark as read, mark all as read)

### 2. Repositories Created

#### ✅ Search Requests Repository (`lib/features/home/data/repositories/search_requests_repository.dart`)
- `createSearchRequest()` - POST /api/v1/search-requests
- `getMySearchRequests()` - GET /api/v1/search-requests/my
- `getSearchRequestDetails()` - GET /api/v1/search-requests/{id}
- `acceptSearchRequest()` - POST /api/v1/search-requests/{id}/accept
- `rejectSearchRequest()` - POST /api/v1/search-requests/{id}/reject

#### ✅ Vendor Repository (`lib/features/vendor/data/repositories/vendor_repository.dart`)
- `getIncomingRequests()` - GET /api/v1/vendor/search-requests
- `toggleOnline()` - POST /api/v1/vendor/online

#### ✅ Chat Repository (`lib/features/chat/data/repositories/chat_repository.dart`)
- `getChats()` - GET /api/v1/chats
- `getChatDetails()` - GET /api/v1/chats/{id}
- `getChatMessages()` - GET /api/v1/chats/{id}/messages (paginated)
- `sendMessage()` - POST /api/v1/chats/{id}/messages
- `markChatAsRead()` - POST /api/v1/chats/{id}/read

#### ✅ Notifications Repository (`lib/features/notifications/data/repositories/notifications_repository.dart`)
- `getNotifications()` - GET /api/v1/notifications (paginated)
- `markAsRead()` - POST /api/v1/notifications/{id}/read
- `markAllAsRead()` - POST /api/v1/notifications/read-all

#### ✅ Auth Repository Updated (`lib/features/auth/data/repositories/auth_repository.dart`)
- `getCurrentUser()` - GET /api/v1/auth/me
- `logout()` - POST /api/v1/auth/logout
- `refreshToken()` - POST /api/v1/auth/refresh
- `forgotPassword()` - POST /api/v1/auth/forgot-password
- `verifyOtp()` - POST /api/v1/auth/verify-otp
- `resetPassword()` - POST /api/v1/auth/reset-password
- `getActiveTokens()` - GET /api/v1/auth/tokens
- `revokeToken()` - DELETE /api/v1/auth/tokens/{id}
- `logoutAll()` - POST /api/v1/auth/logout-all

### 3. Cubits Created

#### ✅ Search Requests Cubit (`lib/features/home/presentation/cubit/search_requests_cubit.dart`)
- Manages search request creation and listing
- States: Initial, Loading, Success, Error, MySearchRequestsLoaded

#### ✅ Vendor Requests Cubit (`lib/features/vendor/presentation/cubit/vendor_requests_cubit.dart`)
- Manages vendor incoming requests and online status
- States: Initial, Loading, Loaded, Error, OnlineToggled

#### ✅ Chat Cubit (`lib/features/chat/presentation/cubit/chat_cubit.dart`)
- Manages chat list, messages, and sending
- States: Initial, Loading, ChatsLoaded, ChatDetailsLoaded, MessagesLoaded, MessageSent, Error

#### ✅ Notifications Cubit (`lib/features/notifications/presentation/cubit/notifications_cubit.dart`)
- Manages notifications list and read status
- States: Initial, Loading, Loaded, Error, NotificationMarkedAsRead, AllNotificationsMarkedAsRead

### 4. UI Screens Updated

#### ✅ Vendor Incoming Requests Screen
- Connected to VendorRequestsCubit
- Connected to SearchRequestsRepository for accept/reject
- Shows loading states
- Handles errors
- Refreshes list after accept/reject

## 🔄 Remaining UI Integration Tasks

### 1. Home Screen (Client)
**File:** `lib/features/home/presentation/views/home_screen.dart`
**Needs:**
- Connect to SearchRequestsCubit for creating search requests
- Update `_handleSearch()` to use `SearchRequestsCubit.createSearchRequest()`
- Navigate to "My Ads" screen after successful creation

### 2. Chat List Screen
**File:** `lib/features/chat/presentation/views/chat_list_screen.dart`
**Needs:**
- Wrap with BlocProvider<ChatCubit>
- Call `ChatCubit.getChats()` on load
- Display real chat data from API
- Handle unread counts
- Navigate to chat room with real chat_id

### 3. Chat Room Screen
**File:** `lib/features/chat/presentation/views/chat_room_screen.dart`
**Needs:**
- Wrap with BlocProvider<ChatCubit>
- Call `ChatCubit.getChatDetails()` and `getChatMessages()` on load
- Use `ChatCubit.sendMessage()` for sending
- Call `ChatCubit.markAsRead()` when opening chat
- Display real messages from API
- Handle pagination for older messages

### 4. Notifications Screen
**File:** `lib/features/notifications/presentation/views/notifications_screen.dart` (needs to be created)
**Needs:**
- Create new screen file
- Wrap with BlocProvider<NotificationsCubit>
- Call `NotificationsCubit.getNotifications()` on load
- Display notifications grouped by date (Today, Yesterday)
- Handle tap to mark as read and navigate
- Implement "Mark all as read" button
- Handle pagination

### 5. My Ads Management Screen
**File:** Needs to be created at `lib/features/home/presentation/views/my_ads_screen.dart`
**Needs:**
- Create new screen
- Wrap with BlocProvider<SearchRequestsCubit>
- Call `SearchRequestsCubit.getMySearchRequests()` on load
- Display search requests with status badges
- Navigate to details on tap
- Show empty state when no requests

### 6. Vendor Dashboard Screen
**File:** `lib/features/vendor/presentation/views/vendor_dashboard_screen.dart`
**Needs:**
- Connect to VendorRequestsCubit for online toggle
- Call `VendorRequestsCubit.getIncomingRequests()` to get count
- Display pending requests count badge
- Connect online/offline toggle to `VendorRequestsCubit.toggleOnline()`

### 7. User Profile Screen
**File:** `lib/features/profile/presentation/views/user_profile_screen.dart`
**Needs:**
- Connect to AuthRepository for:
  - `getCurrentUser()` - display user info
  - `getActiveTokens()` - show active sessions
  - `revokeToken()` - revoke session
  - `logoutAll()` - logout from all devices
- Add forgot password flow using:
  - `forgotPassword()` → `verifyOtp()` → `resetPassword()`

### 8. Splash Screen
**File:** `lib/features/auth/presentation/views/splash_screen.dart`
**Needs:**
- Call `AuthRepository.getCurrentUser()` to check token validity
- Navigate based on `user.type`:
  - `customer` → Home Screen
  - `vendor` → Vendor Dashboard
- Handle 401 → Navigate to Login

## 📝 Usage Examples

### Example 1: Using SearchRequestsCubit in Home Screen

```dart
BlocProvider(
  create: (context) => SearchRequestsCubit(),
  child: BlocConsumer<SearchRequestsCubit, SearchRequestsState>(
    listener: (context, state) {
      if (state is SearchRequestsSuccess) {
        // Navigate to My Ads or show success
        Navigator.pushNamed(context, AppRoutes.myAds);
      } else if (state is SearchRequestsError) {
        CustomToast.showError(context, state.message);
      }
    },
    builder: (context, state) {
      final isLoading = state is SearchRequestsLoading;
      return PrimaryButton(
        text: 'إرسال الطلب الآن',
        onPressed: isLoading ? null : () {
          context.read<SearchRequestsCubit>().createSearchRequest(
            brandId: selectedBrandId,
            modelId: selectedModelId,
            governorateId: selectedGovernorateId,
            partText: partText,
          );
        },
        isLoading: isLoading,
      );
    },
  ),
)
```

### Example 2: Using ChatCubit in Chat List Screen

```dart
BlocProvider(
  create: (context) => ChatCubit()..getChats(),
  child: BlocBuilder<ChatCubit, ChatState>(
    builder: (context, state) {
      if (state is ChatsLoaded) {
        return ListView.builder(
          itemCount: state.chats.length,
          itemBuilder: (context, index) {
            final chat = state.chats[index];
            return ChatItem(
              name: chat['vendor']?['company_name'] ?? chat['customer']?['name'] ?? '',
              lastMessage: chat['last_message']?['body'] ?? '',
              timestamp: _formatTimestamp(chat['last_message_at']),
              unreadCount: chat['unread_count'] ?? 0,
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.chatRoom,
                  arguments: {'chatId': chat['id']},
                );
              },
            );
          },
        );
      }
      // Handle other states...
    },
  ),
)
```

### Example 3: Using NotificationsCubit

```dart
BlocProvider(
  create: (context) => NotificationsCubit()..getNotifications(),
  child: BlocBuilder<NotificationsCubit, NotificationsState>(
    builder: (context, state) {
      if (state is NotificationsLoaded) {
        // Group by date and display
        return ListView.builder(
          itemCount: state.notifications.length,
          itemBuilder: (context, index) {
            final notification = state.notifications[index];
            return NotificationItem(
              title: notification['title'],
              body: notification['body'],
              isRead: notification['read_at'] != null,
              onTap: () {
                context.read<NotificationsCubit>().markAsRead(notification['id']);
                // Navigate based on type
                if (notification['meta']?['chat_id'] != null) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.chatRoom,
                    arguments: {'chatId': notification['meta']['chat_id']},
                  );
                }
              },
            );
          },
        );
      }
      // Handle other states...
    },
  ),
)
```

## 🔧 Next Steps

1. **Update Home Screen** - Connect search request creation
2. **Update Chat Screens** - Connect to ChatCubit
3. **Create Notifications Screen** - Full implementation
4. **Create My Ads Screen** - Display user's search requests
5. **Update Vendor Dashboard** - Connect online toggle and requests count
6. **Update User Profile** - Connect all auth endpoints
7. **Update Splash Screen** - Use getCurrentUser() for auth check
8. **Add Error Handling** - Consistent error handling across all screens
9. **Add Loading States** - Proper loading indicators
10. **Add Pull-to-Refresh** - Where applicable

## 📚 API Documentation Reference

All endpoints follow the structure defined in:
- Base URL: `http://187.124.35.51/api/v1` (configured in `AppConstants.baseUrl`)
- Auth: Bearer Token (Laravel Sanctum)
- All requests include: `Authorization: Bearer {token}`, `Accept: application/json`

## ✅ Testing Checklist

- [ ] Test search request creation flow
- [ ] Test vendor accept/reject flow
- [ ] Test chat list and messages
- [ ] Test notifications list and read status
- [ ] Test auth endpoints (login, register, logout, refresh)
- [ ] Test error handling (401, 403, 422, 500)
- [ ] Test loading states
- [ ] Test empty states
- [ ] Test pagination where applicable

