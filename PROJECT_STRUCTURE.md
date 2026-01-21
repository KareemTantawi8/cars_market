# Project Structure Guide

This document explains the project structure and architecture used in the Cars Market Flutter application.

## Architecture Pattern

**MVVM (Model-View-ViewModel) + Cubit (BLoC)**

- **Model**: Data models and entities
- **View**: UI screens and widgets
- **ViewModel**: Business logic (implemented using Cubit)
- **Cubit**: State management (from flutter_bloc package)

## Folder Structure

```
lib/
├── core/                          # Core functionality shared across the app
│   ├── theme/                     # Theme configuration
│   │   ├── app_colors.dart       # Color palette
│   │   ├── app_text_styles.dart  # Text styles
│   │   └── app_theme.dart        # Theme configuration
│   ├── utils/                     # Utilities
│   │   ├── constants.dart        # App constants
│   │   └── extensions.dart       # Dart extensions
│   ├── network/                   # Network layer
│   │   ├── api_client.dart       # Dio HTTP client
│   │   └── api_endpoints.dart    # API endpoints
│   └── services/                  # Core services
│       └── storage_service.dart  # Local storage service
│
├── features/                      # Feature-based modules
│   ├── auth/                      # Authentication feature
│   │   ├── data/                  # Data layer
│   │   │   ├── models/           # Data models (DTOs)
│   │   │   └── repositories/     # Repository implementations
│   │   ├── domain/                # Domain layer (business logic)
│   │   │   ├── entities/         # Domain entities
│   │   │   └── repositories/     # Repository interfaces
│   │   └── presentation/          # Presentation layer (UI)
│   │       ├── cubit/            # State management (Cubits)
│   │       ├── view_models/      # View models (if needed)
│   │       └── views/            # UI screens
│   │           ├── splash_screen.dart
│   │           ├── login_screen.dart
│   │           └── register_screen.dart
│   │
│   ├── home/                      # Home feature
│   │   └── presentation/
│   │       ├── cubit/
│   │       ├── view_models/
│   │       └── views/
│   │
│   ├── chat/                      # Chat feature
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── cubit/
│   │       ├── view_models/
│   │       └── views/
│   │           ├── chat_list_screen.dart
│   │           └── chat_room_screen.dart
│   │
│   ├── vendor/                    # Vendor feature
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── subscription/              # Subscription feature
│   │   └── presentation/
│   │
│   ├── profile/                   # Profile feature
│   │   └── presentation/
│   │
│   └── notifications/             # Notifications feature
│       └── presentation/
│
└── shared/                        # Shared resources
    ├── widgets/                   # Reusable widgets
    │   ├── buttons/              # Button widgets
    │   │   ├── primary_button.dart
    │   │   └── secondary_button.dart
    │   ├── text_fields/          # Text field widgets
    │   │   └── app_text_field.dart
    │   ├── loading/              # Loading widgets
    │   │   └── loading_indicator.dart
    │   └── common/               # Common widgets
    │       ├── empty_state.dart
    │       ├── error_state.dart
    │       ├── app_card.dart
    │       └── online_indicator.dart
    └── models/                    # Shared models
```

## Color System

Colors are defined in `lib/core/theme/app_colors.dart`:

- **Primary Colors**: Blue shades for primary actions
- **Background Colors**: Dark theme colors
- **Text Colors**: White, light gray, and gray
- **Status Colors**: Success, error, warning, info
- **Chat Colors**: User and vendor message bubbles

## Text Styles

Text styles are defined in `lib/core/theme/app_text_styles.dart`:

- **Heading**: Large, medium, small
- **Body**: Large, medium, small
- **Caption**: Regular and small
- **Button**: Regular and small
- **Input**: Labels, hints, and input text
- **Special**: Links, errors, success messages

## Common Widgets

### Buttons
- `PrimaryButton`: Main action button with loading state
- `SecondaryButton`: Secondary action button with outline style

### Text Fields
- `AppTextField`: Custom text field with label, hint, validation, and icons

### Loading & States
- `LoadingIndicator`: Circular progress indicator with optional message
- `EmptyState`: Display when there's no data
- `ErrorState`: Display when an error occurs

### Common
- `AppCard`: Custom card widget with optional tap action
- `OnlineIndicator`: Online/offline status indicator

## Usage Examples

### Using Primary Button
```dart
PrimaryButton(
  text: 'تسجيل الدخول',
  onPressed: () {
    // Handle button press
  },
  isLoading: false,
)
```

### Using App Text Field
```dart
AppTextField(
  label: 'رقم الهاتف',
  hint: '01X XXXX XXXX',
  controller: phoneController,
  keyboardType: TextInputType.phone,
  prefixIcon: Icon(Icons.phone),
)
```

### Using Loading Indicator
```dart
LoadingIndicator(
  message: 'جاري التحميل...',
)
```

### Using Colors
```dart
Container(
  color: AppColors.primaryColor,
  child: Text(
    'Hello',
    style: AppTextStyles.headingLarge,
  ),
)
```

## Development Guidelines

1. **Feature-based Structure**: Each feature is self-contained with its own data, domain, and presentation layers
2. **State Management**: Use Cubit for state management in each feature
3. **Reusable Widgets**: Use shared widgets for common UI elements
4. **Theme Consistency**: Always use `AppColors` and `AppTextStyles` for consistent theming
5. **API Calls**: Use `ApiClient` for all HTTP requests
6. **Local Storage**: Use `StorageService` for persisting data locally

## Next Steps

1. Implement authentication feature (Login, Register)
2. Implement home screens for both User and Vendor
3. Implement chat functionality
4. Implement vendor dashboard
5. Implement subscription flow
6. Add push notifications
7. Add rating system
8. Testing and optimization

