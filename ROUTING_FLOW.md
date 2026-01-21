# Application Routing Flow - Complete Guide

This document describes the complete navigation flow for all screens, clearly distinguishing between **User (Customer)** and **Vendor** flows.

---

## 🔐 Authentication Flow (Both User Types)

```
┌─────────────────────────────────────────┐
│         SPLASH SCREEN                   │
│            (/splash)                    │
│                                         │
│  ┌──────────────────────────────┐      │
│  │  Check: Auth Token exists?   │      │
│  └──────────────────────────────┘      │
│           │                             │
│           ├─ YES ───────────────────────┼─┐
│           │                              │ │
│           └─ NO                          │ │
│              │                           │ │
│              ▼                           │ │
│  ┌──────────────────────────────┐      │ │
│  │      LOGIN SCREEN            │      │ │
│  │        (/login)              │      │ │
│  └──────────────────────────────┘      │ │
│           │                             │ │
│           ├─→ Register Link             │ │
│           │   └─→ REGISTER SCREEN       │ │
│           │       (/register)          │ │
│           │                             │ │
│           └─→ Login Button              │ │
│               └─→ Check User Type ───────┘ │
│                                           │
└───────────────────────────────────────────┘
```

---

## 👤 USER (CUSTOMER) FLOW

### **After Login/Register (Customer):**
```
Login/Register (Customer)
    ↓
HOME SCREEN (User)
    │
    ├─→ Search Button
    │   └─→ SEARCH RESULTS SCREEN
    │       │
    │       ├─→ Vendor Card
    │       │   └─→ VENDOR PROFILE SCREEN
    │       │       ├─→ Start Chat Button
    │       │       │   └─→ CHAT ROOM SCREEN
    │       │       └─→ Phone Button (Future)
    │       │
    │       └─→ Customer Reviews Section
    │
    ├─→ Supplier Card (from home list)
    │   └─→ VENDOR PROFILE SCREEN
    │       └─→ CHAT ROOM SCREEN
    │
    └─→ Bottom Navigation:
        ├─→ Home (stays on home)
        ├─→ Orders → Orders Screen (TODO)
        ├─→ Garage → Garage Screen (TODO)
        └─→ Profile → USER PROFILE SCREEN
            │
            ├─→ Edit Profile (TODO)
            ├─→ Language (TODO)
            ├─→ Help & Support (TODO)
            └─→ Logout → LOGIN SCREEN
```

### **Chat Flow (User):**
```
CHAT LIST SCREEN
    │
    ├─→ Chat Item
    │   └─→ CHAT ROOM SCREEN
    │       │
    │       ├─→ Send Message (normal input)
    │       └─→ Gallery Icon (Future: attach image)
    │
    ├─→ Filter: All | Unread | Archive
    │
    ├─→ FAB (+) → (Future: New Chat)
    │
    └─→ Bottom Navigation:
        ├─→ Home → HOME SCREEN
        ├─→ My Cars → Garage Screen
        ├─→ Chats (current)
        └─→ Account → USER PROFILE SCREEN
```

---

## 🏪 VENDOR FLOW

### **After Login/Register (Vendor):**
```
Login/Register (Vendor)
    ↓
    ├─→ If No Subscription
    │   └─→ SUBSCRIPTION PLANS SCREEN
    │       │
    │       ├─→ Select Plan
    │       ├─→ Payment (Future: Paymob)
    │       └─→ After Payment Success
    │           └─→ VENDOR DASHBOARD
    │
    └─→ If Has Subscription
        └─→ VENDOR DASHBOARD SCREEN
```

### **Vendor Dashboard Navigation:**
```
VENDOR DASHBOARD SCREEN
    │
    ├─→ Renew/Upgrade Button
    │   └─→ SUBSCRIPTION PLANS SCREEN
    │
    ├─→ Quick Links:
    │   ├─→ Manage Inventory (TODO)
    │   ├─→ Edit Store Profile (TODO)
    │   └─→ Technical Support (TODO)
    │
    └─→ Bottom Navigation:
        ├─→ Home → (stays on dashboard)
        ├─→ Chats → CHAT LIST SCREEN (Vendor)
        ├─→ Add Item → (TODO: Add Item Screen)
        ├─→ Reports → (TODO: Reports Screen)
        ├─→ Activity → (TODO: Activity Screen)
        └─→ Account → (TODO: Vendor Account Screen)
```

