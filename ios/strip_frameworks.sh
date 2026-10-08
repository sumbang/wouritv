#!/bin/bash

# This script strips invalid architectures from embedded frameworks
# Usage: Add as a "Run Script" build phase in Xcode

set -e  # Exit on error
set -u  # Exit on undefined variable

APP_PATH="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"

echo "Stripping frameworks in: $APP_PATH"

# Check if APP_PATH exists
if [ ! -d "$APP_PATH" ]; then
    echo "App path does not exist: $APP_PATH"
    exit 0
fi

# This script loops through the frameworks embedded in the application and
# removes unused architectures.
find "$APP_PATH" -name '*.framework' -type d 2>/dev/null | while read -r FRAMEWORK
do
    # Check if Info.plist exists
    if [ ! -f "$FRAMEWORK/Info.plist" ]; then
        echo "Skipping $FRAMEWORK (no Info.plist)"
        continue
    fi

    FRAMEWORK_EXECUTABLE_NAME=$(defaults read "$FRAMEWORK/Info.plist" CFBundleExecutable 2>/dev/null || echo "")
    
    if [ -z "$FRAMEWORK_EXECUTABLE_NAME" ]; then
        echo "Skipping $FRAMEWORK (no executable name in Info.plist)"
        continue
    fi
    
    FRAMEWORK_EXECUTABLE_PATH="$FRAMEWORK/$FRAMEWORK_EXECUTABLE_NAME"
    
    # Check if executable exists
    if [ ! -f "$FRAMEWORK_EXECUTABLE_PATH" ]; then
        echo "Skipping $FRAMEWORK (executable not found: $FRAMEWORK_EXECUTABLE_PATH)"
        continue
    fi
    
    echo "Processing: $FRAMEWORK_EXECUTABLE_PATH"

    # Get current architectures
    CURRENT_ARCHS=$(lipo -info "$FRAMEWORK_EXECUTABLE_PATH" 2>/dev/null | awk '{print $NF}' || echo "")
    
    if [ -z "$CURRENT_ARCHS" ]; then
        echo "Skipping $FRAMEWORK (cannot read architectures)"
        continue
    fi
    
    echo "Current architectures: $CURRENT_ARCHS"
    echo "Target architectures: ${ARCHS}"
    
    EXTRACTED_ARCHS=()
    
    for ARCH in $ARCHS
    do
        # Check if this architecture exists in the framework
        if lipo -info "$FRAMEWORK_EXECUTABLE_PATH" 2>/dev/null | grep -q "$ARCH"; then
            echo "Extracting $ARCH from $FRAMEWORK_EXECUTABLE_NAME"
            lipo -extract "$ARCH" "$FRAMEWORK_EXECUTABLE_PATH" -o "$FRAMEWORK_EXECUTABLE_PATH-$ARCH" 2>/dev/null || {
                echo "Failed to extract $ARCH, skipping..."
                continue
            }
            EXTRACTED_ARCHS+=("$FRAMEWORK_EXECUTABLE_PATH-$ARCH")
        else
            echo "Architecture $ARCH not found in $FRAMEWORK_EXECUTABLE_NAME, skipping..."
        fi
    done

    # Only proceed if we extracted at least one architecture
    if [ ${#EXTRACTED_ARCHS[@]} -eq 0 ]; then
        echo "No architectures extracted for $FRAMEWORK_EXECUTABLE_NAME, skipping..."
        continue
    fi

    echo "Merging extracted architectures: ${EXTRACTED_ARCHS[@]}"
    lipo -o "$FRAMEWORK_EXECUTABLE_PATH-merged" -create "${EXTRACTED_ARCHS[@]}" || {
        echo "Failed to create merged binary, cleaning up..."
        rm -f "${EXTRACTED_ARCHS[@]}"
        continue
    }
    
    # Clean up extracted files
    rm -f "${EXTRACTED_ARCHS[@]}"

    echo "Replacing original executable with thinned version"
    rm -f "$FRAMEWORK_EXECUTABLE_PATH"
    mv "$FRAMEWORK_EXECUTABLE_PATH-merged" "$FRAMEWORK_EXECUTABLE_PATH" || {
        echo "Failed to replace executable for $FRAMEWORK_EXECUTABLE_NAME"
        exit 1
    }
    
    echo "Successfully processed $FRAMEWORK_EXECUTABLE_NAME"
done

echo "Strip frameworks completed successfully"
