import 'package:block_test/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Agora call screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Agora Video Call'), findsOneWidget);
    expect(find.text('Join call'), findsOneWidget);
    expect(find.text('Agora App ID'), findsOneWidget);
  });
}
