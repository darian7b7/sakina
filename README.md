# Sakina

Quran reminders by category. Choose the categories and times you want, and Sakina sends a verse with its translation at those times. It works fully offline, with no account and no server.

## Run

Flutter is installed in `~/flutter`. Add it to your PATH once:

```bash
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

**In the browser (Chromium):**

```bash
cd ~/sakina
CHROME_EXECUTABLE=/usr/bin/chromium flutter run -d chrome
```

In the browser you can test everything except delivery of scheduled reminders, which only works on a phone. The test notification does work in the browser.

**Tests:**

```bash
flutter test                    # Dart VM
flutter test --platform chrome  # same tests in the browser
```

**On an Android phone:** install Android Studio (it brings the Android SDK), enable USB debugging on the phone, connect it, then run `flutter run`. To make an installable file, run `flutter build apk`.

## Verses

The full Quran is in `data/quran/quran.json`: all 6,236 verses in Arabic (Uthmani script), English (Saheeh International) and German (Bubenheim & Elyas), downloaded from the quran.com API. Footnote markers were removed; the text is otherwise unchanged.

**Choosing verses:** edit `data/selection.json`. It lists the categories and, for each one, the verse references:

```json
{ "id": "hope", "name": { "de": "Hoffnung", "en": "Hope" }, "verses": ["2:214", "39:53", "94:5-6"] }
```

Then build the app's content file:

```bash
dart run tool/build_content.dart
```

This writes `assets/ayat.json` with only the selected verses (Arabic, German and English), so the app stays small.

- **Several categories:** a verse can be listed in more than one, e.g. 39:53 is in Mercy, Forgiveness and Hope.
- **Ranges:** like `94:5-6` become separate verses.
- **New category:** add an entry. No code change is needed.
- **Typos:** a reference that doesn't exist stops the build with a clear error, e.g. `verse 2:999 does not exist`.

After rebuilding the content, restart the app (in `flutter run`, press `R`).

**Copyright:** the Arabic text may be used freely. The translations are copyrighted by their publishers, so for a paid app, get permission or switch to an openly licensed translation.

## How reminders work

- **When:** you choose times of day and weekdays. The next 7 days are scheduled in advance (at most 60 reminders, because iOS allows 64), and the plan is topped up whenever the app is opened.
- **Which verse:** each round shows every verse from your categories once, in shuffled order, and the same verse never comes twice in a row. Replanning continues the same order, so nothing is skipped or repeated.
- **Opening a reminder:** tapping it opens that verse. Opening the app normally shows the latest delivered reminder.
- **Timing:** delivery is "inexact", so a reminder can arrive a few minutes late. In return, Android doesn't require the special exact-alarm permission.

## Structure

| File | Purpose |
|---|---|
| `data/quran/quran.json` | Full Quran: Arabic, English, German (source) |
| `data/selection.json` | Which verses belong to which category |
| `tool/build_content.dart` | Builds `assets/ayat.json` from the two files above |
| `lib/core/content.dart` | Reads and checks `assets/ayat.json` |
| `lib/core/schedule.dart` | Reminder times (DST-safe), verse order, plan. Pure Dart, unit-tested |
| `lib/core/strings.dart` | German/English interface texts |
| `lib/state.dart` | Settings, saved verses, reminder plan, stored on the device |
| `lib/notifications.dart` | The only file that talks to the notification plugin |
| `lib/ui/` | Today, Categories, Saved, Settings |

Packages: `flutter_local_notifications`, `timezone`, `flutter_timezone`, `shared_preferences`, `share_plus`.

## License

The code is under the [MIT License](LICENSE). The data keeps its own licence (see the sources above).
