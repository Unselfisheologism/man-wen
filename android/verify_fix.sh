#!/bin/bash

# Android Build Fix Verification Script
# Verifies the fixes applied to resolve Android build failures

echo "=== Android Build Fix Verification ==="
echo

# Get the absolute path to the project root
PROJECT_ROOT="/opt/data/workspace/man-wen"

# Change to the android directory for relative path operations
cd "$PROJECT_ROOT/android"

echo "✅ Android project root: $(pwd)"
echo

# Check 1: Verify gradle.properties has suppression flags
echo "📋 Checking gradle.properties configuration..."
if grep -q "android.suppressUnsupportedCompileSdk=34" gradle.properties; then
    echo "✅ android.suppressUnsupportedCompileSdk=34 found"
else
    echo "❌ android.suppressUnsupportedCompileSdk=34 NOT found"
    exit 1
fi

if grep -q "android.suppressDeprecatedPackage=34" gradle.properties; then
    echo "✅ android.suppressDeprecatedPackage=34 found"
else
    echo "❌ android.suppressDeprecatedPackage=34 NOT found"
    exit 1
fi
echo

# Check 2: Verify AndroidManifest.xml has correct configChanges
echo "📋 Checking AndroidManifest.xml configChanges..."
if grep -q "android:configChanges=\"orientation|keyboardHidden|screenLayout|uiMode\"" app/src/main/AndroidManifest.xml; then
    echo "✅ AndroidManifest.xml has correct configChanges"
else
    echo "❌ AndroidManifest.xml configChanges incorrect"
    exit 1
fi
echo

# Check 3: Verify LaunchTheme is defined in styles.xml
echo "📋 Checking LaunchTheme in styles.xml..."
if grep -q "<style name=\"LaunchTheme\"" app/src/main/res/values/styles.xml; then
    echo "✅ LaunchTheme is defined in styles.xml"
else
    echo "❌ LaunchTheme NOT found in styles.xml"
    exit 1
fi
echo

# Check 4: Verify mipmap directories exist
echo "📋 Checking mipmap directories..."
MIPMAP_DIR="app/src/main/res"
REQUIRED_DIRS=("hdpi" "mdpi" "xhdpi" "xxhdpi" "xxxhdpi" "anydpi-v26")

missing_dirs=()
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$MIPMAP_DIR/mipmap-${dir}" ]; then
        missing_dirs+=("$dir")
    fi
done

if [ ${#missing_dirs[@]} -eq 0 ]; then
    echo "✅ All required mipmap directories exist"
else
    echo "❌ Missing mipmap directories: ${missing_dirs[*]}"
    exit 1
fi
echo

# Check 5: Verify ic_launcher.png exists
echo "📋 Checking ic_launcher.png files..."
launcher_files=$(find "$MIPMAP_DIR" -name "ic_launcher.png" | wc -l)
if [ "$launcher_files" -gt 0 ]; then
    echo "✅ Found $launcher_files ic_launcher.png files"
else
    echo "❌ No ic_launcher.png files found"
    exit 1
fi
echo

# Check 6: Verify ic_launcher_round.png exists
echo "📋 Checking ic_launcher_round.png files..."
round_files=$(find "$MIPMAP_DIR" -name "ic_launcher_round.png" | wc -l)
if [ "$round_files" -gt 0 ]; then
    echo "✅ Found $round_files ic_launcher_round.png files"
else
    echo "❌ No ic_launcher_round.png files found"
    exit 1
fi
echo

echo "🎉 All verification checks passed!"
echo

echo "=== Summary ==="
echo "The following fixes have been successfully applied:"
echo "1. ✅ Added suppression flags to gradle.properties"
echo "2. ✅ Fixed AndroidManifest.xml configChanges attribute"
echo "3. ✅ Added LaunchTheme to styles.xml"
echo "4. ✅ Verified all mipmap directories exist"
echo "5. ✅ Verified icon files exist"
echo
echo "The Android build should now succeed! 🚀"