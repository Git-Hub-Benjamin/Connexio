#!/bin/bash
# Connexio Setup Script

set -e

echo "🚀 Setting up Connexio..."

# Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first:"
    echo "   https://docs.flutter.dev/get-started/install"
    echo ""
    echo "   Quick install (Linux):"
    echo "   sudo snap install flutter --classic"
    exit 1
fi

echo "✅ Flutter found"

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Check platform
case "$(uname -s)" in
    Linux*)
        echo "🐧 Building for Linux..."
        flutter build linux --release
        
        echo ""
        echo "✅ Build complete!"
        echo ""
        echo "📁 Binary location: build/linux/x64/release/bundle/"
        echo ""
        echo "To install system-wide:"
        echo "  sudo mkdir -p /opt/connexio"
        echo "  sudo cp -r build/linux/x64/release/bundle/* /opt/connexio/"
        echo "  sudo ln -sf /opt/connexio/connexio /usr/local/bin/connexio"
        echo ""
        echo "Then run with: connexio"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        echo "🪟 Building for Windows..."
        flutter build windows --release
        
        echo ""
        echo "✅ Build complete!"
        echo ""
        echo "📁 Binary location: build\\windows\\x64\\runner\\Release\\"
        ;;
    *)
        echo "Unknown platform. Building for current platform..."
        flutter build
        ;;
esac

echo ""
echo "📱 To build for Android:"
echo "   flutter build apk --release"
echo ""
echo "🖥️  To run the server on your homelab:"
echo "   cd server && go build && ./connexio-server -port 8080"
