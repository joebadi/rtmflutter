/// Payment configuration seam.
///
/// The app sells diamonds (in-app virtual currency). Outside the Google Play
/// Store (direct APK / other stores) we use Paystack. If the app is shipped on
/// the Play Store, Google policy requires Google Play Billing for virtual
/// currency instead — build with:
///
///   flutter build apk --dart-define=USE_PLAY_BILLING=true
///
/// and wire a PlayBilling gateway (see PaymentGateway.purchase). Until then the
/// flag defaults to false and all purchases route through Paystack.
const bool kUseGooglePlayBilling =
    bool.fromEnvironment('USE_PLAY_BILLING', defaultValue: false);
