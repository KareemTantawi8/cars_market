# Application Routing Flow

This document describes the complete navigation flow for all screens in the Cars Market application.

## Navigation Map

```
┌─────────────────────────────────────────────────────────────┐
│                      SPLASH SCREEN                          │
│                         (/splash)                           │
│                                                             │
│              ┌──────────────────────────┐                  │
│              │   Auto Navigate After    │                  │
│              │      3 seconds           │                  │
│              └──────────────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      LOGIN SCREEN                           │
│                         (/login)                            │
│                                                             │
│  ┌────────────────┐            ┌────────────────────┐     │
│  │ Register Link  │───────────▶│  REGISTER SCREEN   │     │
│  └────────────────┘            │     (/register)    │     │
│                                │                     │     │
│                                │  ┌──────────────┐  │     │
│                                │  │ After Reg    │  │     │
│                                │  │ (Vendor) →   │  │     │
│                                │  └──────────────┘  │     │
│                                └────────────────────┘     │
│                                      │                     │
│                                      ▼                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   HOME SCREEN (USER)                        │
│                        (/home)                              │
│                                                             │
│  ┌─────────────────────┐                                   │
│  │  Search Button      │                                   │
│  └─────────────────────┘                                   │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────────┐                                   │
│  │ SEARCH RESULTS      │                                   │
│  │   (/search-results) │                                   │
│  │                     │                                   │
│  │  ┌──────────────┐   │                                   │
│  │  │ Contact Btn  │───┼────────────────────────────┐     │
│  │  └──────────────┘   │                            │     │
│  └─────────────────────┘                            │     │
│                                                     │     │
│  ┌─────────────────────┐                            │     │
│  │ Supplier Cards      │                            │     │
│  └─────────────────────┘                            │     │
│           │                                           │     │
│           └──────────────────────────────────────────┘     │
│                                                             │
│  ┌──────────────────────────────────────────────────┐     │
│  │              BOTTOM NAVIGATION                   │     │
│  │  Home | Orders | Garage | Profile               │     │
│  └──────────────────────────────────────────────────┘     │
│           │          │         │          │                │
│           │          │         │          └─────────┐      │
│           │          │         │                    │      │
│           │          │         ▼                    │      │
│           │          │  ┌─────────────┐            │      │
│           │          │  │  GARAGE     │            │      │
│           │          │  │   SCREEN    │            │      │
│           │          │  └─────────────┘            │      │
│           │          │                              │      │
│           │          ▼                              │      │
│           │  ┌─────────────┐                       │      │
│           │  │   ORDERS    │                       │      │
│           │  │   SCREEN    │                       │      │
│           │  └─────────────┘                       │      │
│           │                                         │      │
│           └─────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              VENDOR PROFILE SCREEN                          │
│                  (/vendor-profile)                          │
│                                                             │
│  ┌──────────────────────┐                                  │
│  │  Start Chat Button   │                                  │
│  └──────────────────────┘                                  │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────────┐                                  │
│  │  CHAT ROOM SCREEN    │                                  │
│  │    (/chat-room)      │                                  │
│  │                      │                                  │
│  │  ┌──────────────┐    │                                  │
│  │  │ Send Message │    │                                  │
│  │  └──────────────┘    │                                  │
│  └──────────────────────┘                                  │
│                                                             │
│  ┌──────────────────────┐                                  │
│  │   Phone Button       │                                  │
│  │   (Future: Call)     │                                  │
│  └──────────────────────┘                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  CHAT LIST SCREEN                           │
│                    (/chat-list)                             │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  Filter: All | Unread | Archive                   │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────┐                                  │
│  │  Chat Items          │                                  │
│  └──────────────────────┘                                  │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────────┐                                  │
│  │  CHAT ROOM SCREEN    │                                  │
│  │    (/chat-room)      │                                  │
│  │                      │                                  │
│  │  ┌──────────────┐    │                                  │
│  │  │ Message Input│    │                                  │
│  │  │ Send Button  │    │                                  │
│  │  └──────────────┘    │                                  │
│  └──────────────────────┘                                  │
│                                                             │
│  ┌──────────────────────┐                                  │
│  │   FAB (Add Chat)     │                                  │
│  └──────────────────────┘                                  │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │              BOTTOM NAVIGATION                     │   │
│  │  Home | My Cars | + | Chats | Account             │   │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 CHAT ROOM SCREEN                            │
│                   (/chat-room)                              │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  Header: Vendor Name | Phone Icon                  │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  Messages (User/Business bubbles)                  │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  Message Input: Text | Gallery | Send              │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  (For Vendors only)                                        │
│  ┌──────────────────────┐                                  │
│  │  Send Message Dialog │                                  │
│  │  (Modal)             │                                  │
│  └──────────────────────┘                                  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│            USER PROFILE SCREEN                              │
│                  (/profile)                                 │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  Profile Picture | Name | Phone                    │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  Loyalty Program Card                              │   │
│  │  - Points Display                                  │   │
│  │  - Redeem Points Button                            │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  Account Settings                                  │   │
│  │  - Edit Profile                                    │   │
│  │  - Language                                        │   │
│  │  - Help & Support                                  │   │
│  │  - Logout                                          │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  BOTTOM NAV: Home | Search | Orders | Account      │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  Footer: App Version                               │   │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│          VENDOR DASHBOARD SCREEN                            │
│              (/vendor-dashboard)                            │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  Store Info | Online Status                        │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  Performance Metrics                               │   │
│  │  - Response Time                                   │   │
│  │  - Total Chats                                     │   │
│  │  - Rating                                          │   │
│  │  - Weekly Activity Graph                           │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  Subscription Section                              │   │
│  │  ┌──────────────────────────────┐                  │   │
│  │  │ Renew/Upgrade Button         │                  │   │
│  │  └──────────────────────────────┘                  │   │
│  │           │                                        │   │
│  │           ▼                                        │   │
│  │  ┌──────────────────────────────┐                  │   │
│  │  │ SUBSCRIPTION PLANS SCREEN    │                  │   │
│  │  │  (/subscription-plans)       │                  │   │
│  │  │                              │                  │   │
│  │  │  ┌────────────────────┐      │                  │   │
│  │  │  │  Plan Cards        │      │                  │   │
│  │  │  │  - Basic           │      │                  │   │
│  │  │  │  - Golden          │      │                  │   │
│  │  │  │  - Silver          │      │                  │   │
│  │  │  └────────────────────┘      │                  │   │
│  │  └──────────────────────────────┘                  │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  Quick Links                                       │   │
│  │  - Manage Inventory                                │   │
│  │  - Edit Store Profile                              │   │
│  │  - Technical Support                               │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  BOTTOM NAV: Home | Chats | Add | Reports | Activity│  │
│  │                   | Account                         │  │
│  └────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Complete Navigation Flow

### 1. **Authentication Flow**
```
Splash Screen
    ↓ (3 seconds)
