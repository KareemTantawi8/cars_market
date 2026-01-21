# Cars Market - Mobile Application Documentation

## نظرة عامة على التطبيق (Application Overview)

التطبيق عبارة عن منصة موبايل تربط بين:
- **Clients (مستخدمين)** - العملاء الذين يبحثون عن قطع غيار وخدمات
- **Vendors (تجار)** - الموردين الذين يقدمون قطع الغيار والخدمات

التواصل داخل التطبيق يتم عن طريق Chat مباشر فقط (لا يوجد مكالمات صوتية أو فيديو حالياً).
التطبيق يستخدم اللهجة المصرية للعربية ويتضمن نظام اشتراكات للتجار، لوحات تحكم منفصلة، وإشعارات.

---

## أنواع المستخدمين (User Types)

### 2.1 User (مستخدم عادي)
- تسجيل الدخول / إنشاء حساب
- البحث عن تجار
- فتح محادثة مع التاجر
- إرسال واستقبال رسائل
- تقييم التاجر بعد إتمام الطلب
- تجميع Points بعد إتمام طلب ناجح

### 2.2 Vendor (تاجر)
- تسجيل الدخول / إنشاء حساب
- الاشتراك في باقة
- استقبال رسائل من المستخدمين
- الرد على الرسائل
- مشاهدة التقييمات ومتوسط التقييم
- إدارة حساب التاجر
- لوحة تحكم تتضمن:
  - سرعة الرد
  - إحصائيات المحادثات
  - حالة الاشتراك

### 2.3 Admin
- يستخدم لوحة تحكم ويب (غير متضمنة في تطبيق الموبايل)

---

## Authentication & Onboarding Screens

### 3.1 Splash Screen
- عرض شعار التطبيق
- حالة تحميل
- التوجيه المناسب حسب حالة تسجيل الدخول

### 3.2 Login Screen
- رقم موبايل أو Email
- كلمة المرور
- رابط "نسيت كلمة المرور"
- زر "تسجيل الدخول"
- رابط "إنشاء حساب جديد"

### 3.3 Register Screen
- اختيار نوع الحساب:
  - ○ User (عميل)
  - ○ Vendor (تاجر)
- البيانات الأساسية:
  - الاسم الكامل
  - رقم الموبايل
  - Email
  - كلمة المرور
- زر "إنشاء الحساب"
- رابط "تسجيل الدخول" للمستخدمين الحاليين

### 3.4 Logout
- تسجيل خروج فعلي
- Token invalidation

---

## Home & Navigation

### 4.1 Home Screen (User)
- بحث عن تجار
- قائمة التجار مع:
  - الاسم
  - التقييم
  - سرعة الرد المتوسط
  - حالة الاتصال (Online / Offline)
- فلترة وعرض حسب:
  - التقييم
  - سرعة الرد

### 4.2 Home Screen (Vendor)
- قائمة المحادثات
- إشعارات سريعة
- حالة الاشتراك
- لوحة التحكم الأساسية

---

## Vendor Profile Screen

### 5. للمستخدم:
- اسم التاجر
- متوسط التقييم
- عدد التقييمات
- متوسط سرعة الرد
- زر "بدء محادثة" يظهر

---

## Chat Module

### 6.1 Chat List Screen
- قائمة المحادثات
- آخر رسالة
- وقت آخر رسالة
- Unread counter

### 6.2 Chat Room Screen
- محادثة مباشرة (Real-time)
- إرسال واستقبال رسائل نصية فقط
- Timestamp لكل رسالة
- حالة الرسالة (sent / received / read)

**المرحلة الحالية:**
- لا يوجد إرسال ملفات أو صور

### 6.3 Chat Rules
- User ↔ Vendor: مسموح
- User ↔ User: لا يوجد
- Vendor ↔ Vendor: لا يوجد

---

## Notifications

### 7.1 أنواع الإشعارات (Vendor)
- رسالة جديدة من التاجر
- رد من العميل
- قرب انتهاء الاشتراك أو انتهاء الاشتراك

### 7.2 Behavior
- Push Notifications (Foreground / Background)
- In-App Notifications
- عند الضغط على الإشعار:
  - فتح المحادثة أو الصفحة المرتبطة

---

## Ratings & Reviews

### 8.1 Rating Screen
يظهر بعد:
- إتمام طلب حقيقي
- انتهاء محادثة

- تقييم بالنجوم (1 – 5)
- تعليق نصي (اختياري)

### 8.2 Rules
- لا يمكن التقييم بدون تفاعل حقيقي مع التاجر
- ملف التقييم يظهر فقط بعد تفاعل

