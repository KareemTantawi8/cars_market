# iOS Setup Guide

## ✅ iOS Configuration Complete

The application has been prepared to run on iOS. Here's what has been configured:

### 1. **Info.plist Configuration**
- ✅ App Display Name: "Cars Market"
- ✅ Bundle Identifier: `com.example.carsMarket`
- ✅ Network Security: Configured for HTTPS and local networking
- ✅ URL Schemes: Added support for `https`, `http`, `tel`, `sms`, `mailto`
- ✅ Background Modes: Enabled for fetch and remote notifications
- ✅ Supported Orientations: Portrait and Landscape (iPhone & iPad)

### 2. **Deployment Target**
- ✅ iOS Minimum Version: **13.0**
- ✅ Podfile Platform: **13.0** (aligned with project settings)

### 3. **Dependencies**
- ✅ CocoaPods dependencies installed
- ✅ Flutter plugins registered
- ✅ All required pods integrated

### 4. **AppDelegate**
- ✅ Swift-based AppDelegate configured
- ✅ Flutter plugin registration enabled

## 🚀 Running on iOS

### Prerequisites
1. **Xcode** installed (latest version recommended)
2. **CocoaPods** installed (`sudo gem install cocoapods`)
3. **iOS Simulator** or **Physical Device** connected

### Steps to Run

1. **Open in Xcode** (optional, for advanced configuration):
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Run from Flutter**:
   ```bash
   flutter run -d ios
   ```

3. **Build for Release**:
   ```bash
   flutter build ios
   ```

### Common Issues & Solutions

#### Issue: "iOS SDK not found"
- **Solution**: Open Xcode → Settings → Components → Download iOS SDK

#### Issue: "Code signing error"
- **Solution**: 
  1. Open `ios/Runner.xcworkspace` in Xcode
  2. Select Runner target → Signing & Capabilities
  3. Select your development team
  4. Xcode will automatically manage signing

#### Issue: "Pod install fails"
- **Solution**: 
  ```bash
  cd ios
  pod deintegrate
  pod install
  ```

#### Issue: "Build fails with encoding error"
- **Solution**: Set UTF-8 encoding:
  ```bash
  export LANG=en_US.UTF-8
  cd ios && pod install
  ```

## 📱 Testing on Simulator

1. List available simulators:
   ```bash
   flutter devices
   ```

2. Run on specific simulator:
   ```bash
   flutter run -d "iPhone 15 Pro"
   ```

## 📱 Testing on Physical Device

1. Connect your iPhone via USB
2. Trust the computer on your iPhone
3. Open Xcode → Window → Devices and Simulators
4. Select your device and click "Use for Development"
5. Run: `flutter run -d <device-id>`

## 🔧 Additional Configuration

### Bundle Identifier
To change the bundle identifier:
1. Open `ios/Runner.xcodeproj` in Xcode
2. Select Runner target → General
3. Change "Bundle Identifier"

### App Icons
Replace icons in: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Launch Screen
Modify: `ios/Runner/Base.lproj/LaunchScreen.storyboard`

## 📝 Notes

- The app is configured for **RTL (Right-to-Left)** support for Arabic
- Network permissions are configured for API calls
- Background modes enabled for notifications
- Minimum iOS version: **13.0** (supports iPhone 6s and later)

## ✅ Verification Checklist

- [x] Info.plist configured
- [x] Podfile updated
- [x] Dependencies installed
- [x] Deployment target set
- [x] Network permissions added
- [x] URL schemes configured
- [x] Background modes enabled

Your iOS app is ready to run! 🎉

