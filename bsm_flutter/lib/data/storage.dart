/// प्लेटफ़ॉर्म के हिसाब से स्टोरेज चुनें: फ़ोन पर फ़ाइल, वेब पर मेमोरी।
export 'storage_stub.dart' if (dart.library.io) 'storage_io.dart';
