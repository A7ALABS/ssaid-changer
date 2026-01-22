# SSAID Changer

A one-page Flutter app for rooted Android devices that lets you browse installed apps, read their SSAID (device ID) from `settings_ssaid.xml`, and update it on demand.

<p align="center">
  <img src="screenshots/redroid11_x86_64%201_21_2026%2C%204_30_20%20PM.png" width="220" />
  <img src="screenshots/redroid11_x86_64%201_21_2026%2C%204_30_55%20PM.png" width="220" />
  <img src="screenshots/redroid11_x86_64%201_21_2026%2C%204_31_14%20PM.png" width="220" />
  <img src="screenshots/redroid11_x86_64%201_21_2026%2C%204_31_26%20PM.png" width="220" />
  <img src="screenshots/redroid11_x86_64%201_21_2026%2C%204_30_41%20PM.png" width="220" />
</p>

---

## Install and use the app directly

- Download the latest APK from GitHub Releases: <https://github.com/A7ALABS/ssaid-changer/releases>
- Install it on a rooted Android device (allow unknown sources if needed).

---

## Features

- List and search installed apps (including system apps).
- Read SSAID entries per package.
- Update SSAID values with validation (16 hex chars).
- Random SSAID generator.
- Handles Android 11 and below (plain XML) and Android 12+ (ABX) formats.
- Clear status messages for missing ABX tools.

---

## How It Works

- The app reads `/data/system/users/0/settings_ssaid.xml` with root.
- For Android 12+, it converts ABX to XML using `abx2xml`, patches values, then converts back with `xml2abx`.
- For Android 11 and below, it edits the XML directly.
- The SSAID entry is matched by `package="<package-name>"` and updated in-place.

---

## Develop the app on your machine

### Requirements

- Rooted Android device or emulator.
- Android 11 and below: `settings_ssaid.xml` is plain XML.
- Android 12+: `abx2xml` and `xml2abx` must be available on-device.
- Flutter SDK installed on your machine.

---

## Project Structure

```
.
├── android/
│   └── app/
│       └── src/main/AndroidManifest.xml
├── lib/
│   └── main.dart
├── test/
│   └── widget_test.dart
├── patch_device_id.sh
├── pubspec.yaml
└── README.md
```

---

### Usage

1. Ensure your device is rooted.
2. (Android 12+) Install `abx2xml` and `xml2abx` on the device.
3. Run the app:

   ```bash
   flutter pub get
   flutter run
   ```

4. Select an app from the list.
5. Tap "Refresh SSAID" to read the current value.
6. Enter a new 16-char hex SSAID or use "Randomize".
7. Tap "Update SSAID" and restart the target app.

---

## Notes

- The SSAID entry may not exist until the app is launched at least once.
- Incorrect edits can break app behavior; proceed carefully.

---

## Behind the scenes

The app mirrors the workflow in `patch_device_id.sh` for reading and patching
`/data/system/users/0/settings_ssaid.xml`. On Android 12+ it converts ABX to XML
with `abx2xml`, updates only the selected package row, then writes back with
`xml2abx` and restores permissions. On Android 11 and below, the file is plain
XML and the app edits it directly. This keeps behavior consistent with the
script while adding a UI for selecting apps and updating SSAIDs.

---

## Denial of responsibility
Anything you do is at your own risk. No one else is responsible for any data loss, corruption, or damage to your device, including that which results from bugs in this software. There is a nonzero chance of any of these events happening due to using the tools or methods here. Always make backups.

---

## License

MIT
