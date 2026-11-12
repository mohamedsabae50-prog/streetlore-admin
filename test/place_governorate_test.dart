import 'package:flutter_test/flutter_test.dart';
import 'package:streetlore_admin/models/egypt_governorates.dart';
import 'package:streetlore_admin/models/models.dart';

void main() {
  test('Place governorate defaults to Alexandria for legacy rows', () {
    final place = Place.fromJson(const {
      'id': 'legacy-place',
      'name': 'Legacy',
    });

    expect(place.governorate, 'alexandria');
    expect(place.toJson()['governorate'], 'alexandria');
    expect(place.toSupabaseUpdate()['governorate'], 'alexandria');
  });

  test('admin governorate choices match configured coverage', () {
    expect(AdminGovernorate.all, hasLength(2));
    expect(AdminGovernorate.all.map((item) => item.id).toSet(), {
      'alexandria',
      'cairo',
    });
    expect(AdminGovernorate.all.first.nameEn, 'Alexandria');
    expect(AdminGovernorate.all.first.nameAr, 'الإسكندرية');
  });
}
