# 📚 讀書計畫 — Taiwan High School Study Planner

A cross-platform Flutter app for Taiwan junior and senior high school students to manage their study schedule, to-do list, calendar events, and weekly progress — all stored locally on-device with no account required.

> 適合國中、高中生使用的讀書計畫 + 行事曆 App，支援 Android、iOS、Web 與 macOS。

---

## ✨ Features

### 今日 (Today)
- Date header with day-of-week display
- Horizontal week strip — tap any day to switch
- Per-subject to-do items with **weekday recurrence** (e.g. 複習單字 every 一三五)
- Per-subject study sessions with start time and duration
- Tap to check off items; swipe left to delete
- Dot indicator on days that have scheduled items

### 行事曆 (Calendar)
- Full monthly calendar view (Chinese locale, week starts Sunday)
- Pre-loaded **Taiwan 2025–2026 school calendar**:
  - National holidays (春節、清明、端午、中秋、國慶 …)
  - Semester start/end dates
  - Mid-term and final exam periods
- Add personal events: 考試、假日、學校活動、個人
- Tap any day to see sessions and events below the calendar

### 讀書計畫 (Weekly Plan)
- Week-by-week view (Mon → Sun)
- Add study sessions to any day with subject, time, and duration
- Swipe to delete; tap checkbox to mark complete
- Navigate between weeks with prev / next arrows

### 進度 (Progress)
- Weekly study hours summary card
- Pie chart breakdown by subject
- Per-subject linear progress bar vs. weekly goal
- Navigate between weeks to review history

### 科目 (Subjects)
- Create, edit, and delete subjects
- Choose from a 10-colour palette
- Set weekly study minute goals per subject

---

## 📱 Platforms

| Platform | Status |
|----------|--------|
| Android  | ✅ Supported |
| iOS      | ✅ Supported |
| Web      | ✅ Supported |
| macOS    | ✅ Supported |

---

## 🏗️ Tech Stack

| Layer | Library |
|-------|---------|
| UI framework | [Flutter 3.44](https://flutter.dev) |
| State management | [Provider](https://pub.dev/packages/provider) |
| Local storage | [Hive](https://pub.dev/packages/hive) + [hive_flutter](https://pub.dev/packages/hive_flutter) |
| Calendar widget | [table_calendar](https://pub.dev/packages/table_calendar) |
| Charts | [fl_chart](https://pub.dev/packages/fl_chart) |
| Localisation | [intl](https://pub.dev/packages/intl) (zh_TW) |

All data is stored **locally on the device** — no backend, no account, no internet required.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0 ([install guide](https://docs.flutter.dev/get-started/install))
- For Android: Android SDK / Android Studio
- For iOS/macOS: Xcode 14+

### Run locally

```bash
git clone https://github.com/wapert/study_planner.git
cd study_planner
flutter pub get
flutter run
```

### Build release APK (Android)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build for Web

```bash
flutter build web --release
# Output: build/web/
```

---

## 📂 Project Structure

```
lib/
├── main.dart                    # App entry, Hive init, locale setup
├── models/
│   ├── subject.dart             # Subject (name, colour, weekly goal)
│   ├── study_session.dart       # Timed study block on a specific date
│   ├── calendar_event.dart      # Calendar event (exam, holiday, etc.)
│   └── todo_item.dart           # Recurring to-do with weekday assignment
├── providers/
│   └── app_provider.dart        # Single ChangeNotifier — all CRUD & stats
├── screens/
│   ├── today_screen.dart        # 今日 tab (YPT-style day view)
│   ├── calendar_screen.dart     # 行事曆 tab
│   ├── plan_screen.dart         # 讀書計畫 weekly tab
│   ├── progress_screen.dart     # 進度 tab
│   ├── subjects_screen.dart     # 科目 management
│   └── home_screen.dart         # Bottom navigation shell
├── widgets/
│   ├── session_tile.dart        # Dismissible study session row
│   └── event_chip.dart          # Coloured event badge
├── data/
│   └── taiwan_calendar.dart     # 2025-2026 holidays & school events
└── utils/
    └── date_utils.dart          # Date helpers & formatting
```

---

## 🗓️ Pre-loaded Taiwan School Calendar (2025–2026)

| Event | Date |
|-------|------|
| 上學期開學 | 2025-09-01 |
| 第一次期中考 | 2025-10-20 – 22 |
| 第一次期末考 | 2026-01-05 – 07 |
| 寒假 | 2026-01-22 – 02-23 |
| 下學期開學 | 2026-02-24 |
| 第二次期中考 | 2026-04-13 – 15 |
| 第二次期末考 | 2026-06-08 – 10 |
| 暑假 | 2026-06-27 起 |

Plus all national holidays (春節、228、清明、兒童節、端午、中秋、國慶 …).

---

## 📄 License

MIT © 2026 [wapert](https://github.com/wapert)
