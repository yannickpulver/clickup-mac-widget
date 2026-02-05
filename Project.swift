import ProjectDescription

let project = Project(
    name: "ClickUpWidget",
    targets: [
        .target(
            name: "ClickUpWidget",
            destinations: .macOS,
            product: .app,
            bundleId: "com.clickup.widget",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "NSPrincipalClass": "",
                "CFBundleURLTypes": [
                    [
                        "CFBundleURLSchemes": ["clickupwidget"],
                        "CFBundleURLName": "ClickUp Widget OAuth"
                    ]
                ]
            ]),
            sources: ["ClickUpWidget/**"],
            resources: [],
            entitlements: .file(path: "ClickUpWidget/ClickUpWidget.entitlements"),
            dependencies: [
                .target(name: "Shared"),
                .target(name: "WidgetExtension"),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "337L47P9N7",
                    "CODE_SIGN_IDENTITY": "Apple Development",
                    "PROVISIONING_PROFILE_SPECIFIER": "",
                ]
            )
        ),
        .target(
            name: "WidgetExtension",
            destinations: .macOS,
            product: .extensionKitExtension,
            bundleId: "com.clickup.widget.WidgetExtension",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                ]
            ]),
            sources: ["WidgetExtension/**"],
            resources: [],
            entitlements: .file(path: "WidgetExtension/WidgetExtension.entitlements"),
            dependencies: [
                .target(name: "Shared"),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "337L47P9N7",
                    "CODE_SIGN_IDENTITY": "Apple Development",
                ]
            )
        ),
        .target(
            name: "Shared",
            destinations: .macOS,
            product: .framework,
            bundleId: "com.clickup.widget.Shared",
            deploymentTargets: .macOS("14.0"),
            sources: ["Shared/**"],
            resources: [],
            dependencies: []
        ),
    ]
)
