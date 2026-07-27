import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/widgets/widgets.dart';

void main() {
  const email = 'divaibhavyanshu@gmail.com';

  /// Captures whatever the widget hands to the platform clipboard channel.
  List<String> mockClipboard(WidgetTester tester) {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    return copied;
  }

  Widget host(Widget child) => MaterialApp(
        home: Scaffold(body: SelectionArea(child: child)),
      );

  testWidgets('copy button puts the raw value on the clipboard', (tester) async {
    final copied = mockClipboard(tester);

    await tester.pumpWidget(host(
      const ContactLine(
        icon: Icons.email_outlined,
        text: email,
        label: 'Email',
        copyText: email,
      ),
    ));

    expect(find.text(email), findsOneWidget);

    await tester.tap(find.byIcon(Icons.copy_rounded));
    await tester.pump();

    expect(copied, [email]);

    // Let the "copied" timer and the SnackBar expire so no timers leak.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('copies the dialable number, not the display text',
      (tester) async {
    final copied = mockClipboard(tester);

    await tester.pumpWidget(host(
      const ContactLine(
        icon: Icons.phone_outlined,
        text: '+91 9576671336',
        label: 'Phone number',
        copyText: '+919576671336',
      ),
    ));

    await tester.tap(find.byIcon(Icons.copy_rounded));
    await tester.pump();

    expect(copied, ['+919576671336']);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('rows without a copyText show no copy button', (tester) async {
    await tester.pumpWidget(host(
      const ContactLine(
        icon: Icons.school_outlined,
        text: 'B.E. Electronics & Communication',
        label: 'Education',
      ),
    ));

    expect(find.byIcon(Icons.copy_rounded), findsNothing);
    expect(find.text('B.E. Electronics & Communication'), findsOneWidget);
  });

  testWidgets('contact text sits under a SelectionArea so it can be dragged',
      (tester) async {
    await tester.pumpWidget(host(
      const ContactLine(
        icon: Icons.email_outlined,
        text: email,
        label: 'Email',
        copyText: email,
      ),
    ));

    // A Text is only drag-selectable if a SelectionArea encloses it.
    expect(
      find.ancestor(
        of: find.text(email),
        matching: find.byType(SelectionArea),
      ),
      findsOneWidget,
    );
  });
}