### **Chat Flow (Vendor):**
```
CHAT LIST SCREEN (Vendor)
    │
    ├─→ Chat Item
    │   └─→ CHAT ROOM SCREEN
    │       │
    │       ├─→ Send Message (normal input)
    │       │
    │       └─→ Gallery Icon
    │           └─→ SEND MESSAGE DIALOG (Modal)
    │               │
    │               ├─→ Close (X) → Close dialog
    │               └─→ Send Button → Send message
    │
    └─→ Bottom Navigation:
        ├─→ Home → VENDOR DASHBOARD
        ├─→ My Cars → (Future)
        ├─→ Chats (current)
        └─→ Account → (Future: Vendor Account)
```

---

## 📱 Screen-by-Screen Navigation Details

### **1. Splash Screen** (`/`)
- **Auto-navigates after 3 seconds**
- **Checks:** Auth token in storage
- **If logged in:** Navigate to home based on user type
  - Customer → Home Screen
  - Vendor → Vendor Dashboard
- **If not logged in:** Navigate to Login Screen

### **2. Login Screen** (`/login`)
- **Register Link** → Register Screen
- **Login Button** → After successful login:
  - Customer → Home Screen
  - Vendor → Vendor Dashboard

### **3. Register Screen** (`/register`)
- **User Type Selection:** Customer or Vendor
- **Register Button** → After successful registration:
  - **Customer** → Home Screen
  - **Vendor** → Subscription Plans Screen

### **4. Home Screen (User)** (`/home`)
- **Search Button** → Search Results Screen
- **Supplier Card** → Vendor Profile Screen
- **Bottom Nav:**
  - Home (current)
  - Orders → (TODO)
  - Garage → (TODO)
  - Profile → User Profile Screen

### **5. Search Results Screen** (`/search-results`)
- **Vendor Card** → Vendor Profile Screen
- **Filter Chips** (removable)
- **Bottom Nav:**
  - Search (current)
  - Orders → (TODO)
  - Chats → Chat List Screen
  - Account → User Profile Screen

### **6. Vendor Profile Screen** (`/vendor-profile`)
- **Start Chat Button** → Chat Room Screen
- **Phone Button** → (Future: Call)
- **Back Button** → Previous screen

### **7. Chat List Screen** (`/chat-list`)
- **Chat Item** → Chat Room Screen
- **Filter:** All | Unread | Archive
- **FAB (+)** → (Future: New Chat)
- **Bottom Nav:**
  - Home → Home Screen (User) OR Vendor Dashboard (Vendor)
  - My Cars → (Future)
  - Chats (current)
  - Account → Profile Screen

### **8. Chat Room Screen** (`/chat-room`)
- **Send Message** → Normal text input
- **Gallery Icon** → (Future: Image picker)
  - **For Vendors:** Can show Send Message Dialog
- **Back Button** → Chat List Screen

### **9. User Profile Screen** (`/profile`)
- **Edit Profile** → (Future: Edit Profile Screen)
- **Language** → (Future: Language Settings)
- **Help & Support** → (Future: Help Screen)
- **Logout** → Confirmation Dialog → Login Screen
- **Bottom Nav:**
  - Home → Home Screen
  - Search → Home Screen
  - Orders → (TODO)
  - Account (current)

### **10. Vendor Dashboard Screen** (`/vendor-dashboard`)
- **Renew/Upgrade Button** → Subscription Plans Screen
- **Quick Links:**
  - Manage Inventory → (Future)
  - Edit Store Profile → (Future)
  - Technical Support → (Future)
- **Bottom Nav:**
  - Home (current)
  - Chats → Chat List Screen
  - Add Item → (Future)
  - Reports → (Future)
  - Activity → (Future)
  - Account → (Future)

### **11. Subscription Plans Screen** (`/subscription-plans`)
- **Duration Toggle:** Monthly | Annual
- **Plan Cards:** Basic | Golden | Silver
- **Subscribe Button** → After payment:
  - Navigate to Vendor Dashboard
- **Contact Sales** → (Future: Contact form)

---

## 🔄 Navigation Service Methods

### **NavigationService.navigateToHome(context)**
- Checks user type from storage
- Navigates to:
  - **Customer** → Home Screen
  - **Vendor** → Vendor Dashboard

### **NavigationService.navigateAfterLogin(context, userType)**
- After successful login
- Navigates based on userType:
  - `customer` → Home Screen
  - `vendor` → Vendor Dashboard

### **NavigationService.navigateAfterRegister(context, userType)**
- After successful registration
- Navigates based on userType:
  - `customer` → Home Screen
  - `vendor` → Subscription Plans Screen

### **NavigationService.navigateAfterSubscription(context)**
- After successful subscription purchase
- Navigates to: Vendor Dashboard

### **NavigationService.navigateToLogout(context)**
- Clears all storage
- Navigates to: Login Screen

---

## 📋 Route Constants

