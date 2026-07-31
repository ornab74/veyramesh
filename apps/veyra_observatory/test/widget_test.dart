// SPDX-License-Identifier: GPL-3.0-only

import 'package:flutter_test/flutter_test.dart';
import 'package:veyra_observatory/veyra_observatory.dart';

void main() {
  testWidgets('observatory exposes research purpose and metrics', (WidgetTester tester) async {
    await tester.pumpWidget(const VeyraObservatoryApp());
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('VEYRAMESH OBSERVATORY'), findsOneWidget);
    expect(find.text('STUDY OVERVIEW'), findsOneWidget);
    expect(find.text('Add cohort'), findsOneWidget);
  });
}
