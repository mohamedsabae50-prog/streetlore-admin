class AdminGovernorate {
  final String id;
  final String nameEn;
  final String nameAr;
  final double centerLat;
  final double centerLng;

  const AdminGovernorate(
    this.id,
    this.nameEn,
    this.nameAr,
    this.centerLat,
    this.centerLng,
  );

  static const all = <AdminGovernorate>[
    AdminGovernorate(
      'alexandria',
      'Alexandria',
      'الإسكندرية',
      31.2001,
      29.9187,
    ),
    AdminGovernorate('cairo', 'Cairo', 'القاهرة', 30.0444, 31.2357),
    AdminGovernorate('giza', 'Giza', 'الجيزة', 30.0131, 31.2089),
    AdminGovernorate('qalyubia', 'Qalyubia', 'القليوبية', 30.4660, 31.1848),
    AdminGovernorate('beheira', 'Beheira', 'البحيرة', 31.0409, 30.4700),
    AdminGovernorate('matrouh', 'Matrouh', 'مطروح', 31.3543, 27.2373),
    AdminGovernorate(
      'kafr_el_sheikh',
      'Kafr El Sheikh',
      'كفر الشيخ',
      31.1107,
      30.9388,
    ),
    AdminGovernorate('gharbia', 'Gharbia', 'الغربية', 30.7865, 31.0004),
    AdminGovernorate('monufia', 'Monufia', 'المنوفية', 30.5972, 30.9876),
    AdminGovernorate('dakahlia', 'Dakahlia', 'الدقهلية', 31.0409, 31.3785),
    AdminGovernorate('damietta', 'Damietta', 'دمياط', 31.4175, 31.8144),
    AdminGovernorate('port_said', 'Port Said', 'بورسعيد', 31.2653, 32.3019),
    AdminGovernorate('ismailia', 'Ismailia', 'الإسماعيلية', 30.5965, 32.2715),
    AdminGovernorate('suez', 'Suez', 'السويس', 29.9668, 32.5498),
    AdminGovernorate('sharqia', 'Sharqia', 'الشرقية', 30.5877, 31.5020),
    AdminGovernorate(
      'north_sinai',
      'North Sinai',
      'شمال سيناء',
      31.1321,
      33.8033,
    ),
    AdminGovernorate(
      'south_sinai',
      'South Sinai',
      'جنوب سيناء',
      28.5091,
      34.4394,
    ),
    AdminGovernorate('red_sea', 'Red Sea', 'البحر الأحمر', 27.2579, 33.8116),
    AdminGovernorate('faiyum', 'Faiyum', 'الفيوم', 29.3084, 30.8428),
    AdminGovernorate('beni_suef', 'Beni Suef', 'بني سويف', 29.0661, 31.0994),
    AdminGovernorate('minya', 'Minya', 'المنيا', 28.1099, 30.7503),
    AdminGovernorate('assiut', 'Assiut', 'أسيوط', 27.1810, 31.1837),
    AdminGovernorate('sohag', 'Sohag', 'سوهاج', 26.5570, 31.6948),
    AdminGovernorate('qena', 'Qena', 'قنا', 26.1551, 32.7160),
    AdminGovernorate('luxor', 'Luxor', 'الأقصر', 25.6872, 32.6396),
    AdminGovernorate('aswan', 'Aswan', 'أسوان', 24.0889, 32.8998),
    AdminGovernorate(
      'new_valley',
      'New Valley',
      'الوادي الجديد',
      25.4514,
      30.5463,
    ),
  ];
}
