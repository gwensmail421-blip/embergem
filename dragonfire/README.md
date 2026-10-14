# Dragonfire

A calm light puzzle. Dragons breathe fire into a stone chamber; turn the crystals so the fire bends through every gem socket. No timers and no game over.

## Layout

- `game/dragonfire.html` is the whole game in one file.
- `scripts/build-web.js` wraps it into `www/index.html` for the app (full document, notch-safe viewport, local fonts in `www/fonts`).
- `ios/` is the Capacitor iPhone project (bundle ID `com.asylummke.dragonfire`). The StoreKit and Game Center plugins in `ios/App/App/SceneDelegate.swift` are shared with Embergem.
- `assets/` holds the 1024px icon and splash; `scripts/icon.html` draws the icon (`node scripts/render-icon.js`, then `node scripts/render-splash.js`).

## IDs

| What | ID |
|---|---|
| Bundle ID | `com.asylummke.dragonfire` |
| Remove Ads purchase | `com.asylummke.dragonfire.removeads` |
| Leaderboards | `dragonfire.chambers`, `dragonfire.daily`, `dragonfire.endless` |
| AdMob | Google's test IDs until Dragonfire's AdMob app exists: replace `ADS` in the game and `GADApplicationIdentifier` in `ios/App/App/Info.plist` |

## Shipping to TestFlight

`.github/workflows/dragonfire-testflight.yml` builds this folder on a GitHub macOS runner with the same App Store Connect API key secrets as Embergem.

## Fonts

Cormorant Garamond and Marcellus SC are bundled from Google Fonts under the SIL Open Font License 1.1.