Login Screen
    ├─→ Register Screen
    │   └─→ (After registration as Vendor)
    │       └─→ Subscription Plans Screen
    └─→ (After login)
        └─→ Home Screen (User) OR Vendor Dashboard (Vendor)
```

### 2. **User Flow**

#### **Home Screen Navigation:**
```
Home Screen
    ├─→ Search Button → Search Results Screen
    │                       └─→ Vendor Profile → Chat Room
    │
    ├─→ Supplier Card → Vendor Profile Screen
    │                       ├─→ Start Chat Button → Chat Room
    │                       └─→ Phone Button → (Future: Call)
    │
    └─→ Bottom Navigation:
        ├─→ Home (stays on home)
        ├─→ Orders → Orders Screen (TODO)
        ├─→ Garage → Garage Screen (TODO)
        └─→ Profile → User Profile Screen
```

#### **Chat Flow:**
```
Chat List Screen
    ├─→ Chat Item → Chat Room Screen
    │
    ├─→ Filter: All/Unread/Archive
    │
    ├─→ FAB (+) → (Future: New Chat)
    │
    └─→ Bottom Navigation:
        ├─→ Home → Home Screen
        ├─→ My Cars → Garage Screen
        ├─→ Chats (current)
        └─→ Account → Profile Screen
```

#### **Search Results Flow:**
```
Search Results Screen
    ├─→ Filter Chips (removable)
    │
    ├─→ Vendor Card → Vendor Profile → Chat Room
    │
    ├─→ Customer Reviews Section
    │
    └─→ Bottom Navigation:
        ├─→ Search (current)
        ├─→ Orders → Orders Screen
        ├─→ Chats → Chat List
        └─→ Account → Profile Screen
