# OneMart

SwiftUI prototype (iOS 16+) unifying Food, Rides, Logistics, Shop, and Community
marketplace into one app. UI/UX-focused — mock data, stubbed logic, no real
backend/networking/auth.

## Opening the project (macOS + Xcode required)

The `.xcodeproj` isn't committed — it's generated from [project.yml](project.yml)
via [XcodeGen](https://github.com/yonaskolb/XcodeGen) so the project file itself
never has merge conflicts.

```bash
brew install xcodegen
xcodegen generate
open OneMart.xcodeproj
```

Re-run `xcodegen generate` any time files are added/removed on disk (new files
are picked up automatically since sources are folder-referenced, but it's
cheap to re-run whenever the target/scheme config changes).

## Structure

```
OneMart/
  App/        — app entry point, root scene
  Theme/      — colors, typography, spacing, motion (Theme.swift)
  Models/     — plain data models (Restaurant, Product, Order, ...)
  MockData/   — realistic sample data powering every screen
  Views/      — one subfolder per tab (Home, Food, Rides, Logistics, Market) + Shared
  Components/ — reusable pieces (cards, chips, buttons) used across tabs
  Resources/  — Assets.xcassets (adaptive color sets), Info.plist (generated)
```

## Status

- [x] Folder structure, Theme, and core Models
- [ ] Home tab
- [ ] Food tab
- [ ] Rides tab
- [ ] Logistics tab
- [ ] Market tab
- [ ] Shared components, cart/checkout, profile/wallet, animations pass
