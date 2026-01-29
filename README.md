# Connexio

A lightweight cross-platform app for syncing text, images, and files between devices via your homelab.

## Architecture

- **Client**: Flutter app (Windows, Linux, Android, iOS)
- **Server**: Go backend (runs on your homelab)

## Quick Setup

### 1. Install Flutter (if not installed)

```bash
# Linux (snap)
sudo snap install flutter --classic

# Or download from https://docs.flutter.dev/get-started/install
```

### 2. Server Setup (Homelab)

```bash
cd server
go build -o connexio-server
./connexio-server -port 8080
```

Or with Docker:
```bash
cd server
docker build -t connexio-server .
docker run -d -p 8080:8080 -v connexio-data:/data connexio-server
```

### 3. Client Setup

```bash
# Get dependencies
flutter pub get

# Run on Linux
flutter run -d linux

# Build for Linux
flutter build linux --release

# Build for Windows
flutter build windows --release

# Build for Android
flutter build apk --release
```

### 4. Installation

#### Linux
```bash
# Copy the built app
sudo cp -r build/linux/x64/release/bundle /opt/connexio
sudo ln -s /opt/connexio/connexio /usr/local/bin/connexio

# Run from terminal
connexio
```

#### Windows
Run the installer from `build/windows/x64/runner/Release/` or copy the folder to `C:\Program Files\Connexio`

#### Android
Install the APK from `build/app/outputs/flutter-apk/app-release.apk`

## Configuration

On first launch, configure your homelab server IP in Settings (gear icon).

Example: `100.x.x.x:8080` (Tailscale IP)

## Features

- 📝 Sync text between devices instantly
- 🖼️ Share images with preview
- 📁 Transfer files of any type
- 💾 Save items to slots for later access
- 🔒 Connects via Tailscale (secure)