---

## Points System (User)

### 9. Phase (حاليًا)
عند:
- إتمام طلب ناجح على المستخدم

في:
- Profile Screen: عرض النقاط الحالية
- استخدام النقاط: لا يوجد حالياً

---

## Vendor Subscription

### 10.1 Subscription Screen (Vendor)
- عرض باقات الاشتراك
- سعر كل باقة
- مدة الاشتراك
- زر "اشترك الآن"

### 10.2 Payment Flow
- دفع عبر بوابات الدفع داخل مصر:
  - Paymob
- بعد نجاح الدفع:
  - تفعيل حساب الاشتراك
  - استقبال المحادثات
- عند انتهاء الاشتراك:
  - يتم إيقاف استقبال الرسائل

---

## Vendor Dashboard (Mobile)

### 11. إحصائيات سريعة:
- عدد المحادثات
- سرعة الرد المتوسط
- التقييم الحالي
- حالة الاشتراك

### 12. إدارة الحساب
- Profile & Settings

---

## User Profile

- الاسم
- رقم الموبايل
- Email
- Points
- Logout

---

## Vendor Profile

- البيانات الأساسية
- حالة الاشتراك
- Logout

---

## API Integration Guidelines

### Authentication
- باستخدام: JWT Tokens
- كل Request يحتوي: Authorization Header

### Error Handling
- 401 → Logout
- 403 → Permission Denied
- 500 → Generic Error Message

---

## General UI / UX Notes

- Simple UI
- Arabic RTL
- Loading states لكل API
- Empty states (no chats / no vendors)
- Offline handling (no internet)

---

## Out of Scope (حاليًا)

- رفع ملفات أو صور أو صوتية أو فيديو
- مكالمات
- متعددة لغات
- عموﻻت مالية

---

## Notes for Flutter Developer

### Architecture:
- **MVVM (Model-View-ViewModel)**
- **Cubit** للـ State Management

### Business Rules:
- التطبيق API-driven بالكامل
- لا يوجد Logic داخل التطبيق، كل شيء يعتمد على API
- Real-time Chat: يعتمد على WebSocket أو API polling (حسب ما يوفره Backend)

### Technical Requirements:
- شاشة لكل wireframe في الوثيقة
- لو حابب، يمكنك أضيف أو تعدل حسب ما يناسب المشروع
- أي Flutter Dev إن فتح المشروع يفهم فوراً ويبدأ شغل

---

## Project Structure

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── constants.dart
│   │   └── extensions.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   └── api_endpoints.dart
│   └── services/
│       ├── auth_service.dart
│       └── storage_service.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── repositories/
│   │   ├── presentation/
│   │   │   ├── cubit/
│   │   │   ├── view_models/
│   │   │   └── views/
│   │   │       ├── splash_screen.dart
│   │   │       ├── login_screen.dart
│   │   │       └── register_screen.dart
│   ├── home/
│   │   ├── presentation/
│   │   │   ├── cubit/
│   │   │   ├── view_models/
│   │   │   └── views/
│   ├── chat/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── cubit/
│   │       ├── view_models/
│   │       └── views/
│   │           ├── chat_list_screen.dart
│   │           └── chat_room_screen.dart
│   ├── vendor/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── subscription/
│   │   └── presentation/
│   ├── profile/
│   │   └── presentation/
│   └── notifications/
│       └── presentation/
├── shared/
│   ├── widgets/
│   │   ├── buttons/
│   │   ├── text_fields/
│   │   ├── loading/
│   │   └── common/
│   └── models/
└── main.dart
```

---

## Color Palette

Based on the screens:
- **Primary Color**: Blue (#1E88E5 or similar)
- **Secondary Color**: Dark Blue (#0D47A1)
- **Background**: Dark (#121212 or similar)
- **Surface**: Dark Gray (#1E1E1E)
- **Text Primary**: White
- **Text Secondary**: Light Gray
- **Success**: Green
- **Error**: Red
- **Warning**: Orange/Yellow
- **Accent**: Blue

---

## Text Styles

- **Heading Large**: For main titles
- **Heading Medium**: For section titles
- **Body Large**: For important text
- **Body Medium**: For regular text
- **Body Small**: For secondary text
- **Caption**: For timestamps and small info
- **Button**: For button text

---

## Next Steps

1. Set up project structure
2. Configure theme and colors
3. Create common widgets
4. Implement authentication screens
5. Implement chat functionality
6. Implement vendor dashboard
7. Implement subscription flow
8. Add notifications
9. Testing
10. Polish and optimization

