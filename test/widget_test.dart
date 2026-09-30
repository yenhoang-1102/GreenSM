import 'package:flutter_test/flutter_test.dart';
import 'package:ride_booking_app/main.dart';

void main() {
  testWidgets('Ride booking app shows splash screen', (tester) async {
    await tester.pumpWidget(const RideBookingApp());

    expect(find.text('RideGo'), findsOneWidget);
    expect(find.text('Dat xe nhanh, di chuyen an tam'), findsOneWidget);
  });
}
