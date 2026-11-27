import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../config/app_config.dart';

/// भुगतान का नतीजा
enum PayStatus { success, failed, cancelled, demo }

class PayResult {
  const PayResult({
    required this.status,
    this.paymentId = '',
    this.orderId = '',
    this.signature = '',
    this.message = '',
  });

  final PayStatus status;
  final String paymentId;
  final String orderId;
  final String signature;
  final String message;

  bool get isPaid => status == PayStatus.success || status == PayStatus.demo;
}

/// Razorpay चेकआउट — key भरते ही असली भुगतान, वरना डेमो सिमुलेशन।
///
/// ⚠️ असली ऐप में भुगतान के बाद `signature` को **सर्वर पर** verify करें
/// (`order_id|payment_id` + Key Secret) — तभी रसीद जारी करें।
/// यहाँ अभी verify नहीं है क्योंकि बैकएंड नहीं जुड़ा; नीचे TODO देखें।
class PaymentService {
  PaymentService({required this.onResult});

  final void Function(PayResult result) onResult;

  Razorpay? _razorpay;
  bool _busy = false;

  bool get isLive => AppConfig.hasRazorpay;
  bool get isBusy => _busy;

  /// राशि **रुपये** में दें — अंदर paise (×100) में बदल जाती है।
  void start({
    required int amountRupees,
    required String name,
    required String phone,
    required String description,
  }) {
    if (_busy) return;
    _busy = true;

    if (!isLive) {
      // डेमो मोड — 1.4 सेकंड बाद सफल
      Timer(const Duration(milliseconds: 1400), () {
        _busy = false;
        onResult(const PayResult(
          status: PayStatus.demo,
          paymentId: 'demo_pay',
          message: 'डेमो भुगतान',
        ));
      });
      return;
    }

    _razorpay ??= Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onWallet);

    final options = <String, dynamic>{
      'key': AppConfig.razorpayKeyId,
      'amount': amountRupees * 100,
      'currency': 'INR',
      'name': 'बाबा सिद्धनाथ मंदिर',
      'description': description,
      'prefill': {
        'name': name,
        if (phone.isNotEmpty) 'contact': phone,
      },
      'theme': {'color': '#5E0F18'},
      'retry': {'enabled': true, 'max_count': 3},
      // बैकएंड तैयार होने पर:
      // 'order_id': <सर्वर से बना order id>,
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      _busy = false;
      onResult(PayResult(status: PayStatus.failed, message: 'चेकआउट नहीं खुल सका: $e'));
    }
  }

  void _onSuccess(PaymentSuccessResponse response) {
    _busy = false;
    // TODO(backend): यहाँ सर्वर से signature verify कराएँ:
    //   POST ${AppConfig.apiBaseUrl}/payments/verify
    //   {order_id, payment_id, signature} → ok मिलने पर ही रसीद जारी करें।
    onResult(PayResult(
      status: PayStatus.success,
      paymentId: response.paymentId ?? '',
      orderId: response.orderId ?? '',
      signature: response.signature ?? '',
    ));
  }

  void _onError(PaymentFailureResponse response) {
    _busy = false;
    final cancelled = response.code == Razorpay.PAYMENT_CANCELLED;
    onResult(PayResult(
      status: cancelled ? PayStatus.cancelled : PayStatus.failed,
      message: response.message ?? 'भुगतान विफल (कोड ${response.code})',
    ));
  }

  void _onWallet(ExternalWalletResponse response) {
    _busy = false;
    onResult(PayResult(
      status: PayStatus.failed,
      message: 'वॉलेट ${response.walletName ?? ''} पूरा नहीं हुआ',
    ));
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _busy = false;
  }
}
