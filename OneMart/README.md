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

**Open `OneMart.xcodeproj` specifically** — not the repo folder, and not a loose
`.swift` file. Xcode only shows a Run button and a scheme picker once it has an
actual project to build; opening the folder or a single file gives you a plain
text editor with no build target, which is why the Run button looks
missing/greyed out on a fresh clone. `xcodegen generate` also writes a
*shared* scheme (`OneMart.xcodeproj/xcshareddata/xcschemes/OneMart.xcscheme`,
per the `schemes:` block in [project.yml](project.yml)), so the scheme and Run
button are there immediately — no "Manage Schemes" step needed.

Re-run `xcodegen generate` any time files are added/removed on disk (new files
are picked up automatically since sources are folder-referenced, but it's
cheap to re-run whenever the target/scheme config changes).

## Structure

```
OneMart/
  App/        — app entry point, root scene, AppState (single source of truth)
  Theme/      — colors, typography, spacing, motion (Theme.swift), formatters
  Models/     — plain data models (Restaurant, Product, Order, ...)
  MockData/   — realistic sample data powering every screen
  Views/      — one subfolder per tab (Home, Food, Rides, Logistics, Market) + Shared
  Components/ — reusable pieces (cards, chips, buttons) used across tabs
  Resources/  — Assets.xcassets (adaptive color sets + OneMartLogo), Info.plist
```

## Architecture

`AppState` (`App/AppState.swift`) is an `ObservableObject` owned by `OneMartApp`
with `@StateObject` and read everywhere via `@EnvironmentObject`. It holds the
navigation phase (splash → login/signup → main), the signed-in `UserProfile`,
the active tab, **two independent carts** (food and shop never merge), the
favourite id sets, the wallet balance + transaction ledger, the marketplace
message threads, the Community listings board (so a listing posted from the Sell
flow survives a tab switch), and the orders placed during this session (merged
with `MockOrders` behind `activityFeed` for Home).

Demo credentials: **user@gmail.com / password123**.

## Status

- [x] Folder structure, Theme, and core Models
- [x] Shared components, cart/checkout, profile/wallet, animations pass
- [x] Home tab
- [x] Food tab
- [x] Rides tab
- [x] Logistics tab
- [x] Market tab

All five tab experiences are built out. Highlights per tab:

- **Home** — promo hero carousel, quick-actions grid that switches
  `activeTab` (its Wallet tile deep-links into the wallet instead), a wallet
  card with both entry points working (Profile deep-link *and* the Top Up
  sheet), a "happening now" strip, and a cross-module activity feed.
- **Food** — live search + `FoodCategory` chips, full restaurant detail with a
  multi-section menu, add-to-cart with a bounce/"Added" confirmation, and a
  docked cart bar into the shared `CartView`.
- **Rides** — stylised route map, editable pickup/destination, per-vehicle fare
  and ETA that respond to the destination, and an
  idle → searching → driver-found → confirmed booking flow.
- **Send** — a four-step `LogisticsStep` flow with a progress indicator,
  **fully editable pickup and drop-off addresses**, a fare breakdown, and an
  animated tracking timeline.
- **Market** — Shop (live flash-deal countdown, category chips, product grid,
  full product detail) and Community (title search, category chips, listing
  detail, real "Message Seller" threads, and a full-screen Sell flow).

Everything the tabs share is finished and reused rather than rebuilt:

- `Components/AppShellHeader.swift` — profile, messages, and cart entry points.
  Drop it at the top of a tab and the cart sheet/badge wiring comes for free.
- `Components/CartView.swift` — one cart screen parameterised by `CartKind`,
  used for both Food and Shop checkout.
- `Components/PaymentMethodPicker.swift` — Cash on Delivery vs. wallet, with the
  insufficient-balance warning; pair it with `AppState.canPay(with:amount:)`.
  Rides and Send use it too, so every checkout in the app behaves identically.
- `Components/SearchField.swift`, `Components/FilterChip.swift` — the search
  input, filter chips, tag pills, rating labels, section headers, and empty
  states shared across Food and Market.
- `Views/Shared/WalletTopUpView.swift` — the top-up flow, reachable from Home,
  Profile, and every checkout's insufficient-balance warning.
- `Views/Shared/MessagesView.swift` / `MessageThreadView.swift` — marketplace
  chat, seeded from `MockData/MockMessages.swift` and extended by
  "Message Seller" on any Community listing.
