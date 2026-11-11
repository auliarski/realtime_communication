// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:realtime_comm/main.dart';

void main() {
  testWidgets('Praktikum 7 button opens the gRPC sensor screen', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final praktikumButton = find.text('Praktikum 7 - gRPC');
    await tester.scrollUntilVisible(
      praktikumButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(praktikumButton);
    await tester.pumpAndSettle();

    expect(find.text('Monitoring Sensor'), findsOneWidget);
    expect(find.text('Ambil Data Terbaru'), findsOneWidget);
    expect(find.text('Mulai Streaming'), findsOneWidget);
  });

  testWidgets('Praktikum 8 button opens the Firebase screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    final praktikumButton = find.text('Praktikum 8 - Firebase Cloud Messaging');
    await tester.scrollUntilVisible(
      praktikumButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(praktikumButton);
    await tester.pumpAndSettle();

    expect(find.text('Praktikum 8 - Firebase FCM'), findsOneWidget);
    expect(find.text('Push Notification'), findsOneWidget);
    expect(find.text('Aktifkan & Daftarkan FCM'), findsOneWidget);
  });
}
