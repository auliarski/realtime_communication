# realtime_comm

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Praktikum 8 - Firebase Cloud Messaging

Open **Praktikum 8 - Firebase Cloud Messaging** in the app, allow notifications,
and register the device. The screen displays the Firebase Installation ID (FID),
which can be copied as the direct-send target, and shows messages received while
the app is open or opened from a notification. Keep the emulator connected to
the internet and use the Firebase project configured for this app.

When testing a campaign in Firebase Console, select the FID currently shown in
Praktikum 8 (not an older ID left in the console's recent-device list). Foreground
messages appear both in the Android notification tray and in the Praktikum 8
message list.

## Praktikum 6 - WebRTC in Chrome

Start the signaling server from the project root with `node server/server.js`,
then run the Flutter app in Chrome with `flutter run -d chrome`. Open Praktikum 6
in two Chrome tabs (or two devices that can reach the same server), enter the
same Room ID, and choose Caller in one tab and Callee in the other. Allow camera
and microphone access when Chrome asks. The app uses the browser's current host
to connect to the signaling server on port 3000.

Camera and microphone access requires localhost or a secure HTTPS origin.
Connections across restrictive networks may also require a TURN server; this
demo configures a public STUN server only.
