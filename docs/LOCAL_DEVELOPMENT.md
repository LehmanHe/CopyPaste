# Local Development Guide

## Prerequisites

- **macOS 14.0 (Sonoma)** or later
- **Xcode 15+** installed from the App Store
- Set the active developer directory to Xcode:
  ```bash
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  ```

## Method 1: Xcode (Recommended)

1. Open the project:
   ```bash
   open CopyPaste.xcodeproj
   ```

2. **Configure code signing** (first time only):
   - Select the **CopyPaste** target in the project navigator
   - Go to **Signing & Capabilities**
   - Change **Team** to your personal Apple Developer account (free account works)
   - Set **Signing Certificate** to "Sign to Run Locally"
   - If needed, change the **Bundle Identifier** to something unique (e.g., `com.yourname.CopyPaste`)

3. Select the **CopyPaste** scheme and **My Mac** as the destination

4. Press **Cmd+R** to build and run

5. The app will appear as a menu bar icon (scissors icon). Click it or use the global shortcut to open the clipboard panel.

## Method 2: Command Line

### Build

```bash
./scripts/build.sh          # Debug build (default)
./scripts/build.sh Release  # Release build
```

### Run

```bash
./scripts/run.sh
```

This will build (if needed) and launch the app.

## Notes

### App Sandbox

The app uses App Sandbox by default. For local development, you may want to temporarily disable it:

1. In Xcode, select the **CopyPaste** target
2. Go to **Signing & Capabilities**
3. Remove the **App Sandbox** capability (or uncheck its sub-permissions)

This avoids permission issues during local testing.

### Accessibility Permission

CopyPaste needs Accessibility permission to paste items (it simulates Cmd+V). When running a development build:

1. Go to **System Settings > Privacy & Security > Accessibility**
2. Add your development build of CopyPaste.app (or Xcode if running from Xcode)
3. Toggle it on

### Testing

Run the test suite from Xcode (Cmd+U) or from the command line:

```bash
xcodebuild -scheme CopyPaste -configuration Debug \
    -destination 'platform=macOS' \
    test
```

The test plan (`CopyPaste.xctestplan`) passes `enable-testing` to use an in-memory database instead of the on-disk SQLite store.

### Global Shortcut

The default shortcut to open CopyPaste is **Cmd+Shift+C** (configurable in Preferences). The clipboard panel will appear at the bottom of the screen in a horizontal card layout.