```

#### **Profile Flow:**
```
User Profile Screen
    ├─→ Edit Profile → (Future: Edit Profile Screen)
    ├─→ Language → (Future: Language Settings)
    ├─→ Help & Support → (Future: Help Screen)
    ├─→ Logout → Confirmation Dialog → Login Screen
    │
    └─→ Bottom Navigation:
        ├─→ Home → Home Screen
        ├─→ Search → Home Screen
        ├─→ Orders → Orders Screen
        └─→ Account (current)
```

### 3. **Vendor Flow**

#### **Vendor Dashboard Navigation:**
```
Vendor Dashboard Screen
    ├─→ Renew/Upgrade Button → Subscription Plans Screen
    │
    ├─→ Quick Links:
    │   ├─→ Manage Inventory → (Future: Inventory Screen)
    │   ├─→ Edit Store Profile → (Future: Edit Profile)
    │   └─→ Technical Support → (Future: Support Screen)
    │
    └─→ Bottom Navigation:
        ├─→ Home → (Future: Vendor Home)
        ├─→ Chats → Chat List Screen
        ├─→ Add Item → (Future: Add Item Screen)
        ├─→ Reports → (Future: Reports Screen)
        ├─→ Activity → (Future: Activity Screen)
        └─→ Account → (Future: Vendor Account)
```

#### **Vendor Chat Flow:**
```
Chat List Screen (Vendor)
    └─→ Chat Item → Chat Room Screen
                     └─→ (Can send messages to customers)
```

### 4. **Modal Dialogs**

#### **Send Message Dialog:**
```
Any Screen (Vendor context)
    └─→ Show Send Message Dialog
        ├─→ Close (X) → Close dialog
        └─→ Send Button → Send message → Close dialog
```

## Route Constants Reference

```dart
// Authentication
AppRoutes.splash          → '/'               → SplashScreen
AppRoutes.login           → '/login'          → LoginScreen
AppRoutes.register        → '/register'       → RegisterScreen

// Home & Search
AppRoutes.home            → '/home'           → HomeScreen
AppRoutes.searchResults   → '/search-results' → SearchResultsScreen

// Vendor
AppRoutes.vendorProfile   → '/vendor-profile' → VendorProfileScreen
AppRoutes.vendorDashboard → '/vendor-dashboard' → VendorDashboardScreen

// Chat
AppRoutes.chatList        → '/chat-list'      → ChatListScreen
AppRoutes.chatRoom        → '/chat-room'      → ChatRoomScreen

// Subscription
AppRoutes.subscriptionPlans → '/subscription-plans' → SubscriptionPlansScreen

// Profile
AppRoutes.profile         → '/profile'        → UserProfileScreen

// Future Routes (not yet implemented)
AppRoutes.orders          → '/orders'         → OrdersScreen
AppRoutes.garage          → '/garage'         → GarageScreen
```

## Navigation Patterns

### Push Navigation (Forward)
- Used for: Opening new screens on top
- Example: `Navigator.pushNamed(context, AppRoutes.vendorProfile)`

### Push and Remove Until (Clear Stack)
- Used for: Authentication flow, major navigation changes
- Example: `Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false)`

### Pop (Go Back)
- Used for: Closing current screen
- Example: `Navigator.pop(context)`

### Pop with Result
- Used for: Dialogs and modals
- Example: `SendMessageDialog.show(context)` returns `Future<bool?>`

## Key Navigation Points

1. **Splash → Login** (Auto after 3 seconds)
2. **Login → Register** (Register link)
3. **Register → Subscription Plans** (If vendor selected)
4. **Home → Search Results** (Search button)
5. **Search Results → Vendor Profile** (Contact button)
6. **Vendor Profile → Chat Room** (Start chat button)
7. **Home → Vendor Profile** (Supplier card tap)
8. **Chat List → Chat Room** (Chat item tap)
9. **Home → Profile** (Bottom nav - Account)
10. **Profile → Logout** (After confirmation) → Login
11. **Vendor Dashboard → Subscription Plans** (Renew/Upgrade button)

## Notes

- All navigation uses named routes for consistency
- Arguments can be passed via `arguments` parameter
- Bottom navigation bars maintain state per screen
- Modals/dialogs use `showDialog` for overlay behavior

