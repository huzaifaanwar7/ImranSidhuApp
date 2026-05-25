# Imran Sidhu Memorial VCC — Flutter Frontend

A premium cricket scoring & management Flutter app, built screen-for-screen to
the **App Design Proposal v2.0** prototype:

- Cream + navy + gold + ball-red editorial palette
- Fraunces (italic accents) · DM Sans (body) · Bebas Neue (scores/buttons) ·
  JetBrains Mono (labels)
- Flat colored team-flag tiles
- Sponsor strips through every key screen

Data layer is currently a mock provider (`lib/data/mock_data.dart`). Wire the
real .NET 8 API client per the SRS once the backend lands.

---

## Quick start

```bash
# inside this folder
flutter create .            # generates android/, ios/, etc.
flutter pub get
flutter run                 # pick a device
```

Requires **Flutter 3.27+** (uses `Color.withValues`, `TabBarThemeData`,
`CardThemeData`, `surfaceContainerHighest`).

The PNG logos (VCC roundel, Amas, PM Sports Hosiery) are stubbed with a
generated mark in `AppLogo`. Drop the real PNGs into `assets/logos/` and
uncomment the `assets:` block in `pubspec.yaml` to use them.

---

## Screens (all 12 from the prototype + extras)

| # | Screen | File |
|---|--------|------|
| 1 | Splash & Branding | `features/splash/splash_screen.dart` |
| 2 | Home Dashboard | `features/home/dashboard_screen.dart` |
| 3 | Teams Directory | `features/teams/teams_list_screen.dart` |
| 4 | Match Setup (with inline toss) | `features/matches/match_setup_screen.dart` |
| 5 | Live Ball-by-Ball Scoring | `features/matches/live_scoring_screen.dart` |
| 6 | Detailed Scorecard | `features/matches/match_detail_screen.dart` (Scorecard tab) |
| 7 | Ball-by-Ball Commentary | `features/matches/match_detail_screen.dart` (Commentary tab) |
| 8 | Player Profile | `features/players/player_profile_screen.dart` |
| 9 | Detailed Player Stats | `features/statistics/statistics_hub_screen.dart` |
| 10 | Tournament Hub | `features/tournaments/tournament_detail_screen.dart` |
| 11 | Points Table | `features/tournaments/tournament_detail_screen.dart` (Table tab) |
| 12 | Add / Edit Player | `features/players/add_player_screen.dart` |

### Bonus screens (not in prototype, added per SRS)

- Onboarding (4 slides)
- Login / Register / OTP Verify / Forgot Password
- Toss (standalone, animated coin)
- Playing XI picker
- Match detail (Info / Stats tabs)
- Matches list (Live / Upcoming / Completed tabs)
- Players list
- Team detail (Overview / Squad / Matches / Stats)
- Tournaments list
- Notifications feed
- Sponsors (slot-based management)
- Global search (teams / players / matches)
- Profile / Settings

### Bottom navigation (4 tabs per prototype)

`Home · Teams · Tourneys · Profile` — accessed via `HomeShell` with a gold
underline indicator. Matches & Stats are reached from the Home dashboard.

---

## Design system

`lib/core/theme/`
- `app_colors.dart` — navy `#0F2447`, gold `#D4A845`, ball red `#C8202C`,
  cream `#F7F2E6`, line `#E3DCC8`, sponsor accents, run-outcome palette.
- `app_text_styles.dart` — typed helpers `fraunces()`, `dm()`, `bebas()`,
  `mono()`, plus named slots (`displayLarge`, `headlineMedium`, …) and an
  `italicAccent()` helper for the prototype's gold italic word style.
- `app_theme.dart` — Material 3 theme tying it all together.

`lib/core/widgets/`
- `team_badge.dart` — flat rounded-square flag tile (8 palettes).
- `sponsor_banner.dart` — cream-gradient in-app strip with slot label.
- `match_card.dart` — meta · status · two team rows · italic red result line.
- `live_pill.dart` — pulsing red LIVE pill.
- `app_logo.dart` — placeholder roundel.
- `app_top_bar.dart` — top bar + `IconBtn` + reusable `BackBar`.
- `section_header.dart` — `Title + italic accent + → action` header pattern.
- `primary_button.dart` — Bebas Neue all-caps red CTA.

---

## File layout

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── theme/        app_colors · app_theme · app_text_styles
│   ├── constants/    app_assets · app_strings
│   ├── router/       app_router (go_router)
│   └── widgets/      app_logo · team_badge · match_card · sponsor_banner
│                     live_pill · primary_button · section_header · app_top_bar
├── models/           user · player · team · match · innings · ball
│                     commentary · tournament · sponsor · notification · enums
├── data/             mock_data
└── features/
    ├── splash/
    ├── onboarding/
    ├── auth/         login · register · otp · forgot
    ├── home/         dashboard · home_shell
    ├── matches/      list · detail · setup · toss · playing_xi · live_scoring
    ├── teams/        list · detail
    ├── players/      list · profile · add (new!)
    ├── tournaments/  list · detail (fixtures / table / brackets / leaders)
    ├── statistics/   hub (career stats deep-dive)
    ├── notifications/
    ├── sponsors/
    ├── profile/
    └── search/
```

---

## Deferred for the backend phase

- API client (Dio/http) — currently mocked
- SignalR live updates — placeholders shown via static "this over" strip
- WhatsApp share + PNG/PDF export — buttons present, integration pending
- Offline sync queue — model + FR documented, integration pending
- Photo upload (image_picker is pulled but not wired)
