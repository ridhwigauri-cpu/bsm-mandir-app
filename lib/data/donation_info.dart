/// दान के लिए आधिकारिक UPI / बैंक विवरण — स्रोत: फाउंडेशन का PNB QR कार्ड
class DonationInfo {
  const DonationInfo._();

  static const String upiId = '6203051369m@pnb';
  static const String accountName = 'BABA SIDDHNATH MANDIR JIRNODHAR SEVA FOUNDATION';
  static const String accountNo = '1573002100004142';
  static const String bankName = 'पंजाब नेशनल बैंक (PNB), तेलहारा';
  static const String ifsc = 'PUNB157300';
  static const String qrImage = 'assets/images/donation_qr.png';

  /// UPI ऐप जिनसे स्कैन हो सकता है
  static const String apps = 'Google Pay · PhonePe · Paytm · BHIM · Amazon Pay';

  /// NEFT/IMPS के लिए एक साथ
  static String get bankBlock =>
      'खाता नाम: $accountName\n'
      'खाता संख्या: $accountNo\n'
      'बैंक: $bankName\n'
      'IFSC: $ifsc';
}
