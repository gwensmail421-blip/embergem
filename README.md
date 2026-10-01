# Embergem

A calm, dark-gem block puzzle. Fill rows and columns to claim the gems a sleeping dragon wants; no timers and no game over.

## Layout

- `game/embergem.html` is the whole game in one file. It is also what the preview Artifact publishes.
- `scripts/build-web.js` wraps it into `www/index.html` for the app (full document, notch-safe viewport, local fonts in `www/fonts`).
- `ios/` is the Capacitor iPhone project (iPhone only, portrait). Native haptics come from `@capacitor/haptics`.
- `assets/` holds the 1024px icon and splash; `scripts/icon.html` draws the icon.

## Shipping to TestFlight

Every push to `main` that touches the game or the iOS project runs `.github/workflows/testflight.yml` on a GitHub macOS runner, which archives, signs automatically and uploads the build to App Store Connect. It can also be started by hand from the Actions tab.

The repository needs these Actions secrets:

| Secret | Where it comes from |
|---|---|
| `ASC_KEY_ID` | App Store Connect > Users and Access > Integrations > App Store Connect API |
| `ASC_ISSUER_ID` | Same page, above the key list |
| `ASC_KEY_P8` | The downloaded `.p8` file, pasted whole |
| `APPLE_TEAM_ID` | developer.apple.com > Account > Membership details |

The key needs the Admin role so Xcode can create the distribution certificate in the cloud.

## Fonts

Cormorant Garamond and Marcellus SC are bundled from Google Fonts under the SIL Open Font License 1.1.
