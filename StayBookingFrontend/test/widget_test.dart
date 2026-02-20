import 'package:flutter_test/flutter_test.dart';

import 'package:stay_booking_frontend/main.dart';
import 'package:stay_booking_frontend/view/splashscreen.dart';

void main() {
  testWidgets('App opens splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
