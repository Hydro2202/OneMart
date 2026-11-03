// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "OneMart",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "OneMart",
            targets: ["AppModule"],
            bundleIdentifier: "com.onemart.app.playground",
            teamIdentifier: nil,
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .asset("AccentColor"),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift")
            ],
            path: ".",
            exclude: [
                "Package.swift",
                "Supabase/SupabaseConfig.example.swift",
                "AI/GeminiSecrets.example.swift",
                "Resources/Info.plist"
            ]
        )
    ]
)
