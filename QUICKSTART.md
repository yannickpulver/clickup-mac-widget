# Quick Start Guide

## 1. Generate Xcode Project

```bash
brew install tuist  # If not already installed
tuist install
tuist generate
```

## 2. Open in Xcode

```bash
open ClickUpWidget.xcworkspace
```

## 3. Configure Team ID

In Xcode:
1. Select "ClickUpWidget" project
2. Select "ClickUpWidget" target
3. Set Team ID under Signing & Capabilities

## 4. Build and Run

```bash
# Select ClickUpWidget scheme
# Press Cmd+R to build and run
```

## 5. Configure API Key

1. Get API key from: https://app.clickup.com/settings/integrations/api
2. Open ClickUp Widget app
3. Enter API key
4. Click "Test Connection"
5. Click "Save Settings"

## 6. Add Widget to Desktop

1. Right-click on macOS desktop
2. Click "Edit widgets..."
3. Search for "ClickUp Widget"
4. Click "+" to add

## Project Structure

- **ClickUpWidget/** - Main app with settings UI
- **WidgetExtension/** - Widget extension with task display
- **Shared/** - API client and shared code
- **Project.swift** - Tuist configuration

## Key Files

| File | Purpose |
|------|---------|
| `ClickUpWidgetApp.swift` | App entry point |
| `ContentView.swift` | Settings interface |
| `ClickUpAPI.swift` | API client (shared) |
| `WidgetExtensionBundle.swift` | Widget definition |
| `TaskTimelineProvider.swift` | Widget task fetching |

## Entitlements

Both targets have:
- App Groups: `group.com.clickup.widget`
- Network client access
- Sandbox security enabled

## Troubleshooting

**Widget not showing data?**
- Ensure API key is saved
- Check network connectivity
- Wait for 15-minute refresh cycle

**Build errors?**
- Run `tuist install` again
- Check Xcode version (need 15+)
- Verify Team ID is set

**API key not persisting?**
- Check App Groups entitlements
- Verify UserDefaults suite name matches
