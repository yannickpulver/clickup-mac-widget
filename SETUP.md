# ClickUp macOS Widget - Project Setup

## Project Structure

```
clickup-mac-widget/
├── ClickUpWidget/               # Main app target
│   ├── ClickUpWidgetApp.swift   # App entry point
│   ├── ContentView.swift        # Settings UI
│   ├── ClickUpModels.swift      # Data models
│   ├── ClickUpService.swift     # API service
│   └── ClickUpWidget.entitlements
├── WidgetExtension/             # Widget target
│   ├── WidgetExtensionBundle.swift
│   ├── Provider.swift           # Timeline provider
│   ├── TaskTimelineProvider.swift
│   ├── TaskWidgetView.swift
│   ├── WidgetExtension.swift
│   └── WidgetExtension.entitlements
├── Shared/                      # Shared code
│   ├── ClickUpAPI.swift         # API client
│   ├── AppStorage.swift
│   ├── KeychainHelper.swift
│   └── Task.swift
├── Project.swift                # Tuist project definition
├── Tuist/
│   └── Config.swift
└── .gitignore
```

## Setup Instructions

### Prerequisites
- Xcode 15+
- Tuist (install: `brew install tuist`)
- macOS 14.0+

### Generate Xcode Project

```bash
tuist install
tuist generate
```

### Build Configuration

Both targets configured for:
- **Deployment Target**: macOS 14.0
- **App Groups**: `group.com.clickup.widget` (for shared data between app and widget)
- **Entitlements**: Network access, keychain sharing

### Targets

#### ClickUpWidget (App)
- SwiftUI app for configuration
- API key input and storage
- Connection testing
- Workspace selection

#### WidgetExtension (Widget)
- macOS widget displaying tasks
- 15-minute refresh interval
- Supports small and medium sizes

#### Shared (Framework)
- `ClickUpAPI`: API client with singleton pattern
- Data models and helpers
- Shared between app and widget via App Groups

## Key Features

- API key stored in UserDefaults with App Groups container
- Test connection button validates ClickUp API access
- Clean SwiftUI interface
- Widget updates every 15 minutes

## Next Steps

1. Set development team ID in `Project.swift`
2. Add your ClickUp API key in the app settings
3. Configure workspace selection
4. Test widget functionality on macOS desktop
