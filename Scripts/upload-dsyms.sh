#!/bin/bash
# ============================================================================
# dSYM Upload Script for Firebase Crashlytics
# ============================================================================
#
# This script uploads dSYM files to Firebase Crashlytics for symbolication.
# Add this as a "Run Script" build phase in Xcode after "Embed Frameworks".
#
# SETUP INSTRUCTIONS:
# 1. In Xcode, select your target
# 2. Go to Build Phases
# 3. Click "+" and select "New Run Script Phase"
# 4. Name it "Upload dSYMs to Crashlytics"
# 5. Set the script to: "${SRCROOT}/Scripts/upload-dsyms.sh"
# 6. Add to "Input Files": ${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
# 7. Check "Run script only when installing" for faster debug builds
#
# REQUIREMENTS:
# - Firebase Crashlytics SDK added via SPM
# - GoogleService-Info.plist in the project
# ============================================================================

set -e

# Only run for Release builds or when archiving
if [ "${CONFIGURATION}" != "Release" ] && [ "${ACTION}" != "install" ]; then
    echo "Skipping dSYM upload for non-Release build"
    exit 0
fi

# Path to the upload script (installed with Firebase Crashlytics via SPM)
UPLOAD_SCRIPT="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/upload-symbols"

# Alternative path for CocoaPods
if [ ! -f "${UPLOAD_SCRIPT}" ]; then
    UPLOAD_SCRIPT="${PODS_ROOT}/FirebaseCrashlytics/upload-symbols"
fi

# Alternative path for manual installation
if [ ! -f "${UPLOAD_SCRIPT}" ]; then
    UPLOAD_SCRIPT="${SRCROOT}/Scripts/upload-symbols"
fi

# Check if upload script exists
if [ ! -f "${UPLOAD_SCRIPT}" ]; then
    echo "warning: Firebase Crashlytics upload-symbols script not found."
    echo "         dSYMs will not be uploaded automatically."
    echo "         Install Firebase Crashlytics to enable crash symbolication."
    exit 0
fi

# Path to GoogleService-Info.plist
GOOGLE_SERVICE_PLIST="${SRCROOT}/TinyWins/GoogleService-Info.plist"

# Alternative path
if [ ! -f "${GOOGLE_SERVICE_PLIST}" ]; then
    GOOGLE_SERVICE_PLIST="${SRCROOT}/GoogleService-Info.plist"
fi

# Check if plist exists
if [ ! -f "${GOOGLE_SERVICE_PLIST}" ]; then
    echo "warning: GoogleService-Info.plist not found. Skipping dSYM upload."
    exit 0
fi

# dSYM path
DSYM_PATH="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"

# Check if dSYM exists
if [ ! -d "${DSYM_PATH}" ]; then
    echo "warning: dSYM not found at ${DSYM_PATH}. Skipping upload."
    exit 0
fi

echo "Uploading dSYMs to Firebase Crashlytics..."
echo "  dSYM: ${DSYM_PATH}"

# Upload dSYMs
"${UPLOAD_SCRIPT}" \
    -gsp "${GOOGLE_SERVICE_PLIST}" \
    -p ios \
    "${DSYM_PATH}"

echo "dSYM upload completed successfully."
