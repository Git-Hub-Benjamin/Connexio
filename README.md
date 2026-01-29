# Connexio

A lightweight cross-platform app for syncing text, images, and files between devices via your homelab.

## Architecture

- **Client**: Flutter app (Windows, Linux, Android, iOS)
- **Server**: Go backend (runs on your homelab)

## Quick Start

### 🖥️ Desktop (Linux/Windows)

```bash
# Install Flutter
sudo snap install flutter --classic  # Linux
# or https://docs.flutter.dev/get-started/install  # Windows/Mac

# Get dependencies
flutter pub get

# Build
flutter build linux --release    # Linux
flutter build windows --release  # Windows
```

### 📱 Mobile (iOS/Android)

**Automatic builds via GitHub Actions:**
1. Push code to `master` branch
2. Go to GitHub Actions tab
3. Download the artifact:
   - `connexio-android.apk` → Install directly on Android
   - `connexio-ios.ipa` → Install on iOS (see below)

**Manual build (requires machine with that OS):**
```bash
flutter build apk --release      # Android
flutter build ipa --release      # iOS (macOS only)
```

### 📲 Install on iOS

Since you don't have a Mac, use one of these tools to sideload the `.ipa`:
- **AltStore** (easiest) - https://altstore.io
- **Sideloadly** - https://sideloadly.io
- **TestFlight** (if you set up Apple Developer account)

## Installation

#### Linux
```bash
# Copy the built app
sudo cp -r build/linux/x64/release/bundle /opt/connexio
sudo ln -s /opt/connexio/connexio /usr/local/bin/connexio
connexio  # Run from anywhere
```

#### Windows
1. Navigate to `build/windows/x64/runner/Release/`
2. Copy folder to `C:\Program Files\Connexio`
3. Create shortcut to `connexio.exe`

#### Android
1. Enable "Unknown Sources" in Settings
2. Download `.apk` from GitHub Actions
3. Tap to install

#### iOS
1. Download `.ipa` from GitHub Actions
2. Use AltStore/Sideloadly to install on phone

## Configuration

On first launch, enter your server IP in Settings:
- **Local network:** `192.168.x.x:8080`
- **Tailscale:** `100.x.x.x:8080` (recommended for remote)

## Features

- 📝 Sync text between devices instantly
- 🖼️ Share images with preview
- 📁 Transfer files of any type
- 💾 Save items to slots for later access
- 🔒 Connects via Tailscale (secure)
- 🌐 Works across networks (homelab)
