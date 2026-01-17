// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:booru_app/main.dart';
import 'package:booru_app/widgets/download_overlay.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const BooruApp());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(DownloadOverlay), findsOneWidget);
  });
}
