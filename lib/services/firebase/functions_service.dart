import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  FunctionsService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> matchDriver(String bookingId) async {
    final callable = _functions.httpsCallable('matchDriver');
    final result = await callable.call<Map<String, dynamic>>({
      'bookingId': bookingId,
    });
    return result.data;
  }

  Future<void> cancelBooking(String bookingId) async {
    final callable = _functions.httpsCallable('cancelBooking');
    await callable.call({'bookingId': bookingId});
  }
}
