# SSAID Changer

A one-page Flutter app for rooted Android devices that lets you browse installed apps, read their SSAID (device ID) from `settings_ssaid.xml`, and update it on demand.

## Features

- List and search installed apps (including system apps).
- Read SSAID entries per package.
- Update SSAID values with validation (16 hex chars).
- Random SSAID generator.
- Handles Android 11 and below (plain XML) and Android 12+ (ABX) formats.
- Clear status messages for missing ABX tools.

## Requirements

- Rooted Android device or emulator.
- Android 11 and below: `settings_ssaid.xml` is plain XML.
- Android 12+: `abx2xml` and `xml2abx` must be available on-device.
- Flutter SDK installed on your machine.

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

## How It Works

- The app reads `/data/system/users/0/settings_ssaid.xml` with root.
- For Android 12+, it converts ABX to XML using `abx2xml`, patches values, then converts back with `xml2abx`.
- For Android 11 and below, it edits the XML directly.
- The SSAID entry is matched by `package="<package-name>"` and updated in-place.

## Usage

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

## Notes

- The SSAID entry may not exist until the app is launched at least once.
- Incorrect edits can break app behavior; proceed carefully.

## Behind the scenes

The app mirrors the workflow in `patch_device_id.sh` for reading and patching
`/data/system/users/0/settings_ssaid.xml`. On Android 12+ it converts ABX to XML
with `abx2xml`, updates only the selected package row, then writes back with
`xml2abx` and restores permissions. On Android 11 and below, the file is plain
XML and the app edits it directly. This keeps behavior consistent with the
script while adding a UI for selecting apps and updating SSAIDs.

## License

MIT
