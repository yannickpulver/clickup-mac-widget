# ClickUp Widget for macOS

A macOS widget that displays your assigned ClickUp tasks.

## Features

- Shows assigned tasks in a compact widget
- Click tasks to open in ClickUp
- Refresh button for manual updates
- Auto-refreshes every 15 minutes
- Secure OAuth authentication

## Setup

### 1. Create a ClickUp OAuth App

1. Go to [ClickUp Settings > Apps](https://app.clickup.com/settings/apps)
2. Click **Create an App**
3. Fill in:
   - **App Name:** `ClickUp Widget` (or any name)
   - **Redirect URL(s):** `clickupwidget://oauth/callback`
4. Click **Create App**
5. Copy the **Client ID** and **Client Secret**

### 2. Build the App

```bash
# Install tuist if needed
curl -Ls https://install.tuist.io | bash

# Generate Xcode project
tuist generate

# Build
xcodebuild -scheme ClickUpWidget -destination 'platform=macOS' -allowProvisioningUpdates build

# Copy to Applications
cp -R ~/Library/Developer/Xcode/DerivedData/ClickUpWidget-*/Build/Products/Debug/ClickUpWidget.app ~/Applications/
```

Or open in Xcode and build:

```bash
tuist generate
open ClickUpWidget.xcworkspace
```

### 3. Configure the App

1. Open **ClickUpWidget.app**
2. Enter your **Client ID** and **Client Secret**
3. Click **Save**
4. Click **Sign in with ClickUp**
5. Authorize the app in your browser

### 4. Add the Widget

1. Click the date/time in your menu bar (or right-click desktop)
2. Click **Edit Widgets**
3. Find **ClickUp** and add it

## Development

### Requirements

- macOS 14.0+
- Xcode 15+
- Tuist

### Project Structure

```
├── ClickUpWidget/       # Main app (OAuth setup UI)
├── WidgetExtension/     # Widget extension
├── Shared/              # Shared framework (API, models)
├── Project.swift        # Tuist configuration
└── README.md
```

### Building

```bash
tuist generate
xcodebuild -scheme ClickUpWidget -destination 'platform=macOS' -allowProvisioningUpdates build
```

## License

MIT