```dart
// Authentication
AppRoutes.splash          → '/'                  → SplashScreen
AppRoutes.login           → '/login'             → LoginScreen
AppRoutes.register        → '/register'          → RegisterScreen

// User Routes
AppRoutes.home            → '/home'             → HomeScreen (User)
AppRoutes.searchResults   → '/search-results'   → SearchResultsScreen
AppRoutes.profile         → '/profile'          → UserProfileScreen

// Vendor Routes
AppRoutes.vendorDashboard → '/vendor-dashboard' → VendorDashboardScreen
AppRoutes.subscriptionPlans → '/subscription-plans' → SubscriptionPlansScreen

// Shared Routes
AppRoutes.vendorProfile   → '/vendor-profile'  → VendorProfileScreen
AppRoutes.chatList        → '/chat-list'        → ChatListScreen
AppRoutes.chatRoom        → '/chat-room'        → ChatRoomScreen

// Future Routes
AppRoutes.orders          → '/orders'           → OrdersScreen (TODO)
AppRoutes.garage          → '/garage'           → GarageScreen (TODO)
```

---

## 🎯 Key Navigation Patterns

### **1. Authentication Check**
```dart
// In Splash Screen
final authToken = StorageService.getAuthToken();
final userType = StorageService.getUserType();

if (authToken != null && userType != null) {
  NavigationService.navigateToHome(context);
} else {
  Navigator.pushNamed(context, AppRoutes.login);
}
```

### **2. User Type-Based Navigation**
```dart
// After Login
NavigationService.navigateAfterLogin(context, userType);

// After Register
NavigationService.navigateAfterRegister(context, userType);
```

### **3. Push Navigation (Forward)**
```dart
// Navigate to new screen
Navigator.pushNamed(
  context,
  AppRoutes.vendorProfile,
  arguments: {
    'vendorId': 'vendor_1',
    'vendorName': 'Vendor Name',
  },
);
```

### **4. Push and Remove Until (Clear Stack)**
```dart
// After login/register - clear navigation stack
Navigator.pushNamedAndRemoveUntil(
  context,
  AppRoutes.home,
  (route) => false,
);
```

### **5. Modal Dialog**
```dart
// Show send message dialog
SendMessageDialog.show(
  context,
  customerName: 'Customer Name',
);
```

---

## 🔀 Complete User Flow Examples

### **Example 1: Customer Searching for Parts**
```
1. Splash → Login
2. Login → Home Screen
3. Home → Enter search criteria → Search Results
4. Search Results → Tap vendor card → Vendor Profile
5. Vendor Profile → Start Chat → Chat Room
6. Chat Room → Send messages
7. Back → Chat List → See all conversations
```

### **Example 2: Vendor Registration Flow**
```
1. Splash → Login
2. Login → Register
3. Register → Select "Vendor" → Fill form → Register
4. Register → Subscription Plans Screen
5. Subscription Plans → Select plan → Subscribe
6. After payment → Vendor Dashboard
7. Dashboard → Chats → Chat with customers
```

### **Example 3: Vendor Managing Business**
```
1. Vendor Dashboard → View performance metrics
2. Dashboard → Renew Subscription → Subscription Plans
3. Dashboard → Chats → Chat List
4. Chat List → Chat Room → Send messages to customers
5. Dashboard → Quick Links → Manage Inventory (Future)
```

---

## ⚠️ Important Notes

1. **User Type Detection:**
   - Stored in `StorageService` with key `userTypeKey`
   - Values: `customer` or `vendor`
   - Checked on app start and after login

2. **Subscription Check:**
   - Vendors must have active subscription
   - If no subscription → Redirect to Subscription Plans
   - After subscription → Access to Vendor Dashboard

3. **Bottom Navigation:**
   - Different for User vs Vendor
   - User: Home | Orders | Garage | Profile
   - Vendor: Home | Chats | Add | Reports | Activity | Account

4. **Chat Access:**
   - Users can chat with vendors
   - Vendors can chat with users
   - No User-User or Vendor-Vendor chat

5. **Navigation Stack:**
   - Use `pushNamedAndRemoveUntil` for authentication flows
   - Use `pushNamed` for normal navigation
   - Use `pop` to go back

---

## 🚀 Quick Reference

| Action | User Type | Destination |
|--------|-----------|-------------|
| After Login | Customer | Home Screen |
| After Login | Vendor | Vendor Dashboard |
| After Register | Customer | Home Screen |
| After Register | Vendor | Subscription Plans |
| After Subscription | Vendor | Vendor Dashboard |
| Logout | Both | Login Screen |
| Search | Customer | Search Results |
| View Vendor | Customer | Vendor Profile |
| Start Chat | Customer | Chat Room |
| Manage Business | Vendor | Vendor Dashboard |

---

This routing flow ensures proper navigation based on user type and maintains a clear separation between customer and vendor experiences.
