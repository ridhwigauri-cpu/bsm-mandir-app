import 'models.dart';

/// वीडियो में दिखाए गए फाउंडेशन के आँकड़े — असली आँकड़े यहीं बदलें।
class BaseData {
  const BaseData._();

  static const List<String> cats = ['जीर्णोद्धार', 'अन्नदान', 'सामान्य दान'];
  static const List<int> amts = [501, 1100, 2100, 5100];
  static const List<String> pujaTypes = ['सामान्य पूजा', 'विशेष पूजा', 'VIP दर्शन पास'];
  static const List<String> methods = ['UPI', 'कार्ड', 'नेटबैंकिंग'];

  static const int slotCap = 6;
  static const int kirtanCap = 4;

  static const int fundTotal = 2500000;
  static const int fundBank = 2150000;
  static const int fundCash = 350000;

  static const List<Project> projects = [
    Project(name: 'मंदिर जीर्णोद्धार कार्य', spent: 980000, target: 1580000, progress: 62, status: 'चालू'),
    Project(name: 'धर्मशाला मरम्मत', spent: 210000, target: 600000, progress: 35, status: 'चालू'),
    Project(name: 'अन्नदान सेवा', spent: 120000, target: 250000, progress: 48, status: 'चालू'),
  ];

  static const int staffTotal = 18;
  static const List<Dept> depts = [
    Dept(name: 'पुजारी', count: 5),
    Dept(name: 'सुरक्षा', count: 4),
    Dept(name: 'प्रबंधन', count: 3),
    Dept(name: 'सफ़ाई व अन्य', count: 6),
  ];
  static const List<SalaryMonth> salaryMonths = [
    SalaryMonth(month: 'जुलाई', paid: true),
    SalaryMonth(month: 'अगस्त', paid: true),
    SalaryMonth(month: 'सितंबर', paid: true),
    SalaryMonth(month: 'अक्टूबर', paid: true),
    SalaryMonth(month: 'नवंबर', paid: false),
  ];

  static const List<Room> rooms = [
    Room(id: 'R1', name: 'कमरा 1', cap: 2, occupied: true, who: 'रमेश शर्मा'),
    Room(id: 'R2', name: 'कमरा 2', cap: 2, occupied: true, who: 'सुनीता देवी'),
    Room(id: 'R3', name: 'कमरा 3', cap: 3),
    Room(id: 'R4', name: 'कमरा 4', cap: 2),
    Room(id: 'R5', name: 'कमरा 5', cap: 4),
    Room(id: 'R6', name: 'कमरा 6', cap: 2),
  ];

  static const List<String> kirtan = [
    '09:00 – 11:00',
    '12:00 – 14:00',
    '16:00 – 18:00',
    '19:00 – 21:00',
  ];

  static const List<String> pujaSlots = [
    '05:30 – 06:30',
    '07:00 – 08:00',
    '09:00 – 10:00',
    '11:00 – 12:00',
    '17:00 – 18:00',
    '19:00 – 20:00',
  ];

  static const Map<String, int> pujaSeed = {'07:00 – 08:00': 6};
  static const Map<String, int> kirtanSeed = {'16:00 – 18:00': 4};

  static const List<Lekha> lekha = [
    Lekha(month: 'जुलाई 2026', daan: 420000, kharch: 280000, status: 'ऑडिट पूर्ण'),
    Lekha(month: 'अगस्त 2026', daan: 380000, kharch: 310000, status: 'ऑडिट पूर्ण'),
    Lekha(month: 'सितंबर 2026', daan: 510000, kharch: 260000, status: 'ऑडिट पूर्ण'),
    Lekha(month: 'अक्टूबर 2026', daan: 620000, kharch: 320000, status: 'ऑडिट पूर्ण'),
  ];

  static const List<Cam> cams = [
    Cam(id: '01', name: 'सिंह द्वार', sub: 'मुख्य प्रवेश'),
    Cam(id: '02', name: 'गर्भगृह द्वार', sub: 'आंतरिक परिसर'),
    Cam(id: '03', name: 'दान पेटिका क्षेत्र', sub: 'दान कक्ष'),
    Cam(id: '04', name: 'धर्मशाला कॉरिडोर', sub: 'धर्मशाला'),
    Cam(id: '05', name: 'अन्नदान रसोई', sub: 'रसोई क्षेत्र'),
    Cam(id: '07', name: 'मगध द्वार', sub: 'परिसर बाहर मार्ग'),
  ];
}
