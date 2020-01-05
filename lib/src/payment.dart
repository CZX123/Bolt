import '../library.dart';

/// A very simple mock payment API. Will need to further improve and enhance on it.
class PaymentApi {
  static Future<PaymentCompletionDetails> pay({
    @required PaymentDetails details,
  }) async {
    // TODO: Implement payment
    return PaymentCompletionDetails._(
      stallId: details.stallId,
      amount: details.amount,
      success: true,
    );
  }
}

class PaymentDetails {
  /// Which stall to pay to
  final StallId stallId;

  /// How much to pay. Amount in SGD.
  final num amount;

  const PaymentDetails({this.stallId, this.amount});
}

class PaymentCompletionDetails {
  final StallId stallId;
  final num amount;
  final bool success;
  const PaymentCompletionDetails._({this.amount, this.stallId, this.success});
}
