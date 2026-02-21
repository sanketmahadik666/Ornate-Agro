#!/bin/bash

# Quick Start Script for Ornate Agro Flutter App

echo "🚀 Ornate Agro - Quick Start"
echo "============================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed!"
    echo ""
    echo "Please install Flutter first:"
    echo "  sudo snap install flutter --classic"
    echo ""
    echo "Or follow: https://docs.flutter.dev/get-started/install/linux"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Navigate to project directory
cd "$(dirname "$0")"

# Check Flutter doctor
echo "📋 Checking Flutter setup..."
flutter doctor
echo ""

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get
echo ""

# Analyze code
echo "🔍 Analyzing code..."
flutter analyze
echo ""

# List available devices
echo "📱 Available devices:"
flutter devices
echo ""

# Ask user what to do
echo "What would you like to do?"
echo "1) Run on Chrome (Web)"
echo "2) Run on connected device/emulator"
echo "3) Just setup (skip running)"
echo ""
read -p "Enter choice [1-3]: " choice

case $choice in
    1)
        echo "🌐 Starting app in Chrome..."
        flutter run -d chrome
        ;;
    2)
        echo "📱 Starting app on device..."
        flutter run
        ;;
    3)
        echo "✅ Setup complete! Run 'flutter run' when ready."
        ;;
    *)
        echo "Invalid choice. Run 'flutter run' manually."
        ;;
esac
